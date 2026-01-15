import Foundation

class OpenAIService: AIService {
    let provider: AIProvider = .openAI

    private let keychainService = KeychainService.shared
    private let config: APIConfiguration

    var isConfigured: Bool {
        config.isConfigured
    }

    init() {
        let apiKey = keychainService.getAPIKey(for: provider.rawValue)
        self.config = APIConfiguration(provider: .openAI, apiKey: apiKey)
    }

    func sendMessage(_ message: String, conversationHistory: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        guard isConfigured, let apiKey = config.apiKey else {
            throw AIServiceError.notConfigured
        }

        // Build messages array from conversation history
        var messages: [OpenAIMessage] = conversationHistory
            .filter { !$0.isStreaming }
            .map { OpenAIMessage(role: $0.isUser ? "user" : "assistant", content: $0.content) }

        // Add current message
        messages.append(OpenAIMessage(role: "user", content: message))

        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: messages,
            stream: true
        )

        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                        continuation.finish(throwing: AIServiceError.serverError("HTTP \(httpResponse.statusCode)"))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))

                            // Check for [DONE] signal
                            if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            if let data = jsonString.data(using: .utf8),
                               let event = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data) {

                                if let content = event.choices.first?.delta.content {
                                    continuation.yield(content)
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
}

// MARK: - Response Models

struct OpenAIStreamResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let delta: OpenAIDelta
}

struct OpenAIDelta: Codable {
    let content: String?
}
