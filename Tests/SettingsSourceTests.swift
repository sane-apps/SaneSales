import Foundation
import SaneUI
import Testing

@testable import SaneSales

struct SettingsSourceTests {
    @Test("macOS settings use shared SaneUI settings surfaces")
    func macSettingsUseSharedSaneUI() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let macSettingsSource = try String(
            contentsOf: projectRoot.appendingPathComponent("macOS/SaneSalesSettingsMacView.swift"),
            encoding: .utf8
        )

        #expect(macSettingsSource.contains("SaneSettingsContainer("))
        #expect(macSettingsSource.contains("LicenseSettingsView("))
        #expect(macSettingsSource.contains("SaneAboutView("))
        #expect(macSettingsSource.contains("SaneSparkleRow("))
    }

    @Test("SaneSales settings source avoids legacy mail and local updater drift")
    func settingsSourceRemovesLegacyDrift() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let settingsSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let directSupportSource = try String(
            contentsOf: projectRoot.appendingPathComponent("macOS/DirectDistributionSupport.swift"),
            encoding: .utf8
        )

        #expect(!settingsSource.contains("mailto:hi@saneapps.com"))
        #expect(!settingsSource.contains("Read-only merchant data"))
        #expect(!directSupportSource.contains("struct SaneSparkleRow"))
    }

    @Test("SaneSales direct license copy uses the standardized labels")
    func directLicenseCopyUsesStandardLabels() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let source = try String(
            contentsOf: projectRoot.appendingPathComponent("macOS/DirectDistributionSupport.swift"),
            encoding: .utf8
        )

        #expect(source.contains("alternateUnlockLabel: \"Unlock Pro\""))
        #expect(source.contains("alternateEntryLabel: \"Enter License Key\""))
        #expect(source.contains("accessManagementLabel: \"Deactivate Pro\""))
    }
}
