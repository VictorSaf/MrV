import Foundation

/// Orchestrates parallel queries to multiple AI providers
/// Uses racing and fallback strategies for optimal response time
actor ParallelAIOrchestrator {

    // MARK: - Types

    /// Result of a parallel query
    struct QueryResult {
        let provider: AIProvider
        let stream: AsyncThrowingStream<String, Error>
        let startTime: Date
    }

    /// Strategy for parallel queries
    enum QueryStrategy {
        case race           // Query all, use first successful
        case fastest        // Query all, use fastest based on history
        case fallback       // Try primary, fall back to others on failure
        case redundant      // Query multiple, merge responses
    }

    // MARK: - Dependencies

    private let coordinator: AgentCoordinator

    // MARK: - Configuration

    private let defaultTimeout: TimeInterval = 30.0
    private let maxConcurrentQueries: Int = 3

    // MARK: - Initialization

    init(coordinator: AgentCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Public Interface

    /// Query multiple providers in parallel with racing strategy
    /// Returns the first successful response
    func queryParallel(
        input: String,
        intent: IntelligentModelRouter.TaskIntent,
        conversationHistory: [Message],
        strategy: QueryStrategy = .race
    ) async throws -> QueryResult {
        switch strategy {
        case .race:
            return try await queryRace(
                providers: selectProvidersForIntent(intent),
                input: input,
                conversationHistory: conversationHistory
            )
        case .fastest:
            return try await queryFastest(
                providers: selectProvidersForIntent(intent),
                input: input,
                conversationHistory: conversationHistory
            )
        case .fallback:
            return try await queryWithFallback(
                providers: selectProvidersForIntent(intent),
                input: input,
                conversationHistory: conversationHistory
            )
        case .redundant:
            return try await queryRedundant(
                providers: selectProvidersForIntent(intent),
                input: input,
                conversationHistory: conversationHistory
            )
        }
    }

    /// Query specific providers and race them
    func queryRace(
        providers: [AIProvider],
        input: String,
        conversationHistory: [Message]
    ) async throws -> QueryResult {
        // Limit concurrent queries
        let providersToQuery = Array(providers.prefix(maxConcurrentQueries))

        guard !providersToQuery.isEmpty else {
            throw OrchestratorError.noProvidersAvailable
        }

        return try await withThrowingTaskGroup(of: QueryResult?.self) { group in
            // Launch parallel queries
            for provider in providersToQuery {
                group.addTask {
                    await self.queryProvider(
                        provider: provider,
                        input: input,
                        conversationHistory: conversationHistory
                    )
                }
            }

            // Return first successful result
            var lastError: Error?
            for try await result in group {
                if let result = result {
                    // Cancel remaining tasks
                    group.cancelAll()
                    return result
                }
            }

            // All queries failed
            throw lastError ?? OrchestratorError.allProvidersFailed
        }
    }

    /// Query providers in order of historical performance
    func queryFastest(
        providers: [AIProvider],
        input: String,
        conversationHistory: [Message]
    ) async throws -> QueryResult {
        // Get stats and sort by performance
        let stats = await coordinator.getProviderStats()
        let sortedProviders = providers.sorted { first, second in
            guard let firstStats = stats[first],
                  let secondStats = stats[second] else {
                return true
            }
            return firstStats.averageResponseTime < secondStats.averageResponseTime
        }

        // Query in order
        return try await queryWithFallback(
            providers: sortedProviders,
            input: input,
            conversationHistory: conversationHistory
        )
    }

    /// Query with fallback strategy (sequential with fast failure)
    func queryWithFallback(
        providers: [AIProvider],
        input: String,
        conversationHistory: [Message]
    ) async throws -> QueryResult {
        var lastError: Error?

        for provider in providers {
            if let result = await queryProvider(
                provider: provider,
                input: input,
                conversationHistory: conversationHistory
            ) {
                return result
            }
        }

        throw lastError ?? OrchestratorError.allProvidersFailed
    }

    /// Query multiple providers and merge responses (experimental)
    func queryRedundant(
        providers: [AIProvider],
        input: String,
        conversationHistory: [Message]
    ) async throws -> QueryResult {
        // For now, just use race strategy
        // Future: implement response merging/voting
        return try await queryRace(
            providers: providers,
            input: input,
            conversationHistory: conversationHistory
        )
    }

    // MARK: - Private Helpers

    /// Query a single provider with timeout
    private func queryProvider(
        provider: AIProvider,
        input: String,
        conversationHistory: [Message]
    ) async -> QueryResult? {
        let service = AIServiceFactory.createService(for: provider)

        guard service.isConfigured else {
            return nil
        }

        do {
            let startTime = Date()
            let stream = try await withTimeout(defaultTimeout) {
                try await service.sendMessage(input, conversationHistory: conversationHistory)
            }

            return QueryResult(
                provider: provider,
                stream: stream,
                startTime: startTime
            )
        } catch {
            // Record failure
            await coordinator.recordFailure(provider: provider)
            return nil
        }
    }

    /// Select providers based on intent
    private func selectProvidersForIntent(_ intent: IntelligentModelRouter.TaskIntent) -> [AIProvider] {
        let primary = intent.recommendedProvider
        let fallbacks = intent.fallbackProviders

        // Return primary + top 2 fallbacks
        return [primary] + Array(fallbacks.prefix(2))
    }

    /// Execute async operation with timeout
    private func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add main operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw OrchestratorError.timeout
            }

            // Return first result (either completion or timeout)
            guard let result = try await group.next() else {
                throw OrchestratorError.timeout
            }

            // Cancel remaining task
            group.cancelAll()
            return result
        }
    }

    // MARK: - Performance Monitoring

    /// Get performance metrics for providers
    func getPerformanceMetrics() async -> [AIProvider: PerformanceMetric] {
        let stats = await coordinator.getProviderStats()
        var metrics: [AIProvider: PerformanceMetric] = [:]

        for (provider, providerStats) in stats {
            metrics[provider] = PerformanceMetric(
                provider: provider,
                averageResponseTime: providerStats.averageResponseTime,
                successRate: providerStats.successRate,
                totalQueries: providerStats.successCount + providerStats.failureCount
            )
        }

        return metrics
    }

    struct PerformanceMetric {
        let provider: AIProvider
        let averageResponseTime: TimeInterval
        let successRate: Double
        let totalQueries: Int

        var score: Double {
            // Higher is better: weight success rate more than speed
            return successRate * 0.7 + (1.0 / (1.0 + averageResponseTime)) * 0.3
        }
    }

    // MARK: - Errors

    enum OrchestratorError: Error, LocalizedError {
        case noProvidersAvailable
        case allProvidersFailed
        case timeout
        case cancelled

        var errorDescription: String? {
            switch self {
            case .noProvidersAvailable:
                return "No AI providers are available"
            case .allProvidersFailed:
                return "All AI providers failed to respond"
            case .timeout:
                return "Query timed out"
            case .cancelled:
                return "Query was cancelled"
            }
        }
    }

    // MARK: - Debug

    func printPerformanceMetrics() async {
        let metrics = await getPerformanceMetrics()
        print("=== Parallel Orchestrator Performance ===")
        for (provider, metric) in metrics.sorted(by: { $0.value.score > $1.value.score }) {
            print("\(provider.displayName):")
            print("  Score: \(String(format: "%.2f", metric.score))")
            print("  Avg Time: \(String(format: "%.2f", metric.averageResponseTime))s")
            print("  Success Rate: \(String(format: "%.1f", metric.successRate * 100))%")
            print("  Total Queries: \(metric.totalQueries)")
        }
        print("========================================")
    }
}
