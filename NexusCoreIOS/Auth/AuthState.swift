import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthState: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = true

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isSignedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        APIClient.reset()
    }
}
