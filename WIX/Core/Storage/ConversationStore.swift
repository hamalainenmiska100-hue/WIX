import Foundation

actor ConversationStore {
    enum StorageError: LocalizedError {
        case fileTooLarge
        case pdfTooLarge
        case failedToPrepareFolder

        var errorDescription: String? {
            switch self {
            case .fileTooLarge:
                return "Tiedosto on liian suuri. Pidä kokonaiskoko alle noin 100 Mt."
            case .pdfTooLarge:
                return "PDF on liian suuri. Pidä PDF alle noin 50 Mt."
            case .failedToPrepareFolder:
                return "Sovelluksen tallennuskansiota ei voitu valmistella."
            }
        }
    }

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private lazy var baseDirectory: URL = {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = root.appendingPathComponent("WIX", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }()

    private lazy var attachmentsDirectory: URL = {
        let url = baseDirectory.appendingPathComponent("Attachments", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }()

    private var sessionFile: URL {
        baseDirectory.appendingPathComponent("session.json")
    }

    func loadSession() -> ChatSession {
        guard let data = try? Data(contentsOf: sessionFile),
              let session = try? decoder.decode(ChatSession.self, from: data) else {
            return ChatSession()
        }
        return session
    }

    func save(messages: [ChatMessage]) {
        let session = ChatSession(messages: messages, updatedAt: .now)
        guard let data = try? encoder.encode(session) else { return }
        try? data.write(to: sessionFile, options: [.atomic])
    }

    func clearAll() {
        try? fileManager.removeItem(at: baseDirectory)
        _ = baseDirectory
        _ = attachmentsDirectory
    }

    func deleteAttachment(_ attachment: StoredAttachment) {
        try? fileManager.removeItem(at: attachment.fileURL)
    }

    func importFile(from sourceURL: URL, preferredFileName: String? = nil) throws -> StoredAttachment {
        _ = baseDirectory
        _ = attachmentsDirectory

        let fileName = preferredFileName ?? sourceURL.lastPathComponent
        let safeName = "\(UUID().uuidString)-\(fileName.replacingOccurrences(of: "/", with: "-"))"
        let destination = attachmentsDirectory.appendingPathComponent(safeName)

        let startedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if startedAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let resourceValues = try? sourceURL.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Int64(resourceValues?.fileSize ?? 0)
        let mimeType = MimeType.from(fileURL: sourceURL)
        try validateFileSize(fileSize, mimeType: mimeType)

        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)

        let storedMimeType = MimeType.from(fileURL: destination)
        return StoredAttachment(
            fileName: fileName,
            mimeType: storedMimeType,
            localPath: destination.path,
            kind: MimeType.attachmentKind(for: storedMimeType),
            fileSizeBytes: fileSize
        )
    }

    func saveImageData(_ data: Data, fileName: String) throws -> StoredAttachment {
        _ = baseDirectory
        _ = attachmentsDirectory

        try validateFileSize(Int64(data.count), mimeType: "image/jpeg")

        let safeName = "\(UUID().uuidString)-\(fileName.replacingOccurrences(of: "/", with: "-"))"
        let destination = attachmentsDirectory.appendingPathComponent(safeName)
        try data.write(to: destination, options: [.atomic])

        return StoredAttachment(
            fileName: fileName,
            mimeType: "image/jpeg",
            localPath: destination.path,
            kind: .image,
            fileSizeBytes: Int64(data.count)
        )
    }

    private func validateFileSize(_ size: Int64, mimeType: String) throws {
        let fiftyMB = Int64(50 * 1024 * 1024)
        let hundredMB = Int64(100 * 1024 * 1024)

        if mimeType == "application/pdf" && size > fiftyMB {
            throw StorageError.pdfTooLarge
        }

        if size > hundredMB {
            throw StorageError.fileTooLarge
        }
    }
}
