import Foundation
import Testing

@testable import SaneSales

struct KeychainServiceTests {
    @Test("Release-style no-keychain bypass stays available outside debug builds")
    func releaseStyleBypassStillWorks() {
        #expect(KeychainService.shouldBypassKeychain(
            environment: ["SANEAPPS_DISABLE_KEYCHAIN": "1"],
            arguments: ["SaneSales"],
            isDebugBuild: false
        ))

        #expect(KeychainService.shouldBypassKeychain(
            environment: [:],
            arguments: ["SaneSales", "--sane-no-keychain"],
            isDebugBuild: false
        ))

        #expect(!KeychainService.shouldBypassKeychain(
            environment: [:],
            arguments: ["SaneSales"],
            isDebugBuild: false
        ))
    }

    @Test("Legacy no-keychain values migrate into the primary defaults domain")
    func legacyFallbackMigratesForward() {
        let primarySuite = "KeychainServiceTests.primary.\(UUID().uuidString)"
        let legacySuite = "KeychainServiceTests.legacy.\(UUID().uuidString)"
        let key = "sane.no-keychain.com.sanesales.test.license_key"

        let primaryDefaults = UserDefaults(suiteName: primarySuite)!
        let legacyDefaults = UserDefaults(suiteName: legacySuite)!
        primaryDefaults.removePersistentDomain(forName: primarySuite)
        legacyDefaults.removePersistentDomain(forName: legacySuite)
        defer {
            primaryDefaults.removePersistentDomain(forName: primarySuite)
            legacyDefaults.removePersistentDomain(forName: legacySuite)
        }

        legacyDefaults.set("test-pro", forKey: key)

        let migratedValue = KeychainService.fallbackString(
            forKey: key,
            primaryDefaults: primaryDefaults,
            legacyDefaults: legacyDefaults
        )

        #expect(migratedValue == "test-pro")
        #expect(primaryDefaults.string(forKey: key) == "test-pro")
        #expect(legacyDefaults.object(forKey: key) == nil)
    }
}
