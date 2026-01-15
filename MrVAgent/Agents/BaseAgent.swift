import Foundation

/// Base protocol for all autonomous agents
/// Agents are specialized AI workers that execute specific tasks
protocol BaseAgent: Actor {

    // MARK: - Identity

    /// Unique identifier for this agent instance
    nonisolated var id: UUID { get }

    /// Agent type (research, code, analysis, design, etc.)
    nonisolated var type: AgentType { get }

    /// Human-readable name for the agent
    nonisolated var name: String { get }

    /// Description of what this agent does
    nonisolated var description: String { get }

    // MARK: - Capabilities

    /// What this agent is capable of doing
    nonisolated var capabilities: Set<AgentCapability> { get }

    /// Can this agent handle the given task?
    func canHandle(task: AgentTask) -> Bool

    // MARK: - Execution

    /// Execute a task and return result
    func execute(task: AgentTask) async throws -> AgentResult

    /// Cancel current execution
    func cancel() async

    // MARK: - State

    /// Current state of the agent
    var state: AgentState { get }

    /// Performance metrics
    var metrics: AgentMetrics { get }
}

// MARK: - Agent Types

enum AgentType: String, Codable, CaseIterable {
    case research       // Web search, information gathering
    case code           // Code analysis, generation, review
    case analysis       // Data processing, reasoning, insights
    case design         // UI/UX suggestions, visual design
    case custom         // User-defined agents

    var icon: String {
        switch self {
        case .research: return "🔍"
        case .code: return "💻"
        case .analysis: return "📊"
        case .design: return "🎨"
        case .custom: return "⚙️"
        }
    }

    var displayName: String {
        switch self {
        case .research: return "Research Agent"
        case .code: return "Code Agent"
        case .analysis: return "Analysis Agent"
        case .design: return "Design Agent"
        case .custom: return "Custom Agent"
        }
    }
}

// MARK: - Agent State

enum AgentState: Equatable {
    case idle               // Ready to accept tasks
    case working            // Currently executing
    case waiting            // Waiting for dependencies
    case completed          // Task finished successfully
    case failed(String)     // Task failed with error
    case cancelled          // Task was cancelled

    var isActive: Bool {
        switch self {
        case .working, .waiting:
            return true
        default:
            return false
        }
    }
}

// MARK: - Agent Capabilities

enum AgentCapability: String, Codable, Hashable {
    // Research capabilities
    case webSearch
    case documentRetrieval
    case knowledgeGraphQuery
    case memorySearch

    // Code capabilities
    case codeGeneration
    case codeReview
    case codeRefactoring
    case syntaxAnalysis
    case bugDetection

    // Analysis capabilities
    case dataProcessing
    case statisticalAnalysis
    case patternRecognition
    case reasoning
    case decisionMaking

    // Design capabilities
    case uiDesign
    case visualSuggestions
    case colorTheory
    case layoutPlanning

    // General capabilities
    case parallelExecution
    case streaming
    case contextAware
    case learningEnabled

    var description: String {
        switch self {
        case .webSearch: return "Search the web for information"
        case .codeGeneration: return "Generate code from requirements"
        case .codeReview: return "Review code for quality and bugs"
        case .dataProcessing: return "Process and analyze data"
        case .uiDesign: return "Design user interfaces"
        case .memorySearch: return "Search conversation memory"
        case .reasoning: return "Apply logical reasoning"
        case .streaming: return "Stream results in real-time"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - Agent Task

struct AgentTask: Identifiable, Codable {
    let id: UUID
    var type: TaskType
    var input: String
    var context: TaskContext?
    var priority: TaskPriority
    var requiredCapabilities: Set<AgentCapability>
    var timeout: TimeInterval?
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        type: TaskType,
        input: String,
        context: TaskContext? = nil,
        priority: TaskPriority = .normal,
        requiredCapabilities: Set<AgentCapability> = [],
        timeout: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.input = input
        self.context = context
        self.priority = priority
        self.requiredCapabilities = requiredCapabilities
        self.timeout = timeout
        self.metadata = metadata
    }

    enum TaskType: String, Codable {
        case research
        case codeGeneration
        case codeReview
        case analysis
        case design
        case general
    }

    enum TaskPriority: Int, Codable, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3

        static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct TaskContext: Codable {
        var projectId: String?
        var conversationHistory: [String]?
        var knowledgeNodes: [String]?
        var previousResults: [String]?
        var userPreferences: [String: String]?
    }
}

// MARK: - Agent Result

struct AgentResult: Codable {
    let taskId: UUID
    let agentId: UUID
    var success: Bool
    var output: String
    var artifacts: [Artifact]
    var executionTime: TimeInterval
    var confidence: Float  // 0.0 - 1.0
    var metadata: [String: String]

    struct Artifact: Codable {
        let id: UUID
        var type: ArtifactType
        var content: String
        var metadata: [String: String]

        enum ArtifactType: String, Codable {
            case code
            case markdown
            case json
            case data
            case visualization
            case reference
        }
    }

    init(
        taskId: UUID,
        agentId: UUID,
        success: Bool = true,
        output: String,
        artifacts: [Artifact] = [],
        executionTime: TimeInterval = 0,
        confidence: Float = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.taskId = taskId
        self.agentId = agentId
        self.success = success
        self.output = output
        self.artifacts = artifacts
        self.executionTime = executionTime
        self.confidence = confidence
        self.metadata = metadata
    }
}

// MARK: - Agent Metrics

struct AgentMetrics: Codable {
    var tasksCompleted: Int
    var tasksFailed: Int
    var totalExecutionTime: TimeInterval
    var averageExecutionTime: TimeInterval
    var successRate: Float
    var lastUsed: Date?

    init() {
        self.tasksCompleted = 0
        self.tasksFailed = 0
        self.totalExecutionTime = 0
        self.averageExecutionTime = 0
        self.successRate = 1.0
        self.lastUsed = nil
    }

    mutating func recordSuccess(executionTime: TimeInterval) {
        tasksCompleted += 1
        totalExecutionTime += executionTime
        averageExecutionTime = totalExecutionTime / Double(tasksCompleted + tasksFailed)
        successRate = Float(tasksCompleted) / Float(tasksCompleted + tasksFailed)
        lastUsed = Date()
    }

    mutating func recordFailure(executionTime: TimeInterval) {
        tasksFailed += 1
        totalExecutionTime += executionTime
        averageExecutionTime = totalExecutionTime / Double(tasksCompleted + tasksFailed)
        successRate = Float(tasksCompleted) / Float(tasksCompleted + tasksFailed)
        lastUsed = Date()
    }
}
