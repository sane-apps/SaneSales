import Foundation
import Security

/// Keychain storage for API keys. Thread-safe, static-only.
struct KeychainService: Sendable {
    static let service = Bundle.main.bundleIdentifier ?? "com.sanesales.app"
    static let legacyFallbackSuiteName = "com.sanesales.no-keychain"

    static let lemonSqueezyAPIKey = "lemonsqueezy-api-key"
    static let gumroadAPIKey = "gumroad-api-key"
    static let stripeAPIKey = "stripe-api-key"

    @discardableResult
    static func save(data: Data, account: String) -> Bool {
        if isKeychainBypassed {
            fallbackDefaults.set(data.base64EncodedString(), forKey: fallbackKey(account))
            legacyFallbackDefaults?.removeObject(forKey: fallbackKey(account))
            return true
        }

        fallbackDefaults.removeObject(forKey: fallbackKey(account))
        legacyFallbackDefaults?.removeObject(forKey: fallbackKey(account))
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
            guard let encoded = fallbackString(forKey: fallbackKey(account)),
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
        if status == errSecSuccess {
            return result as? Data
        }
        return migrateFallbackToKeychainIfNeeded(account: account)
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        if isKeychainBypassed {
            fallbackDefaults.removeObject(forKey: fallbackKey(account))
            legacyFallbackDefaults?.removeObject(forKey: fallbackKey(account))
            return true
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        fallbackDefaults.removeObject(forKey: fallbackKey(account))
        legacyFallbackDefaults?.removeObject(forKey: fallbackKey(account))
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

    static func shouldBypassKeychain(
        environment: [String: String],
        arguments: [String],
        isDebugBuild: Bool = buildIsDebug
    ) -> Bool {
        if environment["SANEAPPS_DISABLE_KEYCHAIN"] == "1" || arguments.contains("--sane-no-keychain") {
            return true
        }

        guard isDebugBuild else { return false }
        if environment["SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG"] == "1" {
            return false
        }
        return environment["SANEAPPS_BYPASS_KEYCHAIN_IN_DEBUG"] == "1"
    }

    private static var buildIsDebug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    private static var isKeychainBypassed: Bool {
        shouldBypassKeychain(
            environment: ProcessInfo.processInfo.environment,
            arguments: ProcessInfo.processInfo.arguments
        )
    }

    private static var fallbackDefaults: UserDefaults {
        .standard
    }

    private static var legacyFallbackDefaults: UserDefaults? {
        UserDefaults(suiteName: legacyFallbackSuiteName)
    }

    private static func fallbackKey(_ account: String) -> String {
        "sane.no-keychain.\(service).\(account)"
    }

    static func fallbackString(
        forKey key: String,
        primaryDefaults: UserDefaults = .standard,
        legacyDefaults: UserDefaults? = UserDefaults(suiteName: legacyFallbackSuiteName)
    ) -> String? {
        if let value = primaryDefaults.string(forKey: key) {
            return value
        }
        guard let legacyValue = legacyDefaults?.string(forKey: key) else { return nil }

        primaryDefaults.set(legacyValue, forKey: key)
        legacyDefaults?.removeObject(forKey: key)
        return legacyValue
    }

    private static func migrateFallbackToKeychainIfNeeded(account: String) -> Data? {
        guard let encoded = fallbackString(forKey: fallbackKey(account)),
              let data = Data(base64Encoded: encoded)
        else { return nil }

        // Best-effort migration from old debug fallback storage to real Keychain.
        let saved = save(data: data, account: account)
        if saved {
            fallbackDefaults.removeObject(forKey: fallbackKey(account))
            return data
        }
        return nil
    }
}
