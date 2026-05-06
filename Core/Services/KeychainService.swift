import Foundation
import Security

/// Keychain storage for API keys. Thread-safe, static-only.
struct KeychainService: Sendable {
    static let service = Bundle.main.bundleIdentifier ?? "com.sanesales.app"
    static let legacyFallbackSuiteName = "com.sanesales.no-keychain"
    static let synchronizesProviderKeysWithICloud = true

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
        let query = synchronizableKeychainQuery(account: account).merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]) { _, new in new }

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

        if let syncedData = loadSynchronizableKeychainData(account: account) {
            return syncedData
        }

        if let migratedData = migrateLocalKeyToSynchronizableIfNeeded(account: account) {
            return migratedData
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

        let localStatus = SecItemDelete(localKeychainQuery(account: account) as CFDictionary)
        let syncedStatus = SecItemDelete(synchronizableKeychainQuery(account: account) as CFDictionary)
        fallbackDefaults.removeObject(forKey: fallbackKey(account))
        legacyFallbackDefaults?.removeObject(forKey: fallbackKey(account))

        return [localStatus, syncedStatus].allSatisfy { status in
            status == errSecSuccess || status == errSecItemNotFound
        }
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

    static func localKeychainQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func synchronizableKeychainQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true
        ]
    }

    private static func loadLocalKeychainData(account: String) -> Data? {
        loadKeychainData(query: localKeychainQuery(account: account))
    }

    private static func loadSynchronizableKeychainData(account: String) -> Data? {
        loadKeychainData(query: synchronizableKeychainQuery(account: account))
    }

    private static func loadKeychainData(query: [String: Any]) -> Data? {
        var lookupQuery = query
        lookupQuery[kSecReturnData as String] = true
        lookupQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(lookupQuery as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func migrateLocalKeyToSynchronizableIfNeeded(account: String) -> Data? {
        guard let data = loadLocalKeychainData(account: account) else { return nil }

        let query = synchronizableKeychainQuery(account: account).merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]) { _, new in new }

        let saved = SecItemAdd(query as CFDictionary, nil)
        if saved == errSecSuccess {
            SecItemDelete(localKeychainQuery(account: account) as CFDictionary)
            return data
        }
        return nil
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
