import SwiftUI
import FirebaseAuth

@main
struct NexusCoreIOSApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
        }
    }
}
