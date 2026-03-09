import SwiftUI

struct MainNavigationView: View {
    @State private var path = NavigationPath()
    @EnvironmentObject var authState: AuthState

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .assets:
                        AssetsView(path: $path)
                    case .assetDetail(let id):
                        AssetDetailView(assetId: id, path: $path)
                    case .team:
                        TeamView()
                    case .reports:
                        ReportsView()
                    case .events:
                        EventsView()
                    case .settings:
                        SettingsView(path: $path)
                    }
                }
        }
        .navigationBarHidden(true)
    }
}

enum AppRoute: Hashable {
    case assets
    case assetDetail(String?)
    case team
    case reports
    case events
    case settings
}
