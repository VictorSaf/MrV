import Foundation

/// Central coordinator for shared state across the multi-agent system
/// Provides thread-safe access to conversation history, provider stats, and element tracking
actor AgentCoordinator {

    // MARK: - Shared State

    private var conversationHistory: [Message] = []
    private var providerStats: [AIProvider: ProviderStats] = [:]
    private var activeElements: [UUID: ElementInfo] = [:]

    // MARK: - Configuration

    private let maxConversationHistory: Int
    private let statsRetentionPeriod: TimeInterval

    // MARK: - Types

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

        mutating func recordSuccess(responseTime: Double) {
            successCount += 1
            lastUsed = Date()

            // Update rolling average
            let totalResponses = successCount + failureCount
            if totalResponses > 0 {
                averageResponseTime = (averageResponseTime * Double(totalResponses - 1) + responseTime) / Double(totalResponses)
            }
        }

        mutating func recordFailure() {
            failureCount += 1
        }
    }

    struct ElementInfo {
        let id: UUID
        let type: String  // FluidElement.ElementType description
        let createdAt: Date
    }

    // MARK: - Initialization

    init(maxConversationHistory: Int = 100, statsRetentionPeriod: TimeInterval = 86400) {
        self.maxConversationHistory = maxConversationHistory
        self.statsRetentionPeriod = statsRetentionPeriod
    }

    // MARK: - Conversation Management

    /// Append a message to conversation history
    func appendMessage(_ message: Message) {
        conversationHistory.append(message)

        // Trim if exceeds max size
        if conversationHistory.count > maxConversationHistory {
            let excess = conversationHistory.count - maxConversationHistory
            conversationHistory.removeFirst(excess)
        }
    }

    /// Get complete conversation history
    func getConversationHistory() -> [Message] {
        return conversationHistory
    }

    /// Get recent conversation history (last N messages)
    func getRecentHistory(count: Int) -> [Message] {
        let startIndex = max(0, conversationHistory.count - count)
        return Array(conversationHistory[startIndex...])
    }

    /// Clear all conversation history
    func clearHistory() {
        conversationHistory.removeAll()
    }

    /// Get conversation summary statistics
    func getConversationStats() -> (totalMessages: Int, userMessages: Int, aiMessages: Int) {
        let userCount = conversationHistory.filter { $0.isUser }.count
        let aiCount = conversationHistory.count - userCount
        return (conversationHistory.count, userCount, aiCount)
    }

    // MARK: - Provider Stats Management

    /// Record successful provider response
    func recordSuccess(provider: AIProvider, responseTime: TimeInterval) {
        var stats = providerStats[provider] ?? ProviderStats()
        stats.recordSuccess(responseTime: responseTime)
        providerStats[provider] = stats
    }

    /// Record provider failure
    func recordFailure(provider: AIProvider) {
        var stats = providerStats[provider] ?? ProviderStats()
        stats.recordFailure()
        providerStats[provider] = stats
    }

    /// Get all provider statistics
    func getProviderStats() -> [AIProvider: ProviderStats] {
        return providerStats
    }

    /// Get statistics for specific provider
    func getStats(for provider: AIProvider) -> ProviderStats? {
        return providerStats[provider]
    }

    /// Check if provider is reliable based on historical performance
    func isProviderReliable(_ provider: AIProvider) -> Bool {
        guard let stats = providerStats[provider] else {
            return true  // Assume reliable if no history
        }
        return stats.isReliable
    }

    /// Get best performing provider
    func getBestProvider() -> AIProvider? {
        let sortedProviders = providerStats
            .filter { $0.value.successCount > 0 }
            .sorted { first, second in
                // Sort by success rate, then by response time
                if first.value.successRate != second.value.successRate {
                    return first.value.successRate > second.value.successRate
                }
                return first.value.averageResponseTime < second.value.averageResponseTime
            }

        return sortedProviders.first?.key
    }

    /// Reset provider statistics
    func resetProviderStats() {
        providerStats.removeAll()
    }

    // MARK: - Element Tracking

    /// Register a new fluid element
    func registerElement(_ id: UUID, type: String) {
        let info = ElementInfo(id: id, type: type, createdAt: Date())
        activeElements[id] = info
    }

    /// Unregister a fluid element
    func unregisterElement(_ id: UUID) {
        activeElements.removeValue(forKey: id)
    }

    /// Get count of active elements
    func getActiveElementCount() -> Int {
        return activeElements.count
    }

    /// Get count of elements by type
    func getElementCount(ofType type: String) -> Int {
        return activeElements.values.filter { $0.type == type }.count
    }

    /// Get all active element IDs
    func getActiveElementIds() -> [UUID] {
        return Array(activeElements.keys)
    }

    /// Clear old elements (for cleanup)
    func clearElementsOlderThan(seconds: TimeInterval) {
        let cutoffDate = Date().addingTimeInterval(-seconds)
        let oldElements = activeElements.filter { $0.value.createdAt < cutoffDate }
        for (id, _) in oldElements {
            activeElements.removeValue(forKey: id)
        }
    }

    // MARK: - Batch Operations

    /// Update multiple provider stats atomically
    func batchUpdateStats(_ updates: [(AIProvider, Result<TimeInterval, Error>)]) {
        for (provider, result) in updates {
            switch result {
            case .success(let responseTime):
                recordSuccess(provider: provider, responseTime: responseTime)
            case .failure:
                recordFailure(provider: provider)
            }
        }
    }

    /// Get system health snapshot
    func getSystemHealth() -> SystemHealth {
        let conversationStats = getConversationStats()
        let reliableProviders = AIProvider.allCases.filter { isProviderReliable($0) }.count
        let totalProviders = AIProvider.allCases.count

        return SystemHealth(
            conversationMessageCount: conversationStats.totalMessages,
            activeElementCount: activeElements.count,
            reliableProviderCount: reliableProviders,
            totalProviderCount: totalProviders,
            averageResponseTime: calculateAverageResponseTime()
        )
    }

    struct SystemHealth {
        let conversationMessageCount: Int
        let activeElementCount: Int
        let reliableProviderCount: Int
        let totalProviderCount: Int
        let averageResponseTime: Double

        var healthScore: Double {
            let conversationHealth = min(1.0, Double(conversationMessageCount) / 50.0)
            let elementHealth = activeElementCount < 50 ? 1.0 : 0.5
            let providerHealth = Double(reliableProviderCount) / Double(totalProviderCount)
            let responseHealth = averageResponseTime < 3.0 ? 1.0 : (averageResponseTime < 5.0 ? 0.7 : 0.4)

            return (conversationHealth + elementHealth + providerHealth + responseHealth) / 4.0
        }
    }

    // MARK: - Private Helpers

    private func calculateAverageResponseTime() -> Double {
        let times = providerStats.values.map { $0.averageResponseTime }.filter { $0 > 0 }
        guard !times.isEmpty else { return 0 }
        return times.reduce(0, +) / Double(times.count)
    }

    // MARK: - Debug

    func printState() {
        print("=== Agent Coordinator State ===")
        print("Conversation: \(conversationHistory.count) messages")
        print("Active Elements: \(activeElements.count)")
        print("Provider Stats:")
        for (provider, stats) in providerStats {
            print("  \(provider.displayName): \(stats.successCount)/\(stats.failureCount) (\(String(format: "%.1f", stats.successRate * 100))%)")
        }
        print("==============================")
    }
}

