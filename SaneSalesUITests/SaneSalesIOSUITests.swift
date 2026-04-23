import XCTest

@MainActor
final class SaneSalesIOSUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingProviderSwitchUpdatesLabelAndHelp() {
        let app = launchOnboarding()

        let gumroadButton = app.buttons["onboarding.provider.gumroad"]
        XCTAssertTrue(gumroadButton.waitForExistence(timeout: 5))
        gumroadButton.tap()

        let keyLabel = app.staticTexts["onboarding.apiKeyLabel"]
        XCTAssertTrue(keyLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(keyLabel.label, "Gumroad API Key")

        let keyHelp = app.staticTexts["onboarding.apiKeyHelp"]
        XCTAssertTrue(keyHelp.waitForExistence(timeout: 2))
        XCTAssertTrue(keyHelp.label.contains("gumroad.com"))

        let stripeButton = app.buttons["onboarding.provider.stripe"]
        XCTAssertTrue(stripeButton.exists)
        stripeButton.tap()

        XCTAssertEqual(keyLabel.label, "Stripe API Key")
        XCTAssertTrue(keyHelp.label.contains("dashboard.stripe.com"))
    }

    func testConnectButtonStateForWhitespaceAndTrimmedInput() {
        let app = launchOnboarding()

        let field = app.secureTextFields["onboarding.apiKeyField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        let connectButton = app.buttons["onboarding.connectButton"]
        XCTAssertTrue(connectButton.exists)
        XCTAssertFalse(connectButton.isEnabled)

        field.tap()
        field.typeText("   ")
        XCTAssertFalse(connectButton.isEnabled)

        field.typeText("sk_test_123")
        XCTAssertTrue(connectButton.isEnabled)
    }

    func testDemoModeNavigatesAllMainTabs() {
        let app = launchOnboarding()

        let demoButton = app.buttons["onboarding.demoButton"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 5))
        demoButton.tap()

        XCTAssertTrue(waitForMainShell(app))

        let tabs = ["Dashboard", "Orders", "Products", "Settings"]
        for tab in tabs {
            openMainSection(tab, in: app)
        }
    }

    func testOnboardingShowsAppStoreUpgradePath() {
        let app = launchOnboarding()

        let unlockButton = app.buttons["onboarding.unlockProButton"]
        let restoreButton = app.buttons["onboarding.restorePurchasesButton"]

        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        XCTAssertTrue(restoreButton.exists)
    }

    func testSettingsShowsLicenseSectionAndButtons() {
        let app = launchOnboarding()

        let demoButton = app.buttons["onboarding.demoButton"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 5))
        demoButton.tap()

        XCTAssertTrue(waitForMainShell(app))
        openMainSection("Settings", in: app)

        XCTAssertTrue(app.staticTexts["License"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.license.unlockProButton"].exists)
        XCTAssertTrue(app.buttons["settings.license.restorePurchasesButton"].exists)
    }

    func testDashboardProviderOpensSetupFlowWhenConnectionIsAllowed() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset", "--skip-onboarding"]
        app.launchEnvironment["SANEAPPS_SKIP_ONBOARDING"] = "1"
        app.launch()

        let providerMenu = app.buttons["dashboard.providerMenu"]
        XCTAssertTrue(providerMenu.waitForExistence(timeout: 5))
        providerMenu.tap()

        let connectGumroad = app.buttons["Connect Gumroad"]
        XCTAssertTrue(connectGumroad.waitForExistence(timeout: 5))
        connectGumroad.tap()

        XCTAssertTrue(app.staticTexts["Connect Gumroad Account"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["API Key"].exists)
    }

    func testDisconnectedDashboardProviderRoutesToUpgradeInBasicMode() {
        let app = launchOnboarding(extraLaunchArguments: ["--demo-connected-provider=lemonsqueezy"])

        let demoButton = app.buttons["onboarding.demoButton"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 5))
        demoButton.tap()

        let providerMenu = app.buttons["dashboard.providerMenu"]
        XCTAssertTrue(providerMenu.waitForExistence(timeout: 5))
        providerMenu.tap()

        let connectGumroad = app.buttons["Connect Gumroad"]
        XCTAssertTrue(connectGumroad.waitForExistence(timeout: 5))
        connectGumroad.tap()

        XCTAssertTrue(app.staticTexts["License"].waitForExistence(timeout: 5))
    }

    func testLaunchDemoLimitsFreeModeToTodayAndLeavesAllProvidersConnectable() {
        let app = launchFreeDemo()

        let allTimeButton = app.buttons["dashboard.range.allTime"]
        XCTAssertTrue(allTimeButton.waitForExistence(timeout: 8))
        allTimeButton.tap()

        XCTAssertTrue(app.staticTexts["License"].waitForExistence(timeout: 5))

        openMainSection("Settings", in: app)

        XCTAssertTrue(app.buttons["settings.provider.lemonsqueezy.manage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.provider.gumroad.connect"].exists)
        XCTAssertTrue(app.buttons["settings.provider.stripe.connect"].exists)
    }

    func testLaunchDemoInFreeModeLocksOlderOrderHistory() {
        let app = launchFreeDemo()

        openMainSection("Orders", in: app)

        let unlockHistoryButton = app.buttons["orders.unlockHistoryButton"]
        XCTAssertTrue(unlockHistoryButton.waitForExistence(timeout: 5))
        unlockHistoryButton.tap()

        XCTAssertTrue(app.staticTexts["License"].waitForExistence(timeout: 5))
    }

    func testLaunchDemoInFreeModeShowsLockedCSVExport() {
        let app = launchFreeDemo()

        openMainSection("Settings", in: app)

        let lockedExportButton = app.buttons["settings.data.export.lockedButton"]
        XCTAssertTrue(lockedExportButton.waitForExistence(timeout: 5))
    }

    func testLaunchDemoInFreeModeLocksSecondProviderConnectionFromSettings() {
        let app = launchFreeDemo()

        openMainSection("Settings", in: app)

        let connectGumroad = app.buttons["settings.provider.gumroad.connect"]
        XCTAssertTrue(connectGumroad.waitForExistence(timeout: 5))
        connectGumroad.tap()

        XCTAssertTrue(app.staticTexts["License"].waitForExistence(timeout: 5))
    }


    func testProDemoCustomRangeAppliesAcrossDashboardAndOrders() {
        let app = launchProDemo()

        let customButton = app.buttons["dashboard.range.custom"]
        XCTAssertTrue(customButton.waitForExistence(timeout: 5))
        customButton.tap()

        let applyButton = app.buttons["customRange.applyButton"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5))
        applyButton.tap()

        let expectedSummary = defaultCustomRangeSummaryLabel()
        XCTAssertTrue(app.staticTexts[expectedSummary].waitForExistence(timeout: 5))

        openMainSection("Orders", in: app)
        XCTAssertTrue(app.buttons["orders.range.custom"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[expectedSummary].waitForExistence(timeout: 5))
    }

    func testSeededLemonSqueezyKeySkipsOnboarding() throws {
        let apiKeyB64 = try loadSeededLemonSqueezyKeyBase64()

        let app = XCUIApplication()
        app.launchArguments += ["--sane-no-keychain", "--skip-onboarding"]
        app.launchEnvironment["SANEAPPS_DISABLE_KEYCHAIN"] = "1"
        app.launchEnvironment["SANEAPPS_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"] = apiKeyB64
        app.launch()

        let tabView = app.tabBars.firstMatch
        XCTAssertTrue(tabView.waitForExistence(timeout: 8))
        XCTAssertFalse(app.otherElements["onboarding.view"].exists)
    }

    func testSeededLemonSqueezyKeyLoadsDashboardWithoutParseError() throws {
        let apiKeyB64 = try loadSeededLemonSqueezyKeyBase64()

        let app = XCUIApplication()
        app.launchArguments += ["--sane-no-keychain", "--skip-onboarding"]
        app.launchEnvironment["SANEAPPS_DISABLE_KEYCHAIN"] = "1"
        app.launchEnvironment["SANEAPPS_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"] = apiKeyB64
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Failed to parse response from server."].waitForExistence(timeout: 8))
    }

    @discardableResult
    private func launchOnboarding(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset"] + extraLaunchArguments
        app.launch()
        return app
    }

    @discardableResult
    private func launchProDemo() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-reset",
            "--skip-onboarding",
            "--demo",
            "--force-pro-mode"
        ]
        app.launchEnvironment["SANEAPPS_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SANEAPPS_FORCE_PRO_MODE"] = "1"
        app.launch()
        XCTAssertTrue(waitForMainShell(app))
        return app
    }

    @discardableResult
    private func launchFreeDemo() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-reset",
            "--skip-onboarding",
            "--demo",
            "--demo-connected-provider=lemonsqueezy",
            "--force-free-mode"
        ]
        app.launchEnvironment["SANEAPPS_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SANEAPPS_FORCE_FREE_MODE"] = "1"
        app.launch()
        XCTAssertTrue(waitForMainShell(app))
        return app
    }

    private func waitForMainShell(_ app: XCUIApplication, timeout: TimeInterval = 8) -> Bool {
        if app.buttons["dashboard.range.allTime"].waitForExistence(timeout: timeout) {
            return true
        }

        if app.tabBars.firstMatch.waitForExistence(timeout: 1) {
            return true
        }

        return app.buttons["Dashboard"].waitForExistence(timeout: 1)
    }

    private func openMainSection(_ title: String, in app: XCUIApplication) {
        let tabButton = app.tabBars.firstMatch.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        if tabButton.waitForExistence(timeout: 2) {
            if !tabButton.isSelected {
                tabButton.tap()
            }
            return
        }

        let sidebarButton = app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 5), "Missing main section button: \(title)")
        sidebarButton.tap()
    }

    private func defaultCustomRangeSummaryLabel() -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        let formatter = DateIntervalFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: start, to: now)
    }

    private func loadSeededLemonSqueezyKeyBase64() throws -> String {
        if let apiKeyB64 = ProcessInfo.processInfo.environment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !apiKeyB64.isEmpty {
            return apiKeyB64
        }

        let fallbackURL = URL(fileURLWithPath: "/tmp/saneapps_test_lemonsqueezy_api_key.b64")
        if let fallback = try? String(contentsOf: fallbackURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !fallback.isEmpty {
            return fallback
        }

        throw XCTSkip("No seeded LemonSqueezy test key found")
    }
}
