import Foundation

/// Design Agent - Specialized in UI/UX design and visual suggestions
/// Capabilities: UI design, visual suggestions, color theory, layout planning
actor DesignAgent: BaseAgent {

    // MARK: - Identity

    let id: UUID
    let type: AgentType = .design
    let name: String
    let description: String

    // MARK: - Capabilities

    let capabilities: Set<AgentCapability> = [
        .uiDesign,
        .visualSuggestions,
        .colorTheory,
        .layoutPlanning,
        .contextAware,
        .streaming
    ]

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
        name: String = "Design Agent",
        description: String = "Provides UI/UX design suggestions and visual guidance",
        coordinator: AgentCoordinator,
        memorySystem: MemorySystem?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coordinator = coordinator
        self.memorySystem = memorySystem
    }

    // MARK: - Task Handling

    func canHandle(task: AgentTask) -> Bool {
        switch task.type {
        case .design:
            return true
        case .general:
            return task.requiredCapabilities.isSubset(of: capabilities)
        default:
            return false
        }
    }

    func execute(task: AgentTask) async throws -> AgentResult {
        let startTime = Date()
        state = .working
        currentTask = task

        do {
            print("🎨 Design Agent starting: \(task.input)")

            // Use Claude for creative design work
            let service = AIServiceFactory.createService(for: .claude)

            guard service.isConfigured else {
                throw AgentError.serviceNotConfigured("Claude not configured")
            }

            // Build design-specific prompt
            let prompt = buildDesignPrompt(for: task)

            var designOutput = ""
            let stream = try await service.sendMessage(prompt, conversationHistory: [])
            for try await chunk in stream {
                designOutput += chunk
            }

            let executionTime = Date().timeIntervalSince(startTime)

            metrics.recordSuccess(executionTime: executionTime)
            state = .completed
            currentTask = nil

            print("✅ Design suggestions completed in \(String(format: "%.2f", executionTime))s")

            return AgentResult(
                taskId: task.id,
                agentId: id,
                success: true,
                output: designOutput,
                artifacts: [],
                executionTime: executionTime,
                confidence: 0.8,
                metadata: [
                    "model": "claude",
                    "agent_type": type.rawValue
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

    // MARK: - Design Methods

    private func buildDesignPrompt(for task: AgentTask) -> String {
        return """
        Provide UI/UX design guidance for the following:

        \(task.input)

        Consider:
        1. User experience principles
        2. Visual hierarchy and layout
        3. Color theory and aesthetics
        4. Accessibility
        5. Modern design trends
        6. Platform conventions

        Provide specific, actionable design suggestions with rationale.
        """
    }
}
