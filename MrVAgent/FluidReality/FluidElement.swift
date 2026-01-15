import Foundation
import SwiftUI

/// Represents a single fluid element in the reality system
/// Elements can be text, symbols, particles, or interface components
struct FluidElement: Identifiable, Equatable {
    let id: UUID
    var type: ElementType
    var position: FluidPosition
    var lifecycle: LifecycleState
    var content: ElementContent
    var style: ElementStyle

    init(
        id: UUID = UUID(),
        type: ElementType,
        position: FluidPosition = FluidPosition(),
        lifecycle: LifecycleState = LifecycleState(),
        content: ElementContent,
        style: ElementStyle = ElementStyle()
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.lifecycle = lifecycle
        self.content = content
        self.style = style
    }

    // MARK: - Element Type

    enum ElementType: Equatable {
        case text(String)
        case symbol
        case particle
        case interface

        var isText: Bool {
            if case .text = self { return true }
            return false
        }
    }

    // MARK: - Fluid Position

    struct FluidPosition: Equatable {
        var x: CGFloat
        var y: CGFloat
        var z: CGFloat  // depth for blur (0.0 = front, 1.0 = back)
        var opacity: CGFloat
        var scale: CGFloat
        var rotation: CGFloat

        init(
            x: CGFloat = 0,
            y: CGFloat = 0,
            z: CGFloat = 0,
            opacity: CGFloat = 1.0,
            scale: CGFloat = 1.0,
            rotation: CGFloat = 0
        ) {
            self.x = x
            self.y = y
            self.z = z
            self.opacity = opacity
            self.scale = scale
            self.rotation = rotation
        }

        /// Calculate blur radius based on depth
        var blurRadius: CGFloat {
            return z * 10.0  // 0-10 blur range
        }
    }

    // MARK: - Lifecycle State

    struct LifecycleState: Equatable {
        var phase: Phase
        var birthTime: Date
        var age: TimeInterval

        init(
            phase: Phase = .birth,
            birthTime: Date = Date(),
            age: TimeInterval = 0
        ) {
            self.phase = phase
            self.birthTime = birthTime
            self.age = age
        }

        enum Phase: Equatable {
            case birth          // Materializing
            case active         // Fully present
            case dissolving     // Fading away
            case fulfilled      // Purpose complete (special dissolve)
        }

        /// Progress through current phase (0.0 to 1.0)
        var phaseProgress: Double {
            switch phase {
            case .birth:
                return min(age / 1.0, 1.0)  // 1 second birth
            case .active:
                return 0.0  // No progress in active
            case .dissolving, .fulfilled:
                return min(age / 0.8, 1.0)  // 0.8 second dissolve
            }
        }
    }

    // MARK: - Element Content

    enum ElementContent: Equatable {
        case empty
        case text(String)
        case attributedText(AttributedString)
        case symbol(String)  // SF Symbol name
        case custom(String)  // Custom identifier

        var isEmpty: Bool {
            if case .empty = self { return true }
            if case .text(let str) = self, str.isEmpty { return true }
            return false
        }
    }

    // MARK: - Element Style

    struct ElementStyle: Equatable {
        var font: Font
        var foregroundColor: Color
        var glowIntensity: CGFloat
        var particleCount: Int  // For particle effects

        init(
            font: Font = .system(size: 16, weight: .light),
            foregroundColor: Color = .white,
            glowIntensity: CGFloat = 0.0,
            particleCount: Int = 0
        ) {
            self.font = font
            self.foregroundColor = foregroundColor
            self.glowIntensity = glowIntensity
            self.particleCount = particleCount
        }
    }

    // MARK: - Helper Methods

    /// Update element age and lifecycle
    mutating func updateAge(deltaTime: TimeInterval) {
        lifecycle.age += deltaTime

        // Auto-transition from birth to active
        if lifecycle.phase == .birth && lifecycle.phaseProgress >= 1.0 {
            lifecycle.phase = .active
            lifecycle.age = 0
        }

        // Complete dissolve
        if (lifecycle.phase == .dissolving || lifecycle.phase == .fulfilled) && lifecycle.phaseProgress >= 1.0 {
            // Element should be removed by FluidRealityEngine
        }
    }

    /// Begin dissolve animation
    mutating func beginDissolve(fulfilled: Bool = false) {
        lifecycle.phase = fulfilled ? .fulfilled : .dissolving
        lifecycle.age = 0
    }

    /// Calculate current opacity based on lifecycle
    func currentOpacity() -> CGFloat {
        let baseOpacity = position.opacity

        switch lifecycle.phase {
        case .birth:
            return baseOpacity * CGFloat(lifecycle.phaseProgress)
        case .active:
            return baseOpacity
        case .dissolving, .fulfilled:
            return baseOpacity * CGFloat(1.0 - lifecycle.phaseProgress)
        }
    }

    /// Calculate current scale based on lifecycle
    func currentScale() -> CGFloat {
        let baseScale = position.scale

        switch lifecycle.phase {
        case .birth:
            let progress = lifecycle.phaseProgress
            // Ease-out-back effect
            let overshoot = 1.1
            return baseScale * CGFloat(progress * overshoot)
        case .active:
            // Subtle breathing (5% scale variation)
            let breathe = sin(lifecycle.age * 0.5) * 0.025 + 1.0
            return baseScale * CGFloat(breathe)
        case .dissolving:
            return baseScale * CGFloat(1.0 - lifecycle.phaseProgress * 0.3)
        case .fulfilled:
            // Scale up slightly during fulfilled dissolve
            return baseScale * CGFloat(1.0 + lifecycle.phaseProgress * 0.2)
        }
    }

    /// Calculate current blur based on lifecycle and depth
    func currentBlur() -> CGFloat {
        let depthBlur = position.blurRadius

        switch lifecycle.phase {
        case .birth:
            // Start blurred, become sharp
            let birthBlur = 10.0 * (1.0 - lifecycle.phaseProgress)
            return depthBlur + CGFloat(birthBlur)
        case .active:
            return depthBlur
        case .dissolving, .fulfilled:
            // Become blurred as dissolving
            let dissolveBlur = 8.0 * lifecycle.phaseProgress
            return depthBlur + CGFloat(dissolveBlur)
        }
    }
}
