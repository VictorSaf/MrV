import Foundation

class ClaudeService: AIService {
    let provider: AIProvider = .claude

    private let keychainService = KeychainService.shared
    private let config: APIConfiguration

    var isConfigured: Bool {
        config.isConfigured
    }

    init() {
        let apiKey = keychainService.getAPIKey(for: provider.rawValue)
        self.config = APIConfiguration(provider: .claude, apiKey: apiKey)
    }

    func sendMessage(_ message: String, conversationHistory: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        guard isConfigured, let apiKey = config.apiKey else {
            throw AIServiceError.notConfigured
        }

        // Build messages array from conversation history
        var messages: [ClaudeMessage] = conversationHistory
            .filter { !$0.isStreaming }
            .map { ClaudeMessage(role: $0.isUser ? "user" : "assistant", content: $0.content) }

        // Add current message
        messages.append(ClaudeMessage(role: "user", content: message))

        let requestBody = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            messages: messages,
            maxTokens: 4096,
            stream: true
        )

        let url = URL(string: "\(config.baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIServiceError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        let errorMessage = try await parseError(from: bytes)
                        continuation.finish(throwing: AIServiceError.serverError(errorMessage))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let event = try? JSONDecoder().decode(ClaudeStreamEvent.self, from: data) {

                                switch event.type {
                                case "content_block_delta":
                                    if let text = event.delta?.text {
                                        continuation.yield(text)
                                    }
                                case "message_stop":
                                    continuation.finish()
                                    return
                                default:
                                    break
                                }
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AIServiceError.networkError(error))
                }
            }
        }
    }

    private func parseError(from bytes: URLSession.AsyncBytes) async throws -> String {
        var errorData = Data()
        for try await byte in bytes {
            errorData.append(byte)
        }

        if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: errorData) {
            return errorResponse.error.message
        }

        return "Unknown error occurred"
    }
}

// MARK: - Response Models

struct ClaudeStreamEvent: Codable {
    let type: String
    let delta: ClaudeDelta?
}

struct ClaudeDelta: Codable {
    let text: String?
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}
