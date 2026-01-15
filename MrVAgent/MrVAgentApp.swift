import SwiftUI

@main
struct MrVAgentApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var fluidReality = FluidRealityEngine()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    VoidView()
                        .environmentObject(fluidReality)
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
                    // Settings will be opened via toolbar button in MainView
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
