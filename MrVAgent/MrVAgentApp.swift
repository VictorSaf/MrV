import SwiftUI

@main
struct MrVAgentApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var fluidReality = FluidRealityEngine()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    VoidView()
                        .environmentObject(fluidReality)
                        .environmentObject(settingsManager)
                } else {
                    AuthenticationView()
                        .environmentObject(authViewModel)
                }
            }
            .frame(minWidth: 1280, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove "New Window" command
            CommandGroup(replacing: .newItem) {}

            // Add custom commands
            CommandGroup(after: .appInfo) {
                Divider()

                Button("Settings...") {
                    settingsManager.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("Run System Tests") {
                    Task { @MainActor in
                        await runMultiAgentTests()
                    }
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
    }
}
