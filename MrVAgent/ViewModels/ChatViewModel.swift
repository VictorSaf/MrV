import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var selectedProvider: AIProvider = .claude
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""

    private var currentService: AIService {
        AIServiceFactory.createService(for: selectedProvider)
    }

    var isServiceConfigured: Bool {
        currentService.isConfigured
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Check if service is configured
        guard currentService.isConfigured else {
            errorMessage = "Please configure \(selectedProvider.displayName) in Settings first."
            return
        }

        // Clear input and error
        inputText = ""
        errorMessage = nil

        // Add user message
        let userMessage = Message.user(text)
        messages.append(userMessage)

        // Start loading
        isLoading = true

        // Create empty assistant message for streaming
        let assistantMessageId = UUID()
        let emptyAssistantMessage = Message(
            id: assistantMessageId,
            content: "",
            isUser: false,
            isStreaming: true
        )
        messages.append(emptyAssistantMessage)

        Task {
            do {
                let stream = try await currentService.sendMessage(text, conversationHistory: messages)
                var fullResponse = ""

                for try await chunk in stream {
                    fullResponse += chunk

                    // Update the streaming message
                    if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                        messages[index] = Message(
                            id: assistantMessageId,
                            content: fullResponse,
                            isUser: false,
                            isStreaming: true
                        )
                    }
                }

                // Mark message as complete
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index] = Message(
                        id: assistantMessageId,
                        content: fullResponse,
                        isUser: false,
                        isStreaming: false
                    )
                }

                isLoading = false

            } catch {
                // Remove the empty assistant message on error
                messages.removeAll { $0.id == assistantMessageId }

                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }

    func changeProvider(to provider: AIProvider) {
        selectedProvider = provider
    }
}
