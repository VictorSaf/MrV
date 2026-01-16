import Foundation

/// Custom Agent - User-defined agent with configurable capabilities
/// Built from AgentBlueprint with custom system prompt and configuration
actor CustomAgent: BaseAgent {

    // MARK: - Identity

    let id: UUID
    let type: AgentType = .custom
    let name: String
    let description: String

    // MARK: - Blueprint

    private let blueprint: AgentBlueprint

    // MARK: - Capabilities

    let capabilities: Set<AgentCapability>

    // MARK: - Dependencies

    private let coordinator: AgentCoordinator
    private let memorySystem: MemorySystem?

    // MARK: - State

    private(set) var state: AgentState = .idle
    private(set) var metrics: AgentMetrics = AgentMetrics()
    private var currentTask: AgentTask?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        blueprint: AgentBlueprint,
        coordinator: AgentCoordinator,
        memorySystem: MemorySystem?
    ) {
        self.id = id
        self.blueprint = blueprint
        self.name = blueprint.name
        self.description = blueprint.description
        self.capabilities = blueprint.capabilities
        self.coordinator = coordinator
        self.memorySystem = memorySystem
    }

    // MARK: - Task Handling

    func canHandle(task: AgentTask) -> Bool {
        // Custom agents can handle tasks if they have required capabilities
        return task.requiredCapabilities.isSubset(of: capabilities)
    }

    func execute(task: AgentTask) async throws -> AgentResult {
        let startTime = Date()
        state = .working
        currentTask = task

        do {
            print("⚙️ Custom Agent [\(name)] starting: \(task.input)")

            // Use configured model
            let service = AIServiceFactory.createService(for: blueprint.model)

            guard service.isConfigured else {
                throw AgentError.serviceNotConfigured(blueprint.model.displayName)
            }

            // Build prompt with system context
            let fullPrompt = """
            System: \(blueprint.systemPrompt)

            User: \(task.input)
            """

            var output = ""
            if blueprint.config.streamingEnabled {
                let stream = try await service.sendMessage(fullPrompt, conversationHistory: [])
                for try await chunk in stream {
                    output += chunk
                }
            } else {
                let stream = try await service.sendMessage(fullPrompt, conversationHistory: [])
                for try await chunk in stream {
                    output += chunk
                }
            }

            let executionTime = Date().timeIntervalSince(startTime)

            metrics.recordSuccess(executionTime: executionTime)
            state = .completed
            currentTask = nil

            print("✅ Custom agent task completed in \(String(format: "%.2f", executionTime))s")

            return AgentResult(
                taskId: task.id,
                agentId: id,
                success: true,
                output: output,
                artifacts: [],
                executionTime: executionTime,
                confidence: 0.75,  // Conservative confidence for custom agents
                metadata: [
                    "model": blueprint.model.rawValue,
                    "agent_type": type.rawValue,
                    "agent_name": name
                ]
            )

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            metrics.recordFailure(executionTime: executionTime)
            state = .failed(error.localizedDescription)
            currentTask = nil
            throw error
        }
    }

    func cancel() {
        state = .cancelled
        currentTask = nil
    }
}
