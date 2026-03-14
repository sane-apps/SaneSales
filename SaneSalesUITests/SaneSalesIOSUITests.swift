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

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let tabs = ["Dashboard", "Orders", "Products", "Settings"]
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            XCTAssertTrue(tabButton.exists, "Missing tab: \(tab)")
            tabButton.tap()
            XCTAssertTrue(tabButton.isSelected, "Tab did not select: \(tab)")
        }
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
    private func launchOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset"]
        app.launch()
        return app
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
