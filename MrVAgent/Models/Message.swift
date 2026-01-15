import Foundation

struct Message: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    // Helper to create user message
    static func user(_ content: String) -> Message {
        Message(content: content, isUser: true)
    }

    // Helper to create AI message
    static func assistant(_ content: String, streaming: Bool = false) -> Message {
        Message(content: content, isUser: false, isStreaming: streaming)
    }
}
