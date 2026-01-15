import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Configure your AI provider API keys below. Keys are securely stored in macOS Keychain.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(AIProvider.allCases) { provider in
                    Section(header: Text(provider.displayName)) {
                        if provider.requiresAPIKey {
                            SecureField("API Key", text: binding(for: provider))
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text(provider.setupInstructions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if viewModel.isProviderConfigured(provider) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }

                            HStack {
                                Button("Save") {
                                    viewModel.saveAPIKey(for: provider)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.apiKeys[provider]?.isEmpty ?? true)

                                if viewModel.isProviderConfigured(provider) {
                                    Button("Delete") {
                                        viewModel.deleteAPIKey(for: provider)
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundColor(.red)
                                }

                                Spacer()

                                // Save status indicator
                                if let status = viewModel.saveStatus[provider] {
                                    switch status {
                                    case .saving:
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .scaleEffect(0.7)
                                    case .saved:
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Saved")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    case .error(let message):
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    case .none:
                                        EmptyView()
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(provider.setupInstructions)
                                    .font(.body)

                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("No API key required for local models")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("All API keys are securely stored in macOS Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }

    private func binding(for provider: AIProvider) -> Binding<String> {
        Binding(
            get: { viewModel.apiKeys[provider] ?? "" },
            set: { viewModel.apiKeys[provider] = $0 }
        )
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews
