import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct NexusCoreIOSApp: App {
    @StateObject private var authState = AuthState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
        }
    }
}
