import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case claude = "claude"
    case openAI = "openai"
    case perplexity = "perplexity"
    case ollama = "ollama"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude:
            return "Claude (Anthropic)"
        case .openAI:
            return "ChatGPT (OpenAI)"
        case .perplexity:
            return "Perplexity"
        case .ollama:
            return "Ollama (Local)"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama:
            return false
        default:
            return true
        }
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude:
            return "sk-ant-..."
        case .openAI:
            return "sk-..."
        case .perplexity:
            return "pplx-..."
        case .ollama:
            return "No API key needed"
        }
    }

    var setupInstructions: String {
        switch self {
        case .claude:
            return "Get your API key from https://console.anthropic.com/"
        case .openAI:
            return "Get your API key from https://platform.openai.com/api-keys"
        case .perplexity:
            return "Get your API key from https://www.perplexity.ai/settings/api"
        case .ollama:
            return "Install Ollama from https://ollama.ai/ and run 'ollama serve'"
        }
    }
}
