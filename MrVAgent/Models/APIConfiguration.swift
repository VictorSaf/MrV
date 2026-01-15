import Foundation

struct APIConfiguration {
    let provider: AIProvider
    let apiKey: String?
    let baseURL: String

    init(provider: AIProvider, apiKey: String? = nil) {
        self.provider = provider
        self.apiKey = apiKey

        switch provider {
        case .claude:
            self.baseURL = "https://api.anthropic.com/v1"
        case .openAI:
            self.baseURL = "https://api.openai.com/v1"
        case .perplexity:
            self.baseURL = "https://api.perplexity.ai"
        case .ollama:
            self.baseURL = "http://localhost:11434/api"
        }
    }

    var isConfigured: Bool {
        if provider.requiresAPIKey {
            return apiKey != nil && !apiKey!.isEmpty
        }
        return true // Ollama doesn't need API key
    }
}

// MARK: - API Request/Response Models

struct ClaudeRequest: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case stream
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let stream: Bool
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
}
