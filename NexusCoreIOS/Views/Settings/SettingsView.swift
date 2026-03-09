import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authState: AuthState

    @State private var me: AuthUser? = nil
    @State private var selectedBackend: BackendChoice = BackendPreference.shared.current
    @State private var isLoading = true
    @State private var error: String? = nil
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(title: "Settings", showBack: true, onBack: { path.removeLast() })
            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else {
                settingsContent
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await performDeleteAccount() }
            }
        } message: {
            Text("This will permanently delete your profile, and your organization with all its assets if you are the last member. This cannot be undone.")
        }
    }

    private var settingsContent: some View {
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
                accountSection
                backendSection
                Spacer(minLength: 24)
                NexusButton(title: "Sign Out", isOutlined: true) {
                    authState.signOut()
                }
                dangerSection
            }
            .padding(16)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        }
    }

    private var backendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        backendRow(choice)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func backendRow(_ choice: BackendChoice) -> some View {
        Button(action: {
            selectedBackend = choice
            BackendPreference.shared.current = choice
            APIClient.reset()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .stroke(Theme.primary, lineWidth: 2)
                    .background(Circle().fill(selectedBackend == choice ? Theme.primary : Color.clear))
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

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DANGER ZONE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.error)
                .tracking(0.5)
                .padding(.top, 8)
            NexusCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Permanently delete your account. If you are the last member of your organization, the organization and all its assets will also be deleted.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    Button(action: { showDeleteConfirm = true }) {
                        Text("Delete Account")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.error, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.error, lineWidth: 1))
        }
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

    private func performDeleteAccount() async {
        await MainActor.run { isDeletingAccount = true }
        do {
            try await NexusAPI.deleteAccount()
            APIClient.reset()
            authState.signOut()
        } catch {
            print("[Settings] deleteAccount failed: \(error)")
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isDeletingAccount = false
            }
        }
    }
}
