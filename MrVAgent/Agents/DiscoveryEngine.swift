import Foundation

/// Discovery Engine - Background scanning and optimization system
/// Continuously monitors, learns, and improves the agent system
@MainActor
final class DiscoveryEngine: ObservableObject {

    // MARK: - Published State

    @Published var isRunning: Bool = false
    @Published var discoveries: [Discovery] = []
    @Published var recommendations: [Recommendation] = []
    @Published var scanProgress: Double = 0.0

    // MARK: - Dependencies

    private let agentFactory: AgentFactory
    private let mcpIntegration: MCPIntegration?
    private let memorySystem: MemorySystem?

    // MARK: - Configuration

    private let scanInterval: TimeInterval = 300.0  // 5 minutes
    private let maxDiscoveries: Int = 100

    // MARK: - State

    private var scanTask: Task<Void, Never>?
    private var lastScanTime: Date?
    private var scanCount: Int = 0

    // MARK: - Initialization

    init(
        agentFactory: AgentFactory,
        mcpIntegration: MCPIntegration? = nil,
        memorySystem: MemorySystem? = nil
    ) {
        self.agentFactory = agentFactory
        self.mcpIntegration = mcpIntegration
        self.memorySystem = memorySystem
    }

    // MARK: - Engine Control

    /// Start the discovery engine
    func start() {
        guard !isRunning else {
            print("⚠️ Discovery Engine already running")
            return
        }

        print("🔍 Starting Discovery Engine...")
        isRunning = true

        scanTask = Task {
            while !Task.isCancelled {
                await performScan()

                // Wait for next scan interval
                do {
                    try await Task.sleep(nanoseconds: UInt64(scanInterval * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
    }

    /// Stop the discovery engine
    func stop() {
        print("🛑 Stopping Discovery Engine...")
        scanTask?.cancel()
        scanTask = nil
        isRunning = false
        scanProgress = 0.0
    }

    // MARK: - Scanning

    /// Perform a complete discovery scan
    private func performScan() async {
        lastScanTime = Date()
        scanCount += 1
        scanProgress = 0.0

        print("🔍 Discovery Scan #\(scanCount) starting...")

        let scanSteps = 5.0
        let progressPerStep = 1.0 / scanSteps

        // Step 1: Scan agent performance
        await scanAgentPerformance()
        scanProgress += progressPerStep

        // Step 2: Discover MCP servers
        if let mcpIntegration = mcpIntegration {
            await scanMCPServers(integration: mcpIntegration)
        }
        scanProgress += progressPerStep

        // Step 3: Analyze memory patterns
        if let memorySystem = memorySystem {
            await scanMemoryPatterns(memory: memorySystem)
        }
        scanProgress += progressPerStep

        // Step 4: Identify optimization opportunities
        await identifyOptimizations()
        scanProgress += progressPerStep

        // Step 5: Generate recommendations
        await generateRecommendations()
        scanProgress = 1.0

        // Cleanup old discoveries
        cleanupOldDiscoveries()

        print("✅ Discovery Scan #\(scanCount) complete (\(discoveries.count) discoveries, \(recommendations.count) recommendations)")
    }

    // MARK: - Agent Performance Scanning

    private func scanAgentPerformance() async {
        let stats = await agentFactory.getStatistics()

        // Check for underutilized agent types
        for (type, count) in stats.typeDistribution {
            if count == 0 {
                addDiscovery(Discovery(
                    type: .underutilizedAgent,
                    title: "Unused Agent Type",
                    description: "Agent type '\(type.displayName)' has never been used",
                    severity: .low,
                    data: ["agentType": type.rawValue]
                ))
            }
        }

        // Check for high failure rates (from coordinator)
        // This would require accessing coordinator stats
        // For now, placeholder

        addDiscovery(Discovery(
            type: .performanceMetric,
            title: "Agent System Active",
            description: "Total agents: \(stats.totalAgents), Active: \(stats.activeAgents)",
            severity: .info,
            data: [
                "totalAgents": String(stats.totalAgents),
                "activeAgents": String(stats.activeAgents)
            ]
        ))
    }

    // MARK: - MCP Server Scanning

    private func scanMCPServers(integration: MCPIntegration) async {
        // Discover new servers
        let servers = await integration.discoverServers()

        for server in servers where server.status == .disconnected {
            addDiscovery(Discovery(
                type: .newMCPServer,
                title: "MCP Server Available",
                description: "Server '\(server.name)' available at \(server.endpoint)",
                severity: .info,
                data: [
                    "serverId": server.id.uuidString,
                    "name": server.name,
                    "endpoint": server.endpoint
                ]
            ))
        }

        // Check connected servers health
        for server in servers where server.status == .connected {
            // Placeholder health check
            addDiscovery(Discovery(
                type: .serverStatus,
                title: "MCP Server Connected",
                description: "Server '\(server.name)' operating normally",
                severity: .info,
                data: ["serverId": server.id.uuidString]
            ))
        }
    }

    // MARK: - Memory Pattern Scanning

    private func scanMemoryPatterns(memory: MemorySystem) async {
        // Analyze conversation patterns
        let stats = try? await memory.getConversationStats()

        if let stats = stats {
            // Check for conversation activity
            if stats.totalMessages > 0 {
                addDiscovery(Discovery(
                    type: .knowledgeGrowth,
                    title: "Knowledge Base Status",
                    description: "Total messages: \(stats.totalMessages), Avg response time: \(String(format: "%.2f", stats.averageResponseTime))s",
                    severity: .info,
                    data: [
                        "totalMessages": String(stats.totalMessages),
                        "avgResponseTime": String(format: "%.2f", stats.averageResponseTime)
                    ]
                ))
            }

            // Check if a provider is being used more
            if let provider = stats.mostUsedProvider {
                addDiscovery(Discovery(
                    type: .performanceMetric,
                    title: "Most Used Provider",
                    description: "Provider '\(provider.displayName)' is used most frequently",
                    severity: .info,
                    data: ["provider": provider.rawValue]
                ))
            }
        }
    }

    // MARK: - Optimization Identification

    private func identifyOptimizations() async {
        let stats = await agentFactory.getStatistics()

        // Check if too many idle agents (resource waste)
        if stats.idleAgents > 5 {
            addDiscovery(Discovery(
                type: .optimization,
                title: "High Idle Agent Count",
                description: "\(stats.idleAgents) idle agents consuming resources",
                severity: .medium,
                data: ["idleCount": String(stats.idleAgents)]
            ))
        }

        // Check for bottlenecks
        if stats.activeAgents >= agentFactory.maxAgentsPerType {
            addDiscovery(Discovery(
                type: .bottleneck,
                title: "Agent Pool Saturation",
                description: "Agent pool may be saturated, consider increasing limits",
                severity: .medium,
                data: ["activeAgents": String(stats.activeAgents)]
            ))
        }
    }

    // MARK: - Recommendation Generation

    private func generateRecommendations() async {
        // Analyze discoveries and generate actionable recommendations
        let optimizationDiscoveries = discoveries.filter { $0.type == .optimization }

        for discovery in optimizationDiscoveries {
            if discovery.title == "High Idle Agent Count" {
                addRecommendation(Recommendation(
                    title: "Reduce Idle Agents",
                    description: "Consider implementing agent cleanup or reducing max pool size",
                    priority: .medium,
                    action: .configurationChange,
                    relatedDiscoveryId: discovery.id
                ))
            }
        }

        // Recommend MCP connections
        let mcpDiscoveries = discoveries.filter { $0.type == .newMCPServer }
        if !mcpDiscoveries.isEmpty {
            addRecommendation(Recommendation(
                title: "Connect to MCP Servers",
                description: "New MCP servers available with useful capabilities",
                priority: .low,
                action: .mcpConnection,
                relatedDiscoveryId: mcpDiscoveries.first?.id
            ))
        }

        // Learning-based recommendations
        // In future, implement ML-based pattern recognition
    }

    // MARK: - Discovery Management

    private func addDiscovery(_ discovery: Discovery) {
        // Check for duplicates (same type + similar description)
        let isDuplicate = discoveries.contains { existing in
            existing.type == discovery.type &&
            existing.title == discovery.title
        }

        guard !isDuplicate else { return }

        discoveries.insert(discovery, at: 0)
    }

    private func addRecommendation(_ recommendation: Recommendation) {
        // Check for duplicates
        let isDuplicate = recommendations.contains { existing in
            existing.title == recommendation.title
        }

        guard !isDuplicate else { return }

        recommendations.insert(recommendation, at: 0)
    }

    private func cleanupOldDiscoveries() {
        // Keep only recent discoveries
        if discoveries.count > maxDiscoveries {
            discoveries = Array(discoveries.prefix(maxDiscoveries))
        }

        // Remove old low-severity discoveries (older than 1 hour)
        let cutoff = Date().addingTimeInterval(-3600)
        discoveries.removeAll { discovery in
            discovery.severity == .low &&
            discovery.timestamp < cutoff
        }
    }

    // MARK: - Manual Scan

    /// Trigger a manual scan immediately
    func triggerManualScan() async {
        print("🔍 Manual discovery scan triggered...")
        await performScan()
    }

    // MARK: - Statistics

    func getStatistics() -> DiscoveryStatistics {
        return DiscoveryStatistics(
            isRunning: isRunning,
            totalScans: scanCount,
            lastScanTime: lastScanTime,
            discoveryCount: discoveries.count,
            recommendationCount: recommendations.count
        )
    }

    struct DiscoveryStatistics {
        let isRunning: Bool
        let totalScans: Int
        let lastScanTime: Date?
        let discoveryCount: Int
        let recommendationCount: Int
    }
}

// MARK: - Discovery

struct Discovery: Identifiable {
    let id: UUID
    var type: DiscoveryType
    var title: String
    var description: String
    var severity: Severity
    var timestamp: Date
    var data: [String: String]

    enum DiscoveryType {
        case underutilizedAgent
        case newMCPServer
        case serverStatus
        case memoryPattern
        case knowledgeGrowth
        case optimization
        case bottleneck
        case performanceMetric
        case securityIssue
        case configurationIssue

        var icon: String {
            switch self {
            case .underutilizedAgent: return "💤"
            case .newMCPServer: return "🆕"
            case .serverStatus: return "📡"
            case .memoryPattern: return "🧠"
            case .knowledgeGrowth: return "📈"
            case .optimization: return "⚡️"
            case .bottleneck: return "🚧"
            case .performanceMetric: return "📊"
            case .securityIssue: return "🔐"
            case .configurationIssue: return "⚙️"
            }
        }
    }

    enum Severity {
        case info, low, medium, high, critical

        var color: String {
            switch self {
            case .info: return "blue"
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }

    init(
        id: UUID = UUID(),
        type: DiscoveryType,
        title: String,
        description: String,
        severity: Severity,
        timestamp: Date = Date(),
        data: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: - Recommendation

struct Recommendation: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var priority: Priority
    var action: ActionType
    var relatedDiscoveryId: UUID?
    var timestamp: Date

    enum Priority {
        case low, medium, high

        var icon: String {
            switch self {
            case .low: return "⬇️"
            case .medium: return "➡️"
            case .high: return "⬆️"
            }
        }
    }

    enum ActionType {
        case configurationChange
        case mcpConnection
        case agentCreation
        case cleanup
        case optimization
        case learningUpdate

        var description: String {
            switch self {
            case .configurationChange: return "Configuration Change"
            case .mcpConnection: return "MCP Connection"
            case .agentCreation: return "Agent Creation"
            case .cleanup: return "Cleanup"
            case .optimization: return "Optimization"
            case .learningUpdate: return "Learning Update"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        priority: Priority,
        action: ActionType,
        relatedDiscoveryId: UUID? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.action = action
        self.relatedDiscoveryId = relatedDiscoveryId
        self.timestamp = timestamp
    }
}
