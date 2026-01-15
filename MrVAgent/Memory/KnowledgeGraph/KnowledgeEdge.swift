import Foundation

/// Knowledge edge representing relationships between nodes
struct KnowledgeEdge: Identifiable, Codable, Equatable {
    let id: String
    let sourceId: String
    let targetId: String
    var relationship: RelationType
    var weight: Float  // 0.0 - 1.0 (relationship strength)
    var createdAt: Date
    var bidirectional: Bool
    var metadata: EdgeMetadata

    enum RelationType: String, Codable, Equatable, CaseIterable {
        case dependsOn = "depends_on"
        case relatesTo = "relates_to"
        case uses = "uses"
        case implements = "implements"
        case extends = "extends"
        case contains = "contains"
        case createdBy = "created_by"
        case mentions = "mentions"
        case requires = "requires"
        case produces = "produces"
        case influences = "influences"
        case similarTo = "similar_to"

        var description: String {
            switch self {
            case .dependsOn: return "depends on"
            case .relatesTo: return "relates to"
            case .uses: return "uses"
            case .implements: return "implements"
            case .extends: return "extends"
            case .contains: return "contains"
            case .createdBy: return "created by"
            case .mentions: return "mentions"
            case .requires: return "requires"
            case .produces: return "produces"
            case .influences: return "influences"
            case .similarTo: return "similar to"
            }
        }

        var reverseDescription: String {
            switch self {
            case .dependsOn: return "is depended on by"
            case .relatesTo: return "relates to"
            case .uses: return "is used by"
            case .implements: return "is implemented by"
            case .extends: return "is extended by"
            case .contains: return "is contained in"
            case .createdBy: return "created"
            case .mentions: return "is mentioned in"
            case .requires: return "is required by"
            case .produces: return "is produced by"
            case .influences: return "is influenced by"
            case .similarTo: return "similar to"
            }
        }

        var isSymmetric: Bool {
            switch self {
            case .relatesTo, .similarTo:
                return true
            default:
                return false
            }
        }
    }

    struct EdgeMetadata: Codable, Equatable {
        var sourceConversationId: String?
        var sourceDecisionId: String?
        var confidence: Float = 1.0
        var customFields: [String: String] = [:]

        init(
            sourceConversationId: String? = nil,
            sourceDecisionId: String? = nil,
            confidence: Float = 1.0,
            customFields: [String: String] = [:]
        ) {
            self.sourceConversationId = sourceConversationId
            self.sourceDecisionId = sourceDecisionId
            self.confidence = confidence
            self.customFields = customFields
        }
    }

    init(
        id: String = UUID().uuidString,
        sourceId: String,
        targetId: String,
        relationship: RelationType,
        weight: Float = 1.0,
        createdAt: Date = Date(),
        bidirectional: Bool? = nil,
        metadata: EdgeMetadata = EdgeMetadata()
    ) {
        self.id = id
        self.sourceId = sourceId
        self.targetId = targetId
        self.relationship = relationship
        self.weight = weight
        self.createdAt = createdAt
        self.bidirectional = bidirectional ?? relationship.isSymmetric
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    var isStrong: Bool {
        weight >= 0.7
    }

    var isWeak: Bool {
        weight < 0.3
    }

    var ageInDays: Int {
        let components = Calendar.current.dateComponents([.day], from: createdAt, to: Date())
        return components.day ?? 0
    }

    // MARK: - Methods

    mutating func strengthenWeight(_ amount: Float = 0.1) {
        weight = min(1.0, weight + amount)
    }

    mutating func weakenWeight(_ amount: Float = 0.1) {
        weight = max(0.0, weight - amount)
    }

    func connects(nodeId: String) -> Bool {
        return sourceId == nodeId || (bidirectional && targetId == nodeId)
    }

    func otherNode(from nodeId: String) -> String? {
        if sourceId == nodeId {
            return targetId
        } else if bidirectional && targetId == nodeId {
            return sourceId
        }
        return nil
    }
}

// MARK: - Edge Collection Extensions

extension Collection where Element == KnowledgeEdge {
    func filterByRelationship(_ type: KnowledgeEdge.RelationType) -> [KnowledgeEdge] {
        self.filter { $0.relationship == type }
    }

    func filterStrong() -> [KnowledgeEdge] {
        self.filter { $0.isStrong }
    }

    func connectingTo(_ nodeId: String) -> [KnowledgeEdge] {
        self.filter { edge in
            edge.sourceId == nodeId || (edge.bidirectional && edge.targetId == nodeId)
        }
    }

    func sortedByWeight() -> [KnowledgeEdge] {
        self.sorted { $0.weight > $1.weight }
    }
}
