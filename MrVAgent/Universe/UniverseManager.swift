import SwiftUI
import Combine

/// Universe Manager - Orchestrates universe transitions and maintains active universe state
/// Responsible for smooth transitions between project universes
@MainActor
final class UniverseManager: ObservableObject {

    // MARK: - Published State

    @Published var currentUniverse: UniverseTheme
    @Published var isTransitioning: Bool = false
    @Published var transitionProgress: Double = 0.0

    // MARK: - Dependencies

    private weak var fluidReality: FluidRealityEngine?

    // MARK: - Configuration

    private let transitionDuration: TimeInterval = 2.0  // 2 seconds for smooth transitions
    private let surpriseCheckInterval: TimeInterval = 60.0  // Check for surprises every minute

    // MARK: - State

    private var transitionTask: Task<Void, Never>?
    private var surpriseTask: Task<Void, Never>?
    private var lastSurpriseTime: Date = Date()

    // MARK: - Initialization

    init(initialTheme: UniverseTheme = .void, fluidReality: FluidRealityEngine? = nil) {
        self.currentUniverse = initialTheme
        self.fluidReality = fluidReality
    }

    func setFluidReality(_ engine: FluidRealityEngine) {
        self.fluidReality = engine
    }

    // MARK: - Universe Switching

    /// Switch to a new universe with smooth transition
    func switchUniverse(to theme: UniverseTheme, animated: Bool = true) async {
        guard !isTransitioning else {
            print("⚠️ Universe transition already in progress")
            return
        }

        print("🌌 Switching universe: \(currentUniverse.name) → \(theme.name)")

        if animated {
            await performAnimatedTransition(to: theme)
        } else {
            currentUniverse = theme
            await applyUniverseTheme(theme)
        }
    }

    /// Perform animated transition between universes
    private func performAnimatedTransition(to newTheme: UniverseTheme) async {
        isTransitioning = true
        transitionProgress = 0.0

        let oldTheme = currentUniverse

        // Phase 1: Dissolve current universe (0.0 - 0.3)
        await dissolvePhase(oldTheme: oldTheme)

        // Phase 2: Transition void (0.3 - 0.5)
        await voidPhase()

        // Phase 3: Materialize new universe (0.5 - 1.0)
        currentUniverse = newTheme
        await materializePhase(newTheme: newTheme)

        transitionProgress = 1.0
        isTransitioning = false

        print("✅ Universe transition complete: \(newTheme.name)")
    }

    // MARK: - Transition Phases

    /// Phase 1: Dissolve current elements
    private func dissolvePhase(oldTheme: UniverseTheme) async {
        guard let fluidReality = fluidReality else { return }

        print("🌫️  Phase 1: Dissolving \(oldTheme.name)...")

        // Get all active elements
        let elements = fluidReality.activeElements

        // Dissolve based on transition style
        switch oldTheme.effects.transitions {
        case .instant:
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }

        case .fade:
            // Fade out all elements simultaneously
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }
            try? await Task.sleep(nanoseconds: 800_000_000)

        case .slide:
            // Slide elements off screen (future: implement animation)
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }
            try? await Task.sleep(nanoseconds: 800_000_000)

        case .dissolve:
            // Dissolve with particle effect
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)

        case .morph:
            // Morph elements before dissolving
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }
            try? await Task.sleep(nanoseconds: 600_000_000)

        case .cosmic:
            // Particle burst transition
            await triggerParticleBurst(at: CGPoint(x: 640, y: 400))
            for element in elements {
                fluidReality.dissolveElement(element.id)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        transitionProgress = 0.3
    }

    /// Phase 2: Brief void moment
    private func voidPhase() async {
        print("🌀 Phase 2: Void moment...")

        // Brief pause in the void
        try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

        transitionProgress = 0.5
    }

    /// Phase 3: Materialize new universe
    private func materializePhase(newTheme: UniverseTheme) async {
        print("✨ Phase 3: Materializing \(newTheme.name)...")

        // Apply theme to fluid reality
        await applyUniverseTheme(newTheme)

        // Animate appearance based on transition style
        switch newTheme.effects.transitions {
        case .instant:
            break

        case .fade:
            // Fade in effect already handled by crystallization
            try? await Task.sleep(nanoseconds: 800_000_000)

        case .slide:
            // Elements slide in from right
            try? await Task.sleep(nanoseconds: 800_000_000)

        case .dissolve:
            // Crystallize effect already handles this
            try? await Task.sleep(nanoseconds: 1_000_000_000)

        case .morph:
            // Morph in from void
            try? await Task.sleep(nanoseconds: 600_000_000)

        case .cosmic:
            // Particle formation
            await triggerParticleBurst(at: CGPoint(x: 640, y: 400))
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        transitionProgress = 1.0
    }

    // MARK: - Theme Application

    /// Apply universe theme to the fluid reality system
    private func applyUniverseTheme(_ theme: UniverseTheme) async {
        guard let fluidReality = fluidReality else { return }

        print("🎨 Applying universe theme: \(theme.name)")

        // Apply theme to FluidRealityEngine
        fluidReality.applyUniverseTheme(theme)

        // Update particle system
        await updateParticleSystem(with: theme.particles)

        // Update mood system
        await updateMoodSystem(with: theme.mood)

        // Apply visual effects
        await applyVisualEffects(theme.effects)
    }

    // MARK: - Subsystem Updates

    private func updateParticleSystem(with config: ParticleConfiguration) async {
        guard let fluidReality = fluidReality else { return }

        print("💫 Updating particle system: \(config.density.rawValue), \(config.behavior.rawValue)")

        // Update particle configuration in fluid reality
        // This would call into FluidRealityEngine's particle system
        // For now, just log the change
    }

    private func updateMoodSystem(with config: MoodConfiguration) async {
        guard let fluidReality = fluidReality else { return }

        print("🎭 Updating mood configuration: default=\(config.defaultMood)")

        // Set default mood (future: implement mood transition)
        // if let moodState = MoodState(rawValue: config.defaultMood) {
        //     fluidReality.moodManager.transition(to: moodState)
        // }
    }

    private func applyVisualEffects(_ effects: VisualEffects) async {
        guard let fluidReality = fluidReality else { return }

        print("✨ Applying visual effects: blur=\(effects.blur.enabled), glow=\(effects.glow.enabled)")

        // Apply effects to fluid reality
        // This would update shader parameters, blur settings, etc.
        // For now, configuration is stored for use
    }

    // MARK: - Surprise Engine

    /// Start the surprise engine
    func startSurpriseEngine() {
        guard surpriseTask == nil else {
            print("⚠️ Surprise engine already running")
            return
        }

        print("🎉 Starting surprise engine...")

        surpriseTask = Task {
            while !Task.isCancelled {
                // Wait for interval
                try? await Task.sleep(nanoseconds: UInt64(surpriseCheckInterval * 1_000_000_000))

                // Check if we should trigger a surprise
                await checkForSurprise()
            }
        }
    }

    /// Stop the surprise engine
    func stopSurpriseEngine() {
        print("🛑 Stopping surprise engine...")
        surpriseTask?.cancel()
        surpriseTask = nil
    }

    /// Check if a surprise should be triggered
    private func checkForSurprise() async {
        guard currentUniverse.surpriseConfig.enabled else { return }

        // Calculate time since last surprise
        let timeSinceLastSurprise = Date().timeIntervalSince(lastSurpriseTime)
        guard timeSinceLastSurprise > 120 else { return }  // At least 2 minutes between surprises

        // Random chance based on frequency
        let roll = Double.random(in: 0...1)
        guard roll < currentUniverse.surpriseConfig.frequency.probability else { return }

        // Trigger random surprise type
        if let surpriseType = currentUniverse.surpriseConfig.types.randomElement() {
            await triggerSurprise(type: surpriseType)
            lastSurpriseTime = Date()
        }
    }

    /// Trigger a specific surprise
    func triggerSurprise(type: SurpriseConfiguration.SurpriseType) async {
        print("🎉 Triggering surprise: \(type.rawValue)")

        switch type {
        case .visualEffect:
            await triggerVisualSurprise()

        case .particleBurst:
            await triggerParticleBurst(at: randomPosition())

        case .colorShift:
            await triggerColorShift()

        case .message:
            await triggerSurpriseMessage()

        case .animation:
            await triggerSpecialAnimation()

        case .soundEffect:
            // Future: Play sound effect
            print("🔊 Sound effect (not yet implemented)")

        case .achievement:
            await triggerAchievement()
        }
    }

    // MARK: - Surprise Types

    private func triggerVisualSurprise() async {
        guard let fluidReality = fluidReality else { return }

        // Brief flash of light using emoji
        let flashElement = FluidElement(
            type: .text("✨"),
            position: FluidElement.FluidPosition(
                x: 640, y: 400, z: 0,
                opacity: 1.0, scale: 3.0, rotation: 0
            ),
            content: .text("✨"),
            style: FluidElement.ElementStyle(
                font: .system(size: 48),
                foregroundColor: currentUniverse.colors.accent.color,
                glowIntensity: 1.0
            )
        )

        fluidReality.materializeElementWithCrystallization(flashElement)

        try? await Task.sleep(nanoseconds: 500_000_000)

        fluidReality.dissolveElement(flashElement.id)
    }

    private func triggerParticleBurst(at position: CGPoint) async {
        // Trigger particle system burst at position
        print("💥 Particle burst at (\(position.x), \(position.y))")
        // This would call into particle system
    }

    private func triggerColorShift() async {
        print("🌈 Color shift effect")

        // Future: Temporarily shift background color via shader uniforms
        // For now, just a brief pause to simulate the effect
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private func triggerSurpriseMessage() async {
        guard let fluidReality = fluidReality else { return }

        let messages = [
            "✨ Still here?",
            "💫 You're doing great",
            "🌟 Something magical just happened",
            "🎯 Focus is key",
            "🚀 Keep going",
            "🌌 The void sees all",
            "⚡️ Energy shift detected",
            "🎨 Creative flow active"
        ]

        guard let message = messages.randomElement() else { return }

        let messageElement = FluidElement(
            type: .text(message),
            position: FluidElement.FluidPosition(
                x: 640, y: 100, z: 0,
                opacity: 0, scale: 1.0, rotation: 0
            ),
            content: .text(message),
            style: FluidElement.ElementStyle(
                font: .system(size: 18, weight: .light),
                foregroundColor: currentUniverse.colors.accent.color,
                glowIntensity: 0.8
            )
        )

        fluidReality.materializeElementWithCrystallization(messageElement)

        // Keep for 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)

        fluidReality.dissolveElement(messageElement.id)
    }

    private func triggerSpecialAnimation() async {
        print("🎬 Special animation (to be implemented)")
        // Future: Complex animation sequences
    }

    private func triggerAchievement() async {
        print("🏆 Achievement unlocked!")
        // Future: Achievement system
    }

    // MARK: - Utilities

    private func randomPosition() -> CGPoint {
        CGPoint(
            x: Double.random(in: 100...1180),
            y: Double.random(in: 100...700)
        )
    }

    // MARK: - Preset Management

    /// Get a preset theme by name
    static func getPreset(named name: String) -> UniverseTheme? {
        return UniverseTheme.presets.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get all available preset names
    static var availablePresets: [String] {
        return UniverseTheme.presets.map { $0.name }
    }
}
