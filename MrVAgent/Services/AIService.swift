import Foundation

protocol AIService {
    var provider: AIProvider { get }
    var isConfigured: Bool { get }

    func sendMessage(_ message: String, conversationHistory: [Message]) async throws -> AsyncThrowingStream<String, Error>
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case modelNotAvailable
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service is not configured. Please add your API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .modelNotAvailable:
            return "Model is not available. Please try another provider."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - AI Service Factory

class AIServiceFactory {
    static func createService(for provider: AIProvider) -> AIService {
        switch provider {
        case .claude:
            return ClaudeService()
        case .openAI:
            return OpenAIService()
        case .perplexity:
            return PerplexityService()
        case .ollama:
            return OllamaService()
        }
    }
}
