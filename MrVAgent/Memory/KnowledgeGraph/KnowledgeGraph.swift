import Foundation

/// Knowledge Graph engine for Mr.V Agent
/// Manages knowledge nodes and their relationships
actor KnowledgeGraph {

    // MARK: - Properties

    private let db: SQLiteManager
    private var nodeCache: [String: KnowledgeNode] = [:]
    private var edgeCache: [KnowledgeEdge] = []
    private var cacheExpiry: Date = Date()
    private let cacheLifetime: TimeInterval = 300  // 5 minutes

    // MARK: - Initialization

    init(db: SQLiteManager) {
        self.db = db
    }

    // MARK: - Node Operations

    /// Add new node to graph
    func addNode(_ node: KnowledgeNode) async throws {
        let contentJSON = try JSONEncoder().encode(node.content)
        let contentString = String(data: contentJSON, encoding: .utf8) ?? "{}"

        let metadataJSON = try JSONEncoder().encode(node.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        let sql = """
        INSERT INTO knowledge_nodes (id, type, name, content, created_at, updated_at, project_id, confidence, usage_count, last_used, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        try await db.execute(sql, parameters: [
            node.id,
            node.type.rawValue,
            node.name,
            contentString,
            node.createdAt,
            node.updatedAt,
            node.projectId ?? NSNull(),
            Double(node.confidence),
            node.usageCount,
            node.lastUsed ?? NSNull(),
            metadataString
        ])

        // Update cache
        nodeCache[node.id] = node
        invalidateCacheIfNeeded()
    }

    /// Get node by ID
    func getNode(_ nodeId: String) async throws -> KnowledgeNode? {
        // Check cache first
        if let cached = nodeCache[nodeId], Date() < cacheExpiry {
            return cached
        }

        // Query database
        let sql = "SELECT * FROM knowledge_nodes WHERE id = ?;"
        guard let row = try await db.queryOne(sql, parameters: [nodeId]) else {
            return nil
        }

        let node = try nodeFromRow(row)
        nodeCache[nodeId] = node
        return node
    }

    /// Update node
    func updateNode(_ node: KnowledgeNode) async throws {
        let contentJSON = try JSONEncoder().encode(node.content)
        let contentString = String(data: contentJSON, encoding: .utf8) ?? "{}"

        let metadataJSON = try JSONEncoder().encode(node.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        let sql = """
        UPDATE knowledge_nodes
        SET name = ?, content = ?, updated_at = ?, confidence = ?, usage_count = ?, last_used = ?, metadata = ?
        WHERE id = ?;
        """

        try await db.execute(sql, parameters: [
            node.name,
            contentString,
            Date(),
            Double(node.confidence),
            node.usageCount,
            node.lastUsed ?? NSNull(),
            metadataString,
            node.id
        ])

        nodeCache[node.id] = node
    }

    /// Delete node (and its edges via CASCADE)
    func deleteNode(_ nodeId: String) async throws {
        let sql = "DELETE FROM knowledge_nodes WHERE id = ?;"
        try await db.execute(sql, parameters: [nodeId])

        nodeCache.removeValue(forKey: nodeId)
        invalidateCache()
    }

    /// Find nodes by name or tags
    func findNodes(matching query: String, projectId: String? = nil, limit: Int = 20) async throws -> [KnowledgeNode] {
        var sql = """
        SELECT * FROM knowledge_nodes
        WHERE (name LIKE ? OR content LIKE ?)
        """

        var params: [any SQLiteValue] = ["%\(query)%", "%\(query)%"]

        if let projectId = projectId {
            sql += " AND (project_id = ? OR project_id IS NULL)"
            params.append(projectId)
        }

        sql += " ORDER BY usage_count DESC, confidence DESC LIMIT ?;"
        params.append(limit)

        let rows = try await db.query(sql, parameters: params)

        return rows.compactMap { row in
            try? nodeFromRow(row)
        }
    }

    /// Get all nodes of a specific type
    func getNodesByType(_ type: KnowledgeNode.NodeType, projectId: String? = nil) async throws -> [KnowledgeNode] {
        var sql = "SELECT * FROM knowledge_nodes WHERE type = ?"
        var params: [any SQLiteValue] = [type.rawValue]

        if let projectId = projectId {
            sql += " AND (project_id = ? OR project_id IS NULL)"
            params.append(projectId)
        }

        sql += " ORDER BY usage_count DESC;"

        let rows = try await db.query(sql, parameters: params)

        return rows.compactMap { row in
            try? nodeFromRow(row)
        }
    }

    // MARK: - Edge Operations

    /// Connect two nodes with a relationship
    func connect(
        sourceId: String,
        to targetId: String,
        relationship: KnowledgeEdge.RelationType,
        weight: Float = 1.0,
        bidirectional: Bool? = nil
    ) async throws -> KnowledgeEdge {
        let edge = KnowledgeEdge(
            sourceId: sourceId,
            targetId: targetId,
            relationship: relationship,
            weight: weight,
            bidirectional: bidirectional
        )

        let metadataJSON = try JSONEncoder().encode(edge.metadata)
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"

        let sql = """
        INSERT INTO knowledge_edges (id, source_id, target_id, relationship, weight, created_at, bidirectional, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        try await db.execute(sql, parameters: [
            edge.id,
            edge.sourceId,
            edge.targetId,
            edge.relationship.rawValue,
            Double(edge.weight),
            edge.createdAt,
            edge.bidirectional ? 1 : 0,
            metadataString
        ])

        invalidateCache()
        return edge
    }

    /// Get all edges connected to a node
    func getConnections(for nodeId: String) async throws -> [KnowledgeEdge] {
        let sql = """
        SELECT * FROM knowledge_edges
        WHERE source_id = ? OR (bidirectional = 1 AND target_id = ?);
        """

        let rows = try await db.query(sql, parameters: [nodeId, nodeId])

        return rows.compactMap { row in
            try? edgeFromRow(row)
        }
    }

    /// Get edges of a specific relationship type
    func getEdgesByRelationship(_ type: KnowledgeEdge.RelationType, from nodeId: String) async throws -> [KnowledgeEdge] {
        let sql = """
        SELECT * FROM knowledge_edges
        WHERE relationship = ? AND (source_id = ? OR (bidirectional = 1 AND target_id = ?));
        """

        let rows = try await db.query(sql, parameters: [type.rawValue, nodeId, nodeId])

        return rows.compactMap { row in
            try? edgeFromRow(row)
        }
    }

    /// Delete edge
    func deleteEdge(_ edgeId: String) async throws {
        let sql = "DELETE FROM knowledge_edges WHERE id = ?;"
        try await db.execute(sql, parameters: [edgeId])
        invalidateCache()
    }

    // MARK: - Graph Traversal

    /// Find related nodes (1-hop neighbors)
    func findRelated(to nodeId: String, depth: Int = 1) async throws -> [KnowledgeNode] {
        guard depth > 0 else { return [] }

        var visited = Set<String>()
        var result: [KnowledgeNode] = []

        try await traverseDepthFirst(nodeId: nodeId, currentDepth: 0, maxDepth: depth, visited: &visited, result: &result)

        return result
    }

    private func traverseDepthFirst(
        nodeId: String,
        currentDepth: Int,
        maxDepth: Int,
        visited: inout Set<String>,
        result: inout [KnowledgeNode]
    ) async throws {
        guard currentDepth < maxDepth, !visited.contains(nodeId) else { return }

        visited.insert(nodeId)

        // Get node
        if let node = try await getNode(nodeId), currentDepth > 0 {  // Don't include root
            result.append(node)
        }

        // Get connected nodes
        let edges = try await getConnections(for: nodeId)

        for edge in edges {
            if let nextNodeId = edge.otherNode(from: nodeId) {
                try await traverseDepthFirst(
                    nodeId: nextNodeId,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    visited: &visited,
                    result: &result
                )
            }
        }
    }

    /// Find path between two nodes (BFS)
    func findPath(from sourceId: String, to targetId: String) async throws -> [KnowledgeNode]? {
        guard sourceId != targetId else {
            return try await getNode(sourceId).map { [$0] }
        }

        var queue: [(String, [String])] = [(sourceId, [sourceId])]
        var visited = Set<String>([sourceId])

        while !queue.isEmpty {
            let (currentId, path) = queue.removeFirst()

            // Get connections
            let edges = try await getConnections(for: currentId)

            for edge in edges {
                guard let nextId = edge.otherNode(from: currentId), !visited.contains(nextId) else {
                    continue
                }

                let newPath = path + [nextId]

                if nextId == targetId {
                    // Found path - convert IDs to nodes
                    var nodes: [KnowledgeNode] = []
                    for nodeId in newPath {
                        if let node = try await getNode(nodeId) {
                            nodes.append(node)
                        }
                    }
                    return nodes
                }

                visited.insert(nextId)
                queue.append((nextId, newPath))
            }
        }

        return nil  // No path found
    }

    /// Get strongly connected subgraph around a node
    func getSubgraph(around nodeId: String, maxNodes: Int = 20) async throws -> (nodes: [KnowledgeNode], edges: [KnowledgeEdge]) {
        var nodes: [KnowledgeNode] = []
        var edges: [KnowledgeEdge] = []
        var nodeIds = Set<String>()

        // Start with center node
        if let centerNode = try await getNode(nodeId) {
            nodes.append(centerNode)
            nodeIds.insert(nodeId)
        }

        // Get immediate connections
        let centerEdges = try await getConnections(for: nodeId)
        edges.append(contentsOf: centerEdges)

        // Add connected nodes
        for edge in centerEdges {
            guard nodes.count < maxNodes else { break }

            if let nextId = edge.otherNode(from: nodeId), !nodeIds.contains(nextId) {
                if let node = try await getNode(nextId) {
                    nodes.append(node)
                    nodeIds.insert(nextId)
                }
            }
        }

        // Get edges between collected nodes (if we have room)
        if nodes.count < maxNodes {
            for nodeId in nodeIds {
                let nodeEdges = try await getConnections(for: nodeId)
                for edge in nodeEdges {
                    if let otherId = edge.otherNode(from: nodeId), nodeIds.contains(otherId) {
                        if !edges.contains(where: { $0.id == edge.id }) {
                            edges.append(edge)
                        }
                    }
                }
            }
        }

        return (nodes, edges)
    }

    // MARK: - Auto-Population from Conversations

    /// Extract and add knowledge from conversation
    func extractKnowledge(
        from conversation: ConversationMemory,
        projectId: String?
    ) async throws {
        let text = conversation.userInput + " " + conversation.aiResponse

        // Extract tool mentions (simple keyword matching for now)
        let tools = ["Swift", "Python", "JavaScript", "React", "SwiftUI", "SQLite", "Metal", "Git"]
        for tool in tools {
            if text.contains(tool) {
                // Check if node already exists
                let existing = try await findNodes(matching: tool, projectId: projectId)

                if existing.isEmpty {
                    let node = KnowledgeNode(
                        type: .tool,
                        name: tool,
                        content: KnowledgeNode.NodeContent(
                            description: "Tool mentioned in conversation"
                        ),
                        projectId: projectId,
                        metadata: KnowledgeNode.NodeMetadata(
                            sourceConversationIds: [conversation.id]
                        )
                    )
                    try await addNode(node)
                } else if var existingNode = existing.first {
                    existingNode.incrementUsage()
                    existingNode.metadata.sourceConversationIds.append(conversation.id)
                    try await updateNode(existingNode)
                }
            }
        }

        // TODO Phase 3: More sophisticated NER and entity extraction
    }

    // MARK: - Statistics

    func getStatistics(projectId: String? = nil) async throws -> GraphStatistics {
        var sql = "SELECT COUNT(*) as count FROM knowledge_nodes"
        var params: [any SQLiteValue] = []

        if let projectId = projectId {
            sql += " WHERE project_id = ?"
            params.append(projectId)
        }

        let nodeCount = try await db.queryOne(sql, parameters: params)
            .flatMap { $0["count"] as? Int64 }
            .map { Int($0) } ?? 0

        let edgeCount = try await db.count(table: "knowledge_edges")

        return GraphStatistics(nodeCount: nodeCount, edgeCount: edgeCount)
    }

    // MARK: - Cache Management

    private func invalidateCache() {
        edgeCache = []
        cacheExpiry = Date()
    }

    private func invalidateCacheIfNeeded() {
        if Date() >= cacheExpiry {
            nodeCache.removeAll()
            edgeCache = []
            cacheExpiry = Date().addingTimeInterval(cacheLifetime)
        }
    }

    // MARK: - Parsing Helpers

    private func nodeFromRow(_ row: [String: any SQLiteValue]) throws -> KnowledgeNode {
        guard let id = row["id"] as? String,
              let typeString = row["type"] as? String,
              let type = KnowledgeNode.NodeType(rawValue: typeString),
              let name = row["name"] as? String else {
            throw GraphError.invalidData("Invalid node row")
        }

        let projectId = row["project_id"] as? String

        let content: KnowledgeNode.NodeContent = if let contentString = row["content"] as? String,
                                                     let contentData = contentString.data(using: .utf8) {
            (try? JSONDecoder().decode(KnowledgeNode.NodeContent.self, from: contentData)) ?? KnowledgeNode.NodeContent()
        } else {
            KnowledgeNode.NodeContent()
        }

        let metadata: KnowledgeNode.NodeMetadata = if let metadataString = row["metadata"] as? String,
                                                       let metadataData = metadataString.data(using: .utf8) {
            (try? JSONDecoder().decode(KnowledgeNode.NodeMetadata.self, from: metadataData)) ?? KnowledgeNode.NodeMetadata()
        } else {
            KnowledgeNode.NodeMetadata()
        }

        let confidence = Float(row["confidence"] as? Double ?? 1.0)
        let usageCount = Int(row["usage_count"] as? Int64 ?? 0)

        return KnowledgeNode(
            id: id,
            type: type,
            name: name,
            content: content,
            projectId: projectId,
            confidence: confidence,
            usageCount: usageCount,
            metadata: metadata
        )
    }

    private func edgeFromRow(_ row: [String: any SQLiteValue]) throws -> KnowledgeEdge {
        guard let id = row["id"] as? String,
              let sourceId = row["source_id"] as? String,
              let targetId = row["target_id"] as? String,
              let relationshipString = row["relationship"] as? String,
              let relationship = KnowledgeEdge.RelationType(rawValue: relationshipString) else {
            throw GraphError.invalidData("Invalid edge row")
        }

        let weight = Float(row["weight"] as? Double ?? 1.0)
        let bidirectional = (row["bidirectional"] as? Int64) == 1

        let metadata: KnowledgeEdge.EdgeMetadata = if let metadataString = row["metadata"] as? String,
                                                       let metadataData = metadataString.data(using: .utf8) {
            (try? JSONDecoder().decode(KnowledgeEdge.EdgeMetadata.self, from: metadataData)) ?? KnowledgeEdge.EdgeMetadata()
        } else {
            KnowledgeEdge.EdgeMetadata()
        }

        return KnowledgeEdge(
            id: id,
            sourceId: sourceId,
            targetId: targetId,
            relationship: relationship,
            weight: weight,
            bidirectional: bidirectional,
            metadata: metadata
        )
    }

    // MARK: - Errors

    enum GraphError: LocalizedError {
        case invalidData(String)
        case nodeNotFound(String)
        case cycleDetected

        var errorDescription: String? {
            switch self {
            case .invalidData(let message):
                return "Invalid data: \(message)"
            case .nodeNotFound(let id):
                return "Node not found: \(id)"
            case .cycleDetected:
                return "Cycle detected in graph"
            }
        }
    }
}

// MARK: - Supporting Types

struct GraphStatistics: Codable {
    var nodeCount: Int
    var edgeCount: Int
    var averageConnections: Double {
        guard nodeCount > 0 else { return 0 }
        return Double(edgeCount) / Double(nodeCount)
    }
}
