import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authState: AuthState

    @State private var me: AuthUser? = nil
    @State private var selectedBackend: BackendChoice = BackendPreference.shared.current
    @State private var isLoading = true
    @State private var error: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(title: "Settings", showBack: true, onBack: { path.removeLast() })

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let error {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.error)
                                .padding()
                                .background(Theme.errorContainer)
                                .cornerRadius(8)
                        }

                        // Account
                        Text("ACCOUNT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .tracking(0.5)

                        NexusCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(me?.name ?? me?.email ?? "")
                                    .font(.system(size: 16, weight: .semibold))
                                if let email = me?.email {
                                    Text(email)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Text("Role: \(me?.role.rawValue ?? "")")
                                    .font(.system(size: 14))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Backend
                        Text("BACKEND")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .tracking(0.5)

                        NexusCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select which API backend to connect to. Takes effect on next restart.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)

                                ForEach(BackendChoice.allCases, id: \.self) { choice in
                                    Button(action: {
                                        selectedBackend = choice
                                        BackendPreference.shared.current = choice
                                        APIClient.reset()
                                    }) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .stroke(Theme.primary, lineWidth: 2)
                                                .background(
                                                    Circle().fill(selectedBackend == choice ? Theme.primary : Color.clear)
                                                )
                                                .frame(width: 20, height: 20)
                                                .padding(.top, 2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(choice.label)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(Theme.onBackground)
                                                Text(choice.baseURL)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Theme.textSecondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer(minLength: 24)

                        NexusButton(title: "Sign Out", isOutlined: true) {
                            authState.signOut()
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            let meData = try await NexusAPI.getMe()
            await MainActor.run {
                me = meData
                selectedBackend = BackendPreference.shared.current
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}
