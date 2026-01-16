import Foundation

/// Factory for creating and managing autonomous agents
/// Handles agent instantiation, pooling, and lifecycle
@MainActor
final class AgentFactory: ObservableObject {

    // MARK: - Published State

    @Published var activeAgents: [UUID: any BaseAgent] = [:]
    @Published var agentPool: [AgentType: [UUID]] = [:]
    @Published var totalTasksExecuted: Int = 0

    // MARK: - Dependencies

    private let coordinator: AgentCoordinator
    private let memorySystem: MemorySystem?

    // MARK: - Configuration

    internal let maxAgentsPerType: Int = 5
    private let agentReuseEnabled: Bool = true

    // MARK: - Initialization

    init(coordinator: AgentCoordinator, memorySystem: MemorySystem? = nil) {
        self.coordinator = coordinator
        self.memorySystem = memorySystem
        initializeAgentPools()
    }

    private func initializeAgentPools() {
        for type in AgentType.allCases {
            agentPool[type] = []
        }
    }

    // MARK: - Agent Creation

    /// Create an agent of the specified type
    func createAgent(type: AgentType, blueprint: AgentBlueprint? = nil) async throws -> any BaseAgent {
        let agent: any BaseAgent

        switch type {
        case .research:
            agent = await ResearchAgent(
                coordinator: coordinator,
                memorySystem: memorySystem
            )

        case .code:
            agent = await CodeAgent(
                coordinator: coordinator,
                memorySystem: memorySystem
            )

        case .analysis:
            agent = await AnalysisAgent(
                coordinator: coordinator,
                memorySystem: memorySystem
            )

        case .design:
            agent = await DesignAgent(
                coordinator: coordinator,
                memorySystem: memorySystem
            )

        case .custom:
            guard let blueprint = blueprint else {
                throw AgentFactoryError.blueprintRequired
            }
            agent = await CustomAgent(
                blueprint: blueprint,
                coordinator: coordinator,
                memorySystem: memorySystem
            )
        }

        // Register agent
        activeAgents[agent.id] = agent
        agentPool[type, default: []].append(agent.id)

        print("🤖 Agent created: \(type.displayName) [\(agent.id)]")

        return agent
    }

    /// Get or create an agent for the task
    func getAgent(for task: AgentTask) async throws -> any BaseAgent {
        // Determine best agent type for task
        let agentType = selectAgentType(for: task)

        // Try to reuse existing idle agent
        if agentReuseEnabled, let existingAgent = try await findIdleAgent(ofType: agentType) {
            print("♻️ Reusing existing agent: \(agentType.displayName)")
            return existingAgent
        }

        // Check pool limit
        let currentCount = agentPool[agentType]?.count ?? 0
        if currentCount >= maxAgentsPerType {
            // Wait for an agent to become available or create anyway
            if let waitingAgent = try await waitForAvailableAgent(ofType: agentType, timeout: 30.0) {
                return waitingAgent
            }
        }

        // Create new agent
        return try await createAgent(type: agentType)
    }

    // MARK: - Agent Selection

    /// Select the best agent type for a task
    private func selectAgentType(for task: AgentTask) -> AgentType {
        // Direct type mapping
        switch task.type {
        case .research:
            return .research
        case .codeGeneration, .codeReview:
            return .code
        case .analysis:
            return .analysis
        case .design:
            return .design
        case .general:
            // Analyze required capabilities
            if task.requiredCapabilities.contains(.webSearch) || task.requiredCapabilities.contains(.documentRetrieval) {
                return .research
            } else if task.requiredCapabilities.contains(.codeGeneration) || task.requiredCapabilities.contains(.codeReview) {
                return .code
            } else if task.requiredCapabilities.contains(.dataProcessing) || task.requiredCapabilities.contains(.reasoning) {
                return .analysis
            } else if task.requiredCapabilities.contains(.uiDesign) {
                return .design
            }
            // Default to analysis for general tasks
            return .analysis
        }
    }

    /// Find an idle agent of the specified type
    private func findIdleAgent(ofType type: AgentType) async throws -> (any BaseAgent)? {
        guard let agentIds = agentPool[type] else { return nil }

        for agentId in agentIds {
            guard let agent = activeAgents[agentId] else { continue }
            let state = await agent.state
            if state == .idle {
                return agent
            }
        }

        return nil
    }

    /// Wait for an agent to become available
    private func waitForAvailableAgent(ofType type: AgentType, timeout: TimeInterval) async throws -> (any BaseAgent)? {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if let agent = try await findIdleAgent(ofType: type) {
                return agent
            }
            // Wait a bit before checking again
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return nil
    }

    // MARK: - Agent Management

    /// Execute a task with the appropriate agent
    func executeTask(_ task: AgentTask) async throws -> AgentResult {
        let agent = try await getAgent(for: task)

        // Check if agent can handle the task
        let canHandle = await agent.canHandle(task: task)
        guard canHandle else {
            throw AgentFactoryError.agentCannotHandleTask(agent.type, task.type)
        }

        // Execute
        let startTime = Date()
        do {
            let result = try await agent.execute(task: task)
            let executionTime = Date().timeIntervalSince(startTime)

            totalTasksExecuted += 1

            print("✅ Task completed by \(agent.type.displayName) in \(String(format: "%.2f", executionTime))s")

            return result
        } catch {
            print("❌ Task failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Execute multiple tasks in parallel
    func executeTasksParallel(_ tasks: [AgentTask]) async throws -> [AgentResult] {
        try await withThrowingTaskGroup(of: AgentResult.self) { group in
            for task in tasks {
                group.addTask {
                    try await self.executeTask(task)
                }
            }

            var results: [AgentResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    /// Cancel all active agents
    func cancelAll() async {
        for (_, agent) in activeAgents {
            await agent.cancel()
        }
    }

    /// Remove inactive agents to free memory
    func cleanup() async {
        var toRemove: [UUID] = []

        for (id, agent) in activeAgents {
            let state = await agent.state
            switch state {
            case .completed, .cancelled, .failed:
                toRemove.append(id)
            default:
                break
            }
        }

        for id in toRemove {
            activeAgents.removeValue(forKey: id)

            // Remove from pool
            for (type, var ids) in agentPool {
                if let index = ids.firstIndex(of: id) {
                    ids.remove(at: index)
                    agentPool[type] = ids
                }
            }
        }

        if !toRemove.isEmpty {
            print("🧹 Cleaned up \(toRemove.count) inactive agents")
        }
    }

    // MARK: - Statistics

    /// Get agent statistics
    func getStatistics() async -> AgentStatistics {
        var totalAgents = 0
        var activeCount = 0
        var idleCount = 0
        var typeDistribution: [AgentType: Int] = [:]

        for (type, ids) in agentPool {
            typeDistribution[type] = ids.count
            totalAgents += ids.count
        }

        for (_, agent) in activeAgents {
            let state = await agent.state
            if state.isActive {
                activeCount += 1
            } else if state == .idle {
                idleCount += 1
            }
        }

        return AgentStatistics(
            totalAgents: totalAgents,
            activeAgents: activeCount,
            idleAgents: idleCount,
            totalTasksExecuted: totalTasksExecuted,
            typeDistribution: typeDistribution
        )
    }

    struct AgentStatistics {
        let totalAgents: Int
        let activeAgents: Int
        let idleAgents: Int
        let totalTasksExecuted: Int
        let typeDistribution: [AgentType: Int]
    }
}

// MARK: - Agent Blueprint

/// Blueprint for creating custom agents
struct AgentBlueprint: Codable {
    let id: UUID
    var name: String
    var description: String
    var capabilities: Set<AgentCapability>
    var systemPrompt: String
    var model: AIProvider
    var config: AgentConfig

    struct AgentConfig: Codable {
        var temperature: Float
        var maxTokens: Int
        var streamingEnabled: Bool
        var contextWindowSize: Int
        var retryAttempts: Int
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        capabilities: Set<AgentCapability>,
        systemPrompt: String,
        model: AIProvider = .claude,
        config: AgentConfig = .default
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.capabilities = capabilities
        self.systemPrompt = systemPrompt
        self.model = model
        self.config = config
    }

    static let `default` = AgentBlueprint(
        name: "Custom Agent",
        description: "A custom agent for specialized tasks",
        capabilities: [.contextAware, .streaming],
        systemPrompt: "You are a helpful AI assistant."
    )
}

extension AgentBlueprint.AgentConfig {
    static let `default` = AgentBlueprint.AgentConfig(
        temperature: 0.7,
        maxTokens: 4096,
        streamingEnabled: true,
        contextWindowSize: 10,
        retryAttempts: 3
    )
}

// MARK: - Errors

enum AgentFactoryError: Error, LocalizedError {
    case blueprintRequired
    case agentCreationFailed(String)
    case agentCannotHandleTask(AgentType, AgentTask.TaskType)
    case noAvailableAgents
    case executionTimeout

    var errorDescription: String? {
        switch self {
        case .blueprintRequired:
            return "Blueprint required for custom agents"
        case .agentCreationFailed(let reason):
            return "Failed to create agent: \(reason)"
        case .agentCannotHandleTask(let agentType, let taskType):
            return "\(agentType.displayName) cannot handle \(taskType.rawValue) tasks"
        case .noAvailableAgents:
            return "No agents available to handle the task"
        case .executionTimeout:
            return "Task execution timed out"
        }
    }
}
