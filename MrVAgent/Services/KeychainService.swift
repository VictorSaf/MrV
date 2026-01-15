import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case invalidData
    case unhandledError(status: OSStatus)
}

class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.vict0r.MrVAgent"

    private init() {}

    // MARK: - Password Management

    func savePassword(_ password: String, for account: String) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Try to delete existing item first
        try? deletePassword(for: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func getPassword(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return password
    }

    func deletePassword(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func passwordExists(for account: String) -> Bool {
        do {
            _ = try getPassword(for: account)
            return true
        } catch {
            return false
        }
    }

    // MARK: - API Key Management

    func saveAPIKey(_ key: String, for provider: String) throws {
        let account = "apikey_\(provider)"
        try savePassword(key, for: account)
    }

    func getAPIKey(for provider: String) -> String? {
        let account = "apikey_\(provider)"
        return try? getPassword(for: account)
    }

    func deleteAPIKey(for provider: String) throws {
        let account = "apikey_\(provider)"
        try deletePassword(for: account)
    }

    func apiKeyExists(for provider: String) -> Bool {
        let account = "apikey_\(provider)"
        return passwordExists(for: account)
    }
}
