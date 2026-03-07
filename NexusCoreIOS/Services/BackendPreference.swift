import Foundation

class BackendPreference {
    static let shared = BackendPreference()
    private let key = "selected_backend"

    var current: BackendChoice {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let choice = BackendChoice(rawValue: raw) else {
                return .js
            }
            return choice
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
