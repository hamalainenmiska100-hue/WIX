import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String
    var createdAt: Date
    var attachments: [StoredAttachment]
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        createdAt: Date = .now,
        attachments: [StoredAttachment] = [],
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.attachments = attachments
        self.isStreaming = isStreaming
    }
}
