import Foundation

/// Background processor for non-critical async operations
/// Handles tasks like summarization, stats optimization, and cleanup
actor BackgroundProcessor {

    // MARK: - Types

    enum BackgroundTask: Equatable, Hashable {
        case summarizeConversation(messageCount: Int)
        case optimizeRouting
        case cleanupOldElements(olderThan: TimeInterval)
        case analyzePerformance
        case pruneHistory(maxMessages: Int)

        var priority: TaskPriority {
            switch self {
            case .summarizeConversation, .pruneHistory:
                return .medium
            case .optimizeRouting, .analyzePerformance:
                return .low
            case .cleanupOldElements:
                return .background
            }
        }

        var debounceInterval: TimeInterval {
            switch self {
            case .summarizeConversation:
                return 30.0  // Wait 30s before summarizing
            case .optimizeRouting:
                return 60.0  // Optimize every minute
            case .cleanupOldElements:
                return 300.0  // Cleanup every 5 minutes
            case .analyzePerformance:
                return 120.0  // Analyze every 2 minutes
            case .pruneHistory:
                return 60.0  // Prune every minute
            }
        }
    }

    struct TaskResult {
        let task: BackgroundTask
        let success: Bool
        let duration: TimeInterval
        let error: Error?
    }

    // MARK: - Dependencies

    private let coordinator: AgentCoordinator

    // MARK: - State

    private var runningTasks: [BackgroundTask: Task<Void, Never>] = [:]
    private var taskResults: [TaskResult] = []
    private var lastExecutionTime: [BackgroundTask: Date] = [:]

    // MARK: - Configuration

    private let maxTaskResults: Int = 50
    private let enableDebouncing: Bool = true

    // MARK: - Initialization

    init(coordinator: AgentCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Public Interface

    /// Schedule a background task with debouncing
    func scheduleTask(_ task: BackgroundTask) {
        // Check if task is already running
        if runningTasks[task] != nil {
            return
        }

        // Check debouncing
        if enableDebouncing, let lastExecution = lastExecutionTime[task] {
            let timeSinceLastExecution = Date().timeIntervalSince(lastExecution)
            if timeSinceLastExecution < task.debounceInterval {
                // Too soon, skip execution
                return
            }
        }

        // Schedule task
        let taskHandle = Task(priority: task.priority) {
            await self.executeTask(task)
        }

        runningTasks[task] = taskHandle
    }

    /// Cancel a specific background task
    func cancelTask(_ task: BackgroundTask) {
        runningTasks[task]?.cancel()
        runningTasks.removeValue(forKey: task)
    }

    /// Cancel all running tasks
    func cancelAllTasks() {
        for (_, taskHandle) in runningTasks {
            taskHandle.cancel()
        }
        runningTasks.removeAll()
    }

    /// Get task execution history
    func getTaskResults() -> [TaskResult] {
        return taskResults
    }

    /// Get running tasks count
    func getRunningTasksCount() -> Int {
        return runningTasks.count
    }

    // MARK: - Task Execution

    private func executeTask(_ task: BackgroundTask) async {
        let startTime = Date()
        var success = false
        var error: Error?

        do {
            switch task {
            case .summarizeConversation(let messageCount):
                try await performSummarization(messageCount: messageCount)
            case .optimizeRouting:
                try await performRoutingOptimization()
            case .cleanupOldElements(let olderThan):
                try await performCleanup(olderThan: olderThan)
            case .analyzePerformance:
                try await performPerformanceAnalysis()
            case .pruneHistory(let maxMessages):
                try await performHistoryPruning(maxMessages: maxMessages)
            }

            success = true
        } catch let taskError {
            error = taskError
            print("⚠️ Background task failed: \(task) - \(taskError.localizedDescription)")
        }

        // Record result
        let duration = Date().timeIntervalSince(startTime)
        let result = TaskResult(
            task: task,
            success: success,
            duration: duration,
            error: error
        )

        taskResults.append(result)
        if taskResults.count > maxTaskResults {
            taskResults.removeFirst()
        }

        // Update last execution time
        lastExecutionTime[task] = Date()

        // Remove from running tasks
        runningTasks.removeValue(forKey: task)
    }

    // MARK: - Task Implementations

    private func performSummarization(messageCount: Int) async throws {
        // Get recent conversation history
        let history = await coordinator.getConversationHistory()

        guard history.count >= messageCount else {
            return  // Not enough messages to summarize
        }

        // TODO: Implement actual summarization (could use AI)
        print("📝 Summarizing \(history.count) messages...")

        // For now, just log stats
        let stats = await coordinator.getConversationStats()
        print("   - Total messages: \(stats.totalMessages)")
        print("   - User messages: \(stats.userMessages)")
        print("   - AI messages: \(stats.aiMessages)")
    }

    private func performRoutingOptimization() async throws {
        // Get provider stats
        let stats = await coordinator.getProviderStats()

        print("🎯 Optimizing routing strategy...")

        // Analyze performance patterns
        for (provider, providerStats) in stats {
            let reliability = providerStats.successRate
            let speed = 1.0 / (1.0 + providerStats.averageResponseTime)
            let score = reliability * 0.7 + speed * 0.3

            print("   - \(provider.displayName): score=\(String(format: "%.2f", score))")
        }

        // TODO: Adjust routing weights based on analysis
    }

    private func performCleanup(olderThan: TimeInterval) async throws {
        print("🧹 Cleaning up old elements (older than \(olderThan)s)...")

        // Cleanup old element tracking
        await coordinator.clearElementsOlderThan(seconds: olderThan)

        let remainingCount = await coordinator.getActiveElementCount()
        print("   - Remaining active elements: \(remainingCount)")
    }

    private func performPerformanceAnalysis() async throws {
        print("📊 Analyzing system performance...")

        let health = await coordinator.getSystemHealth()

        print("   - Health Score: \(String(format: "%.2f", health.healthScore))")
        print("   - Conversations: \(health.conversationMessageCount)")
        print("   - Active Elements: \(health.activeElementCount)")
        print("   - Reliable Providers: \(health.reliableProviderCount)/\(health.totalProviderCount)")
        print("   - Avg Response Time: \(String(format: "%.2f", health.averageResponseTime))s")

        // Log warning if health is poor
        if health.healthScore < 0.5 {
            print("   ⚠️ WARNING: System health is low!")
        }
    }

    private func performHistoryPruning(maxMessages: Int) async throws {
        let stats = await coordinator.getConversationStats()

        guard stats.totalMessages > maxMessages else {
            return  // No pruning needed
        }

        print("✂️ Pruning conversation history...")
        print("   - Current: \(stats.totalMessages) messages")
        print("   - Target: \(maxMessages) messages")

        // Note: Actual pruning would need to be implemented in AgentCoordinator
        // For now, just log the intention
    }

    // MARK: - Automatic Background Tasks

    /// Start automatic background processing
    func startAutomaticProcessing() {
        // Schedule periodic tasks
        Task(priority: .background) {
            while !Task.isCancelled {
                // Wait 2 minutes
                try? await Task.sleep(nanoseconds: 120_000_000_000)

                // Schedule periodic tasks
                await self.scheduleTask(.analyzePerformance)
                await self.scheduleTask(.optimizeRouting)
                await self.scheduleTask(.cleanupOldElements(olderThan: 300))
            }
        }
    }

    // MARK: - Debug

    func printStatus() {
        print("=== Background Processor Status ===")
        print("Running Tasks: \(runningTasks.count)")

        if !taskResults.isEmpty {
            let successCount = taskResults.filter { $0.success }.count
            let failureCount = taskResults.count - successCount
            let avgDuration = taskResults.map { $0.duration }.reduce(0, +) / Double(taskResults.count)

            print("Task History:")
            print("  - Total: \(taskResults.count)")
            print("  - Success: \(successCount)")
            print("  - Failures: \(failureCount)")
            print("  - Avg Duration: \(String(format: "%.3f", avgDuration))s")

            // Show last 5 tasks
            print("  - Recent:")
            for result in taskResults.suffix(5) {
                let status = result.success ? "✓" : "✗"
                print("    \(status) \(result.task) (\(String(format: "%.3f", result.duration))s)")
            }
        }
        print("==================================")
    }
}

// MARK: - Task Errors

enum BackgroundTaskError: Error, LocalizedError {
    case cancelled
    case timeout
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Task was cancelled"
        case .timeout:
            return "Task timed out"
        case .insufficientData:
            return "Insufficient data to complete task"
        }
    }
}
