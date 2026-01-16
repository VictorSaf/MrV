import Foundation

/// MCP (Model Context Protocol) Integration Framework
/// Allows agents to connect to external tools and services via MCP
@MainActor
final class MCPIntegration: ObservableObject {

    // MARK: - Published State

    @Published var connectedServers: [MCPServer] = []
    @Published var availableTools: [MCPTool] = []
    @Published var isDiscovering: Bool = false

    // MARK: - Configuration

    private let maxConnections: Int = 10
    private let discoveryTimeout: TimeInterval = 30.0

    // MARK: - Initialization

    init() {
        // Load saved servers
        loadSavedServers()
    }

    // MARK: - Server Management

    /// Discover available MCP servers
    func discoverServers() async -> [MCPServer] {
        isDiscovering = true
        defer { isDiscovering = false }

        print("🔍 Discovering MCP servers...")

        // For now, return pre-configured servers
        // In future, implement actual discovery protocol
        let servers: [MCPServer] = [
            MCPServer(
                id: UUID(),
                name: "Filesystem Tools",
                endpoint: "localhost:3000",
                capabilities: [.fileOperations, .directoryListing],
                status: .disconnected
            ),
            MCPServer(
                id: UUID(),
                name: "Web Browser",
                endpoint: "localhost:3001",
                capabilities: [.webBrowsing, .screenshotCapture],
                status: .disconnected
            ),
            MCPServer(
                id: UUID(),
                name: "Database Tools",
                endpoint: "localhost:3002",
                capabilities: [.databaseQuery, .dataAnalysis],
                status: .disconnected
            )
        ]

        connectedServers = servers
        return servers
    }

    /// Connect to an MCP server
    func connect(server: MCPServer) async throws {
        print("🔌 Connecting to MCP server: \(server.name)...")

        guard connectedServers.count < maxConnections else {
            throw MCPError.maxConnectionsReached
        }

        // Update server status
        if let index = connectedServers.firstIndex(where: { $0.id == server.id }) {
            connectedServers[index].status = .connecting

            // Simulate connection (in future, implement actual MCP handshake)
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5s

            connectedServers[index].status = .connected
            connectedServers[index].connectedAt = Date()

            // Load tools from server
            let tools = try await loadTools(from: server)
            availableTools.append(contentsOf: tools)

            print("✅ Connected to: \(server.name) (\(tools.count) tools available)")
        }
    }

    /// Disconnect from an MCP server
    func disconnect(server: MCPServer) async {
        print("🔌 Disconnecting from: \(server.name)...")

        if let index = connectedServers.firstIndex(where: { $0.id == server.id }) {
            connectedServers[index].status = .disconnected
            connectedServers[index].connectedAt = nil

            // Remove tools from this server
            availableTools.removeAll { $0.serverId == server.id }

            print("✅ Disconnected from: \(server.name)")
        }
    }

    // MARK: - Tool Execution

    /// Execute an MCP tool
    func executeTool(tool: MCPTool, parameters: [String: Any]) async throws -> MCPToolResult {
        print("🔧 Executing MCP tool: \(tool.name)...")

        guard let server = connectedServers.first(where: { $0.id == tool.serverId }) else {
            throw MCPError.serverNotConnected
        }

        guard server.status == .connected else {
            throw MCPError.serverNotConnected
        }

        // Simulate tool execution (in future, implement actual MCP protocol)
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1s

        let result = MCPToolResult(
            toolId: tool.id,
            success: true,
            output: "Tool \(tool.name) executed successfully",
            executionTime: 1.0,
            metadata: parameters
        )

        print("✅ Tool execution complete: \(tool.name)")
        return result
    }

    /// Find tools by capability
    func findTools(withCapability capability: MCPCapability) -> [MCPTool] {
        return availableTools.filter { tool in
            tool.capabilities.contains(capability)
        }
    }

    /// Find tools by name pattern
    func findTools(matching pattern: String) -> [MCPTool] {
        let lowercased = pattern.lowercased()
        return availableTools.filter { tool in
            tool.name.lowercased().contains(lowercased) ||
            tool.description.lowercased().contains(lowercased)
        }
    }

    // MARK: - Tool Loading

    private func loadTools(from server: MCPServer) async throws -> [MCPTool] {
        // Simulate loading tools from server
        // In future, implement actual MCP tool discovery

        var tools: [MCPTool] = []

        if server.capabilities.contains(.fileOperations) {
            tools.append(contentsOf: [
                MCPTool(
                    id: UUID(),
                    serverId: server.id,
                    name: "read_file",
                    description: "Read contents of a file",
                    capabilities: [.fileOperations],
                    parameters: ["path": "string"]
                ),
                MCPTool(
                    id: UUID(),
                    serverId: server.id,
                    name: "write_file",
                    description: "Write contents to a file",
                    capabilities: [.fileOperations],
                    parameters: ["path": "string", "content": "string"]
                )
            ])
        }

        if server.capabilities.contains(.webBrowsing) {
            tools.append(contentsOf: [
                MCPTool(
                    id: UUID(),
                    serverId: server.id,
                    name: "navigate_to",
                    description: "Navigate browser to URL",
                    capabilities: [.webBrowsing],
                    parameters: ["url": "string"]
                ),
                MCPTool(
                    id: UUID(),
                    serverId: server.id,
                    name: "take_screenshot",
                    description: "Capture screenshot of current page",
                    capabilities: [.screenshotCapture],
                    parameters: [:]
                )
            ])
        }

        if server.capabilities.contains(.databaseQuery) {
            tools.append(contentsOf: [
                MCPTool(
                    id: UUID(),
                    serverId: server.id,
                    name: "execute_query",
                    description: "Execute SQL query",
                    capabilities: [.databaseQuery],
                    parameters: ["query": "string"]
                )
            ])
        }

        return tools
    }

    // MARK: - Persistence

    private func loadSavedServers() {
        // In future, load from UserDefaults or config file
        connectedServers = []
    }

    private func saveServers() {
        // In future, save to UserDefaults or config file
    }

    // MARK: - Statistics

    func getStatistics() -> MCPStatistics {
        let connectedCount = connectedServers.filter { $0.status == .connected }.count

        return MCPStatistics(
            totalServers: connectedServers.count,
            connectedServers: connectedCount,
            availableTools: availableTools.count
        )
    }

    struct MCPStatistics {
        let totalServers: Int
        let connectedServers: Int
        let availableTools: Int
    }
}

// MARK: - MCP Server

struct MCPServer: Identifiable, Codable {
    let id: UUID
    var name: String
    var endpoint: String
    var capabilities: Set<MCPCapability>
    var status: ServerStatus
    var connectedAt: Date?

    enum ServerStatus: String, Codable {
        case disconnected
        case connecting
        case connected
        case error

        var icon: String {
            switch self {
            case .disconnected: return "⚪️"
            case .connecting: return "🟡"
            case .connected: return "🟢"
            case .error: return "🔴"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        endpoint: String,
        capabilities: Set<MCPCapability>,
        status: ServerStatus = .disconnected,
        connectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.capabilities = capabilities
        self.status = status
        self.connectedAt = connectedAt
    }
}

// MARK: - MCP Tool

struct MCPTool: Identifiable, Codable {
    let id: UUID
    let serverId: UUID
    var name: String
    var description: String
    var capabilities: Set<MCPCapability>
    var parameters: [String: String]  // parameter name -> type

    var displayName: String {
        return name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - MCP Tool Result

struct MCPToolResult: Codable {
    let toolId: UUID
    var success: Bool
    var output: String
    var executionTime: TimeInterval
    var metadata: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case toolId, success, output, executionTime
    }

    init(toolId: UUID, success: Bool, output: String, executionTime: TimeInterval, metadata: [String: Any]? = nil) {
        self.toolId = toolId
        self.success = success
        self.output = output
        self.executionTime = executionTime
        self.metadata = metadata
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toolId, forKey: .toolId)
        try container.encode(success, forKey: .success)
        try container.encode(output, forKey: .output)
        try container.encode(executionTime, forKey: .executionTime)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolId = try container.decode(UUID.self, forKey: .toolId)
        success = try container.decode(Bool.self, forKey: .success)
        output = try container.decode(String.self, forKey: .output)
        executionTime = try container.decode(TimeInterval.self, forKey: .executionTime)
        metadata = nil
    }
}

// MARK: - MCP Capability

enum MCPCapability: String, Codable, Hashable, CaseIterable {
    // File operations
    case fileOperations
    case directoryListing

    // Web operations
    case webBrowsing
    case screenshotCapture
    case webScraping

    // Database operations
    case databaseQuery
    case dataAnalysis

    // System operations
    case processExecution
    case environmentAccess

    // AI operations
    case embeddingGeneration
    case imageGeneration

    var description: String {
        switch self {
        case .fileOperations: return "Read/write files"
        case .directoryListing: return "List directory contents"
        case .webBrowsing: return "Browse web pages"
        case .screenshotCapture: return "Capture screenshots"
        case .webScraping: return "Extract web data"
        case .databaseQuery: return "Query databases"
        case .dataAnalysis: return "Analyze data"
        case .processExecution: return "Execute processes"
        case .environmentAccess: return "Access environment"
        case .embeddingGeneration: return "Generate embeddings"
        case .imageGeneration: return "Generate images"
        }
    }
}

// MARK: - Errors

enum MCPError: Error, LocalizedError {
    case serverNotConnected
    case maxConnectionsReached
    case toolNotFound
    case executionFailed(String)
    case invalidParameters

    var errorDescription: String? {
        switch self {
        case .serverNotConnected:
            return "MCP server not connected"
        case .maxConnectionsReached:
            return "Maximum MCP connections reached"
        case .toolNotFound:
            return "MCP tool not found"
        case .executionFailed(let reason):
            return "Tool execution failed: \(reason)"
        case .invalidParameters:
            return "Invalid tool parameters"
        }
    }
}
