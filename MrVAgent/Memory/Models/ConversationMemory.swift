import Foundation

/// Conversation memory model
/// Stores a single conversation exchange with metadata
struct ConversationMemory: Identifiable, Codable, Equatable {
    let id: String
    let projectId: String?
    let timestamp: Date
    let userInput: String
    let aiResponse: String
    let modelUsed: AIProvider
    var responseTime: TimeInterval
    var metadata: ConversationMetadata

    struct ConversationMetadata: Codable, Equatable {
        var mood: String?  // Mood state during conversation
        var intent: String?  // Detected intent
        var providerStats: ProviderPerformance?
        var tokenCount: Int?
        var costEstimate: Double?
        var contextLength: Int?
        var customFields: [String: String] = [:]

        init(
            mood: String? = nil,
            intent: String? = nil,
            providerStats: ProviderPerformance? = nil,
            tokenCount: Int? = nil,
            costEstimate: Double? = nil,
            contextLength: Int? = nil,
            customFields: [String: String] = [:]
        ) {
            self.mood = mood
            self.intent = intent
            self.providerStats = providerStats
            self.tokenCount = tokenCount
            self.costEstimate = costEstimate
            self.contextLength = contextLength
            self.customFields = customFields
        }
    }

    struct ProviderPerformance: Codable, Equatable {
        var provider: AIProvider
        var successRate: Double
        var averageResponseTime: TimeInterval
        var fallbackUsed: Bool

        init(
            provider: AIProvider,
            successRate: Double,
            averageResponseTime: TimeInterval,
            fallbackUsed: Bool = false
        ) {
            self.provider = provider
            self.successRate = successRate
            self.averageResponseTime = averageResponseTime
            self.fallbackUsed = fallbackUsed
        }
    }

    init(
        id: String = UUID().uuidString,
        projectId: String? = nil,
        timestamp: Date = Date(),
        userInput: String,
        aiResponse: String,
        modelUsed: AIProvider,
        responseTime: TimeInterval,
        metadata: ConversationMetadata = ConversationMetadata()
    ) {
        self.id = id
        self.projectId = projectId
        self.timestamp = timestamp
        self.userInput = userInput
        self.aiResponse = aiResponse
        self.modelUsed = modelUsed
        self.responseTime = responseTime
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    var isRecent: Bool {
        let hoursSinceConversation = Date().timeIntervalSince(timestamp) / 3600
        return hoursSinceConversation < 24
    }

    var summary: String {
        let inputPreview = userInput.prefix(50)
        let responsePreview = aiResponse.prefix(50)
        return "\(inputPreview)... → \(responsePreview)..."
    }

    var wordCount: Int {
        (userInput + " " + aiResponse).components(separatedBy: .whitespacesAndNewlines).count
    }

    // MARK: - Methods

    func matchesKeywords(_ keywords: [String]) -> Bool {
        let combined = (userInput + " " + aiResponse).lowercased()
        return keywords.contains { keyword in
            combined.contains(keyword.lowercased())
        }
    }

    func containsCode() -> Bool {
        // Simple heuristic: check for common code patterns
        let codePatterns = ["func ", "class ", "def ", "import ", "const ", "var ", "let "]
        let combined = userInput + " " + aiResponse
        return codePatterns.contains { pattern in
            combined.contains(pattern)
        }
    }

    func similarity(to other: ConversationMemory) -> Double {
        // Simple Jaccard similarity based on words
        let words1 = Set(self.userInput.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(other.userInput.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count

        guard union > 0 else { return 0.0 }
        return Double(intersection) / Double(union)
    }
}

// MARK: - Conversation Statistics

struct ConversationStats: Codable, Equatable {
    var totalMessages: Int
    var averageResponseTime: TimeInterval
    var totalWordCount: Int
    var mostUsedProvider: AIProvider?
    var averageMessagesPerDay: Double
    var longestConversation: Int  // Max messages in single session

    init(
        totalMessages: Int = 0,
        averageResponseTime: TimeInterval = 0,
        totalWordCount: Int = 0,
        mostUsedProvider: AIProvider? = nil,
        averageMessagesPerDay: Double = 0,
        longestConversation: Int = 0
    ) {
        self.totalMessages = totalMessages
        self.averageResponseTime = averageResponseTime
        self.totalWordCount = totalWordCount
        self.mostUsedProvider = mostUsedProvider
        self.averageMessagesPerDay = averageMessagesPerDay
        self.longestConversation = longestConversation
    }
}
