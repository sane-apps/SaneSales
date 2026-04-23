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
        #expect(macSettingsSource.contains("CompactSection("))
        #expect(macSettingsSource.contains("LicenseSettingsView("))
        #expect(macSettingsSource.contains("SaneAboutView("))
        #expect(macSettingsSource.contains("SaneSparkleRow("))
        #expect(macSettingsSource.contains("SaneLanguageSettingsRow("))
        #expect(macSettingsSource.contains("labels: SaneSalesSettingsCopy.aboutLabels"))
        #expect(macSettingsSource.contains("SaneSalesSettingsCopy.providersSectionTitle"))
        #expect(macSettingsSource.contains("SaneSalesSettingsCopy.snapshotSectionTitle"))
        #expect(macSettingsSource.contains("SaneSalesSettingsCopy.actionsSectionTitle"))
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

    @Test("Primary app plists opt into Apple app-language settings")
    func appPlistsOptIntoLanguageSettings() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let macInfo = try String(
            contentsOf: projectRoot.appendingPathComponent("SaneSales/Info.plist"),
            encoding: .utf8
        )
        let iosInfo = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Info.plist"),
            encoding: .utf8
        )

        #expect(macInfo.contains("<key>UIPrefersShowingLanguageSettings</key>"))
        #expect(iosInfo.contains("<key>UIPrefersShowingLanguageSettings</key>"))
    }

    @Test("macOS settings navigation uses queued routing instead of timer delays")
    func macSettingsNavigationUsesQueuedRouting() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let appSource = try String(
            contentsOf: projectRoot.appendingPathComponent("macOS/SaneSalesMacApp.swift"),
            encoding: .utf8
        )
        let menuSource = try String(
            contentsOf: projectRoot.appendingPathComponent("macOS/MenuBarManager.swift"),
            encoding: .utf8
        )
        let contentSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/ContentView.swift"),
            encoding: .utf8
        )

        #expect(appSource.contains("final class SettingsTabNavigationStorage"))
        #expect(appSource.contains("SettingsTabNavigationStorage.shared.requestShowSettingsTab()"))
        #expect(!appSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)"))
        #expect(menuSource.contains("SettingsTabNavigationStorage.shared.requestShowSettingsTab()"))
        #expect(!menuSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)"))
        #expect(contentSource.contains("SettingsTabNavigationStorage.shared.consumePendingRequest()"))
        #expect(contentSource.contains("SettingsTabNavigationStorage.shared.markRequestHandled()"))
    }

    @Test("In-app settings routes avoid timer-based follow-up notifications")
    func inAppSettingsRoutesAvoidTimerBasedNotifications() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let dashboardSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/DashboardView.swift"),
            encoding: .utf8
        )
        let ordersSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/OrdersListView.swift"),
            encoding: .utf8
        )
        let productsSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/ProductsView.swift"),
            encoding: .utf8
        )
        let settingsSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let contentSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/ContentView.swift"),
            encoding: .utf8
        )

        #expect(!dashboardSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)"))
        #expect(!dashboardSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)"))
        #expect(!ordersSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)"))
        #expect(!ordersSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.12)"))
        #expect(!productsSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)"))
        #expect(!productsSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.12)"))
        #expect(!settingsSource.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)"))
        #expect(!dashboardSource.contains(".showSettingsProviderSetup"))
        #expect(!ordersSource.contains(".showSettingsProviderSetup"))
        #expect(!productsSource.contains(".showSettingsProviderSetup"))
        #expect(!settingsSource.contains(".showSettingsProviderSetup"))
        #expect(!contentSource.contains("showSettingsProviderSetup"))
        #expect(dashboardSource.contains("DispatchQueue.main.async"))
        #expect(ordersSource.contains("DispatchQueue.main.async"))
        #expect(productsSource.contains("DispatchQueue.main.async"))
        #expect(settingsSource.contains("DispatchQueue.main.async"))
    }
}
