import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var passwordExists = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let authService = AuthenticationService.shared

    init() {
        checkPasswordExists()
    }

    func checkPasswordExists() {
        passwordExists = authService.passwordExists()
    }

    func setPassword(_ password: String) {
        isLoading = true
        errorMessage = nil

        do {
            try authService.setPassword(password)
            passwordExists = true
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func login(password: String) {
        isLoading = true
        errorMessage = nil

        do {
            let success = try authService.authenticate(password: password)
            if success {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid password"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        isAuthenticated = false
    }
}
