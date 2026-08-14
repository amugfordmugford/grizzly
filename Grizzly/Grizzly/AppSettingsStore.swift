import Foundation
import Observation

/// Holds the TrackBear server URL and API token. The token lives in the
/// Keychain; only the (non-secret) base URL is kept in UserDefaults.
@Observable
final class AppSettingsStore {
    static let defaultBaseURLString = "https://trackbear.app/api/v1"
    private static let tokenKey = "trackbear-api-token"
    private static let baseURLDefaultsKey = "trackbear-base-url"
    private static let demoModeKey = "trackbear-demo-mode"

    var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Self.baseURLDefaultsKey) }
    }

    var apiToken: String {
        didSet { KeychainStore.set(apiToken, for: Self.tokenKey) }
    }

    /// When true, the app runs on canned `DemoData` and never touches the
    /// network. Lets the full feature set be explored without a TrackBear
    /// account (used by App Review, and anyone curious).
    var isDemoMode: Bool {
        didSet { UserDefaults.standard.set(isDemoMode, forKey: Self.demoModeKey) }
    }

    var isConfigured: Bool {
        isDemoMode || (!apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && baseURL != nil)
    }

    var baseURL: URL? {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    init() {
        self.baseURLString = UserDefaults.standard.string(forKey: Self.baseURLDefaultsKey) ?? Self.defaultBaseURLString
        self.apiToken = KeychainStore.get(Self.tokenKey) ?? ""
        self.isDemoMode = UserDefaults.standard.bool(forKey: Self.demoModeKey)
    }

    func makeClient() -> TrackBearAPIClient? {
        guard let baseURL else { return nil }
        return TrackBearAPIClient(baseURL: baseURL, token: apiToken)
    }

    /// Enter Demo Mode. Any real token is left untouched, but Demo Mode takes
    /// precedence until the user exits it.
    func startDemo() {
        isDemoMode = true
    }

    func clearToken() {
        apiToken = ""
        KeychainStore.remove(Self.tokenKey)
        isDemoMode = false
    }
}
