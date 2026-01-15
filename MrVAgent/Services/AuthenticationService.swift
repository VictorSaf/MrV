import Foundation

class AuthenticationService {
    static let shared = AuthenticationService()

    private let keychainService = KeychainService.shared
    private let accountName = "Vict0r"

    private init() {}

    // Check if password has been set (first-time setup)
    func passwordExists() -> Bool {
        return keychainService.passwordExists(for: accountName)
    }

    // Set password for first-time setup
    func setPassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }

        guard password.count >= 6 else {
            throw AuthenticationError.passwordTooShort
        }

        try keychainService.savePassword(password, for: accountName)
    }

    // Authenticate user with password
    func authenticate(password: String) throws -> Bool {
        guard !password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }

        do {
            let storedPassword = try keychainService.getPassword(for: accountName)
            return storedPassword == password
        } catch KeychainError.itemNotFound {
            throw AuthenticationError.passwordNotSet
        } catch {
            throw AuthenticationError.keychainError(error)
        }
    }

    // Reset password (for future use)
    func resetPassword() throws {
        try keychainService.deletePassword(for: accountName)
    }
}

enum AuthenticationError: LocalizedError {
    case emptyPassword
    case passwordTooShort
    case passwordNotSet
    case invalidPassword
    case keychainError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .passwordNotSet:
            return "Password has not been set. Please set up your password first."
        case .invalidPassword:
            return "Invalid password"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        }
    }
}
