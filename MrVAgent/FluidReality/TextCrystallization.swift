import Foundation
import SwiftUI

/// Text crystallization effect - progressive character-by-character appearance
/// Characters materialize with blur→sharp transition and opacity fade-in
@MainActor
final class TextCrystallization: ObservableObject {

    // MARK: - Crystallization State

    struct CrystallizationState {
        var elementId: UUID
        var fullText: String
        var currentIndex: Int = 0
        var isComplete: Bool = false
        var startTime: Date = Date()

        var visibleText: String {
            let endIndex = min(currentIndex, fullText.count)
            return String(fullText.prefix(endIndex))
        }

        var progress: Double {
            guard fullText.count > 0 else { return 1.0 }
            return Double(currentIndex) / Double(fullText.count)
        }
    }

    // MARK: - Configuration

    nonisolated struct CrystallizationConfig {
        var charactersPerSecond: Double = 30.0  // Speed of typing
        var blurRadius: CGFloat = 8.0           // Initial blur for new characters
        var blurDecayDuration: Double = 0.2     // Time for blur to fade
        var scaleEffect: CGFloat = 1.1          // Initial scale (subtle pop)
        var scaleDecayDuration: Double = 0.15   // Time for scale to normalize

        nonisolated static let `default` = CrystallizationConfig()
        nonisolated static let fast = CrystallizationConfig(charactersPerSecond: 60.0)
        nonisolated static let slow = CrystallizationConfig(charactersPerSecond: 15.0)
    }

    // MARK: - Active Crystallizations

    private var activeStates: [UUID: CrystallizationState] = [:]
    private var timers: [UUID: Timer] = [:]
    private weak var fluidReality: FluidRealityEngine?

    init(fluidReality: FluidRealityEngine? = nil) {
        self.fluidReality = fluidReality
    }

    // MARK: - Public Interface

    /// Begin crystallizing text for a fluid element
    func crystallize(
        text: String,
        elementId: UUID,
        config: CrystallizationConfig = .default,
        completion: (() -> Void)? = nil
    ) {
        // Cancel existing crystallization for this element
        cancelCrystallization(for: elementId)

        // Create new state
        let state = CrystallizationState(
            elementId: elementId,
            fullText: text,
            currentIndex: 0
        )

        activeStates[elementId] = state

        // Calculate interval between characters
        let interval = 1.0 / config.charactersPerSecond

        // Start timer for character-by-character reveal
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            Task { @MainActor in
                await self.advanceCrystallization(for: elementId, config: config, completion: completion)
            }
        }

        timers[elementId] = timer
    }

    /// Update element with streaming text (for AI responses)
    func updateStreamingText(_ text: String, elementId: UUID, config: CrystallizationConfig = .default) {
        if var state = activeStates[elementId] {
            // Update full text if it's longer
            if text.count > state.fullText.count {
                state.fullText = text
                activeStates[elementId] = state
            }
        } else {
            // Start new crystallization
            crystallize(text: text, elementId: elementId, config: config)
        }
    }

    /// Cancel crystallization for an element
    func cancelCrystallization(for elementId: UUID) {
        timers[elementId]?.invalidate()
        timers.removeValue(forKey: elementId)
        activeStates.removeValue(forKey: elementId)
    }

    /// Check if element is currently crystallizing
    func isCrystallizing(elementId: UUID) -> Bool {
        return activeStates[elementId] != nil
    }

    /// Get current visible text for element
    func visibleText(for elementId: UUID) -> String? {
        return activeStates[elementId]?.visibleText
    }

    // MARK: - Internal

    private func advanceCrystallization(
        for elementId: UUID,
        config: CrystallizationConfig,
        completion: (() -> Void)?
    ) async {
        guard var state = activeStates[elementId] else { return }

        // Advance by one character
        state.currentIndex += 1

        // Update state
        activeStates[elementId] = state

        // Update fluid element content
        if let fluidReality = fluidReality,
           let elementIndex = fluidReality.activeElements.firstIndex(where: { $0.id == elementId }) {

            let visibleText = state.visibleText
            fluidReality.activeElements[elementIndex].content = .text(visibleText)

            // Apply subtle effects to last character (optional enhancement)
            // Could add particle emission here
        }

        // Check if complete
        if state.currentIndex >= state.fullText.count {
            state.isComplete = true
            activeStates[elementId] = state

            // Cleanup
            cancelCrystallization(for: elementId)

            // Call completion handler
            completion?()
        }
    }

    // MARK: - Character Animation Helpers

    /// Get blur radius for character at index (decays over time)
    func blurRadiusForCharacter(at index: Int, in elementId: UUID, config: CrystallizationConfig) -> CGFloat {
        guard let state = activeStates[elementId] else { return 0 }

        let characterAge = Date().timeIntervalSince(state.startTime) - (Double(index) / config.charactersPerSecond)

        if characterAge < 0 {
            return config.blurRadius
        } else if characterAge < config.blurDecayDuration {
            let progress = characterAge / config.blurDecayDuration
            return config.blurRadius * CGFloat(1.0 - progress)
        } else {
            return 0
        }
    }

    /// Get scale for character at index (decays to 1.0 over time)
    func scaleForCharacter(at index: Int, in elementId: UUID, config: CrystallizationConfig) -> CGFloat {
        guard let state = activeStates[elementId] else { return 1.0 }

        let characterAge = Date().timeIntervalSince(state.startTime) - (Double(index) / config.charactersPerSecond)

        if characterAge < 0 {
            return config.scaleEffect
        } else if characterAge < config.scaleDecayDuration {
            let progress = characterAge / config.scaleDecayDuration
            return config.scaleEffect - (config.scaleEffect - 1.0) * CGFloat(progress)
        } else {
            return 1.0
        }
    }

    /// Get opacity for character at index (fades in)
    func opacityForCharacter(at index: Int, in elementId: UUID, config: CrystallizationConfig) -> Double {
        guard let state = activeStates[elementId] else { return 1.0 }

        let characterAge = Date().timeIntervalSince(state.startTime) - (Double(index) / config.charactersPerSecond)

        if characterAge < 0 {
            return 0
        } else if characterAge < 0.1 {  // Quick fade-in
            return characterAge / 0.1
        } else {
            return 1.0
        }
    }
}

// MARK: - Streaming Integration

extension TextCrystallization {
    /// Convenience method for streaming AI responses
    func processStreamChunk(
        _ chunk: String,
        for elementId: UUID,
        appendingTo currentText: String,
        config: CrystallizationConfig = .default
    ) {
        let newText = currentText + chunk
        updateStreamingText(newText, elementId: elementId, config: config)
    }
}
