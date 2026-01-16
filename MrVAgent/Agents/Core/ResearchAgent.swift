import Foundation

/// Research Agent - Specialized in information gathering and web search
/// Capabilities: Web search, document retrieval, memory search, knowledge graph queries
actor ResearchAgent: BaseAgent {

    // MARK: - Identity

    let id: UUID
    let type: AgentType = .research
    let name: String
    let description: String

    // MARK: - Capabilities

    let capabilities: Set<AgentCapability> = [
        .webSearch,
        .documentRetrieval,
        .knowledgeGraphQuery,
        .memorySearch,
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
        name: String = "Research Agent",
        description: String = "Gathers information from web, memory, and knowledge graph",
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
        // Check if task requires research capabilities
        switch task.type {
        case .research:
            return true
        case .general:
            // Can handle if requires web search or memory search
            return task.requiredCapabilities.contains(.webSearch) ||
                   task.requiredCapabilities.contains(.memorySearch) ||
                   task.requiredCapabilities.contains(.knowledgeGraphQuery)
        default:
            return false
        }
    }

    func execute(task: AgentTask) async throws -> AgentResult {
        let startTime = Date()
        state = .working
        currentTask = task

        do {
            print("🔍 Research Agent starting: \(task.input)")

            // Gather information from multiple sources
            var results: [String] = []
            var artifacts: [AgentResult.Artifact] = []
            var sources: [String] = []

            // 1. Search memory if available
            if let memorySystem = memorySystem {
                let memoryResults = try await searchMemory(query: task.input, memorySystem: memorySystem)
                if !memoryResults.isEmpty {
                    results.append("## Memory Context\n\n\(memoryResults)")
                    sources.append("Memory System")
                }
            }

            // 2. Search knowledge graph if available
            if let memorySystem = memorySystem {
                let knowledgeResults = try await searchKnowledgeGraph(query: task.input, memorySystem: memorySystem)
                if !knowledgeResults.isEmpty {
                    results.append("## Knowledge Graph\n\n\(knowledgeResults)")
                    sources.append("Knowledge Graph")
                }
            }

            // 3. Web search using Perplexity (if enabled)
            if task.requiredCapabilities.contains(.webSearch) {
                let webResults = try await performWebSearch(query: task.input)
                if !webResults.isEmpty {
                    results.append("## Web Search Results\n\n\(webResults)")
                    sources.append("Web Search")

                    // Create artifact for web results
                    artifacts.append(AgentResult.Artifact(
                        id: UUID(),
                        type: .reference,
                        content: webResults,
                        metadata: ["source": "perplexity"]
                    ))
                }
            }

            // 4. Synthesize findings using AI
            let synthesis = try await synthesizeFindings(
                query: task.input,
                findings: results.joined(separator: "\n\n"),
                sources: sources
            )

            // Create final result
            let executionTime = Date().timeIntervalSince(startTime)
            let output = """
            # Research Results

            \(synthesis)

            ---

            **Sources**: \(sources.joined(separator: ", "))
            **Execution Time**: \(String(format: "%.2f", executionTime))s
            """

            // Update metrics
            metrics.recordSuccess(executionTime: executionTime)
            state = .completed
            currentTask = nil

            print("✅ Research completed in \(String(format: "%.2f", executionTime))s")

            return AgentResult(
                taskId: task.id,
                agentId: id,
                success: true,
                output: output,
                artifacts: artifacts,
                executionTime: executionTime,
                confidence: calculateConfidence(sources: sources),
                metadata: [
                    "sources_count": String(sources.count),
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

    // MARK: - Research Methods

    private func searchMemory(query: String, memorySystem: MemorySystem) async throws -> String {
        // Extract keywords from query
        let keywords = query.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }

        guard !keywords.isEmpty else { return "" }

        let conversations = try await memorySystem.searchConversations(keywords: keywords)

        if conversations.isEmpty {
            return "No relevant conversations found in memory."
        }

        // Format results
        let formatted = conversations.prefix(5).map { conv in
            """
            **Q**: \(conv.userInput.prefix(150))
            **A**: \(conv.aiResponse.prefix(150))
            """
        }.joined(separator: "\n\n")

        return "Found \(conversations.count) relevant conversations:\n\n\(formatted)"
    }

    private func searchKnowledgeGraph(query: String, memorySystem: MemorySystem) async throws -> String {
        let knowledge = try await memorySystem.searchKnowledge(query, limit: 10)

        if knowledge.isEmpty {
            return "No relevant knowledge nodes found."
        }

        // Format results
        let formatted = knowledge.map { node in
            let desc = node.content.description ?? "No description"
            return "\(node.type.icon) **\(node.name)**: \(desc)"
        }.joined(separator: "\n")

        return "Found \(knowledge.count) knowledge nodes:\n\n\(formatted)"
    }

    private func performWebSearch(query: String) async throws -> String {
        // Use Perplexity through coordinator
        let service = AIServiceFactory.createService(for: .perplexity)

        guard service.isConfigured else {
            return "Web search unavailable (Perplexity not configured)"
        }

        // Create research prompt
        let prompt = """
        Research the following query and provide comprehensive, factual information with sources:

        \(query)

        Focus on:
        1. Current information (prioritize recent data)
        2. Multiple perspectives
        3. Factual accuracy
        4. Relevant examples

        Format response as markdown with clear sections.
        """

        do {
            var result = ""
            let stream = try await service.sendMessage(prompt, conversationHistory: [])
            for try await chunk in stream {
                result += chunk
            }
            return result.isEmpty ? "No web results found." : result
        } catch {
            return "Web search failed: \(error.localizedDescription)"
        }
    }

    private func synthesizeFindings(query: String, findings: String, sources: [String]) async throws -> String {
        // Use Claude to synthesize findings
        let service = AIServiceFactory.createService(for: .claude)

        guard service.isConfigured else {
            // Fallback: return raw findings
            return findings
        }

        let synthesisPrompt = """
        You are a research assistant synthesizing information from multiple sources.

        **Original Query**: \(query)

        **Sources**: \(sources.joined(separator: ", "))

        **Findings**:
        \(findings)

        Synthesize these findings into a clear, comprehensive answer. Structure your response with:
        1. Direct answer to the query
        2. Key insights from sources
        3. Important details and context
        4. Any limitations or caveats

        Be concise but thorough. Use markdown formatting.
        """

        var synthesis = ""
        let stream = try await service.sendMessage(synthesisPrompt, conversationHistory: [])
        for try await chunk in stream {
            synthesis += chunk
        }

        return synthesis
    }

    private func calculateConfidence(sources: [String]) -> Float {
        // Confidence based on number and type of sources
        var confidence: Float = 0.5  // Base confidence

        if sources.contains("Memory System") {
            confidence += 0.15  // Recent context is valuable
        }

        if sources.contains("Knowledge Graph") {
            confidence += 0.15  // Structured knowledge adds confidence
        }

        if sources.contains("Web Search") {
            confidence += 0.20  // Real-time data is highly valuable
        }

        return min(1.0, confidence)
    }
}
