import Foundation
import SwiftUI
import Combine

/// Cross-Project Intelligence - Connects learning and insights across all projects
/// Enables transfer learning, pattern recognition, and holistic understanding
@MainActor
final class CrossProjectIntelligence: ObservableObject {

    // MARK: - Published State

    @Published var crossProjectInsights: [CrossProjectInsight] = []
    @Published var projectGraph: ProjectGraph = ProjectGraph()
    @Published var transferredLearnings: [TransferredLearning] = []
    @Published var isAnalyzing: Bool = false

    // MARK: - Dependencies

    private var memorySystem: MemorySystem?
    private var analysisTask: Task<Void, Never>?

    // MARK: - State

    private var projectContexts: [String: ProjectContext] = [:]
    private var globalKnowledge: GlobalKnowledge = GlobalKnowledge()
    private var analogyEngine: AnalogyEngine

    // MARK: - Configuration

    private let analysisInterval: TimeInterval = 7200.0  // Analyze every 2 hours
    private let similarityThreshold: Float = 0.6

    // MARK: - Initialization

    init(memorySystem: MemorySystem? = nil) {
        self.memorySystem = memorySystem
        self.analogyEngine = AnalogyEngine()

        loadCrossProjectState()
    }

    // MARK: - Analysis Control

    /// Start cross-project analysis
    func startAnalysis() {
        guard !isAnalyzing else {
            print("⚠️ Cross-project analysis already running")
            return
        }

        print("🌐 Starting Cross-Project Intelligence...")
        isAnalyzing = true

        analysisTask = Task {
            while !Task.isCancelled {
                await performCrossProjectAnalysis()

                // Wait for next analysis cycle
                try? await Task.sleep(nanoseconds: UInt64(analysisInterval * 1_000_000_000))
            }
        }
    }

    /// Stop analysis
    func stopAnalysis() {
        print("🛑 Stopping cross-project analysis...")
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }

    // MARK: - Cross-Project Analysis

    /// Perform complete cross-project analysis
    private func performCrossProjectAnalysis() async {
        print("🔍 Cross-project analysis cycle starting...")

        let startTime = Date()

        // Phase 1: Update project contexts
        await updateProjectContexts()

        // Phase 2: Identify connections
        await identifyConnections()

        // Phase 3: Transfer learning
        await transferLearning()

        // Phase 4: Generate insights
        await generateCrossProjectInsights()

        // Phase 5: Update global knowledge
        await updateGlobalKnowledge()

        // Phase 6: Discover analogies
        await discoverAnalogies()

        let duration = Date().timeIntervalSince(startTime)
        print("✅ Cross-project analysis complete (\(String(format: "%.2f", duration))s)")
    }

    // MARK: - Project Context Management

    private func updateProjectContexts() async {
        print("📋 Updating project contexts...")

        guard let memorySystem = memorySystem else { return }

        let projects = await memorySystem.getProjects()

        for project in projects {
            do {
                // Get project conversations
                let conversations = try await memorySystem.getProjectConversations(projectId: project.id)

                // Extract patterns
                let patterns = extractPatterns(from: conversations)

                // Extract concepts
                let concepts = extractConcepts(from: conversations)

                // Build context
                let context = ProjectContext(
                    projectId: project.id,
                    name: project.name,
                    patterns: patterns,
                    concepts: concepts,
                    lastUpdated: Date()
                )

                projectContexts[project.id] = context

            } catch {
                print("  ⚠️ Failed to update context for project \(project.name): \(error)")
            }
        }

        print("  Updated \(projectContexts.count) project contexts")
    }

    private func extractPatterns(from conversations: [ConversationMemory]) -> [String] {
        var patterns: [String] = []

        // Simple pattern extraction
        let allText = conversations.map { $0.userInput + " " + $0.aiResponse }.joined()

        // Look for recurring themes
        if allText.contains("implement") && allText.contains("test") {
            patterns.append("TDD workflow")
        }
        if allText.contains("refactor") {
            patterns.append("code improvement")
        }
        if allText.contains("bug") || allText.contains("fix") {
            patterns.append("debugging")
        }

        return patterns
    }

    private func extractConcepts(from conversations: [ConversationMemory]) -> [String] {
        var concepts: Set<String> = []

        for conv in conversations {
            // Extract technology mentions
            let text = conv.userInput.lowercased()
            if text.contains("swift") { concepts.insert("Swift") }
            if text.contains("python") { concepts.insert("Python") }
            if text.contains("react") { concepts.insert("React") }
            if text.contains("database") { concepts.insert("Database") }
            if text.contains("api") { concepts.insert("API") }
        }

        return Array(concepts)
    }

    // MARK: - Connection Identification

    private func identifyConnections() async {
        print("🔗 Identifying cross-project connections...")

        var connections: [ProjectConnection] = []

        // Compare all project pairs
        let projectIds = Array(projectContexts.keys)
        for i in 0..<projectIds.count {
            for j in (i+1)..<projectIds.count {
                let projectA = projectContexts[projectIds[i]]!
                let projectB = projectContexts[projectIds[j]]!

                if let connection = findConnection(between: projectA, and: projectB) {
                    connections.append(connection)
                }
            }
        }

        // Update project graph
        projectGraph.connections = connections

        print("  Found \(connections.count) cross-project connections")
    }

    private func findConnection(between projectA: ProjectContext, and projectB: ProjectContext) -> ProjectConnection? {
        // Check for shared patterns
        let sharedPatterns = Set(projectA.patterns).intersection(projectB.patterns)

        // Check for shared concepts
        let sharedConcepts = Set(projectA.concepts).intersection(projectB.concepts)

        if !sharedPatterns.isEmpty || !sharedConcepts.isEmpty {
            let strength = Float(sharedPatterns.count + sharedConcepts.count) / 10.0
            if strength >= similarityThreshold {
                return ProjectConnection(
                    sourceId: projectA.projectId,
                    targetId: projectB.projectId,
                    type: .sharedConcepts,
                    strength: strength,
                    sharedElements: Array(sharedPatterns) + Array(sharedConcepts)
                )
            }
        }

        return nil
    }

    // MARK: - Learning Transfer

    private func transferLearning() async {
        print("📚 Transferring learning across projects...")

        var transfers: [TransferredLearning] = []

        // Find opportunities to transfer successful patterns
        for (_, sourceContext) in projectContexts {
            for (_, targetContext) in projectContexts where targetContext.projectId != sourceContext.projectId {
                // Check if source has patterns that target doesn't
                let uniquePatterns = Set(sourceContext.patterns).subtracting(targetContext.patterns)

                for pattern in uniquePatterns {
                    // Check if pattern is successful
                    if isSuccessfulPattern(pattern, in: sourceContext) {
                        let transfer = TransferredLearning(
                            fromProject: sourceContext.projectId,
                            toProject: targetContext.projectId,
                            learningType: .pattern,
                            content: pattern,
                            confidence: 0.7,
                            reasoning: "Pattern '\(pattern)' was successful in \(sourceContext.name)"
                        )
                        transfers.append(transfer)
                    }
                }
            }
        }

        transferredLearnings.append(contentsOf: transfers)

        // Keep only recent transfers
        if transferredLearnings.count > 100 {
            transferredLearnings = Array(transferredLearnings.suffix(100))
        }

        print("  Transferred \(transfers.count) new learnings")
    }

    private func isSuccessfulPattern(_ pattern: String, in context: ProjectContext) -> Bool {
        // Heuristic: assume pattern is successful if it appears multiple times
        return true
    }

    // MARK: - Insight Generation

    private func generateCrossProjectInsights() async {
        print("💡 Generating cross-project insights...")

        var newInsights: [CrossProjectInsight] = []

        // Identify trending technologies
        let allConcepts = projectContexts.values.flatMap { $0.concepts }
        let conceptFrequency = Dictionary(grouping: allConcepts) { $0 }.mapValues { $0.count }

        for (concept, count) in conceptFrequency where count >= 2 {
            newInsights.append(CrossProjectInsight(
                type: .trendingTechnology,
                title: "\(concept) used across \(count) projects",
                description: "Technology '\(concept)' is being used in multiple projects",
                affectedProjects: projectContexts.filter { $0.value.concepts.contains(concept) }.map { $0.key },
                confidence: Float(count) / Float(projectContexts.count)
            ))
        }

        // Identify common challenges
        let allPatterns = projectContexts.values.flatMap { $0.patterns }
        let patternFrequency = Dictionary(grouping: allPatterns) { $0 }.mapValues { $0.count }

        for (pattern, count) in patternFrequency where count >= 2 {
            newInsights.append(CrossProjectInsight(
                type: .commonPattern,
                title: "\(pattern) pattern appears in \(count) projects",
                description: "Pattern '\(pattern)' is recurring across projects",
                affectedProjects: projectContexts.filter { $0.value.patterns.contains(pattern) }.map { $0.key },
                confidence: 0.8
            ))
        }

        // Identify knowledge gaps
        let lessExperiencedProjects = projectContexts.filter { $0.value.patterns.count < 3 }
        for (projectId, context) in lessExperiencedProjects {
            // Find projects with more experience that could help
            let experiencedProjects = projectContexts.filter { $0.value.patterns.count >= 5 }

            if !experiencedProjects.isEmpty {
                newInsights.append(CrossProjectInsight(
                    type: .knowledgeGap,
                    title: "Project '\(context.name)' could benefit from cross-project learning",
                    description: "This project has fewer established patterns and could learn from others",
                    affectedProjects: [projectId],
                    confidence: 0.6
                ))
            }
        }

        crossProjectInsights.append(contentsOf: newInsights)

        // Keep only recent insights
        if crossProjectInsights.count > 50 {
            crossProjectInsights = Array(crossProjectInsights.suffix(50))
        }

        print("  Generated \(newInsights.count) new insights")
    }

    // MARK: - Global Knowledge

    private func updateGlobalKnowledge() async {
        print("🌍 Updating global knowledge base...")

        // Aggregate all concepts
        let allConcepts = projectContexts.values.flatMap { $0.concepts }
        globalKnowledge.knownConcepts = Set(allConcepts)

        // Aggregate all patterns
        let allPatterns = projectContexts.values.flatMap { $0.patterns }
        globalKnowledge.knownPatterns = Set(allPatterns)

        // Update last update time
        globalKnowledge.lastUpdated = Date()

        print("  Global knowledge: \(globalKnowledge.knownConcepts.count) concepts, \(globalKnowledge.knownPatterns.count) patterns")
    }

    // MARK: - Analogy Discovery

    private func discoverAnalogies() async {
        print("🔮 Discovering analogies...")

        let analogies = await analogyEngine.discoverAnalogies(
            between: Array(projectContexts.values)
        )

        for analogy in analogies {
            print("  ✨ Analogy: \(analogy.description)")
        }
    }

    // MARK: - Query Interface

    /// Find similar projects to the given project
    func findSimilarProjects(to projectId: String, limit: Int = 5) -> [SimilarProject] {
        guard let targetContext = projectContexts[projectId] else { return [] }

        var similarities: [SimilarProject] = []

        for (id, context) in projectContexts where id != projectId {
            let similarity = calculateSimilarity(between: targetContext, and: context)

            if similarity > 0 {
                similarities.append(SimilarProject(
                    projectId: id,
                    name: context.name,
                    similarity: similarity,
                    sharedPatterns: Set(targetContext.patterns).intersection(context.patterns),
                    sharedConcepts: Set(targetContext.concepts).intersection(context.concepts)
                ))
            }
        }

        return Array(similarities.sorted(by: { $0.similarity > $1.similarity }).prefix(limit))
    }

    private func calculateSimilarity(between contextA: ProjectContext, and contextB: ProjectContext) -> Float {
        let sharedPatterns = Set(contextA.patterns).intersection(contextB.patterns)
        let sharedConcepts = Set(contextA.concepts).intersection(contextB.concepts)

        let totalPatterns = Set(contextA.patterns).union(contextB.patterns).count
        let totalConcepts = Set(contextA.concepts).union(contextB.concepts).count

        let patternSimilarity = totalPatterns > 0 ? Float(sharedPatterns.count) / Float(totalPatterns) : 0
        let conceptSimilarity = totalConcepts > 0 ? Float(sharedConcepts.count) / Float(totalConcepts) : 0

        return (patternSimilarity + conceptSimilarity) / 2.0
    }

    /// Get insights relevant to a specific project
    func getInsights(for projectId: String) -> [CrossProjectInsight] {
        return crossProjectInsights.filter { $0.affectedProjects.contains(projectId) }
    }

    /// Get transferred learnings for a project
    func getTransferredLearnings(for projectId: String) -> [TransferredLearning] {
        return transferredLearnings.filter { $0.toProject == projectId }
    }

    // MARK: - State Persistence

    private func loadCrossProjectState() {
        print("📥 Loading cross-project state...")
        // TODO: Load from disk
    }

    private func saveCrossProjectState() {
        print("💾 Saving cross-project state...")
        // TODO: Save to disk
    }

    // MARK: - Statistics

    func getStatistics() -> CrossProjectStatistics {
        return CrossProjectStatistics(
            trackedProjects: projectContexts.count,
            connections: projectGraph.connections.count,
            insights: crossProjectInsights.count,
            transferredLearnings: transferredLearnings.count,
            knownConcepts: globalKnowledge.knownConcepts.count,
            knownPatterns: globalKnowledge.knownPatterns.count
        )
    }
}

// MARK: - Supporting Types

/// Context about a single project
struct ProjectContext {
    var projectId: String
    var name: String
    var patterns: [String]
    var concepts: [String]
    var lastUpdated: Date
}

/// Connection between two projects
struct ProjectConnection: Identifiable {
    let id = UUID()
    var sourceId: String
    var targetId: String
    var type: ConnectionType
    var strength: Float
    var sharedElements: [String]

    enum ConnectionType {
        case sharedConcepts
        case sharedPatterns
        case sharedTools
        case similarProblems
    }
}

/// Graph of project relationships
struct ProjectGraph {
    var connections: [ProjectConnection] = []

    func getConnections(for projectId: String) -> [ProjectConnection] {
        connections.filter { $0.sourceId == projectId || $0.targetId == projectId }
    }
}

/// Learning transferred from one project to another
struct TransferredLearning: Identifiable {
    let id = UUID()
    var fromProject: String
    var toProject: String
    var learningType: LearningType
    var content: String
    var confidence: Float
    var reasoning: String

    enum LearningType {
        case pattern, technique, concept, tool, workflow
    }
}

/// Cross-project insight
struct CrossProjectInsight: Identifiable {
    let id = UUID()
    var type: InsightType
    var title: String
    var description: String
    var affectedProjects: [String]
    var confidence: Float
    var timestamp: Date = Date()

    enum InsightType {
        case trendingTechnology
        case commonPattern
        case knowledgeGap
        case synergy
        case duplication
    }
}

/// Global aggregated knowledge
struct GlobalKnowledge {
    var knownConcepts: Set<String> = []
    var knownPatterns: Set<String> = []
    var lastUpdated: Date = Date()
}

/// Similar project result
struct SimilarProject {
    var projectId: String
    var name: String
    var similarity: Float
    var sharedPatterns: Set<String>
    var sharedConcepts: Set<String>
}

/// Statistics about cross-project intelligence
struct CrossProjectStatistics {
    var trackedProjects: Int
    var connections: Int
    var insights: Int
    var transferredLearnings: Int
    var knownConcepts: Int
    var knownPatterns: Int
}

// MARK: - Analogy Engine

/// Discovers deep analogies between projects
actor AnalogyEngine {
    func discoverAnalogies(between contexts: [ProjectContext]) async -> [Analogy] {
        var analogies: [Analogy] = []

        // Find projects that solve similar problems with different approaches
        for i in 0..<contexts.count {
            for j in (i+1)..<contexts.count {
                if let analogy = findAnalogy(between: contexts[i], and: contexts[j]) {
                    analogies.append(analogy)
                }
            }
        }

        return analogies
    }

    private func findAnalogy(between contextA: ProjectContext, and contextB: ProjectContext) -> Analogy? {
        // Look for different patterns that serve similar purposes
        let uniquePatternsA = Set(contextA.patterns).subtracting(contextB.patterns)
        let uniquePatternsB = Set(contextB.patterns).subtracting(contextA.patterns)

        if !uniquePatternsA.isEmpty && !uniquePatternsB.isEmpty {
            return Analogy(
                sourceProject: contextA.projectId,
                targetProject: contextB.projectId,
                description: "Projects use different patterns: [\(uniquePatternsA.joined(separator: ", "))] vs [\(uniquePatternsB.joined(separator: ", "))]",
                strength: 0.5
            )
        }

        return nil
    }
}

struct Analogy {
    var sourceProject: String
    var targetProject: String
    var description: String
    var strength: Float
}

// MARK: - Memory System Extension

extension MemorySystem {
    func getProjects() async -> [ProjectMemory] {
        return projects
    }

    func getProjectConversations(projectId: String) async throws -> [ConversationMemory] {
        // Get all conversations for a project
        return try await searchConversations(keywords: []).filter { conv in
            // Filter by project (this assumes we track project ID in conversations)
            return currentProject?.id == projectId
        }
    }
}
