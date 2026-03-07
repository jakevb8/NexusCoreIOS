import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct LoginView: View {
    @State private var selectedBackend: BackendChoice = BackendPreference.shared.current
    @State private var isLoading = false
    @State private var error: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 80)

                Text("NexusCore")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.primary)

                Text("Resource Management")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 4)

                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Backend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.onBackground)

                    HStack(spacing: 8) {
                        ForEach(BackendChoice.allCases, id: \.self) { choice in
                            Button(action: {
                                selectedBackend = choice
                                BackendPreference.shared.current = choice
                                APIClient.reset()
                            }) {
                                Text(choice.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(selectedBackend == choice ? Theme.onPrimary : Theme.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedBackend == choice ? Theme.primary : Color.clear)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Theme.primary, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

                Spacer(minLength: 32)

                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.3)
                    } else {
                        NexusButton(title: "Sign in with Google") {
                            handleGoogleSignIn()
                        }
                        .padding(.horizontal, 32)
                    }

                    if let error {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer(minLength: 60)
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func handleGoogleSignIn() {
        isLoading = true
        error = nil
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            error = "Cannot find root view controller"
            isLoading = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, signInError in
            if let signInError {
                error = signInError.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                error = "No ID token returned"
                isLoading = false
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, authError in
                if let authError {
                    error = authError.localizedDescription
                    isLoading = false
                    return
                }
                // Auth state listener in AuthState will handle navigation
                isLoading = false
            }
        }
    }
}
