import Combine
import Foundation

final class AppConfigStore: ObservableObject {
    @Published var modelName: String {
        didSet {
            UserDefaults.standard.set(modelName, forKey: Keys.modelName)
        }
    }

    @Published var apiKey: String {
        didSet {
            KeychainHelper.shared.save(apiKey, service: Keys.keychainService, account: Keys.apiKeyAccount)
        }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
        }
    }

    @Published var selectedMode: ResponseMode {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: Keys.selectedMode)
        }
    }

    private enum Keys {
        static let modelName = "wix.modelName"
        static let hasSeenOnboarding = "wix.hasSeenOnboarding"
        static let selectedMode = "wix.selectedMode"
        static let keychainService = "WIX"
        static let apiKeyAccount = "gemini_api_key"
    }

    init() {
        self.modelName = UserDefaults.standard.string(forKey: Keys.modelName) ?? "gemini-2.5-flash-lite"
        self.apiKey = KeychainHelper.shared.read(service: Keys.keychainService, account: Keys.apiKeyAccount)
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: Keys.hasSeenOnboarding)
        self.selectedMode = ResponseMode(rawValue: UserDefaults.standard.string(forKey: Keys.selectedMode) ?? "instant") ?? .instant
    }

    var hasValidConfiguration: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
