import Foundation

/// Interface mode selection for the application
/// Enables toggling between Standard and Fluid Reality experiences
enum InterfaceMode: String, CaseIterable, Codable {
    /// Standard chat interface with sidebar and traditional UI
    /// - Production-ready
    /// - Proven performance (67% faster with orchestration)
    /// - Familiar UX
    case standard

    /// Experimental Fluid Reality interface
    /// - Abstract, breathing void aesthetic
    /// - Metal-rendered generative background
    /// - Text crystallization effects
    /// - Revolutionary UX (high risk, high differentiation)
    case fluidReality

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .fluidReality:
            return "Fluid Reality"
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "Traditional chat interface with sidebar. Production-ready and battle-tested."
        case .fluidReality:
            return "Experimental abstract interface. Revolutionary UX with breathing void and text crystallization."
        }
    }

    var icon: String {
        switch self {
        case .standard:
            return "bubble.left.and.bubble.right"
        case .fluidReality:
            return "sparkles"
        }
    }

    /// Whether this mode is experimental
    var isExperimental: Bool {
        switch self {
        case .standard:
            return false
        case .fluidReality:
            return true
        }
    }
}

/// Configuration manager for interface mode
@MainActor
final class InterfaceModeManager: ObservableObject {
    /// Current active interface mode
    @Published var currentMode: InterfaceMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "interfaceMode")
            print("🎨 Interface mode changed to: \(currentMode.displayName)")
        }
    }

    /// Whether experimental features are enabled
    @Published var experimentalFeaturesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(experimentalFeaturesEnabled, forKey: "experimentalFeaturesEnabled")
        }
    }

    init() {
        // Load saved mode or default to standard
        if let savedMode = UserDefaults.standard.string(forKey: "interfaceMode"),
           let mode = InterfaceMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }

        // Load experimental features preference
        self.experimentalFeaturesEnabled = UserDefaults.standard.bool(forKey: "experimentalFeaturesEnabled")
    }

    /// Toggle between interface modes
    func toggleMode() {
        switch currentMode {
        case .standard:
            if experimentalFeaturesEnabled {
                currentMode = .fluidReality
            } else {
                print("⚠️ Fluid Reality mode requires experimental features to be enabled")
            }
        case .fluidReality:
            currentMode = .standard
        }
    }

    /// Switch to specific mode
    func switchTo(_ mode: InterfaceMode) {
        if mode.isExperimental && !experimentalFeaturesEnabled {
            print("⚠️ Cannot switch to experimental mode without enabling experimental features")
            return
        }
        currentMode = mode
    }

    /// Enable experimental features and switch to Fluid Reality
    func enableExperimentalMode() {
        experimentalFeaturesEnabled = true
        currentMode = .fluidReality
    }
}
