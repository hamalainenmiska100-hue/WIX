import Foundation

struct ChatSession: Codable {
    var messages: [ChatMessage]
    var updatedAt: Date

    init(messages: [ChatMessage] = [], updatedAt: Date = .now) {
        self.messages = messages
        self.updatedAt = updatedAt
    }
}
