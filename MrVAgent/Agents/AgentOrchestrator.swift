import Foundation

/// Agent Orchestrator - Coordinates multiple agents working in parallel
/// Manages task distribution, execution monitoring, and result aggregation
@MainActor
final class AgentOrchestrator: ObservableObject {

    // MARK: - Published State

    @Published var activeTasks: [UUID: OrchestrationTask] = [:]
    @Published var completedTasks: [UUID: AgentResult] = [:]
    @Published var totalTasksOrchestrated: Int = 0

    // MARK: - Dependencies

    private let agentFactory: AgentFactory

    // MARK: - Configuration

    private let maxConcurrentTasks: Int = 10
    private let taskTimeoutDefault: TimeInterval = 300.0  // 5 minutes

    // MARK: - Initialization

    init(agentFactory: AgentFactory) {
        self.agentFactory = agentFactory
    }

    // MARK: - Orchestration Task

    struct OrchestrationTask: Identifiable {
        let id: UUID
        var agentTask: AgentTask
        var assignedAgentId: UUID?
        var status: TaskStatus
        var startTime: Date?
        var endTime: Date?
        var retryCount: Int
        var maxRetries: Int

        enum TaskStatus {
            case queued
            case assigned
            case executing
            case completed(AgentResult)
            case failed(Error)
            case timeout
            case cancelled

            var isActive: Bool {
                switch self {
                case .queued, .assigned, .executing:
                    return true
                default:
                    return false
                }
            }
        }

        init(agentTask: AgentTask, maxRetries: Int = 3) {
            self.id = agentTask.id
            self.agentTask = agentTask
            self.status = .queued
            self.retryCount = 0
            self.maxRetries = maxRetries
        }
    }

    // MARK: - Single Task Execution

    /// Execute a single task through an agent
    func execute(task: AgentTask) async throws -> AgentResult {
        print("🎯 Orchestrating task: \(task.input.prefix(50))...")

        // Create orchestration task
        var orchTask = OrchestrationTask(agentTask: task)
        activeTasks[orchTask.id] = orchTask

        do {
            // Execute through factory
            orchTask.status = .executing
            orchTask.startTime = Date()
            activeTasks[orchTask.id] = orchTask

            let result = try await agentFactory.executeTask(task)

            // Update status
            orchTask.status = .completed(result)
            orchTask.endTime = Date()
            activeTasks[orchTask.id] = orchTask

            // Move to completed
            completedTasks[orchTask.id] = result
            activeTasks.removeValue(forKey: orchTask.id)
            totalTasksOrchestrated += 1

            return result

        } catch {
            orchTask.status = .failed(error)
            orchTask.endTime = Date()
            activeTasks[orchTask.id] = orchTask

            // Retry if configured
            if orchTask.retryCount < orchTask.maxRetries {
                print("⚠️ Task failed, retrying (\(orchTask.retryCount + 1)/\(orchTask.maxRetries))...")
                orchTask.retryCount += 1
                orchTask.status = .queued
                activeTasks[orchTask.id] = orchTask

                // Recursive retry
                return try await execute(task: task)
            }

            throw error
        }
    }

    // MARK: - Parallel Execution

    /// Execute multiple tasks in parallel
    func executeParallel(tasks: [AgentTask], strategy: ExecutionStrategy = .parallel) async throws -> [AgentResult] {
        print("🎯 Orchestrating \(tasks.count) tasks in parallel...")

        switch strategy {
        case .parallel:
            return try await executeAllParallel(tasks: tasks)
        case .sequential:
            return try await executeSequential(tasks: tasks)
        case .raceFirst:
            return try await executeRaceFirst(tasks: tasks)
        case .priorityBased:
            return try await executePriorityBased(tasks: tasks)
        }
    }

    /// Execute all tasks in parallel (wait for all)
    private func executeAllParallel(tasks: [AgentTask]) async throws -> [AgentResult] {
        try await withThrowingTaskGroup(of: (UUID, AgentResult).self) { group in
            // Add all tasks
            for task in tasks {
                group.addTask {
                    let result = try await self.execute(task: task)
                    return (task.id, result)
                }
            }

            // Collect results
            var results: [UUID: AgentResult] = [:]
            for try await (taskId, result) in group {
                results[taskId] = result
            }

            // Return in original order
            return tasks.compactMap { results[$0.id] }
        }
    }

    /// Execute tasks sequentially (one after another)
    private func executeSequential(tasks: [AgentTask]) async throws -> [AgentResult] {
        var results: [AgentResult] = []

        for task in tasks {
            let result = try await execute(task: task)
            results.append(result)
        }

        return results
    }

    /// Race multiple tasks, return first to complete
    private func executeRaceFirst(tasks: [AgentTask]) async throws -> [AgentResult] {
        guard !tasks.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: AgentResult.self) { group in
            // Add all tasks
            for task in tasks {
                group.addTask {
                    try await self.execute(task: task)
                }
            }

            // Wait for first to complete
            if let firstResult = try await group.next() {
                // Cancel remaining tasks
                group.cancelAll()

                // Cancel in factory
                await agentFactory.cancelAll()

                return [firstResult]
            }

            return []
        }
    }

    /// Execute tasks based on priority (high priority first)
    private func executePriorityBased(tasks: [AgentTask]) async throws -> [AgentResult] {
        // Sort by priority
        let sorted = tasks.sorted { $0.priority > $1.priority }

        // Execute in priority order with some parallelism
        var results: [AgentResult] = []
        var currentPriority = sorted.first?.priority

        var batch: [AgentTask] = []

        for task in sorted {
            // If priority changed and we have batched tasks, execute batch
            if task.priority != currentPriority && !batch.isEmpty {
                let batchResults = try await executeAllParallel(tasks: batch)
                results.append(contentsOf: batchResults)
                batch = []
            }

            batch.append(task)
            currentPriority = task.priority
        }

        // Execute final batch
        if !batch.isEmpty {
            let batchResults = try await executeAllParallel(tasks: batch)
            results.append(contentsOf: batchResults)
        }

        return results
    }

    // MARK: - Complex Workflows

    /// Execute a workflow where tasks depend on previous results
    func executeWorkflow(workflow: Workflow) async throws -> [AgentResult] {
        print("🎯 Orchestrating workflow: \(workflow.name)")

        var results: [UUID: AgentResult] = [:]
        var completedStages: Set<UUID> = []

        // Execute stages in order
        for stage in workflow.stages {
            // Wait for dependencies
            for depId in stage.dependencies {
                guard completedStages.contains(depId) else {
                    throw OrchestrationError.dependencyNotMet(stageId: stage.id, dependencyId: depId)
                }
            }

            // Build task with context from previous results
            var task = stage.task

            // Inject previous results as context
            if !stage.dependencies.isEmpty {
                let previousResults = stage.dependencies.compactMap { results[$0]?.output }
                task.context = AgentTask.TaskContext(
                    projectId: task.context?.projectId,
                    conversationHistory: task.context?.conversationHistory,
                    knowledgeNodes: task.context?.knowledgeNodes,
                    previousResults: previousResults,
                    userPreferences: task.context?.userPreferences
                )
            }

            // Execute stage
            let result = try await execute(task: task)
            results[stage.id] = result
            completedStages.insert(stage.id)

            print("✅ Stage '\(stage.name)' completed")
        }

        // Return results in stage order
        return workflow.stages.compactMap { results[$0.id] }
    }

    // MARK: - Monitoring

    /// Get active tasks count
    func getActiveCost() -> Int {
        return activeTasks.values.filter { $0.status.isActive }.count
    }

    /// Check if orchestrator is busy
    var isBusy: Bool {
        return getActiveTaskCount() > 0
    }

    /// Get current task statistics
    func getStatistics() -> OrchestrationStatistics {
        let activeCount = activeTasks.count
        let completedCount = completedTasks.count
        let failedCount = activeTasks.values.filter {
            if case .failed = $0.status { return true }
            return false
        }.count

        return OrchestrationStatistics(
            activeTasks: activeCount,
            completedTasks: completedCount,
            failedTasks: failedCount,
            totalOrchestrated: totalTasksOrchestrated
        )
    }

    func getActiveTaskCount() -> Int {
        return activeTasks.values.filter { $0.status.isActive }.count
    }

    struct OrchestrationStatistics {
        let activeTasks: Int
        let completedTasks: Int
        let failedTasks: Int
        let totalOrchestrated: Int
    }

    // MARK: - Cleanup

    /// Clean up completed and failed tasks
    func cleanup() {
        activeTasks = activeTasks.filter { _, task in
            switch task.status {
            case .completed, .failed, .timeout, .cancelled:
                return false  // Filter out completed/failed
            default:
                return true  // Keep active
            }
        }

        // Keep only recent completed tasks (last 100)
        if completedTasks.count > 100 {
            let sorted = completedTasks.sorted { $0.value.executionTime > $1.value.executionTime }
            completedTasks = Dictionary(uniqueKeysWithValues: sorted.prefix(100).map { ($0.key, $0.value) })
        }
    }
}

// MARK: - Workflow

struct Workflow: Identifiable {
    let id: UUID
    var name: String
    var stages: [WorkflowStage]

    struct WorkflowStage: Identifiable {
        let id: UUID
        var name: String
        var task: AgentTask
        var dependencies: [UUID]  // IDs of stages this depends on

        init(
            id: UUID = UUID(),
            name: String,
            task: AgentTask,
            dependencies: [UUID] = []
        ) {
            self.id = id
            self.name = name
            self.task = task
            self.dependencies = dependencies
        }
    }

    init(id: UUID = UUID(), name: String, stages: [WorkflowStage]) {
        self.id = id
        self.name = name
        self.stages = stages
    }
}

// MARK: - Execution Strategy

enum ExecutionStrategy {
    case parallel          // Execute all tasks in parallel (wait for all)
    case sequential        // Execute tasks one by one
    case raceFirst         // Execute all, return first to complete
    case priorityBased     // Execute by priority (high priority first)
}

// MARK: - Errors

enum OrchestrationError: Error, LocalizedError {
    case taskTimeout(UUID)
    case dependencyNotMet(stageId: UUID, dependencyId: UUID)
    case maxConcurrencyReached
    case workflowFailed(String)

    var errorDescription: String? {
        switch self {
        case .taskTimeout(let id):
            return "Task \(id) timed out"
        case .dependencyNotMet(let stageId, let depId):
            return "Stage \(stageId) dependency \(depId) not met"
        case .maxConcurrencyReached:
            return "Maximum concurrent tasks reached"
        case .workflowFailed(let reason):
            return "Workflow failed: \(reason)"
        }
    }
}
