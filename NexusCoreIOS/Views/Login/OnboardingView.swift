import SwiftUI

struct OnboardingView: View {
    @State private var displayName = ""
    @State private var orgName = ""
    @State private var orgSlug = ""
    @State private var slugEdited = false
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var navigateToPending = false

    private var slugValid: Bool {
        orgSlug.count >= 3 && orgSlug.range(of: "^[a-z0-9-]+$", options: .regularExpression) != nil
    }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !orgName.trimmingCharacters(in: .whitespaces).isEmpty &&
        slugValid
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            Text("Create your organization")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 32)

            VStack(spacing: 16) {
                TextField("Your name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)

                TextField("Organization name", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: orgName) { newValue in
                        if !slugEdited {
                            orgSlug = slugify(newValue)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Organization slug", text: $orgSlug)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: orgSlug) { newValue in
                            slugEdited = true
                            let filtered = newValue.lowercased()
                                .filter { $0.isLetter || $0.isNumber || $0 == "-" }
                            if filtered != newValue { orgSlug = filtered }
                        }
                    Text("Lowercase letters, numbers, and hyphens only (min 3 chars)")
                        .font(.system(size: 11))
                        .foregroundColor(orgSlug.isEmpty || slugValid ? Theme.textSecondary : Theme.error)
                }

                if isLoading {
                    ProgressView().scaleEffect(1.3)
                } else {
                    NexusButton(title: "Create Organization") {
                        handleRegister()
                    }
                    .opacity(canSubmit ? 1 : 0.5)
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

    private func slugify(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func handleRegister() {
        guard canSubmit else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let req = RegisterRequest(
                    organizationName: orgName.trimmingCharacters(in: .whitespaces),
                    organizationSlug: orgSlug.trimmingCharacters(in: .whitespaces),
                    displayName: displayName.trimmingCharacters(in: .whitespaces).isEmpty
                        ? nil
                        : displayName.trimmingCharacters(in: .whitespaces)
                )
                try await NexusAPI.register(req)
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
