import SwiftUI

struct MainView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            // Sidebar with model selector
            ModelSelectorView(chatViewModel: chatViewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            // Main chat area
            ChatView(viewModel: chatViewModel)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showSettings = true
                }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 500, idealWidth: 640, maxWidth: .infinity,
                       minHeight: 400, idealHeight: 480, maxHeight: .infinity)
        }
    }
}

// MARK: - Environment Key for ChatViewModel

private struct ChatViewModelKey: EnvironmentKey {
    static let defaultValue: ChatViewModel? = nil
}

extension EnvironmentValues {
    var chatViewModel: ChatViewModel? {
        get { self[ChatViewModelKey.self] }
        set { self[ChatViewModelKey.self] = newValue }
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews

