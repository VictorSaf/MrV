import Foundation

/// Intelligent routing system for selecting optimal AI model
/// Analyzes intent and context to choose the best provider
@MainActor
final class IntelligentModelRouter {

    // MARK: - Dependencies

    private let coordinator: AgentCoordinator

    // MARK: - Initialization

    init(coordinator: AgentCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Task Intent

    enum TaskIntent {
        case conversation      // General chat
        case coding           // Code generation/review
        case research         // Information lookup, current events
        case creative         // Creative writing, ideation
        case analysis         // Data analysis, reasoning
        case technical        // Technical documentation, explanations
        case quickResponse    // Simple questions, confirmations

        var recommendedProvider: AIProvider {
            switch self {
            case .conversation:
                return .claude       // Best for natural conversation
            case .coding:
                return .openAI       // GPT-4 excels at code
            case .research:
                return .perplexity   // Real-time web access
            case .creative:
                return .claude       // Creative and nuanced
            case .analysis:
                return .claude       // Strong reasoning
            case .technical:
                return .openAI       // Technical accuracy
            case .quickResponse:
                return .ollama       // Fast local responses
            }
        }

        var fallbackProviders: [AIProvider] {
            switch self {
            case .conversation:
                return [.openAI, .ollama, .perplexity]
            case .coding:
                return [.claude, .ollama, .perplexity]
            case .research:
                return [.openAI, .claude, .ollama]
            case .creative:
                return [.openAI, .perplexity, .ollama]
            case .analysis:
                return [.openAI, .perplexity, .ollama]
            case .technical:
                return [.claude, .perplexity, .ollama]
            case .quickResponse:
                return [.claude, .openAI, .perplexity]
            }
        }

        var description: String {
            switch self {
            case .conversation: return "conversation"
            case .coding: return "coding"
            case .research: return "research"
            case .creative: return "creative"
            case .analysis: return "analysis"
            case .technical: return "technical"
            case .quickResponse: return "quick_response"
            }
        }
    }

    // MARK: - Provider Performance Tracking
    // Note: Stats are now managed by AgentCoordinator

    // MARK: - Intent Analysis

    /// Analyze user input to determine intent
    func analyzeIntent(_ input: String) -> TaskIntent {
        let lowercased = input.lowercased()

        // Quick response patterns
        if isQuickResponse(lowercased) {
            return .quickResponse
        }

        // Research patterns
        if containsResearchKeywords(lowercased) {
            return .research
        }

        // Coding patterns
        if containsCodingKeywords(lowercased) {
            return .coding
        }

        // Creative patterns
        if containsCreativeKeywords(lowercased) {
            return .creative
        }

        // Analysis patterns
        if containsAnalysisKeywords(lowercased) {
            return .analysis
        }

        // Technical patterns
        if containsTechnicalKeywords(lowercased) {
            return .technical
        }

        // Default to conversation
        return .conversation
    }

    // MARK: - Model Selection

    /// Select optimal model based on intent and availability
    func selectOptimalModel(for input: String, currentProvider: AIProvider? = nil) async -> AIProvider {
        let intent = analyzeIntent(input)

        // Get stats from coordinator
        let stats = await coordinator.getProviderStats()

        // Get recommended provider
        let recommended = intent.recommendedProvider

        // Check if recommended provider is available
        if isProviderAvailable(recommended, stats: stats) {
            return recommended
        }

        // Try fallbacks
        for fallback in intent.fallbackProviders {
            if isProviderAvailable(fallback, stats: stats) {
                return fallback
            }
        }

        // Last resort: use current provider if available
        if let current = currentProvider, isProviderAvailable(current, stats: stats) {
            return current
        }

        // Absolute fallback: Claude (most versatile)
        return .claude
    }

    /// Select multiple models for complex tasks (future enhancement)
    func routeMultiModel(intent: TaskIntent) -> [AIProvider] {
        // For now, just return primary and one fallback
        let primary = intent.recommendedProvider
        if let fallback = intent.fallbackProviders.first {
            return [primary, fallback]
        }
        return [primary]
    }

    // MARK: - Availability Check

    private func isProviderAvailable(_ provider: AIProvider, stats: [AIProvider: AgentCoordinator.ProviderStats]) -> Bool {
        // Check if provider is configured
        let service = AIServiceFactory.createService(for: provider)
        guard service.isConfigured else {
            return false
        }

        // Check historical reliability
        if let providerStats = stats[provider] {
            return providerStats.isReliable || providerStats.successCount + providerStats.failureCount < 5
        }

        return true
    }

    // MARK: - Performance Tracking
    // Note: Recording is now handled by AgentCoordinator

    // MARK: - Intent Detection Helpers

    private func isQuickResponse(_ text: String) -> Bool {
        let quickPatterns = ["yes", "no", "ok", "sure", "thanks", "hello", "hi", "bye"]
        return quickPatterns.contains { text.contains($0) } && text.split(separator: " ").count < 5
    }

    private func containsResearchKeywords(_ text: String) -> Bool {
        let keywords = ["search", "find", "look up", "what is", "who is", "when did", "latest", "current", "news", "recent"]
        return keywords.contains { text.contains($0) }
    }

    private func containsCodingKeywords(_ text: String) -> Bool {
        let keywords = ["code", "function", "class", "bug", "debug", "implement", "algorithm", "program", "script", "refactor"]
        return keywords.contains { text.contains($0) }
    }

    private func containsCreativeKeywords(_ text: String) -> Bool {
        let keywords = ["write", "story", "poem", "creative", "imagine", "brainstorm", "idea", "design"]
        return keywords.contains { text.contains($0) }
    }

    private func containsAnalysisKeywords(_ text: String) -> Bool {
        let keywords = ["analyze", "compare", "evaluate", "assess", "examine", "review", "critique"]
        return keywords.contains { text.contains($0) }
    }

    private func containsTechnicalKeywords(_ text: String) -> Bool {
        let keywords = ["explain", "how does", "why does", "technical", "documentation", "specification"]
        return keywords.contains { text.contains($0) }
    }

    // MARK: - Debug

    func printStats() async {
        let stats = await coordinator.getProviderStats()
        print("=== Model Router Stats ===")
        for (provider, providerStats) in stats {
            print("\(provider.displayName):")
            print("  Success: \(providerStats.successCount), Failures: \(providerStats.failureCount)")
            print("  Success Rate: \(String(format: "%.1f", providerStats.successRate * 100))%")
            print("  Avg Response: \(String(format: "%.2f", providerStats.averageResponseTime))s")
            if let lastUsed = providerStats.lastUsed {
                print("  Last Used: \(lastUsed)")
            }
        }
        print("=========================")
    }
}
