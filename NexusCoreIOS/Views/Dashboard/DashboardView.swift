import SwiftUI

struct DashboardView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authState: AuthState

    private let navItems: [(title: String, description: String, route: AppRoute)] = [
        ("Assets", "Manage your organization's assets", .assets),
        ("Team", "Manage members and invitations", .team),
        ("Reports", "View utilization analytics", .reports),
        ("Events", "Browse Kafka asset status change history", .events),
        ("Settings", "Backend and account settings", .settings),
    ]

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(title: "Dashboard")

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(navItems, id: \.title) { item in
                        Button(action: { path.append(item.route) }) {
                            NexusCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Theme.onBackground)
                                    Text(item.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
