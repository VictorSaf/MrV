import SwiftUI

struct ModelSelectorView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Provider")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            Divider()

            List(AIProvider.allCases, selection: $chatViewModel.selectedProvider) { provider in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.displayName)
                            .font(.body)

                        if !provider.requiresAPIKey {
                            Text("Local")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if settingsViewModel.isProviderConfigured(provider) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }

                    if chatViewModel.selectedProvider == provider {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    chatViewModel.changeProvider(to: provider)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(chatViewModel.isServiceConfigured ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(chatViewModel.isServiceConfigured ? "Ready" : "Not configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews
