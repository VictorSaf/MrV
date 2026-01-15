import Foundation

/// Code Agent - Specialized in code analysis, generation, and review
/// Capabilities: Code generation, review, refactoring, syntax analysis, bug detection
actor CodeAgent: BaseAgent {

    // MARK: - Identity

    let id: UUID
    let type: AgentType = .code
    let name: String
    let description: String

    // MARK: - Capabilities

    let capabilities: Set<AgentCapability> = [
        .codeGeneration,
        .codeReview,
        .codeRefactoring,
        .syntaxAnalysis,
        .bugDetection,
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
        name: String = "Code Agent",
        description: String = "Generates, analyzes, and reviews code",
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
        case .codeGeneration, .codeReview:
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
            print("💻 Code Agent starting: \(task.input)")

            // Use GPT-4 for code tasks (it excels at code)
            let service = AIServiceFactory.createService(for: .openAI)

            guard service.isConfigured else {
                throw AgentError.serviceNotConfigured("OpenAI (GPT-4) not configured")
            }

            // Build code-specific prompt
            let prompt = buildCodePrompt(for: task)

            var codeOutput = ""
            let stream = try await service.sendMessage(prompt, conversationHistory: [])
            for try await chunk in stream {
                codeOutput += chunk
            }

            let executionTime = Date().timeIntervalSince(startTime)

            // Extract code artifacts if present
            let artifacts = extractCodeArtifacts(from: codeOutput)

            metrics.recordSuccess(executionTime: executionTime)
            state = .completed
            currentTask = nil

            print("✅ Code task completed in \(String(format: "%.2f", executionTime))s")

            return AgentResult(
                taskId: task.id,
                agentId: id,
                success: true,
                output: codeOutput,
                artifacts: artifacts,
                executionTime: executionTime,
                confidence: 0.9,
                metadata: [
                    "model": "gpt-4",
                    "agent_type": type.rawValue,
                    "artifacts_count": String(artifacts.count)
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

    // MARK: - Code Methods

    private func buildCodePrompt(for task: AgentTask) -> String {
        var prompt = ""

        switch task.type {
        case .codeGeneration:
            prompt = """
            Generate code based on the following requirements:

            \(task.input)

            Requirements:
            - Write clean, maintainable code
            - Include comments for complex logic
            - Follow best practices
            - Consider error handling
            - Use appropriate design patterns

            Provide the complete implementation with explanations.
            """

        case .codeReview:
            prompt = """
            Review the following code and provide detailed feedback:

            \(task.input)

            Focus on:
            1. Bugs and potential errors
            2. Performance issues
            3. Security vulnerabilities
            4. Code quality and maintainability
            5. Best practices violations
            6. Suggested improvements

            Be specific and actionable in your feedback.
            """

        default:
            prompt = task.input
        }

        return prompt
    }

    private func extractCodeArtifacts(from output: String) -> [AgentResult.Artifact] {
        var artifacts: [AgentResult.Artifact] = []

        // Simple code block extraction (```language ... ```)
        let pattern = "```([a-z]+)?\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return artifacts
        }

        let nsOutput = output as NSString
        let matches = regex.matches(in: output, range: NSRange(location: 0, length: nsOutput.length))

        for match in matches {
            if match.numberOfRanges >= 3 {
                let codeRange = match.range(at: 2)
                let code = nsOutput.substring(with: codeRange)

                artifacts.append(AgentResult.Artifact(
                    id: UUID(),
                    type: .code,
                    content: code,
                    metadata: ["extracted": "true"]
                ))
            }
        }

        return artifacts
    }
}

// MARK: - Agent Error

enum AgentError: Error, LocalizedError {
    case serviceNotConfigured(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .serviceNotConfigured(let service):
            return "Service not configured: \(service)"
        case .executionFailed(let reason):
            return "Execution failed: \(reason)"
        }
    }
}
