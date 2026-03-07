import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        Group {
            if authState.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if authState.isSignedIn {
                MainNavigationView()
            } else {
                LoginView()
            }
        }
    }
}
