import Foundation
import SwiftUI

/// Project memory model
/// Represents a project with its metadata and configuration
struct ProjectMemory: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var createdAt: Date
    var updatedAt: Date
    var status: ProjectStatus
    var metadata: ProjectMetadata
    var color: Color?
    var universeConfig: UniverseConfig?

    enum ProjectStatus: String, Codable {
        case active
        case archived
        case completed
    }

    struct ProjectMetadata: Codable, Equatable {
        var tags: [String] = []
        var category: String?
        var priority: Int = 0  // 0-5
        var estimatedDuration: TimeInterval?
        var actualDuration: TimeInterval?
        var customFields: [String: String] = [:]

        init(
            tags: [String] = [],
            category: String? = nil,
            priority: Int = 0,
            estimatedDuration: TimeInterval? = nil,
            actualDuration: TimeInterval? = nil,
            customFields: [String: String] = [:]
        ) {
            self.tags = tags
            self.category = category
            self.priority = priority
            self.estimatedDuration = estimatedDuration
            self.actualDuration = actualDuration
            self.customFields = customFields
        }
    }

    struct UniverseConfig: Codable, Equatable {
        var primaryColor: String  // Hex color
        var secondaryColor: String  // Hex color
        var particleDensity: Float = 1.0
        var moodPreset: String?  // Mood preset name
        var themePreset: String?  // Theme preset name (void, cosmos, forest, etc.)

        enum CodingKeys: String, CodingKey {
            case primaryColor
            case secondaryColor
            case particleDensity
            case moodPreset
            case themePreset
        }

        // Custom coding for [String: Any]
        init(
            primaryColor: String,
            secondaryColor: String,
            particleDensity: Float = 1.0,
            moodPreset: String? = nil,
            themePreset: String? = nil
        ) {
            self.primaryColor = primaryColor
            self.secondaryColor = secondaryColor
            self.particleDensity = particleDensity
            self.moodPreset = moodPreset
            self.themePreset = themePreset
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            primaryColor = try container.decode(String.self, forKey: .primaryColor)
            secondaryColor = try container.decode(String.self, forKey: .secondaryColor)
            particleDensity = try container.decode(Float.self, forKey: .particleDensity)
            moodPreset = try container.decodeIfPresent(String.self, forKey: .moodPreset)
            themePreset = try container.decodeIfPresent(String.self, forKey: .themePreset)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(primaryColor, forKey: .primaryColor)
            try container.encode(secondaryColor, forKey: .secondaryColor)
            try container.encode(particleDensity, forKey: .particleDensity)
            try container.encodeIfPresent(moodPreset, forKey: .moodPreset)
            try container.encodeIfPresent(themePreset, forKey: .themePreset)
        }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: ProjectStatus = .active,
        metadata: ProjectMetadata = ProjectMetadata(),
        color: Color? = nil,
        universeConfig: UniverseConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.metadata = metadata
        self.color = color
        self.universeConfig = universeConfig
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        status == .active
    }

    var ageInDays: Int {
        let components = Calendar.current.dateComponents([.day], from: createdAt, to: Date())
        return components.day ?? 0
    }

    var daysSinceUpdate: Int {
        let components = Calendar.current.dateComponents([.day], from: updatedAt, to: Date())
        return components.day ?? 0
    }

    // MARK: - Methods

    mutating func update(name: String? = nil, description: String? = nil, status: ProjectStatus? = nil) {
        if let name = name {
            self.name = name
        }
        if let description = description {
            self.description = description
        }
        if let status = status {
            self.status = status
        }
        self.updatedAt = Date()
    }

    mutating func archive() {
        self.status = .archived
        self.updatedAt = Date()
    }

    mutating func complete() {
        self.status = .completed
        self.updatedAt = Date()

        // Record actual duration
        metadata.actualDuration = Date().timeIntervalSince(createdAt)
    }

    mutating func reactivate() {
        self.status = .active
        self.updatedAt = Date()
    }
}

// MARK: - Color Coding Extension
// Note: This extension adds Codable conformance to SwiftUI.Color for serialization

extension Color: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let o = try container.decode(Double.self, forKey: .opacity)
        self.init(red: r, green: g, blue: b, opacity: o)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Extract RGBA components (simplified - may need platform-specific extraction)
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        try container.encode(Double(components[0]), forKey: .red)
        try container.encode(Double(components[1]), forKey: .green)
        try container.encode(Double(components[2]), forKey: .blue)
        try container.encode(Double(components[safe: 3] ?? 1.0), forKey: .opacity)
    }
}

// Safe array access helper
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
