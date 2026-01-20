import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var password = ""
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: 30) {
            // Logo/Icon area
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            VStack(spacing: 8) {
                Text("Mr.V Agent")
                    .font(.system(size: 32, weight: .bold))

                Text(authViewModel.passwordExists ? "Welcome back, Vict0r" : "Welcome, Vict0r")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                SecureField(
                    authViewModel.passwordExists ? "Enter your password" : "Create a password",
                    text: $password
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .focused($isPasswordFocused)
                .focusable(true)
                .onSubmit {
                    handleSubmit()
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Action button
            Button(action: handleSubmit) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 280)
                } else {
                    Text(authViewModel.passwordExists ? "Login" : "Set Password")
                        .frame(width: 280)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.isEmpty || authViewModel.isLoading)
        }
        .padding(60)
        .frame(width: 500, height: 450)
        .focusable()
        .onAppear {
            // Auto-focus password field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPasswordFocused = true
            }
        }
    }

    private func handleSubmit() {
        if authViewModel.passwordExists {
            authViewModel.login(password: password)
        } else {
            authViewModel.setPassword(password)
        }
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews
