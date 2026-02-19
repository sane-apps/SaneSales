import Foundation
import Security

/// Keychain storage for API keys. Thread-safe, static-only.
struct KeychainService: Sendable {
    static let service = Bundle.main.bundleIdentifier ?? "com.sanesales.app"

    static let lemonSqueezyAPIKey = "lemonsqueezy-api-key"
    static let gumroadAPIKey = "gumroad-api-key"
    static let stripeAPIKey = "stripe-api-key"

    @discardableResult
    static func save(data: Data, account: String) -> Bool {
        if isKeychainBypassed {
            fallbackDefaults.set(data.base64EncodedString(), forKey: fallbackKey(account))
            return true
        }

        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: true
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(account: String) -> Data? {
        if isKeychainBypassed {
            guard let encoded = fallbackDefaults.string(forKey: fallbackKey(account)),
                  let data = Data(base64Encoded: encoded)
            else { return nil }
            return data
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        if isKeychainBypassed {
            fallbackDefaults.removeObject(forKey: fallbackKey(account))
            return true
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func exists(account: String) -> Bool {
        load(account: account) != nil
    }

    // MARK: - String Convenience

    @discardableResult
    static func save(string: String, account: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, account: account)
    }

    static func loadString(account: String) -> String? {
        guard let data = load(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static var isKeychainBypassed: Bool {
#if DEBUG
        let processInfo = ProcessInfo.processInfo
        let forceRealKeychain = processInfo.environment["SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG"] == "1"
        if forceRealKeychain {
            return false
        }

        // Default debug behavior: bypass Keychain to avoid prompts during local simulator/UI testing.
        return true
#else
        // Production builds always use Keychain. No bypass path in App Store/TestFlight binaries.
        return false
#endif
    }

    private static var fallbackDefaults: UserDefaults {
        UserDefaults(suiteName: "com.sanesales.no-keychain") ?? .standard
    }

    private static func fallbackKey(_ account: String) -> String {
        "sane.no-keychain.\(service).\(account)"
    }
}
