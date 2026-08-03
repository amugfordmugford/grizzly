import Foundation
import Observation

/// Holds the TrackBear server URL and API token. The token lives in the
/// Keychain; only the (non-secret) base URL is kept in UserDefaults.
@Observable
final class AppSettingsStore {
    static let defaultBaseURLString = "https://trackbear.app/api/v1"
    private static let tokenKey = "trackbear-api-token"
    private static let baseURLDefaultsKey = "trackbear-base-url"

    var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Self.baseURLDefaultsKey) }
    }

    var apiToken: String {
        didSet { KeychainStore.set(apiToken, for: Self.tokenKey) }
    }

    var isConfigured: Bool {
        !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && baseURL != nil
    }

    var baseURL: URL? {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    init() {
        self.baseURLString = UserDefaults.standard.string(forKey: Self.baseURLDefaultsKey) ?? Self.defaultBaseURLString
        self.apiToken = KeychainStore.get(Self.tokenKey) ?? ""
    }

    func makeClient() -> TrackBearAPIClient? {
        guard let baseURL else { return nil }
        return TrackBearAPIClient(baseURL: baseURL, token: apiToken)
    }

    func clearToken() {
        apiToken = ""
        KeychainStore.remove(Self.tokenKey)
    }
}
