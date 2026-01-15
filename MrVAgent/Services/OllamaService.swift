import Foundation

class OllamaService: AIService {
    let provider: AIProvider = .ollama

    private let config: APIConfiguration

    var isConfigured: Bool {
        // Ollama runs locally, always considered configured
        true
    }

    init() {
        self.config = APIConfiguration(provider: .ollama)
    }

    func sendMessage(_ message: String, conversationHistory: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        // Build context from conversation history
        var prompt = ""

        for msg in conversationHistory.filter({ !$0.isStreaming }) {
            if msg.isUser {
                prompt += "User: \(msg.content)\n"
            } else {
                prompt += "Assistant: \(msg.content)\n"
            }
        }

        prompt += "User: \(message)\nAssistant: "

        let requestBody = OllamaRequest(
            model: "llama2",
            prompt: prompt,
            stream: true
        )

        let url = URL(string: "\(config.baseURL)/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
                        if httpResponse.statusCode == 404 {
                            continuation.finish(throwing: AIServiceError.modelNotAvailable)
                        } else {
                            continuation.finish(throwing: AIServiceError.serverError("HTTP \(httpResponse.statusCode)"))
                        }
                        return
                    }

                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8),
                           let event = try? JSONDecoder().decode(OllamaStreamResponse.self, from: data) {

                            if let response = event.response {
                                continuation.yield(response)
                            }

                            if event.done {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    // Check if it's a connection error (Ollama not running)
                    if (error as NSError).code == NSURLErrorCannotConnectToHost {
                        continuation.finish(throwing: AIServiceError.serverError("Cannot connect to Ollama. Please ensure Ollama is running (ollama serve)"))
                    } else {
                        continuation.finish(throwing: AIServiceError.networkError(error))
                    }
                }
            }
        }
    }
}

// MARK: - Response Models

struct OllamaStreamResponse: Codable {
    let model: String?
    let response: String?
    let done: Bool
}
