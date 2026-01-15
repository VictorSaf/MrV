import Foundation

/// Analysis Agent - Specialized in data processing, reasoning, and insights
/// Capabilities: Data processing, statistical analysis, pattern recognition, reasoning, decision making
actor AnalysisAgent: BaseAgent {

    // MARK: - Identity

    let id: UUID
    let type: AgentType = .analysis
    let name: String
    let description: String

    // MARK: - Capabilities

    let capabilities: Set<AgentCapability> = [
        .dataProcessing,
        .statisticalAnalysis,
        .patternRecognition,
        .reasoning,
        .decisionMaking,
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
        name: String = "Analysis Agent",
        description: String = "Processes data and provides insights through reasoning",
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
        case .analysis:
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
            print("📊 Analysis Agent starting: \(task.input)")

            // Use Claude for analysis (strong reasoning)
            let service = AIServiceFactory.createService(for: .claude)

            guard service.isConfigured else {
                throw AgentError.serviceNotConfigured("Claude not configured")
            }

            // Build analysis-specific prompt
            let prompt = buildAnalysisPrompt(for: task)

            var analysisOutput = ""
            let stream = try await service.sendMessage(prompt, conversationHistory: [])
            for try await chunk in stream {
                analysisOutput += chunk
            }

            let executionTime = Date().timeIntervalSince(startTime)

            // Extract data artifacts if present
            let artifacts = extractDataArtifacts(from: analysisOutput)

            metrics.recordSuccess(executionTime: executionTime)
            state = .completed
            currentTask = nil

            print("✅ Analysis completed in \(String(format: "%.2f", executionTime))s")

            return AgentResult(
                taskId: task.id,
                agentId: id,
                success: true,
                output: analysisOutput,
                artifacts: artifacts,
                executionTime: executionTime,
                confidence: 0.85,
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

    // MARK: - Analysis Methods

    private func buildAnalysisPrompt(for task: AgentTask) -> String {
        return """
        Analyze the following and provide detailed insights:

        \(task.input)

        Your analysis should include:
        1. Key patterns and trends
        2. Important observations
        3. Logical conclusions
        4. Potential implications
        5. Recommendations (if applicable)

        Be thorough, objective, and data-driven in your analysis.
        Use structured reasoning and cite specific evidence.
        """
    }

    private func extractDataArtifacts(from output: String) -> [AgentResult.Artifact] {
        var artifacts: [AgentResult.Artifact] = []

        // Look for JSON data blocks
        if let jsonRange = output.range(of: "```json\\n([\\s\\S]*?)```", options: .regularExpression) {
            let jsonString = String(output[jsonRange])
            artifacts.append(AgentResult.Artifact(
                id: UUID(),
                type: .json,
                content: jsonString,
                metadata: ["extracted": "true"]
            ))
        }

        return artifacts
    }
}
