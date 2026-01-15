import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var saveStatus: [AIProvider: SaveStatus] = [:]

    private let keychainService = KeychainService.shared

    enum SaveStatus {
        case none
        case saving
        case saved
        case error(String)
    }

    init() {
        loadAPIKeys()
    }

    func loadAPIKeys() {
        for provider in AIProvider.allCases {
            if let key = keychainService.getAPIKey(for: provider.rawValue) {
                apiKeys[provider] = key
            }
        }
    }

    func saveAPIKey(for provider: AIProvider) {
        saveStatus[provider] = .saving

        guard let key = apiKeys[provider], !key.isEmpty else {
            saveStatus[provider] = .error("API key cannot be empty")
            return
        }

        // Basic validation
        if !isValidAPIKey(key, for: provider) {
            saveStatus[provider] = .error("Invalid API key format")
            return
        }

        do {
            try keychainService.saveAPIKey(key, for: provider.rawValue)
            saveStatus[provider] = .saved

            // Reset status after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                saveStatus[provider] = SaveStatus.none
            }
        } catch {
            saveStatus[provider] = .error(error.localizedDescription)
        }
    }

    func deleteAPIKey(for provider: AIProvider) {
        do {
            try keychainService.deleteAPIKey(for: provider.rawValue)
            apiKeys[provider] = nil
            saveStatus[provider] = SaveStatus.none
        } catch {
            saveStatus[provider] = .error(error.localizedDescription)
        }
    }

    func isProviderConfigured(_ provider: AIProvider) -> Bool {
        if !provider.requiresAPIKey {
            return true
        }
        return keychainService.apiKeyExists(for: provider.rawValue)
    }

    private func isValidAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        // Basic format validation
        switch provider {
        case .claude:
            return key.hasPrefix("sk-ant-")
        case .openAI:
            return key.hasPrefix("sk-")
        case .perplexity:
            return key.hasPrefix("pplx-")
        case .ollama:
            return true // No API key needed
        }
    }
}
