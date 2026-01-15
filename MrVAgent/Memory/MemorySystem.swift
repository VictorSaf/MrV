import Foundation
import SwiftUI

/// Core Memory System for Mr.V Agent
/// Manages all persistent memory: projects, conversations, decisions, knowledge
@MainActor
class MemorySystem: ObservableObject {

    // MARK: - Published State

    @Published var currentProject: ProjectMemory?
    @Published var projects: [ProjectMemory] = []
    @Published var isInitialized = false
    @Published var lastError: String?

    // MARK: - Dependencies

    private let db: SQLiteManager
    private var sessionStartTime = Date()
    private var sessionConversations: [ConversationMemory] = []

    // MARK: - Configuration

    private let maxConversationHistory = 1000  // Per project
    private let contextRetrievalLimit = 10     // Recent conversations to retrieve
    private let semanticSearchThreshold = 0.3  // Similarity threshold

    // MARK: - Initialization

    init(dbPath: String? = nil) {
        self.db = SQLiteManager(dbPath: dbPath)
    }

    /// Initialize memory system and database
    func initialize() async throws {
        guard !isInitialized else { return }

        // Initialize database
        try await db.initialize()

        // Load all projects
        try await loadProjects()

        // Load current project (most recently used active project)
        try await loadCurrentProject()

        isInitialized = true
        print("✅ Memory System initialized")
        print("   - Projects loaded: \(projects.count)")
        print("   - Current project: \(currentProject?.name ?? "None")")
    }

    // MARK: - Project Management

    /// Create new project
    func createProject(
        name: String,
        description: String? = nil,
        color: Color? = nil
    ) async throws -> ProjectMemory {
        let project = ProjectMemory(
            name: name,
            description: description,
            color: color
        )

        // Store in database
        let metadataJSON = try JSONEncoder().encode(project.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        var colorJSON: String? = nil
        if let color = color {
            let colorData = try? JSONEncoder().encode(color)
            colorJSON = String(data: colorData ?? Data(), encoding: .utf8)
        }

        let sql = """
        INSERT INTO projects (id, name, description, status, metadata, color)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        try await db.execute(sql, parameters: [
            project.id,
            project.name,
            project.description ?? NSNull(),
            project.status.rawValue,
            metadataString,
            colorJSON ?? NSNull()
        ])

        // Add to projects array
        projects.append(project)

        // Switch to new project
        currentProject = project

        print("✅ Project created: \(name)")
        return project
    }

    /// Load all projects from database
    private func loadProjects() async throws {
        let sql = "SELECT * FROM projects ORDER BY updated_at DESC;"
        let rows = try await db.query(sql)

        projects = rows.compactMap { row in
            try? self.projectFromRow(row)
        }
    }

    /// Load current project (most recently used)
    private func loadCurrentProject() async throws {
        // Get most recently updated active project
        let sql = """
        SELECT * FROM projects
        WHERE status = 'active'
        ORDER BY updated_at DESC
        LIMIT 1;
        """

        if let row = try await db.queryOne(sql) {
            currentProject = try? projectFromRow(row)
        }
    }

    /// Switch to different project
    func switchProject(_ projectId: String) async throws {
        guard let project = projects.first(where: { $0.id == projectId }) else {
            throw MemoryError.projectNotFound(projectId)
        }

        // Update project's updated_at timestamp
        try await updateProjectTimestamp(projectId)

        currentProject = project
        sessionStartTime = Date()
        sessionConversations = []

        print("🔄 Switched to project: \(project.name)")
    }

    /// Archive project
    func archiveProject(_ projectId: String) async throws {
        let sql = "UPDATE projects SET status = 'archived', updated_at = CURRENT_TIMESTAMP WHERE id = ?;"
        try await db.execute(sql, parameters: [projectId])

        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].status = .archived
        }

        // If current project was archived, switch to another
        if currentProject?.id == projectId {
            currentProject = projects.first { $0.status == .active }
        }
    }

    /// Delete project and all associated data
    func deleteProject(_ projectId: String) async throws {
        // CASCADE will automatically delete related conversations, decisions, etc.
        let sql = "DELETE FROM projects WHERE id = ?;"
        try await db.execute(sql, parameters: [projectId])

        projects.removeAll { $0.id == projectId }

        if currentProject?.id == projectId {
            currentProject = projects.first { $0.status == .active }
        }

        print("🗑️ Project deleted: \(projectId)")
    }

    // MARK: - Conversation Storage

    /// Store conversation in memory
    func storeConversation(
        userInput: String,
        aiResponse: String,
        modelUsed: AIProvider,
        responseTime: TimeInterval,
        mood: String? = nil,
        intent: String? = nil
    ) async throws {
        let conversation = ConversationMemory(
            projectId: currentProject?.id,
            userInput: userInput,
            aiResponse: aiResponse,
            modelUsed: modelUsed,
            responseTime: responseTime,
            metadata: ConversationMemory.ConversationMetadata(
                mood: mood,
                intent: intent
            )
        )

        // Add to session conversations
        sessionConversations.append(conversation)

        // Store in database
        let metadataJSON = try JSONEncoder().encode(conversation.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        let sql = """
        INSERT INTO conversations (id, project_id, timestamp, user_input, ai_response, model_used, response_time, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        try await db.execute(sql, parameters: [
            conversation.id,
            conversation.projectId ?? NSNull(),
            conversation.timestamp,
            conversation.userInput,
            conversation.aiResponse,
            conversation.modelUsed.rawValue,
            conversation.responseTime,
            metadataString
        ])

        // Update project timestamp
        if let projectId = currentProject?.id {
            try await updateProjectTimestamp(projectId)
        }
    }

    // MARK: - Context Retrieval

    /// Get relevant context for current input
    func getRelevantContext(for input: String, limit: Int? = nil) async throws -> [ConversationMemory] {
        let actualLimit = limit ?? contextRetrievalLimit

        // Get recent conversations from current project
        var sql = """
        SELECT * FROM conversations
        WHERE project_id = ?
        ORDER BY timestamp DESC
        LIMIT ?;
        """

        var params: [any SQLiteValue] = [currentProject?.id ?? NSNull(), actualLimit]

        // If no current project, get global recent conversations
        if currentProject == nil {
            sql = """
            SELECT * FROM conversations
            ORDER BY timestamp DESC
            LIMIT ?;
            """
            params = [actualLimit]
        }

        let rows = try await db.query(sql, parameters: params)

        let conversations = rows.compactMap { row in
            try? self.conversationFromRow(row)
        }

        // TODO Phase 2.5: Add semantic search based on input similarity
        // For now, return chronological recent conversations

        return conversations.reversed()  // Return in chronological order
    }

    /// Search conversations by keywords
    func searchConversations(keywords: [String], projectId: String? = nil) async throws -> [ConversationMemory] {
        var sql = """
        SELECT * FROM conversations
        WHERE (user_input LIKE ? OR ai_response LIKE ?)
        """

        var params: [any SQLiteValue] = []

        // Build LIKE patterns for all keywords
        for keyword in keywords {
            let pattern = "%\(keyword)%"
            params.append(pattern)
            params.append(pattern)

            if keywords.first != keyword {
                sql += " OR (user_input LIKE ? OR ai_response LIKE ?)"
            }
        }

        // Filter by project if specified
        if let projectId = projectId {
            sql += " AND project_id = ?"
            params.append(projectId)
        }

        sql += " ORDER BY timestamp DESC LIMIT 50;"

        let rows = try await db.query(sql, parameters: params)

        return rows.compactMap { row in
            try? self.conversationFromRow(row)
        }
    }

    // MARK: - Decision Logging

    /// Store decision
    func storeDecision(
        decisionText: String,
        rationale: String? = nil,
        alternatives: [DecisionLog.Alternative] = [],
        owner: DecisionLog.DecisionOwner = .collaborative,
        tags: [String] = []
    ) async throws -> DecisionLog {
        let decision = DecisionLog(
            projectId: currentProject?.id,
            decisionText: decisionText,
            rationale: rationale,
            alternatives: alternatives,
            owner: owner,
            tags: tags
        )

        // Store in database
        let alternativesJSON = try JSONEncoder().encode(alternatives)
        let alternativesString = String(data: alternativesJSON, encoding: .utf8) ?? "[]"

        let tagsJSON = try JSONEncoder().encode(tags)
        let tagsString = String(data: tagsJSON, encoding: .utf8) ?? "[]"

        let metadataJSON = try JSONEncoder().encode(decision.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        let sql = """
        INSERT INTO decisions (id, project_id, timestamp, decision_text, rationale, alternatives, owner, tags, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        try await db.execute(sql, parameters: [
            decision.id,
            decision.projectId ?? NSNull(),
            decision.timestamp,
            decision.decisionText,
            decision.rationale ?? NSNull(),
            alternativesString,
            decision.owner.rawValue,
            tagsString,
            metadataString
        ])

        print("📝 Decision logged: \(decisionText.prefix(50))...")
        return decision
    }

    /// Get project decisions
    func getProjectDecisions(_ projectId: String? = nil) async throws -> [DecisionLog] {
        let targetProjectId = projectId ?? currentProject?.id

        guard let targetProjectId = targetProjectId else {
            return []
        }

        let sql = """
        SELECT * FROM decisions
        WHERE project_id = ?
        ORDER BY timestamp DESC;
        """

        let rows = try await db.query(sql, parameters: [targetProjectId])

        return rows.compactMap { row in
            try? self.decisionFromRow(row)
        }
    }

    // MARK: - Statistics

    /// Get conversation statistics for project
    func getConversationStats(_ projectId: String? = nil) async throws -> ConversationStats {
        let targetProjectId = projectId ?? currentProject?.id

        var sql = "SELECT COUNT(*) as count, AVG(response_time) as avg_time FROM conversations"
        var params: [any SQLiteValue] = []

        if let targetProjectId = targetProjectId {
            sql += " WHERE project_id = ?"
            params.append(targetProjectId)
        }

        guard let row = try await db.queryOne(sql, parameters: params),
              let count = row["count"] as? Int64,
              let avgTime = row["avg_time"] as? Double else {
            return ConversationStats()
        }

        // Get most used provider
        var providerSQL = "SELECT model_used, COUNT(*) as count FROM conversations"
        if let targetProjectId = targetProjectId {
            providerSQL += " WHERE project_id = ?"
        }
        providerSQL += " GROUP BY model_used ORDER BY count DESC LIMIT 1"

        let mostUsedProvider: AIProvider? = if let providerRow = try await db.queryOne(providerSQL, parameters: params),
                                               let providerString = providerRow["model_used"] as? String {
            AIProvider(rawValue: providerString)
        } else {
            nil
        }

        return ConversationStats(
            totalMessages: Int(count),
            averageResponseTime: avgTime,
            mostUsedProvider: mostUsedProvider
        )
    }

    // MARK: - Session Management

    /// Get current session conversations
    func getSessionConversations() -> [ConversationMemory] {
        return sessionConversations
    }

    /// Clear session (conversations still persisted)
    func clearSession() {
        sessionConversations = []
        sessionStartTime = Date()
    }

    // MARK: - Private Helpers

    private func updateProjectTimestamp(_ projectId: String) async throws {
        let sql = "UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = ?;"
        try await db.execute(sql, parameters: [projectId])
    }

    private func projectFromRow(_ row: [String: any SQLiteValue]) throws -> ProjectMemory {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String,
              let statusString = row["status"] as? String,
              let status = ProjectMemory.ProjectStatus(rawValue: statusString) else {
            throw MemoryError.invalidData("Invalid project row")
        }

        let description = row["description"] as? String

        // Parse metadata
        let metadata: ProjectMemory.ProjectMetadata = if let metadataString = row["metadata"] as? String,
                                                         let metadataData = metadataString.data(using: .utf8) {
            (try? JSONDecoder().decode(ProjectMemory.ProjectMetadata.self, from: metadataData)) ?? ProjectMemory.ProjectMetadata()
        } else {
            ProjectMemory.ProjectMetadata()
        }

        // Parse color
        let color: Color? = if let colorString = row["color"] as? String,
                               let colorData = colorString.data(using: .utf8) {
            try? JSONDecoder().decode(Color.self, from: colorData)
        } else {
            nil
        }

        // Parse dates (SQLite returns as strings)
        let createdAt = Date()  // TODO: Parse from timestamp string
        let updatedAt = Date()  // TODO: Parse from timestamp string

        return ProjectMemory(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            metadata: metadata,
            color: color
        )
    }

    private func conversationFromRow(_ row: [String: any SQLiteValue]) throws -> ConversationMemory {
        guard let id = row["id"] as? String,
              let userInput = row["user_input"] as? String,
              let aiResponse = row["ai_response"] as? String,
              let modelString = row["model_used"] as? String,
              let model = AIProvider(rawValue: modelString) else {
            throw MemoryError.invalidData("Invalid conversation row")
        }

        let projectId = row["project_id"] as? String
        let responseTime = (row["response_time"] as? Double) ?? 0.0

        // Parse metadata
        let metadata: ConversationMemory.ConversationMetadata = if let metadataString = row["metadata"] as? String,
                                                                    let metadataData = metadataString.data(using: .utf8) {
            (try? JSONDecoder().decode(ConversationMemory.ConversationMetadata.self, from: metadataData)) ?? ConversationMemory.ConversationMetadata()
        } else {
            ConversationMemory.ConversationMetadata()
        }

        return ConversationMemory(
            id: id,
            projectId: projectId,
            timestamp: Date(),  // TODO: Parse from row
            userInput: userInput,
            aiResponse: aiResponse,
            modelUsed: model,
            responseTime: responseTime,
            metadata: metadata
        )
    }

    private func decisionFromRow(_ row: [String: any SQLiteValue]) throws -> DecisionLog {
        guard let id = row["id"] as? String,
              let decisionText = row["decision_text"] as? String,
              let ownerString = row["owner"] as? String,
              let owner = DecisionLog.DecisionOwner(rawValue: ownerString) else {
            throw MemoryError.invalidData("Invalid decision row")
        }

        let projectId = row["project_id"] as? String
        let rationale = row["rationale"] as? String

        // Parse alternatives
        let alternatives: [DecisionLog.Alternative] = if let altString = row["alternatives"] as? String,
                                                          let altData = altString.data(using: .utf8) {
            (try? JSONDecoder().decode([DecisionLog.Alternative].self, from: altData)) ?? []
        } else {
            []
        }

        // Parse tags
        let tags: [String] = if let tagsString = row["tags"] as? String,
                                let tagsData = tagsString.data(using: .utf8) {
            (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
        } else {
            []
        }

        // Parse metadata
        let metadata: DecisionLog.DecisionMetadata = if let metadataString = row["metadata"] as? String,
                                                        let metadataData = metadataString.data(using: .utf8) {
            (try? JSONDecoder().decode(DecisionLog.DecisionMetadata.self, from: metadataData)) ?? DecisionLog.DecisionMetadata()
        } else {
            DecisionLog.DecisionMetadata()
        }

        return DecisionLog(
            id: id,
            projectId: projectId,
            timestamp: Date(),  // TODO: Parse from row
            decisionText: decisionText,
            rationale: rationale,
            alternatives: alternatives,
            owner: owner,
            tags: tags,
            metadata: metadata
        )
    }

    // MARK: - Errors

    enum MemoryError: LocalizedError {
        case projectNotFound(String)
        case invalidData(String)
        case databaseError(String)

        var errorDescription: String? {
            switch self {
            case .projectNotFound(let id):
                return "Project not found: \(id)"
            case .invalidData(let message):
                return "Invalid data: \(message)"
            case .databaseError(let message):
                return "Database error: \(message)"
            }
        }
    }
}
