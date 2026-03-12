import Foundation

struct GeminiAPI {
    enum GeminiError: LocalizedError {
        case missingConfiguration
        case invalidResponse
        case serverError(String)
        case emptyReply

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Lisää ensin Gemini API -avain ja mallin nimi asetuksissa."
            case .invalidResponse:
                return "Gemini palautti odottamattoman vastauksen."
            case .serverError(let message):
                return message
            case .emptyReply:
                return "Malli ei palauttanut tekstiä."
            }
        }
    }

    private let session: URLSession
    private let parser = SSEEventParser()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func streamReply(
        history: [ChatMessage],
        currentUserMessage: ChatMessage,
        apiKey: String,
        modelName: String,
        mode: ResponseMode,
        onDelta: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty, !trimmedModel.isEmpty else {
            throw GeminiError.missingConfiguration
        }

        let uploadedFiles = try await uploadAttachments(currentUserMessage.attachments, apiKey: trimmedKey)
        defer {
            Task {
                await deleteUploadedFilesIfPossible(uploadedFiles, apiKey: trimmedKey)
            }
        }

        let contents = makeContents(history: history, currentUserMessage: currentUserMessage, uploadedFiles: uploadedFiles)
        let body = GenerateContentRequest(
            contents: contents,
            generationConfig: .init(temperature: mode.temperature, maxOutputTokens: mode.maxOutputTokens)
        )

        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(trimmedModel):streamGenerateContent?alt=sse"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 240
        request.setValue(trimmedKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if !(200 ... 299).contains(http.statusCode) {
            var errorText = ""
            for try await line in bytes.lines {
                errorText += line
            }
            throw GeminiError.serverError(errorText.isEmpty ? "Gemini API palautti virheen \(http.statusCode)." : errorText)
        }

        var completeText = ""

        for try await line in bytes.lines {
            guard let payload = parser.dataPayload(from: line),
                  let data = payload.data(using: .utf8) else {
                continue
            }

            if let chunk = try? JSONDecoder().decode(StreamGenerateContentResponse.self, from: data) {
                let delta = chunk.candidates?
                    .compactMap { candidate in
                        candidate.content?.parts?.compactMap(\.text).joined()
                    }
                    .joined() ?? ""

                if !delta.isEmpty {
                    completeText += delta
                    await MainActor.run {
                        onDelta(delta)
                    }
                }
                continue
            }

            if let apiError = try? JSONDecoder().decode(GeminiErrorEnvelope.self, from: data) {
                throw GeminiError.serverError(apiError.error.message)
            }
        }

        guard !completeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiError.emptyReply
        }

        return completeText
    }

    private func makeContents(
        history: [ChatMessage],
        currentUserMessage: ChatMessage,
        uploadedFiles: [UploadedFile]
    ) -> [ContentPayload] {
        var contentPayloads = history.map { message in
            ContentPayload(
                role: message.role == .user ? "user" : "model",
                parts: [.text(message.text.trimmingCharacters(in: .whitespacesAndNewlines))]
            )
        }
        .filter { !$0.parts.isEmpty && !$0.parts.allSatisfy(\.isEffectivelyEmpty) }

        var currentParts: [ContentPart] = []
        let currentText = currentUserMessage.text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentParts.append(.text(currentText.isEmpty ? "Analyze the attached content." : currentText))
        currentParts.append(contentsOf: uploadedFiles.map { .fileData(mimeType: $0.mimeType, fileURI: $0.uri) })

        contentPayloads.append(ContentPayload(role: "user", parts: currentParts))
        return contentPayloads
    }

    private func uploadAttachments(_ attachments: [StoredAttachment], apiKey: String) async throws -> [UploadedFile] {
        var results: [UploadedFile] = []
        for attachment in attachments {
            let data = try Data(contentsOf: attachment.fileURL)
            let uploaded = try await uploadResumableFile(
                data: data,
                displayName: attachment.fileName,
                mimeType: attachment.mimeType,
                apiKey: apiKey
            )
            results.append(uploaded)
        }
        return results
    }

    private func uploadResumableFile(
        data: Data,
        displayName: String,
        mimeType: String,
        apiKey: String
    ) async throws -> UploadedFile {
        guard let startURL = URL(string: "https://generativelanguage.googleapis.com/upload/v1beta/files") else {
            throw GeminiError.invalidResponse
        }

        var startRequest = URLRequest(url: startURL)
        startRequest.httpMethod = "POST"
        startRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        startRequest.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        startRequest.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        startRequest.setValue("\(data.count)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        startRequest.setValue(mimeType, forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        startRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        startRequest.httpBody = try JSONEncoder().encode(UploadStartRequest(file: .init(displayName: displayName)))

        let (_, startResponse) = try await session.data(for: startRequest)
        guard let startHTTP = startResponse as? HTTPURLResponse,
              (200 ... 299).contains(startHTTP.statusCode),
              let uploadURLString = startHTTP.value(forHTTPHeaderField: "x-goog-upload-url") ?? startHTTP.value(forHTTPHeaderField: "X-Goog-Upload-URL"),
              let uploadURL = URL(string: uploadURLString) else {
            throw GeminiError.serverError("Tiedoston uploadin aloitus epäonnistui.")
        }

        var finalizeRequest = URLRequest(url: uploadURL)
        finalizeRequest.httpMethod = "POST"
        finalizeRequest.timeoutInterval = 300
        finalizeRequest.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        finalizeRequest.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        finalizeRequest.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        finalizeRequest.httpBody = data

        let (finalData, finalResponse) = try await session.data(for: finalizeRequest)
        guard let finalHTTP = finalResponse as? HTTPURLResponse,
              (200 ... 299).contains(finalHTTP.statusCode) else {
            let responseBody = String(data: finalData, encoding: .utf8) ?? ""
            throw GeminiError.serverError(responseBody.isEmpty ? "Tiedoston upload epäonnistui." : responseBody)
        }

        let envelope = try JSONDecoder().decode(FileEnvelope.self, from: finalData)
        return try await waitUntilFileIsReady(envelope.file, apiKey: apiKey)
    }

    private func waitUntilFileIsReady(_ file: UploadedFile, apiKey: String) async throws -> UploadedFile {
        guard let state = file.state, !state.isEmpty, state.uppercased() != "ACTIVE" else {
            return file
        }

        var attempts = 0
        var current = file
        while attempts < 24 {
            try await Task.sleep(for: .seconds(1))
            current = try await fetchFile(name: current.name, apiKey: apiKey)
            if current.state?.uppercased() == "ACTIVE" || current.state == nil {
                return current
            }
            attempts += 1
        }

        return current
    }

    private func fetchFile(name: String, apiKey: String) async throws -> UploadedFile {
        let escapedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(escapedName)") else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode) else {
            throw GeminiError.serverError("Tiedoston tilan tarkistus epäonnistui.")
        }

        return try JSONDecoder().decode(UploadedFile.self, from: data)
    }

    private func deleteUploadedFilesIfPossible(_ files: [UploadedFile], apiKey: String) async {
        for file in files {
            let escapedName = file.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.name
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(escapedName)") else {
                continue
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            _ = try? await session.data(for: request)
        }
    }
}

private struct GenerateContentRequest: Encodable {
    let contents: [ContentPayload]
    let generationConfig: GenerationConfig?
}

private struct GenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "maxOutputTokens"
    }
}

private struct ContentPayload: Encodable {
    let role: String
    let parts: [ContentPart]
}

private enum ContentPart: Encodable {
    case text(String)
    case fileData(mimeType: String, fileURI: String)

    var isEffectivelyEmpty: Bool {
        switch self {
        case .text(let value):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .fileData:
            return false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(TextPart(text: text))
        case .fileData(let mimeType, let fileURI):
            try container.encode(FileDataPart(fileData: .init(mimeType: mimeType, fileURI: fileURI)))
        }
    }
}

private struct TextPart: Encodable {
    let text: String
}

private struct FileDataPart: Encodable {
    let fileData: FileDataPayload

    enum CodingKeys: String, CodingKey {
        case fileData = "file_data"
    }
}

private struct FileDataPayload: Encodable {
    let mimeType: String
    let fileURI: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case fileURI = "file_uri"
    }
}

private struct UploadStartRequest: Encodable {
    let file: UploadFileMetadata
}

private struct UploadFileMetadata: Encodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

private struct FileEnvelope: Decodable {
    let file: UploadedFile
}

private struct UploadedFile: Decodable {
    let name: String
    let uri: String
    let mimeType: String
    let state: String?

    enum CodingKeys: String, CodingKey {
        case name
        case uri
        case mimeType
        case state
    }
}

private struct StreamGenerateContentResponse: Decodable {
    let candidates: [StreamCandidate]?
}

private struct StreamCandidate: Decodable {
    let content: StreamContent?
}

private struct StreamContent: Decodable {
    let parts: [StreamPart]?
}

private struct StreamPart: Decodable {
    let text: String?
}

private struct GeminiErrorEnvelope: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let message: String
}
