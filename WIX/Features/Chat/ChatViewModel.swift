import SwiftUI
import Foundation
import PhotosUI
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var composerText = ""
    @Published var draftAttachments: [StoredAttachment] = []
    @Published var isShowingFileImporter = false
    @Published var isShowingSettings = false
    @Published var isStreaming = false
    @Published var errorMessage: String?

    private let conversationStore: ConversationStore
    private let api: GeminiAPI
    private unowned let config: AppConfigStore
    private var streamingTask: Task<Void, Never>?
    private var currentStreamingMessageID: UUID?

    init(
        config: AppConfigStore,
        conversationStore: ConversationStore = ConversationStore(),
        api: GeminiAPI = GeminiAPI()
    ) {
        self.config = config
        self.conversationStore = conversationStore
        self.api = api

        Task { [weak self] in
            guard let self else { return }
            let session = await conversationStore.loadSession()
            self.messages = session.messages
        }
    }

    var canSend: Bool {
        (!composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !draftAttachments.isEmpty) && !isStreaming
    }

    func sendMessage() {
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = draftAttachments
        guard !text.isEmpty || !attachments.isEmpty else { return }

        Haptics.soft()

        let historySnapshot = messages
        let userMessage = ChatMessage(
            role: .user,
            text: text.isEmpty ? defaultAttachmentPrompt(for: attachments) : text,
            attachments: attachments
        )
        let assistantPlaceholder = ChatMessage(role: .assistant, text: "", isStreaming: true)

        messages.append(userMessage)
        messages.append(assistantPlaceholder)
        composerText = ""
        draftAttachments = []
        isStreaming = true
        currentStreamingMessageID = assistantPlaceholder.id
        persist()

        streamingTask?.cancel()
        streamingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let _ = try await api.streamReply(
    history: historySnapshot,
    currentUserMessage: userMessage,
    apiKey: config.apiKey,
    modelName: config.modelName,
    mode: config.selectedMode
) { [weak self] delta in
    Task { @MainActor in
        self?.appendStreamingText(delta, to: assistantPlaceholder.id)
    }
}
                self.finishStreamingMessage(id: assistantPlaceholder.id)
                Haptics.success()
            } catch is CancellationError {
                self.stopStreaming(markAsCancelled: true)
            } catch {
                self.markStreamingFailed(id: assistantPlaceholder.id, error: error)
                Haptics.warning()
            }
        }
    }

    func stopStreaming(markAsCancelled: Bool = false) {
        streamingTask?.cancel()
        streamingTask = nil

        guard let id = currentStreamingMessageID,
              let index = messages.firstIndex(where: { $0.id == id }) else {
            isStreaming = false
            return
        }

        messages[index].isStreaming = false
        if markAsCancelled && messages[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages[index].text = "Keskeytetty."
        }
        isStreaming = false
        currentStreamingMessageID = nil
        persist()
    }

    func addFiles(from urls: [URL]) {
        Task { [weak self] in
            guard let self else { return }
            for url in urls {
                do {
                    let attachment = try await conversationStore.importFile(from: url)
                    draftAttachments.append(attachment)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func addPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let imageData = UIImage(data: data)?.jpegData(compressionQuality: 0.88) ?? data
                let fileName = "image-\(UUID().uuidString).jpg"
                let attachment = try await conversationStore.saveImageData(imageData, fileName: fileName)
                draftAttachments.append(attachment)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeDraftAttachment(_ attachment: StoredAttachment) {
        draftAttachments.removeAll { $0.id == attachment.id }
        Task {
            await conversationStore.deleteAttachment(attachment)
        }
    }

    func clearEverything() {
        streamingTask?.cancel()
        messages = []
        composerText = ""
        draftAttachments = []
        isStreaming = false
        currentStreamingMessageID = nil
        Task {
            await conversationStore.clearAll()
        }
        Haptics.warning()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func appendStreamingText(_ text: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text += text
        persist()
    }

    private func finishStreamingMessage(id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].isStreaming = false
        isStreaming = false
        currentStreamingMessageID = nil
        streamingTask = nil
        persist()
    }

    private func markStreamingFailed(id: UUID, error: Error) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        if messages[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages[index].text = "Virhe: \(error.localizedDescription)"
        }
        messages[index].isStreaming = false
        isStreaming = false
        currentStreamingMessageID = nil
        streamingTask = nil
        errorMessage = error.localizedDescription
        persist()
    }

    private func persist() {
        let snapshot = messages
        Task {
            await conversationStore.save(messages: snapshot)
        }
    }

    private func defaultAttachmentPrompt(for attachments: [StoredAttachment]) -> String {
        let imageCount = attachments.filter { $0.kind == .image }.count
        let fileCount = attachments.count - imageCount

        switch (imageCount, fileCount) {
        case (let images, 0):
            return images == 1 ? "Analyze this image." : "Analyze these images."
        case (0, let files):
            return files == 1 ? "Analyze this file." : "Analyze these files."
        default:
            return "Analyze the attached content."
        }
    }
}
