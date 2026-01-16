import SwiftUI

/// Universe Theme - Complete visual and behavioral identity for a project
/// Each project exists in its own "universe" with distinct aesthetics and personality
struct UniverseTheme: Codable, Equatable {

    // MARK: - Identity

    let id: UUID
    var name: String
    var description: String?

    // MARK: - Visual Identity

    var colors: UniverseColors
    var particles: ParticleConfiguration
    var effects: VisualEffects
    var typography: TypographyStyle

    // MARK: - Behavioral Identity

    var mood: MoodConfiguration
    var agentPersonality: AgentPersonality
    var surpriseConfig: SurpriseConfiguration

    // MARK: - Metadata

    var createdAt: Date
    var lastModified: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        colors: UniverseColors = .default,
        particles: ParticleConfiguration = .default,
        effects: VisualEffects = .default,
        typography: TypographyStyle = .default,
        mood: MoodConfiguration = .default,
        agentPersonality: AgentPersonality = .default,
        surpriseConfig: SurpriseConfiguration = .default,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.colors = colors
        self.particles = particles
        self.effects = effects
        self.typography = typography
        self.mood = mood
        self.agentPersonality = agentPersonality
        self.surpriseConfig = surpriseConfig
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

// MARK: - Universe Colors

struct UniverseColors: Codable, Equatable {
    var primary: ColorDefinition
    var secondary: ColorDefinition
    var accent: ColorDefinition
    var background: ColorDefinition
    var text: ColorDefinition
    var glow: ColorDefinition

    /// Gradient for background
    var backgroundGradient: [ColorDefinition]

    /// Color for different element types
    var elementColors: ElementColors

    static let `default` = UniverseColors(
        primary: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0),
        secondary: ColorDefinition(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
        accent: ColorDefinition(red: 0.4, green: 0.8, blue: 0.6, alpha: 1.0),
        background: ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
        text: ColorDefinition(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9),
        glow: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.5),
        backgroundGradient: [
            ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ColorDefinition(red: 0.05, green: 0.02, blue: 0.08, alpha: 1.0)
        ],
        elementColors: .default
    )
}

struct ElementColors: Codable, Equatable {
    var userMessage: ColorDefinition
    var aiMessage: ColorDefinition
    var systemMessage: ColorDefinition
    var errorMessage: ColorDefinition
    var warningMessage: ColorDefinition

    static let `default` = ElementColors(
        userMessage: ColorDefinition(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9),
        aiMessage: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.9),
        systemMessage: ColorDefinition(red: 0.6, green: 0.6, blue: 0.8, alpha: 0.8),
        errorMessage: ColorDefinition(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.9),
        warningMessage: ColorDefinition(red: 1.0, green: 0.7, blue: 0.2, alpha: 0.9)
    )
}

struct ColorDefinition: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(from color: Color) {
        // Simplified extraction - in production would use cgColor
        self.red = 0.8
        self.green = 0.6
        self.blue = 0.4
        self.alpha = 1.0
    }
}

// MARK: - Particle Configuration

struct ParticleConfiguration: Codable, Equatable {
    var density: ParticleDensity
    var speed: Double  // 0.0 - 2.0
    var size: ParticleSize
    var behavior: ParticleBehavior
    var color: ColorDefinition
    var opacity: Double  // 0.0 - 1.0

    enum ParticleDensity: String, Codable {
        case none, minimal, low, medium, high, intense

        var count: Int {
            switch self {
            case .none: return 0
            case .minimal: return 50
            case .low: return 200
            case .medium: return 500
            case .high: return 1000
            case .intense: return 2000
            }
        }
    }

    enum ParticleSize: String, Codable {
        case tiny, small, medium, large

        var value: Float {
            switch self {
            case .tiny: return 1.0
            case .small: return 2.0
            case .medium: return 4.0
            case .large: return 8.0
            }
        }
    }

    enum ParticleBehavior: String, Codable {
        case floating       // Slow random drift
        case orbiting       // Circle around center
        case flowing        // Directional flow
        case chaotic        // Unpredictable movement
        case reactive       // Respond to cursor
        case pulsing        // Grow/shrink rhythmically
    }

    static let `default` = ParticleConfiguration(
        density: .medium,
        speed: 0.5,
        size: .small,
        behavior: .floating,
        color: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.3),
        opacity: 0.3
    )
}

// MARK: - Visual Effects

struct VisualEffects: Codable, Equatable {
    var blur: BlurConfiguration
    var glow: GlowConfiguration
    var transitions: TransitionStyle
    var breathing: BreathingEffect

    struct BlurConfiguration: Codable, Equatable {
        var enabled: Bool
        var intensity: Double  // 0.0 - 1.0
        var depthBased: Bool
    }

    struct GlowConfiguration: Codable, Equatable {
        var enabled: Bool
        var intensity: Double  // 0.0 - 1.0
        var color: ColorDefinition
        var pulsing: Bool
    }

    enum TransitionStyle: String, Codable {
        case instant
        case fade
        case slide
        case dissolve
        case morph
        case cosmic  // Particle-based transition
    }

    struct BreathingEffect: Codable, Equatable {
        var enabled: Bool
        var speed: Double  // 0.1 - 2.0
        var intensity: Double  // 0.0 - 1.0
    }

    static let `default` = VisualEffects(
        blur: BlurConfiguration(enabled: true, intensity: 0.3, depthBased: true),
        glow: GlowConfiguration(
            enabled: true,
            intensity: 0.5,
            color: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.5),
            pulsing: true
        ),
        transitions: .fade,
        breathing: BreathingEffect(enabled: true, speed: 0.5, intensity: 0.2)
    )
}

// MARK: - Typography Style

struct TypographyStyle: Codable, Equatable {
    var fontFamily: FontFamily
    var fontSize: FontSize
    var weight: FontWeight
    var letterSpacing: Double  // -2.0 to 10.0
    var lineHeight: Double  // 1.0 - 2.0

    enum FontFamily: String, Codable {
        case system
        case monospace
        case rounded
        case serif
    }

    enum FontSize: String, Codable {
        case small, medium, large, extraLarge

        var value: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            case .extraLarge: return 20
            }
        }
    }

    enum FontWeight: String, Codable {
        case ultraLight, light, regular, medium, semibold, bold

        var swiftUIWeight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }

    static let `default` = TypographyStyle(
        fontFamily: .system,
        fontSize: .medium,
        weight: .light,
        letterSpacing: 0.5,
        lineHeight: 1.5
    )
}

// MARK: - Mood Configuration

struct MoodConfiguration: Codable, Equatable {
    var defaultMood: String  // Reference to MoodState
    var moodSensitivity: Double  // 0.0 - 1.0, how quickly mood changes
    var allowedMoods: [String]  // Which moods this universe can enter
    var moodColors: [String: ColorDefinition]  // Mood name -> color override

    static let `default` = MoodConfiguration(
        defaultMood: "calm",
        moodSensitivity: 0.5,
        allowedMoods: ["dormant", "focused", "creative", "analytical", "playful", "calm"],
        moodColors: [:]
    )
}

// MARK: - Agent Personality

struct AgentPersonality: Codable, Equatable {
    var tone: Tone
    var verbosity: Verbosity
    var formality: Formality
    var humor: HumorLevel
    var creativity: Double  // 0.0 - 1.0
    var proactiveness: Double  // 0.0 - 1.0

    enum Tone: String, Codable {
        case professional, friendly, playful, serious, inspiring, mysterious
    }

    enum Verbosity: String, Codable {
        case concise, balanced, detailed, verbose
    }

    enum Formality: String, Codable {
        case casual, balanced, formal, academic
    }

    enum HumorLevel: String, Codable {
        case none, subtle, moderate, frequent
    }

    static let `default` = AgentPersonality(
        tone: .friendly,
        verbosity: .balanced,
        formality: .balanced,
        humor: .subtle,
        creativity: 0.7,
        proactiveness: 0.5
    )
}

// MARK: - Surprise Configuration

struct SurpriseConfiguration: Codable, Equatable {
    var enabled: Bool
    var frequency: SurpriseFrequency
    var types: [SurpriseType]
    var intensity: Double  // 0.0 - 1.0

    enum SurpriseFrequency: String, Codable {
        case rare, occasional, frequent, constant

        var probability: Double {
            switch self {
            case .rare: return 0.05
            case .occasional: return 0.15
            case .frequent: return 0.30
            case .constant: return 0.50
            }
        }
    }

    enum SurpriseType: String, Codable {
        case visualEffect     // Unexpected visual moment
        case particleBurst    // Particle explosion
        case colorShift       // Sudden color change
        case message          // Surprise message from Mr.V
        case animation        // Special animation
        case soundEffect      // Audio surprise (future)
        case achievement      // Milestone celebration
    }

    static let `default` = SurpriseConfiguration(
        enabled: true,
        frequency: .occasional,
        types: [.visualEffect, .particleBurst, .colorShift],
        intensity: 0.5
    )
}

// MARK: - Preset Themes

extension UniverseTheme {

    /// Predefined universe themes
    static let presets: [UniverseTheme] = [
        .void,
        .cosmos,
        .forest,
        .ocean,
        .fire,
        .crystal,
        .shadow,
        .neon
    ]

    /// The Void - Default minimal theme
    static let void = UniverseTheme(
        name: "The Void",
        description: "Minimal, abstract, infinite black",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0),
            secondary: ColorDefinition(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
            accent: ColorDefinition(red: 0.4, green: 0.8, blue: 0.6, alpha: 1.0),
            background: ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
            text: ColorDefinition(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9),
            glow: ColorDefinition(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.3),
            backgroundGradient: [
                ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .minimal,
            speed: 0.3,
            size: .tiny,
            behavior: .floating,
            color: ColorDefinition(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2),
            opacity: 0.2
        )
    )

    /// Cosmos - Deep space theme
    static let cosmos = UniverseTheme(
        name: "Cosmos",
        description: "Deep space with stars and nebulae",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),
            secondary: ColorDefinition(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0),
            accent: ColorDefinition(red: 0.4, green: 1.0, blue: 0.8, alpha: 1.0),
            background: ColorDefinition(red: 0.02, green: 0.01, blue: 0.05, alpha: 1.0),
            text: ColorDefinition(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9),
            glow: ColorDefinition(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.4),
            backgroundGradient: [
                ColorDefinition(red: 0.02, green: 0.01, blue: 0.05, alpha: 1.0),
                ColorDefinition(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .high,
            speed: 0.2,
            size: .tiny,
            behavior: .floating,
            color: ColorDefinition(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6),
            opacity: 0.6
        )
    )

    /// Forest - Natural green theme
    static let forest = UniverseTheme(
        name: "Forest",
        description: "Deep forest with organic energy",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0),
            secondary: ColorDefinition(red: 0.4, green: 0.6, blue: 0.2, alpha: 1.0),
            accent: ColorDefinition(red: 0.8, green: 0.9, blue: 0.3, alpha: 1.0),
            background: ColorDefinition(red: 0.02, green: 0.05, blue: 0.02, alpha: 1.0),
            text: ColorDefinition(red: 0.9, green: 1.0, blue: 0.9, alpha: 0.9),
            glow: ColorDefinition(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.3),
            backgroundGradient: [
                ColorDefinition(red: 0.02, green: 0.05, blue: 0.02, alpha: 1.0),
                ColorDefinition(red: 0.05, green: 0.12, blue: 0.05, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .medium,
            speed: 0.4,
            size: .small,
            behavior: .floating,
            color: ColorDefinition(red: 0.4, green: 1.0, blue: 0.5, alpha: 0.4),
            opacity: 0.4
        )
    )

    /// Ocean - Deep water theme
    static let ocean = UniverseTheme(
        name: "Ocean",
        description: "Deep ocean with flowing currents",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0),
            secondary: ColorDefinition(red: 0.1, green: 0.4, blue: 0.7, alpha: 1.0),
            accent: ColorDefinition(red: 0.3, green: 0.9, blue: 1.0, alpha: 1.0),
            background: ColorDefinition(red: 0.01, green: 0.03, blue: 0.06, alpha: 1.0),
            text: ColorDefinition(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9),
            glow: ColorDefinition(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.4),
            backgroundGradient: [
                ColorDefinition(red: 0.01, green: 0.03, blue: 0.06, alpha: 1.0),
                ColorDefinition(red: 0.03, green: 0.08, blue: 0.15, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .high,
            speed: 0.6,
            size: .medium,
            behavior: .flowing,
            color: ColorDefinition(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.3),
            opacity: 0.3
        )
    )

    /// Fire - Intense warm theme
    static let fire = UniverseTheme(
        name: "Fire",
        description: "Intense energy and warmth",
        colors: UniverseColors(
            primary: ColorDefinition(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0),
            secondary: ColorDefinition(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
            accent: ColorDefinition(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0),
            background: ColorDefinition(red: 0.05, green: 0.01, blue: 0.0, alpha: 1.0),
            text: ColorDefinition(red: 1.0, green: 0.95, blue: 0.9, alpha: 0.9),
            glow: ColorDefinition(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.5),
            backgroundGradient: [
                ColorDefinition(red: 0.05, green: 0.01, blue: 0.0, alpha: 1.0),
                ColorDefinition(red: 0.15, green: 0.05, blue: 0.0, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .high,
            speed: 1.0,
            size: .medium,
            behavior: .chaotic,
            color: ColorDefinition(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.5),
            opacity: 0.5
        )
    )

    /// Crystal - Sharp, geometric theme
    static let crystal = UniverseTheme(
        name: "Crystal",
        description: "Crystalline precision and clarity",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
            secondary: ColorDefinition(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0),
            accent: ColorDefinition(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0),
            background: ColorDefinition(red: 0.01, green: 0.02, blue: 0.04, alpha: 1.0),
            text: ColorDefinition(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.95),
            glow: ColorDefinition(red: 0.6, green: 0.9, blue: 1.0, alpha: 0.6),
            backgroundGradient: [
                ColorDefinition(red: 0.01, green: 0.02, blue: 0.04, alpha: 1.0),
                ColorDefinition(red: 0.05, green: 0.08, blue: 0.12, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .medium,
            speed: 0.3,
            size: .small,
            behavior: .orbiting,
            color: ColorDefinition(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.7),
            opacity: 0.7
        )
    )

    /// Shadow - Dark, mysterious theme
    static let shadow = UniverseTheme(
        name: "Shadow",
        description: "Dark mystery and subtle power",
        colors: UniverseColors(
            primary: ColorDefinition(red: 0.6, green: 0.5, blue: 0.7, alpha: 1.0),
            secondary: ColorDefinition(red: 0.4, green: 0.3, blue: 0.5, alpha: 1.0),
            accent: ColorDefinition(red: 0.8, green: 0.6, blue: 0.9, alpha: 1.0),
            background: ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
            text: ColorDefinition(red: 0.85, green: 0.8, blue: 0.9, alpha: 0.85),
            glow: ColorDefinition(red: 0.6, green: 0.4, blue: 0.8, alpha: 0.3),
            backgroundGradient: [
                ColorDefinition(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
                ColorDefinition(red: 0.02, green: 0.01, blue: 0.03, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .low,
            speed: 0.2,
            size: .tiny,
            behavior: .floating,
            color: ColorDefinition(red: 0.7, green: 0.5, blue: 0.8, alpha: 0.25),
            opacity: 0.25
        )
    )

    /// Neon - Vibrant cyberpunk theme
    static let neon = UniverseTheme(
        name: "Neon",
        description: "Electric cyberpunk energy",
        colors: UniverseColors(
            primary: ColorDefinition(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),
            secondary: ColorDefinition(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),
            accent: ColorDefinition(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
            background: ColorDefinition(red: 0.0, green: 0.0, blue: 0.05, alpha: 1.0),
            text: ColorDefinition(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            glow: ColorDefinition(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.8),
            backgroundGradient: [
                ColorDefinition(red: 0.0, green: 0.0, blue: 0.05, alpha: 1.0),
                ColorDefinition(red: 0.05, green: 0.0, blue: 0.1, alpha: 1.0)
            ],
            elementColors: .default
        ),
        particles: ParticleConfiguration(
            density: .intense,
            speed: 1.2,
            size: .small,
            behavior: .reactive,
            color: ColorDefinition(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.6),
            opacity: 0.6
        )
    )
}
