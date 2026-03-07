import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @State private var name = ""
    @State private var orgName = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var navigateToPending = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            Text("Create your organization")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 32)

            VStack(spacing: 16) {
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)

                TextField("Organization name", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)

                if isLoading {
                    ProgressView().scaleEffect(1.3)
                } else {
                    NexusButton(title: "Create Organization") {
                        handleRegister()
                    }
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                             orgName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }

                if let error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.error)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $navigateToPending) {
            PendingApprovalView()
        }
    }

    private func handleRegister() {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let token = try await user.getIDToken(forcingRefresh: false)
                let req = RegisterRequest(
                    firebaseToken: token,
                    orgName: orgName.trimmingCharacters(in: .whitespaces),
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: user.email ?? ""
                )
                _ = try await NexusAPI.register(req)
                await MainActor.run { navigateToPending = true }
            } catch {
                await MainActor.run {
                    self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
