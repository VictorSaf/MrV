import Foundation
import SwiftUI
import Combine

/// Mr.V Consciousness - The living intelligence behind the void
/// Integrates AI models with the Fluid Reality system
@MainActor
final class MrVConsciousness: ObservableObject {

    // MARK: - Published State

    @Published var state: ConsciousnessState = .dormant
    @Published var selectedProvider: AIProvider = .claude
    @Published var currentResponse: String = ""
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private weak var fluidReality: FluidRealityEngine?
    private var conversationHistory: [Message] = []

    // MARK: - Consciousness State

    enum ConsciousnessState: Equatable {
        case dormant        // Waiting for input
        case processing     // Analyzing input
        case responding     // Generating response
        case error(String)  // Error state

        var isActive: Bool {
            switch self {
            case .processing, .responding:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Initialization

    init(fluidReality: FluidRealityEngine? = nil) {
        self.fluidReality = fluidReality
    }

    func setFluidReality(_ engine: FluidRealityEngine) {
        self.fluidReality = engine
    }

    // MARK: - AI Service

    private var currentService: AIService {
        AIServiceFactory.createService(for: selectedProvider)
    }

    var isServiceConfigured: Bool {
        currentService.isConfigured
    }

    // MARK: - Input Processing

    /// Process user input and generate response
    func processInput(_ input: String) async {
        guard !input.isEmpty else { return }

        // Check if service is configured
        guard currentService.isConfigured else {
            await handleError("Please configure \(selectedProvider.displayName) in Settings first.")
            return
        }

        // Change state to processing
        state = .processing

        // Add user message to history
        let userMessage = Message.user(input)
        conversationHistory.append(userMessage)

        // Create user input fluid element (already done by InvisibleInput)
        // Now create response element

        guard let fluidReality = fluidReality else {
            await handleError("Fluid Reality Engine not initialized")
            return
        }

        // Calculate position for response
        let responsePosition = calculateResponsePosition(viewSize: CGSize(width: 1280, height: 800))

        // Create empty response element
        let responseId = UUID()
        let responseElement = FluidElement(
            id: responseId,
            type: .text(""),
            position: responsePosition,
            content: .text(""),
            style: FluidElement.ElementStyle(
                font: .system(size: 16, weight: .light),
                foregroundColor: providerColor(for: selectedProvider),
                glowIntensity: 0.2
            )
        )

        // Materialize empty element
        fluidReality.materializeElement(responseElement)

        // Change state to responding
        state = .responding
        currentResponse = ""

        // Stream response from AI
        do {
            let stream = try await currentService.sendMessage(input, conversationHistory: conversationHistory)

            for try await chunk in stream {
                currentResponse += chunk

                // Update element with streaming text and crystallization
                fluidReality.updateElementTextStreaming(
                    responseId,
                    newText: currentResponse,
                    config: .fast  // Fast crystallization for AI responses
                )
            }

            // Add to conversation history
            let assistantMessage = Message(
                id: UUID(),
                content: currentResponse,
                isUser: false,
                isStreaming: false
            )
            conversationHistory.append(assistantMessage)

            // Return to dormant state
            state = .dormant
            currentResponse = ""

        } catch {
            await handleError(error.localizedDescription)

            // Remove the empty response element
            fluidReality.removeElement(responseId)
        }
    }

    // MARK: - Position Calculation

    private func calculateResponsePosition(viewSize: CGSize) -> FluidElement.FluidPosition {
        guard let fluidReality = fluidReality else {
            return FluidElement.FluidPosition(
                x: viewSize.width * 0.15,
                y: viewSize.height * 0.5,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        }

        // Get existing text elements
        let existingTextElements = fluidReality.activeElements.filter { $0.type.isText }

        // Calculate position below last element
        if let lastElement = existingTextElements.last {
            return FluidElement.FluidPosition(
                x: lastElement.position.x,
                y: lastElement.position.y + 40,  // 40px below
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        } else {
            // First element - start at top-left
            return FluidElement.FluidPosition(
                x: viewSize.width * 0.15,
                y: viewSize.height * 0.2,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
        }
    }

    // MARK: - Provider Styling

    private func providerColor(for provider: AIProvider) -> Color {
        switch provider {
        case .claude:
            return Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.9)  // Warm orange
        case .openAI:
            return Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.9)  // Mint green
        case .perplexity:
            return Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.9)  // Purple
        case .ollama:
            return Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.9)  // Blue
        }
    }

    // MARK: - Error Handling

    private func handleError(_ message: String) async {
        errorMessage = message
        state = .error(message)

        // Create error fluid element
        if let fluidReality = fluidReality {
            let errorPosition = FluidElement.FluidPosition(
                x: 200,
                y: 100,
                z: 0.0,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )

            let errorElement = FluidElement(
                type: .text("Error: \(message)"),
                position: errorPosition,
                content: .text("⚠️ \(message)"),
                style: FluidElement.ElementStyle(
                    font: .system(size: 14, weight: .medium),
                    foregroundColor: .red.opacity(0.8),
                    glowIntensity: 0.3
                )
            )

            fluidReality.materializeElementWithCrystallization(errorElement)

            // Auto-dissolve error after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                fluidReality.dissolveElement(errorElement.id)
            }
        }

        // Clear error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.errorMessage = nil
            self.state = .dormant
        }
    }

    // MARK: - Conversation Management

    func clearConversation() {
        conversationHistory.removeAll()

        // Dissolve all text elements
        if let fluidReality = fluidReality {
            let textElements = fluidReality.activeElements.filter { $0.type.isText }
            for element in textElements {
                fluidReality.dissolveElement(element.id)
            }
        }
    }

    func changeProvider(to provider: AIProvider) {
        selectedProvider = provider
    }

    // MARK: - Intent Analysis (Future Enhancement)

    private func analyzeIntent(_ input: String) -> Intent {
        // TODO: Implement intent analysis in Phase 3
        // For now, assume general conversation
        return .conversation
    }

    enum Intent {
        case conversation
        case coding
        case research
        case creative
        case analysis
    }
}
