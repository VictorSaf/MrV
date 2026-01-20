import Foundation
import SwiftUI

/// Manages settings visibility state across the application
/// Follows the project's environment object pattern for cross-view communication
@MainActor
final class SettingsManager: ObservableObject {
    /// Controls whether the settings sheet is visible
    @Published var showSettings = false

    /// Open the settings sheet
    func openSettings() {
        showSettings = true
    }

    /// Close the settings sheet
    func closeSettings() {
        showSettings = false
    }
}
