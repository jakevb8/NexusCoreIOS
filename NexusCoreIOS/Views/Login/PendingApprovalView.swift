import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Pending Approval")
                .font(.system(size: 24, weight: .bold))

            Text("Your organization is pending approval. You'll be notified once an administrator reviews your request.")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NexusButton(title: "Sign Out", action: { authState.signOut() }, isOutlined: true)
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
