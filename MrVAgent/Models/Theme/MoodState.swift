import Foundation
import SwiftUI

/// System mood states that affect visual presentation
/// Complete emotional vocabulary for Mr.V consciousness
enum MoodState: String, CaseIterable {
    // Base states
    case dormant      // Waiting, inactive
    case calm         // Steady state, peaceful

    // Cognitive states
    case focused      // Working intensely, concentrated
    case analytical   // Processing data, reasoning
    case contemplative // Slow, deep thinking
    case curious      // Exploring, questioning
    case reflective   // Looking back, learning

    // Creative states
    case creative     // Exploring ideas, brainstorming
    case inspired     // Breakthrough moments, enlightened
    case playful      // Surprising moments, fun

    // Energy states
    case energetic    // High activity, dynamic
    case excited      // High energy, enthusiastic
    case determined   // Goal-oriented, persistent

    // Emotional states
    case confident    // Assured, strong
    case uncertain    // Hesitant, questioning
    case melancholic  // Thoughtful sadness, introspective

    // MARK: - Visual Properties

    /// Color palette for this mood
    var colors: [Color] {
        switch self {
        // Base states
        case .dormant:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.1),  // Deep blue-black
                Color(red: 0.08, green: 0.08, blue: 0.12)
            ]
        case .calm:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.1),   // Soft green
                Color(red: 0.1, green: 0.15, blue: 0.12)
            ]

        // Cognitive states
        case .focused:
            return [
                Color(red: 0.1, green: 0.05, blue: 0.15),   // Deep purple
                Color(red: 0.15, green: 0.08, blue: 0.2)
            ]
        case .analytical:
            return [
                Color(red: 0.05, green: 0.1, blue: 0.15),   // Cool blue
                Color(red: 0.08, green: 0.15, blue: 0.2)
            ]
        case .contemplative:
            return [
                Color(red: 0.08, green: 0.08, blue: 0.15),  // Deep indigo
                Color(red: 0.1, green: 0.1, blue: 0.18)
            ]
        case .curious:
            return [
                Color(red: 0.12, green: 0.15, blue: 0.18),  // Bright blue-gray
                Color(red: 0.15, green: 0.18, blue: 0.22)
            ]
        case .reflective:
            return [
                Color(red: 0.1, green: 0.12, blue: 0.15),   // Muted blue
                Color(red: 0.12, green: 0.14, blue: 0.18)
            ]

        // Creative states
        case .creative:
            return [
                Color(red: 0.15, green: 0.08, blue: 0.1),   // Warm red-purple
                Color(red: 0.2, green: 0.12, blue: 0.15)
            ]
        case .inspired:
            return [
                Color(red: 0.18, green: 0.15, blue: 0.08),  // Bright gold
                Color(red: 0.22, green: 0.18, blue: 0.1)
            ]
        case .playful:
            return [
                Color(red: 0.15, green: 0.1, blue: 0.05),   // Warm orange
                Color(red: 0.2, green: 0.15, blue: 0.08)
            ]

        // Energy states
        case .energetic:
            return [
                Color(red: 0.18, green: 0.08, blue: 0.08),  // Vibrant red
                Color(red: 0.22, green: 0.1, blue: 0.1)
            ]
        case .excited:
            return [
                Color(red: 0.2, green: 0.12, blue: 0.05),   // Bright orange-red
                Color(red: 0.25, green: 0.15, blue: 0.08)
            ]
        case .determined:
            return [
                Color(red: 0.15, green: 0.05, blue: 0.05),  // Deep red
                Color(red: 0.18, green: 0.08, blue: 0.08)
            ]

        // Emotional states
        case .confident:
            return [
                Color(red: 0.12, green: 0.08, blue: 0.15),  // Rich purple
                Color(red: 0.15, green: 0.1, blue: 0.18)
            ]
        case .uncertain:
            return [
                Color(red: 0.1, green: 0.1, blue: 0.12),    // Neutral gray-blue
                Color(red: 0.12, green: 0.12, blue: 0.15)
            ]
        case .melancholic:
            return [
                Color(red: 0.08, green: 0.1, blue: 0.12),   // Cool gray-blue
                Color(red: 0.1, green: 0.12, blue: 0.15)
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
        // Base states
        case .dormant:
            return 0.3      // Minimal particles
        case .calm:
            return 0.5      // Low, smooth

        // Cognitive states
        case .focused:
            return 1.5      // High activity
        case .analytical:
            return 1.0      // Moderate activity
        case .contemplative:
            return 0.7      // Slow, steady
        case .curious:
            return 1.2      // Active exploration
        case .reflective:
            return 0.8      // Moderate, thoughtful

        // Creative states
        case .creative:
            return 2.0      // Maximum particles
        case .inspired:
            return 2.5      // Burst of particles
        case .playful:
            return 1.8      // High, varied

        // Energy states
        case .energetic:
            return 2.2      // Very high
        case .excited:
            return 2.8      // Maximum energy
        case .determined:
            return 1.6      // Strong, focused

        // Emotional states
        case .confident:
            return 1.3      // Steady, strong
        case .uncertain:
            return 0.6      // Low, hesitant
        case .melancholic:
            return 0.4      // Minimal, slow
        }
    }

    /// Overall animation speed multiplier
    var animationSpeed: Float {
        switch self {
        // Base states
        case .dormant:
            return 0.5      // Slow
        case .calm:
            return 0.7      // Slow and smooth

        // Cognitive states
        case .focused:
            return 1.2      // Slightly faster
        case .analytical:
            return 1.0      // Normal
        case .contemplative:
            return 0.6      // Very slow
        case .curious:
            return 1.3      // Active
        case .reflective:
            return 0.8      // Measured

        // Creative states
        case .creative:
            return 1.5      // Fast
        case .inspired:
            return 1.8      // Very fast
        case .playful:
            return 1.8      // Very fast

        // Energy states
        case .energetic:
            return 2.0      // High speed
        case .excited:
            return 2.5      // Maximum speed
        case .determined:
            return 1.4      // Steady fast

        // Emotional states
        case .confident:
            return 1.1      // Steady
        case .uncertain:
            return 0.6      // Hesitant
        case .melancholic:
            return 0.5      // Very slow
        }
    }

    /// Breathing intensity for background
    var breathingIntensity: Float {
        switch self {
        // Base states
        case .dormant:
            return 0.2
        case .calm:
            return 0.3

        // Cognitive states
        case .focused:
            return 0.5
        case .analytical:
            return 0.4
        case .contemplative:
            return 0.6
        case .curious:
            return 0.7
        case .reflective:
            return 0.5

        // Creative states
        case .creative:
            return 0.8
        case .inspired:
            return 1.2
        case .playful:
            return 1.0

        // Energy states
        case .energetic:
            return 0.9
        case .excited:
            return 1.5
        case .determined:
            return 0.6

        // Emotional states
        case .confident:
            return 0.7
        case .uncertain:
            return 0.4
        case .melancholic:
            return 0.3
        }
    }

    /// Cursor response strength
    var cursorResponseStrength: Float {
        switch self {
        // Base states
        case .dormant:
            return 0.5
        case .calm:
            return 0.6

        // Cognitive states
        case .focused:
            return 1.2
        case .analytical:
            return 0.8
        case .contemplative:
            return 0.7
        case .curious:
            return 1.4
        case .reflective:
            return 0.9

        // Creative states
        case .creative:
            return 1.5
        case .inspired:
            return 1.8
        case .playful:
            return 2.0

        // Energy states
        case .energetic:
            return 1.7
        case .excited:
            return 2.5
        case .determined:
            return 1.3

        // Emotional states
        case .confident:
            return 1.1
        case .uncertain:
            return 0.6
        case .melancholic:
            return 0.4
        }
    }

    // MARK: - Mood Detection

    /// Detect mood from user input
    static func detectMood(from input: String) -> MoodState {
        let lowercased = input.lowercased()

        // Energy states (check first for high-energy keywords)
        if containsExcitedKeywords(lowercased) {
            return .excited
        }
        if containsEnergeticKeywords(lowercased) {
            return .energetic
        }
        if containsDeterminedKeywords(lowercased) {
            return .determined
        }

        // Creative states
        if containsInspiredKeywords(lowercased) {
            return .inspired
        }
        if containsPlayfulKeywords(lowercased) {
            return .playful
        }
        if containsCreativeKeywords(lowercased) {
            return .creative
        }

        // Cognitive states
        if containsCuriousKeywords(lowercased) {
            return .curious
        }
        if containsContemplativeKeywords(lowercased) {
            return .contemplative
        }
        if containsReflectiveKeywords(lowercased) {
            return .reflective
        }
        if containsAnalyticalKeywords(lowercased) {
            return .analytical
        }
        if containsFocusedKeywords(lowercased) {
            return .focused
        }

        // Emotional states
        if containsConfidentKeywords(lowercased) {
            return .confident
        }
        if containsUncertainKeywords(lowercased) {
            return .uncertain
        }
        if containsMelancholicKeywords(lowercased) {
            return .melancholic
        }

        // Base states
        if containsCalmKeywords(lowercased) {
            return .calm
        }

        // Default to dormant
        return .dormant
    }

    // Base states
    private static func containsCalmKeywords(_ text: String) -> Bool {
        let keywords = ["calm", "relax", "peace", "slow", "gentle", "easy", "simple", "tranquil"]
        return keywords.contains { text.contains($0) }
    }

    // Cognitive states
    private static func containsFocusedKeywords(_ text: String) -> Bool {
        let keywords = ["urgent", "important", "critical", "focus", "concentrate", "priority", "asap"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsAnalyticalKeywords(_ text: String) -> Bool {
        let keywords = ["analyze", "data", "calculate", "logic", "reason", "compare", "evaluate", "examine"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsContemplativeKeywords(_ text: String) -> Bool {
        let keywords = ["contemplate", "ponder", "think deeply", "consider", "meditate", "muse", "philosophical"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsCuriousKeywords(_ text: String) -> Bool {
        let keywords = ["curious", "wonder", "what if", "how does", "why", "explore", "discover", "investigate", "what about"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsReflectiveKeywords(_ text: String) -> Bool {
        let keywords = ["reflect", "looking back", "remember", "recall", "learned", "retrospect", "review"]
        return keywords.contains { text.contains($0) }
    }

    // Creative states
    private static func containsCreativeKeywords(_ text: String) -> Bool {
        let keywords = ["create", "imagine", "design", "art", "story", "idea", "invent", "dream", "build"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsInspiredKeywords(_ text: String) -> Bool {
        let keywords = ["inspired", "brilliant", "breakthrough", "eureka", "aha", "lightbulb", "insight", "epiphany", "wow"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsPlayfulKeywords(_ text: String) -> Bool {
        let keywords = ["fun", "play", "joke", "funny", "lol", "haha", "😄", "🎉", "surprise", "amusing"]
        return keywords.contains { text.contains($0) }
    }

    // Energy states
    private static func containsEnergeticKeywords(_ text: String) -> Bool {
        let keywords = ["energetic", "dynamic", "active", "vigorous", "lively", "go go go", "let's do it"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsExcitedKeywords(_ text: String) -> Bool {
        let keywords = ["excited", "amazing", "awesome", "incredible", "yes!!!", "yay", "fantastic", "let's go", "!!!"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsDeterminedKeywords(_ text: String) -> Bool {
        let keywords = ["determined", "will", "must", "commit", "persistence", "driven", "resolve", "push through"]
        return keywords.contains { text.contains($0) }
    }

    // Emotional states
    private static func containsConfidentKeywords(_ text: String) -> Bool {
        let keywords = ["confident", "sure", "certain", "definitely", "absolutely", "strong", "assured", "know"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsUncertainKeywords(_ text: String) -> Bool {
        let keywords = ["uncertain", "maybe", "not sure", "don't know", "confused", "unclear", "hesitant", "doubt"]
        return keywords.contains { text.contains($0) }
    }

    private static func containsMelancholicKeywords(_ text: String) -> Bool {
        let keywords = ["melancholic", "sad", "sorrow", "wistful", "longing", "miss", "nostalgic", "bittersweet"]
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
