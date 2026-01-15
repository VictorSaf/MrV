import Foundation
import SwiftUI
import Combine

/// Mr.V Consciousness - The living intelligence behind the void
/// Integrates AI models with the Fluid Reality system
@MainActor
final class MrVConsciousness: ObservableObject {

    // MARK: - Published State

    @Published var state: ConsciousnessState = .dormant
    @Published var selectedProvider: AIProvider = .claude
    @Published var currentResponse: String = ""
    @Published var errorMessage: String?
    @Published var autoRouting: Bool = true  // Enable intelligent routing

    // MARK: - Dependencies

    private weak var fluidReality: FluidRealityEngine?
    private let coordinator = AgentCoordinator()
    private lazy var modelRouter: IntelligentModelRouter = {
        IntelligentModelRouter(coordinator: coordinator)
    }()
    private lazy var parallelOrchestrator: ParallelAIOrchestrator = {
        ParallelAIOrchestrator(coordinator: coordinator)
    }()
    private lazy var backgroundProcessor: BackgroundProcessor = {
        BackgroundProcessor(coordinator: coordinator)
    }()
    private lazy var memorySystem: MemorySystem = {
        MemorySystem()
    }()

    // MARK: - Memory State

    @Published var currentProjectName: String?
    @Published var isMemoryInitialized = false

    // MARK: - Consciousness State

    enum ConsciousnessState: Equatable {
        case dormant        // Waiting for input
        case processing     // Analyzing input
        case responding     // Generating response
        case error(String)  // Error state

        var isActive: Bool {
            switch self {
            case .processing, .responding:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Initialization

    init(fluidReality: FluidRealityEngine? = nil) {
        self.fluidReality = fluidReality
    }

    func setFluidReality(_ engine: FluidRealityEngine) {
        self.fluidReality = engine

        // Initialize memory system
        Task {
            do {
                try await memorySystem.initialize()
                isMemoryInitialized = true
                currentProjectName = memorySystem.currentProject?.name
                print("✅ Memory system initialized in MrVConsciousness")
            } catch {
                print("❌ Failed to initialize memory: \(error)")
            }
        }
    }

    // MARK: - AI Service

    private var currentService: AIService {
        AIServiceFactory.createService(for: selectedProvider)
    }

    var isServiceConfigured: Bool {
        currentService.isConfigured
    }

    // MARK: - Input Processing

    /// Process user input and generate response
    func processInput(_ input: String) async {
        guard !input.isEmpty else { return }

        // Intelligent model routing (if enabled)
        if autoRouting {
            let optimalProvider = await modelRouter.selectOptimalModel(for: input, currentProvider: selectedProvider)
            if optimalProvider != selectedProvider {
                print("🧠 Auto-routing: \(selectedProvider.displayName) → \(optimalProvider.displayName)")
                selectedProvider = optimalProvider
            }
        }

        // Detect and transition mood based on input
        fluidReality?.moodManager.detectAndTransition(from: input)

        // Check if service is configured
        guard currentService.isConfigured else {
            await handleError("Please configure \(selectedProvider.displayName) in Settings first.")
            return
        }

        // Change state to processing
        state = .processing

        // Add user message to history (through coordinator)
        let userMessage = Message.user(input)
        await coordinator.appendMessage(userMessage)

        // Create user input fluid element (already done by InvisibleInput)
        // Now create response element

        guard let fluidReality = fluidReality else {
            await handleError("Fluid Reality Engine not initialized")
            return
        }

        // Calculate position for response
        let responsePosition = calculateResponsePosition(viewSize: CGSize(width: 1280, height: 800))

        // Create empty response element
        let responseId = UUID()
        let responseElement = FluidElement(
            id: responseId,
            type: .text(""),
            position: responsePosition,
            content: .text(""),
            style: FluidElement.ElementStyle(
                font: .system(size: 16, weight: .light),
                foregroundColor: providerColor(for: selectedProvider),
                glowIntensity: 0.2
            )
        )

        // Materialize empty element
        fluidReality.materializeElement(responseElement)

        // Change state to responding
        state = .responding
        currentResponse = ""

        // Query AI using parallel orchestrator
        let startTime = Date()
        do {
            // Get conversation history from coordinator
            let history = await coordinator.getConversationHistory()
            let intent = modelRouter.analyzeIntent(input)

            // Get relevant context from memory system (if initialized)
            var contextualPrompt = input
            if isMemoryInitialized {
                do {
                    // Get recent conversations for context
                    let relevantContext = try await memorySystem.getRelevantContext(for: input, limit: 5)

                    // Search knowledge graph for mentioned concepts
                    let knowledge = try await memorySystem.searchKnowledge(input, limit: 5)

                    // Build enhanced prompt with context
                    if !relevantContext.isEmpty || !knowledge.isEmpty {
                        var contextParts: [String] = []

                        if !relevantContext.isEmpty {
                            let recentSummary = relevantContext.map { conv in
                                "Q: \(conv.userInput.prefix(100))\nA: \(conv.aiResponse.prefix(100))"
                            }.joined(separator: "\n\n")
                            contextParts.append("Recent context:\n\(recentSummary)")
                        }

                        if !knowledge.isEmpty {
                            let knowledgeSummary = knowledge.map { node in
                                "\(node.type.icon) \(node.name): \(node.content.description ?? "")"
                            }.joined(separator: "\n")
                            contextParts.append("Relevant knowledge:\n\(knowledgeSummary)")
                        }

                        if let projectName = currentProjectName {
                            contextParts.insert("Current project: \(projectName)", at: 0)
                        }

                        contextualPrompt = contextParts.joined(separator: "\n\n") + "\n\nUser question: \(input)"
                        print("🧠 Enhanced prompt with \(relevantContext.count) context items + \(knowledge.count) knowledge nodes")
                    }
                } catch {
                    print("⚠️ Failed to retrieve context: \(error)")
                    // Continue with original input if context retrieval fails
                }
            }

            // Use parallel orchestrator for multi-provider queries (with contextual prompt)
            let result = try await parallelOrchestrator.queryParallel(
                input: contextualPrompt,  // Use enhanced prompt
                intent: intent,
                conversationHistory: history,
                strategy: .race  // Race multiple providers
            )

            // Update selected provider with winner
            selectedProvider = result.provider
            print("🏁 Query won by: \(result.provider.displayName)")

            // Stream response
            for try await chunk in result.stream {
                currentResponse += chunk

                // Update element with streaming text and crystallization
                fluidReality.updateElementTextStreaming(
                    responseId,
                    newText: currentResponse,
                    config: .fast  // Fast crystallization for AI responses
                )
            }

            // Record success (through coordinator)
            let responseTime = Date().timeIntervalSince(startTime)
            await coordinator.recordSuccess(provider: selectedProvider, responseTime: responseTime)

            // Add to conversation history (through coordinator)
            let assistantMessage = Message(
                id: UUID(),
                content: currentResponse,
                isUser: false,
                isStreaming: false
            )
            await coordinator.appendMessage(assistantMessage)

            // Store conversation in memory system
            if isMemoryInitialized {
                Task {
                    do {
                        let mood = fluidReality.moodManager.currentMood.rawValue
                        try await memorySystem.storeConversation(
                            userInput: input,  // Store original input, not contextual prompt
                            aiResponse: currentResponse,
                            modelUsed: selectedProvider,
                            responseTime: responseTime,
                            mood: mood,
                            intent: intent.description
                        )

                        // Extract knowledge from conversation
                        try await memorySystem.extractKnowledgeFromLastConversation()

                        print("💾 Conversation stored in memory")
                    } catch {
                        print("❌ Failed to store conversation: \(error)")
                    }
                }
            }

            // Schedule background tasks
            Task {
                await backgroundProcessor.scheduleTask(.analyzePerformance)
                await backgroundProcessor.scheduleTask(.optimizeRouting)

                // Summarize if enough messages
                let stats = await coordinator.getConversationStats()
                if stats.totalMessages >= 10 {
                    await backgroundProcessor.scheduleTask(.summarizeConversation(messageCount: stats.totalMessages))
                }
            }

            // Return to dormant state
            state = .dormant
            currentResponse = ""

        } catch {
            // Record failure (through coordinator)
            await coordinator.recordFailure(provider: selectedProvider)

            await handleError(error.localizedDescription)

            // Remove the empty response element
            fluidReality.removeElement(responseId)
        }
    }

    // MARK: - Position Calculation

    private func calculateResponsePosition(viewSize: CGSize) -> FluidElement.FluidPosition {
        guard let fluidReality = fluidReality else {
            return FluidElement.FluidPosition(
                x: viewSize.width * 0.15,
                y: viewSize.height * 0.5,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        }

        // Get existing text elements
        let existingTextElements = fluidReality.activeElements.filter { $0.type.isText }

        // Calculate position below last element
        if let lastElement = existingTextElements.last {
            return FluidElement.FluidPosition(
                x: lastElement.position.x,
                y: lastElement.position.y + 40,  // 40px below
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        } else {
            // First element - start at top-left
            return FluidElement.FluidPosition(
                x: viewSize.width * 0.15,
                y: viewSize.height * 0.2,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        }
    }

    // MARK: - Provider Styling

    private func providerColor(for provider: AIProvider) -> Color {
        switch provider {
        case .claude:
            return Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.9)  // Warm orange
        case .openAI:
            return Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.9)  // Mint green
        case .perplexity:
            return Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.9)  // Purple
        case .ollama:
            return Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.9)  // Blue
        }
    }

    // MARK: - Error Handling

    private func handleError(_ message: String) async {
        errorMessage = message
        state = .error(message)

        // Create error fluid element
        if let fluidReality = fluidReality {
            let errorPosition = FluidElement.FluidPosition(
                x: 200,
                y: 100,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )

            let errorElement = FluidElement(
                type: .text("Error: \(message)"),
                position: errorPosition,
                content: .text("⚠️ \(message)"),
                style: FluidElement.ElementStyle(
                    font: Font.system(size: 14, weight: .medium),
                    foregroundColor: Color.red.opacity(0.8),
                    glowIntensity: 0.3
                )
            )

            fluidReality.materializeElementWithCrystallization(errorElement)

            // Auto-dissolve error after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                fluidReality.dissolveElement(errorElement.id)
            }
        }

        // Clear error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.errorMessage = nil
            self.state = .dormant
        }
    }

    // MARK: - Conversation Management

    func clearConversation() {
        Task {
            await coordinator.clearHistory()
        }

        // Dissolve all text elements
        if let fluidReality = fluidReality {
            let textElements = fluidReality.activeElements.filter { $0.type.isText }
            for element in textElements {
                fluidReality.dissolveElement(element.id)
            }
        }
    }

    func changeProvider(to provider: AIProvider) {
        selectedProvider = provider
    }

    // MARK: - Memory Management

    /// Get memory system access
    func getMemorySystem() -> MemorySystem {
        return memorySystem
    }

    /// Create new project
    func createProject(name: String, description: String? = nil) async throws {
        let project = try await memorySystem.createProject(name: name, description: description)
        currentProjectName = project.name
        print("📁 Project created: \(name)")
    }

    /// Switch to different project
    func switchProject(_ projectId: String) async throws {
        try await memorySystem.switchProject(projectId)
        currentProjectName = memorySystem.currentProject?.name
        print("🔄 Switched to project: \(currentProjectName ?? "Unknown")")
    }

    /// Get all projects
    func getProjects() async -> [ProjectMemory] {
        return memorySystem.projects
    }

    /// Search conversations
    func searchConversations(keywords: [String]) async throws -> [ConversationMemory] {
        return try await memorySystem.searchConversations(keywords: keywords)
    }

    // MARK: - Intent Analysis (Future Enhancement)

    private func analyzeIntent(_ input: String) -> Intent {
        // TODO: Implement intent analysis in Phase 3
        // For now, assume general conversation
        return .conversation
    }

    enum Intent {
        case conversation
        case coding
        case research
        case creative
        case analysis

        var description: String {
            switch self {
            case .conversation: return "conversation"
            case .coding: return "coding"
            case .research: return "research"
            case .creative: return "creative"
            case .analysis: return "analysis"
            }
        }
    }
}
