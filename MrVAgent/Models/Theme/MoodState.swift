import Foundation
import SwiftUI

/// System mood states that affect visual presentation
enum MoodState: String, CaseIterable {
    case dormant      // Waiting, inactive
    case focused      // Working intensely, concentrated
    case creative     // Exploring ideas, brainstorming
    case analytical   // Processing data, reasoning
    case playful      // Surprising moments, fun
    case calm         // Steady state, peaceful

    // MARK: - Visual Properties

    /// Color palette for this mood
    var colors: [Color] {
        switch self {
        case .dormant:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.1),  // Deep blue-black
                Color(red: 0.08, green: 0.08, blue: 0.12)
            ]
        case .focused:
            return [
                Color(red: 0.1, green: 0.05, blue: 0.15),   // Deep purple
                Color(red: 0.15, green: 0.08, blue: 0.2)
            ]
        case .creative:
            return [
                Color(red: 0.15, green: 0.08, blue: 0.1),   // Warm red-purple
                Color(red: 0.2, green: 0.12, blue: 0.15)
            ]
        case .analytical:
            return [
                Color(red: 0.05, green: 0.1, blue: 0.15),   // Cool blue
                Color(red: 0.08, green: 0.15, blue: 0.2)
            ]
        case .playful:
            return [
                Color(red: 0.15, green: 0.1, blue: 0.05),   // Warm orange
                Color(red: 0.2, green: 0.15, blue: 0.08)
            ]
        case .calm:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.1),   // Soft green
                Color(red: 0.1, green: 0.15, blue: 0.12)
            ]
        }
    }

    /// Base color as SIMD3 for Metal shaders
    var baseColorSIMD: SIMD3<Float> {
        let color = colors[0]
        let uiColor = NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }

    /// Particle emission intensity for this mood
    var particleIntensity: Float {
        switch self {
        case .dormant:
            return 0.3      // Minimal particles
        case .focused:
            return 1.5      // High activity
        case .creative:
            return 2.0      // Maximum particles
        case .analytical:
            return 1.0      // Moderate activity
        case .playful:
            return 1.8      // High, varied
        case .calm:
            return 0.5      // Low, smooth
        }
    }

    /// Overall animation speed multiplier
    var animationSpeed: Float {
        switch self {
        case .dormant:
            return 0.5      // Slow
        case .focused:
            return 1.2      // Slightly faster
        case .creative:
            return 1.5      // Fast
        case .analytical:
            return 1.0      // Normal
        case .playful:
            return 1.8      // Very fast
        case .calm:
            return 0.7      // Slow and smooth
        }
    }

    /// Breathing intensity for background
    var breathingIntensity: Float {
        switch self {
        case .dormant:
            return 0.2
        case .focused:
            return 0.5
        case .creative:
            return 0.8
        case .analytical:
            return 0.4
        case .playful:
            return 1.0
        case .calm:
            return 0.3
        }
    }

    /// Cursor response strength
    var cursorResponseStrength: Float {
        switch self {
        case .dormant:
            return 0.5
        case .focused:
            return 1.2
        case .creative:
            return 1.5
        case .analytical:
            return 0.8
        case .playful:
            return 2.0
        case .calm:
            return 0.6
        }
    }

    // MARK: - Mood Detection

    /// Detect mood from user input
    static func detectMood(from input: String) -> MoodState {
        let lowercased = input.lowercased()

        // Playful indicators
        if containsPlayfulKeywords(lowercased) {
            return .playful
        }

        // Creative indicators
        if containsCreativeKeywords(lowercased) {
            return .creative
        }

        // Analytical indicators
        if containsAnalyticalKeywords(lowercased) {
            return .analytical
        }

        // Focused indicators
        if containsFocusedKeywords(lowercased) {
            return .focused
        }

        // Calm indicators
        if containsCalmKeywords(lowercased) {
            return .calm
        }

        // Default to dormant
        return .dormant
    }

    private static func containsPlayfulKeywords(_ text: String) -> Bool {
        let keywords = ["fun", "play", "joke", "funny", "lol", "haha", "😄", "🎉", "surprise"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsCreativeKeywords(_ text: String) -> Bool {
        let keywords = ["create", "imagine", "design", "art", "story", "idea", "invent", "dream"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsAnalyticalKeywords(_ text: String) -> Bool {
        let keywords = ["analyze", "data", "calculate", "logic", "reason", "compare", "evaluate"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsFocusedKeywords(_ text: String) -> Bool {
        let keywords = ["urgent", "important", "critical", "focus", "concentrate", "priority", "asap"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsCalmKeywords(_ text: String) -> Bool {
        let keywords = ["calm", "relax", "peace", "slow", "gentle", "easy", "simple"]
        return keywords.contains { text.contains($0) }
    }

    // MARK: - Transition

    /// Get transition duration to another mood
    func transitionDuration(to newMood: MoodState) -> Double {
        // Longer transitions for bigger mood shifts
        let distance = abs(self.rawValue.count - newMood.rawValue.count)
        return 2.0 + Double(distance) * 0.5
    }
}

/// Mood manager for tracking and transitioning moods
@MainActor
final class MoodManager: ObservableObject {
    @Published private(set) var currentMood: MoodState = .dormant
    @Published private(set) var isTransitioning: Bool = false

    private var transitionTimer: Timer?

    /// Change mood with smooth transition
    func transitionToMood(_ newMood: MoodState) {
        guard newMood != currentMood else { return }

        isTransitioning = true
        let duration = currentMood.transitionDuration(to: newMood)

        print("🎭 Mood transition: \(currentMood.rawValue) → \(newMood.rawValue) (\(duration)s)")

        // Start transition
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.currentMood = newMood
            self?.isTransitioning = false
        }
    }

    /// Auto-detect and transition based on input
    func detectAndTransition(from input: String) {
        let detectedMood = MoodState.detectMood(from: input)
        if detectedMood != currentMood {
            transitionToMood(detectedMood)
        }
    }

    /// Force immediate mood change (no transition)
    func setMoodImmediate(_ mood: MoodState) {
        currentMood = mood
        isTransitioning = false
    }
}
