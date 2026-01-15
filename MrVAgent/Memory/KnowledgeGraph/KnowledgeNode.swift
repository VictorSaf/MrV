import Foundation

/// Knowledge node in the graph
/// Represents concepts, tools, people, artifacts discovered during conversations
struct KnowledgeNode: Identifiable, Codable, Equatable {
    let id: String
    var type: NodeType
    var name: String
    var content: NodeContent
    var createdAt: Date
    var updatedAt: Date
    var projectId: String?  // nil for global knowledge
    var confidence: Float  // 0.0 - 1.0
    var usageCount: Int
    var lastUsed: Date?
    var metadata: NodeMetadata

    enum NodeType: String, Codable, Equatable {
        case concept      // Abstract concepts, ideas
        case tool         // Libraries, frameworks, APIs
        case person       // People mentioned or referenced
        case artifact     // Files, documents, outputs
        case task         // Tasks or actions
        case file         // Specific file references
        case api          // API endpoints
        case pattern      // Design patterns, practices

        var icon: String {
            switch self {
            case .concept: return "💡"
            case .tool: return "🔧"
            case .person: return "👤"
            case .artifact: return "📦"
            case .task: return "✓"
            case .file: return "📄"
            case .api: return "🔌"
            case .pattern: return "🎨"
            }
        }
    }

    struct NodeContent: Codable, Equatable {
        var description: String?
        var properties: [String: String] = [:]
        var examples: [String] = []
        var references: [String] = []  // URLs or file paths
        var tags: [String] = []

        init(
            description: String? = nil,
            properties: [String: String] = [:],
            examples: [String] = [],
            references: [String] = [],
            tags: [String] = []
        ) {
            self.description = description
            self.properties = properties
            self.examples = examples
            self.references = references
            self.tags = tags
        }
    }

    struct NodeMetadata: Codable, Equatable {
        var sourceConversationIds: [String] = []
        var sourceDecisionIds: [String] = []
        var customFields: [String: String] = [:]
        var importance: Float = 0.5  // 0.0 - 1.0

        init(
            sourceConversationIds: [String] = [],
            sourceDecisionIds: [String] = [],
            customFields: [String: String] = [:],
            importance: Float = 0.5
        ) {
            self.sourceConversationIds = sourceConversationIds
            self.sourceDecisionIds = sourceDecisionIds
            self.customFields = customFields
            self.importance = importance
        }
    }

    init(
        id: String = UUID().uuidString,
        type: NodeType,
        name: String,
        content: NodeContent = NodeContent(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        projectId: String? = nil,
        confidence: Float = 1.0,
        usageCount: Int = 0,
        lastUsed: Date? = nil,
        metadata: NodeMetadata = NodeMetadata()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.projectId = projectId
        self.confidence = confidence
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    var isGlobal: Bool {
        projectId == nil
    }

    var isHighConfidence: Bool {
        confidence >= 0.7
    }

    var isFrequentlyUsed: Bool {
        usageCount >= 5
    }

    var isRecent: Bool {
        guard let lastUsed = lastUsed else { return false }
        let hoursSince = Date().timeIntervalSince(lastUsed) / 3600
        return hoursSince < 168  // Last week
    }

    // MARK: - Methods

    mutating func incrementUsage() {
        usageCount += 1
        lastUsed = Date()
    }

    mutating func updateContent(_ newContent: NodeContent) {
        content = newContent
        updatedAt = Date()
    }

    mutating func adjustConfidence(_ delta: Float) {
        confidence = max(0.0, min(1.0, confidence + delta))
    }

    mutating func addExample(_ example: String) {
        if !content.examples.contains(example) {
            content.examples.append(example)
            updatedAt = Date()
        }
    }

    mutating func addTag(_ tag: String) {
        if !content.tags.contains(tag) {
            content.tags.append(tag)
            updatedAt = Date()
        }
    }

    func matchesKeywords(_ keywords: [String]) -> Bool {
        let searchText = ([name] + [content.description ?? ""] + content.tags).joined(separator: " ").lowercased()
        return keywords.contains { keyword in
            searchText.contains(keyword.lowercased())
        }
    }
}

// MARK: - KnowledgeNode Collection Extensions

extension Collection where Element == KnowledgeNode {
    func sorted(by criterion: KnowledgeSortCriterion) -> [KnowledgeNode] {
        switch criterion {
        case .usageCount:
            return self.sorted { $0.usageCount > $1.usageCount }
        case .confidence:
            return self.sorted { $0.confidence > $1.confidence }
        case .recency:
            return self.sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .alphabetical:
            return self.sorted { $0.name < $1.name }
        case .importance:
            return self.sorted { $0.metadata.importance > $1.metadata.importance }
        }
    }

    func filterByType(_ type: KnowledgeNode.NodeType) -> [KnowledgeNode] {
        self.filter { $0.type == type }
    }

    func filterByProject(_ projectId: String?) -> [KnowledgeNode] {
        self.filter { $0.projectId == projectId }
    }

    func filterHighConfidence() -> [KnowledgeNode] {
        self.filter { $0.isHighConfidence }
    }
}

enum KnowledgeSortCriterion {
    case usageCount
    case confidence
    case recency
    case alphabetical
    case importance
}
