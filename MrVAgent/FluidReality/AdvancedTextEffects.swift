import Foundation
import SwiftUI

/// Advanced text effects for context-aware rendering
enum TextEffect {
    case wave           // Characters wave in
    case glitch         // Error glitch effect
    case glow           // Highlight glow
    case fadePerWord    // Word-by-word fade
    case code           // Monospace with background
    case question       // Different color for questions
    case list           // Indent with bullet animation
    case emphasis       // Emphasized text

    /// Get animation parameters for effect
    func animationConfig() -> AnimationConfig {
        switch self {
        case .wave:
            return AnimationConfig(duration: 0.5, delay: 0.05, easing: .easeInOut)
        case .glitch:
            return AnimationConfig(duration: 0.2, delay: 0, easing: .linear)
        case .glow:
            return AnimationConfig(duration: 1.0, delay: 0, easing: .easeInOut)
        case .fadePerWord:
            return AnimationConfig(duration: 0.3, delay: 0.1, easing: .easeIn)
        case .code:
            return AnimationConfig(duration: 0.4, delay: 0.02, easing: .easeOut)
        case .question:
            return AnimationConfig(duration: 0.4, delay: 0.03, easing: .easeInOut)
        case .list:
            return AnimationConfig(duration: 0.5, delay: 0.08, easing: .easeOut)
        case .emphasis:
            return AnimationConfig(duration: 0.3, delay: 0, easing: .easeOut)
        }
    }

    struct AnimationConfig {
        var duration: Double
        var delay: Double
        var easing: Animation
    }
}

/// Context-aware text effect selector
struct TextEffectSelector {

    /// Detect appropriate effect based on content
    static func detectEffect(for text: String) -> TextEffect {
        let lowercased = text.lowercased()

        // Error/warning patterns
        if lowercased.contains("error") || lowercased.contains("⚠️") || lowercased.contains("warning") {
            return .glitch
        }

        // Code patterns
        if containsCodePatterns(text) {
            return .code
        }

        // Question patterns
        if lowercased.hasSuffix("?") || lowercased.hasPrefix("how") || lowercased.hasPrefix("what") || lowercased.hasPrefix("why") {
            return .question
        }

        // List patterns
        if isListItem(text) {
            return .list
        }

        // Emphasis patterns
        if containsEmphasisMarkers(text) {
            return .emphasis
        }

        // Default wave effect
        return .wave
    }

    private static func containsCodePatterns(_ text: String) -> Bool {
        let codeMarkers = ["```", "`", "func ", "class ", "let ", "var ", "def ", "import ", "=>", "->"]
        return codeMarkers.contains { text.contains($0) }
    }

    private static func isListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") ||
               (trimmed.count > 2 && trimmed[trimmed.startIndex].isNumber && String(trimmed[trimmed.index(after: trimmed.startIndex)]) == ".")
    }

    private static func containsEmphasisMarkers(_ text: String) -> Bool {
        return text.contains("**") || text.contains("__") || text.contains("*") && text.filter({ $0 == "*" }).count >= 2
    }
}

/// View modifier for applying text effects
struct TextEffectModifier: ViewModifier {
    let effect: TextEffect
    let phase: Double  // Animation phase (0.0 to 1.0)

    func body(content: Content) -> some View {
        switch effect {
        case .wave:
            content
                .offset(y: sin(phase * .pi * 2) * 3)
                .opacity(phase)

        case .glitch:
            content
                .offset(
                    x: phase < 0.5 ? CGFloat.random(in: -2...2) : 0,
                    y: phase < 0.5 ? CGFloat.random(in: -1...1) : 0
                )
                .foregroundColor(phase < 0.3 ? .red : .primary)

        case .glow:
            content
                .shadow(
                    color: .white.opacity(0.5 + sin(phase * .pi * 2) * 0.3),
                    radius: 8 + sin(phase * .pi * 2) * 4
                )

        case .fadePerWord:
            content
                .opacity(phase)

        case .code:
            content
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(4)
                .opacity(phase)

        case .question:
            content
                .foregroundColor(.cyan.opacity(0.8))
                .opacity(phase)

        case .list:
            content
                .padding(.leading, 20)
                .opacity(phase)
                .offset(x: (1 - phase) * 20)

        case .emphasis:
            content
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(1.0 + (1 - phase) * 0.1)
                .opacity(phase)
        }
    }
}

extension View {
    /// Apply text effect with animation phase
    func textEffect(_ effect: TextEffect, phase: Double) -> some View {
        modifier(TextEffectModifier(effect: effect, phase: phase))
    }
}
