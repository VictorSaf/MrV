import Foundation

/// Intelligent routing system for selecting optimal AI model
/// Analyzes intent and context to choose the best provider
@MainActor
final class IntelligentModelRouter: ObservableObject {

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
    }

    // MARK: - Provider Performance Tracking

    struct ProviderStats {
        var successCount: Int = 0
        var failureCount: Int = 0
        var averageResponseTime: Double = 0
        var lastUsed: Date?

        var successRate: Double {
            let total = successCount + failureCount
            return total > 0 ? Double(successCount) / Double(total) : 1.0
        }

        var isReliable: Bool {
            successRate > 0.8 && (successCount + failureCount) > 5
        }
    }

    @Published private(set) var providerStats: [AIProvider: ProviderStats] = [:]

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
    func selectOptimalModel(for input: String, currentProvider: AIProvider? = nil) -> AIProvider {
        let intent = analyzeIntent(input)

        // Get recommended provider
        let recommended = intent.recommendedProvider

        // Check if recommended provider is available
        if isProviderAvailable(recommended) {
            return recommended
        }

        // Try fallbacks
        for fallback in intent.fallbackProviders {
            if isProviderAvailable(fallback) {
                return fallback
            }
        }

        // Last resort: use current provider if available
        if let current = currentProvider, isProviderAvailable(current) {
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

    private func isProviderAvailable(_ provider: AIProvider) -> Bool {
        // Check if provider is configured
        let service = AIServiceFactory.createService(for: provider)
        guard service.isConfigured else {
            return false
        }

        // Check historical reliability
        if let stats = providerStats[provider] {
            return stats.isReliable || stats.successCount + stats.failureCount < 5
        }

        return true
    }

    // MARK: - Performance Tracking

    func recordSuccess(for provider: AIProvider, responseTime: Double) {
        var stats = providerStats[provider] ?? ProviderStats()
        stats.successCount += 1
        stats.lastUsed = Date()

        // Update rolling average
        let totalResponses = stats.successCount + stats.failureCount
        stats.averageResponseTime = (stats.averageResponseTime * Double(totalResponses - 1) + responseTime) / Double(totalResponses)

        providerStats[provider] = stats
    }

    func recordFailure(for provider: AIProvider) {
        var stats = providerStats[provider] ?? ProviderStats()
        stats.failureCount += 1
        providerStats[provider] = stats
    }

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

    func printStats() {
        print("=== Model Router Stats ===")
        for (provider, stats) in providerStats {
            print("\(provider.displayName):")
            print("  Success: \(stats.successCount), Failures: \(stats.failureCount)")
            print("  Success Rate: \(String(format: "%.1f", stats.successRate * 100))%")
            print("  Avg Response: \(String(format: "%.2f", stats.averageResponseTime))s")
            if let lastUsed = stats.lastUsed {
                print("  Last Used: \(lastUsed)")
            }
        }
        print("=========================")
    }
}
