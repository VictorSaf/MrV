import Foundation

/// Decision log model
/// Tracks important decisions made during project work
struct DecisionLog: Identifiable, Codable, Equatable {
    let id: String
    let projectId: String?
    let timestamp: Date
    var decisionText: String
    var rationale: String?
    var alternatives: [Alternative]
    var outcome: String?
    var owner: DecisionOwner
    var tags: [String]
    var metadata: DecisionMetadata

    enum DecisionOwner: String, Codable, Equatable {
        case user
        case ai
        case collaborative
    }

    struct Alternative: Codable, Equatable {
        var option: String
        var pros: [String]
        var cons: [String]
        var wasChosen: Bool

        init(
            option: String,
            pros: [String] = [],
            cons: [String] = [],
            wasChosen: Bool = false
        ) {
            self.option = option
            self.pros = pros
            self.cons = cons
            self.wasChosen = wasChosen
        }
    }

    struct DecisionMetadata: Codable, Equatable {
        var importance: Int = 3  // 1-5 scale
        var reversible: Bool = true
        var implementedAt: Date?
        var reviewedAt: Date?
        var relatedConversationIds: [String] = []
        var customFields: [String: String] = [:]

        init(
            importance: Int = 3,
            reversible: Bool = true,
            implementedAt: Date? = nil,
            reviewedAt: Date? = nil,
            relatedConversationIds: [String] = [],
            customFields: [String: String] = [:]
        ) {
            self.importance = importance
            self.reversible = reversible
            self.implementedAt = implementedAt
            self.reviewedAt = reviewedAt
            self.relatedConversationIds = relatedConversationIds
            self.customFields = customFields
        }
    }

    init(
        id: String = UUID().uuidString,
        projectId: String? = nil,
        timestamp: Date = Date(),
        decisionText: String,
        rationale: String? = nil,
        alternatives: [Alternative] = [],
        outcome: String? = nil,
        owner: DecisionOwner = .collaborative,
        tags: [String] = [],
        metadata: DecisionMetadata = DecisionMetadata()
    ) {
        self.id = id
        self.projectId = projectId
        self.timestamp = timestamp
        self.decisionText = decisionText
        self.rationale = rationale
        self.alternatives = alternatives
        self.outcome = outcome
        self.owner = owner
        self.tags = tags
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    var hasOutcome: Bool {
        outcome != nil && !outcome!.isEmpty
    }

    var hasAlternatives: Bool {
        !alternatives.isEmpty
    }

    var chosenAlternative: Alternative? {
        alternatives.first { $0.wasChosen }
    }

    var isImplemented: Bool {
        metadata.implementedAt != nil
    }

    var daysSinceDecision: Int {
        let components = Calendar.current.dateComponents([.day], from: timestamp, to: Date())
        return components.day ?? 0
    }

    var isHighImportance: Bool {
        metadata.importance >= 4
    }

    // MARK: - Methods

    mutating func addOutcome(_ outcome: String) {
        self.outcome = outcome
        metadata.reviewedAt = Date()
    }

    mutating func markImplemented() {
        metadata.implementedAt = Date()
    }

    mutating func addAlternative(_ alternative: Alternative) {
        alternatives.append(alternative)
    }

    mutating func selectAlternative(_ index: Int) {
        guard index < alternatives.count else { return }

        // Unmark all others
        for i in 0..<alternatives.count {
            alternatives[i].wasChosen = (i == index)
        }
    }

    func matchesKeywords(_ keywords: [String]) -> Bool {
        let combined = (decisionText + " " + (rationale ?? "")).lowercased()
        return keywords.contains { keyword in
            combined.contains(keyword.lowercased())
        }
    }
}

// MARK: - Decision Statistics

struct DecisionStats: Codable, Equatable {
    var totalDecisions: Int
    var userDecisions: Int
    var aiDecisions: Int
    var collaborativeDecisions: Int
    var averageAlternativesConsidered: Double
    var implementationRate: Double  // Percentage of decisions actually implemented
    var highImportanceCount: Int

    init(
        totalDecisions: Int = 0,
        userDecisions: Int = 0,
        aiDecisions: Int = 0,
        collaborativeDecisions: Int = 0,
        averageAlternativesConsidered: Double = 0,
        implementationRate: Double = 0,
        highImportanceCount: Int = 0
    ) {
        self.totalDecisions = totalDecisions
        self.userDecisions = userDecisions
        self.aiDecisions = aiDecisions
        self.collaborativeDecisions = collaborativeDecisions
        self.averageAlternativesConsidered = averageAlternativesConsidered
        self.implementationRate = implementationRate
        self.highImportanceCount = highImportanceCount
    }
}
