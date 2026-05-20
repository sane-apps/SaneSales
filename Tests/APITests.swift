import Foundation
@testable import SaneSales
import SaneUI
import Testing

struct APITests {
    // MARK: - Order Parsing

    @Test("Parses LemonSqueezy order JSON correctly")
    func parsesOrderJSON() throws {
        let json = """
        {
            "data": [{
                "id": "123",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 500,
                    "currency": "USD",
                    "user_email": "test@example.com",
                    "user_name": "Test User",
                    "first_order_item": {
                        "product_name": "SaneBar",
                        "variant_name": "Standard"
                    },
                    "created_at": "2026-01-15T10:30:00Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """
        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data.count == 1)
        let attrs = response.data[0].attributes
        #expect(attrs.status == "paid")
        #expect(attrs.total == 500)
        #expect(attrs.currency == "USD")
        #expect(attrs.userEmail == "test@example.com")
        #expect(attrs.userName == "Test User")
        #expect(attrs.firstOrderItem?.productName == "SaneBar")
        #expect(attrs.firstOrderItem?.variantName == "Standard")
    }

    @Test("Handles missing optional fields gracefully")
    func handlesMissingOptionalFields() throws {
        let json = """
        {
            "data": [{
                "id": "456",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 1000,
                    "currency": "EUR",
                    "user_email": "user@test.com",
                    "user_name": "Another User",
                    "created_at": "2026-02-01T08:00:00Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """
        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data[0].attributes.firstOrderItem == nil)
    }

    @Test("Parses ISO8601 dates with fractional seconds")
    func parsesDateWithFractionalSeconds() throws {
        let json = """
        {
            "data": [{
                "id": "789",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 500,
                    "currency": "USD",
                    "user_email": "a@b.com",
                    "user_name": "A B",
                    "created_at": "2026-01-15T10:30:00.123Z"
                }
            }],
            "meta": { "page": { "lastPage": 1 } }
        }
        """
        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)
        #expect(response.data[0].attributes.createdAt.timeIntervalSince1970 > 0)
    }

    @Test("Handles LemonSqueezy orders with missing customer details")
    func handlesOrdersMissingCustomerDetails() throws {
        let json = """
        {
            "data": [{
                "id": "7681144",
                "type": "orders",
                "attributes": {
                    "status": "failed",
                    "order_number": 2706910,
                    "identifier": "01ea3e89-670f-4cdc-883a-5048a0d6636f",
                    "total": 0,
                    "subtotal": 0,
                    "tax": 0,
                    "discount_total": 0,
                    "currency": "USD",
                    "user_email": null,
                    "user_name": null,
                    "tax_inclusive": true,
                    "total_formatted": "$0.00",
                    "subtotal_formatted": "$0.00",
                    "tax_formatted": "$0.00",
                    "discount_total_formatted": "$0.00",
                    "first_order_item": null,
                    "created_at": "2026-03-11T10:30:00.000000Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """
        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data.count == 1)
        #expect(response.data[0].attributes.userEmail == nil)
        #expect(response.data[0].attributes.userName == nil)
        #expect(response.data[0].attributes.firstOrderItem == nil)
    }

    @Test("Parses LemonSqueezy store timestamps with microseconds")
    func parsesStoreJSONWithMicroseconds() throws {
        let json = """
        {
            "data": [{
                "id": "270691",
                "type": "stores",
                "attributes": {
                    "name": "SaneApps",
                    "slug": "saneapps",
                    "currency": "USD",
                    "total_revenue": 185763,
                    "thirty_day_revenue": 92967,
                    "total_sales": 389,
                    "thirty_day_sales": 205,
                    "created_at": "2026-01-10T00:27:28.000000Z"
                }
            }]
        }
        """
        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestStoresResponse.self, from: data)

        #expect(response.data.count == 1)
        #expect(response.data[0].attributes.name == "SaneApps")
        #expect(response.data[0].attributes.createdAt != nil)
    }

    @Test("Handles LemonSqueezy nullable noncritical order fields")
    func parsesOrdersWhenOptionalFieldsAreNull() throws {
        let json = """
        {
            "data": [{
                "id": "901",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "order_number": null,
                    "identifier": null,
                    "total": 500,
                    "subtotal": null,
                    "tax": null,
                    "discount_total": null,
                    "currency": "USD",
                    "user_email": "test@example.com",
                    "user_name": null,
                    "tax_inclusive": null,
                    "total_formatted": null,
                    "subtotal_formatted": null,
                    "tax_formatted": null,
                    "discount_total_formatted": null,
                    "first_order_item": null,
                    "created_at": "2026-03-29T10:30:00.000000Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data.count == 1)
        #expect(response.data[0].attributes.userEmail == "test@example.com")
        #expect(response.data[0].attributes.firstOrderItem == nil)
    }

    @Test("Parses LemonSqueezy snake_case page metadata")
    func parsesStoreJSONWithSnakeCasePageMetadata() throws {
        let json = """
        {
            "data": [{
                "id": "123",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 500,
                    "currency": "USD",
                    "user_email": "test@example.com",
                    "user_name": "Test User",
                    "created_at": "2026-01-15T10:30:00Z"
                }
            }],
            "meta": {
                "page": {
                    "last_page": 2
                }
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)
        #expect(response.meta.page.lastPage == 2)
    }

    @Test("Demo data respects the requested connected providers")
    @MainActor
    func demoDataRespectsConnectedProviders() {
        let manager = SalesManager()
        manager.resetForUITests()

        DemoData.loadInto(manager: manager, connectedProviders: [.lemonSqueezy])

        #expect(manager.connectedProviders == [.lemonSqueezy])
        #expect(manager.isLemonSqueezyConnected)
        #expect(!manager.isGumroadConnected)
        #expect(!manager.isStripeConnected)
        #expect(Set(manager.orders.map(\.provider)) == [.lemonSqueezy])
        #expect(Set(manager.products.map(\.provider)) == [.lemonSqueezy])
        #expect(Set(manager.stores.map(\.provider)) == [.lemonSqueezy])
    }

    @Test("Diagnostics issue URL uses GitHub bug template and clipboard hint")
    @MainActor
    func diagnosticsIssueURLUsesGitHubTemplate() throws {
        let report = SaneDiagnosticReport(
            appName: "SaneSales",
            appVersion: "1.2.2",
            buildNumber: "1203",
            platformDescription: "iOS 26.0",
            deviceDescription: "iPhone",
            recentLogs: [],
            settingsSummary: "demoMode: true\nconnectedProviders: LemonSqueezy",
            collectedAt: Date(timeIntervalSince1970: 0)
        )

        let issueURL = try #require(report.gitHubIssueURL(
            title: "[Bug]: blank report",
            userDescription: "Report body",
            githubRepo: "SaneSales"
        ))
        let components = try #require(URLComponents(url: issueURL, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["template"] == "bug_report.md")
        #expect(items["title"] == "[Bug]: blank report")
        #expect(items["body"]?.contains("Full diagnostics were copied to your clipboard.") == true)
        #expect(items["body"]?.contains("| OS | iOS 26.0 |") == true)
    }

    @Test("Live LemonSqueezy provider loads real SaneApps data when a test key is available")
    func liveLemonSqueezyProviderLoadsRealData() async throws {
        guard let apiKey = loadSeededLemonSqueezyKey() else {
            return
        }

        let provider = LemonSqueezyProvider(apiKey: apiKey)
        let store = try await provider.fetchStore()
        let products = try await provider.fetchProducts()
        let orders = try await provider.fetchAllOrders()

        #expect(store.name == "SaneApps")
        #expect(!products.isEmpty)
        #expect(orders.count > 100)
        #expect(orders.contains { $0.customerName == "Unknown Customer" })
    }

    // MARK: - Order Status

    @Test("OrderStatus handles unknown values")
    func orderStatusUnknown() throws {
        let json = """
        "something_new"
        """
        let data = try #require(json.data(using: .utf8))
        let status = try JSONDecoder().decode(OrderStatus.self, from: data)
        #expect(status == .unknown)
    }
}

struct AppStartupPolicyTests {
    @Test("iOS setup flow shows onboarding for first launch or broken startup")
    func iosSetupFlowShowsOnboardingWhenNeeded() {
        #expect(SalesSetupFlowPolicy.welcomeOverride(arguments: ["--force-onboarding"], environment: [:]) == false)
        #expect(SalesSetupFlowPolicy.welcomeOverride(arguments: ["--skip-onboarding"], environment: [:]) == true)
        #expect(SalesSetupFlowPolicy.welcomeOverride(arguments: [], environment: ["SANEAPPS_SKIP_ONBOARDING": "1"]) == true)
        #expect(SalesSetupFlowPolicy.welcomeOverride(arguments: [], environment: [:]) == nil)

        #expect(SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: false,
            demoModeEnabled: false,
            hasConnectedProviders: false,
            hasAnyData: false,
            hasError: false,
            arguments: []
        ))

        #expect(SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: true,
            demoModeEnabled: false,
            hasConnectedProviders: true,
            hasAnyData: false,
            hasError: true,
            arguments: []
        ))

        #expect(!SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: true,
            demoModeEnabled: true,
            hasConnectedProviders: false,
            hasAnyData: false,
            hasError: false,
            arguments: []
        ))

        #expect(!SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: true,
            demoModeEnabled: false,
            hasConnectedProviders: true,
            hasAnyData: true,
            hasError: false,
            arguments: []
        ))

        #expect(!SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: false,
            demoModeEnabled: false,
            hasConnectedProviders: false,
            hasAnyData: false,
            hasError: false,
            arguments: ["--skip-onboarding"]
        ))
    }

    @Test("Store-only cache does not count as usable dashboard content")
    func storeOnlyCacheDoesNotSuppressSetupRecovery() {
        #expect(!SalesSetupFlowPolicy.hasUsableContent(ordersCount: 0, productsCount: 0))
        #expect(SalesSetupFlowPolicy.hasUsableContent(ordersCount: 1, productsCount: 0))
        #expect(SalesSetupFlowPolicy.hasUsableContent(ordersCount: 0, productsCount: 1))
    }

    @Test("Initial refresh failure only blocks setup completion when no usable content was loaded")
    func initialRefreshFailureBlocksOnlyBlankDashboards() {
        #expect(SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
            error: .decodingError(underlying: NSError(domain: "test", code: 1)),
            ordersCount: 0,
            productsCount: 0
        ))

        #expect(!SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
            error: .decodingError(underlying: NSError(domain: "test", code: 1)),
            ordersCount: 12,
            productsCount: 0
        ))

        #expect(!SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
            error: nil,
            ordersCount: 0,
            productsCount: 0
        ))
    }

    #if os(macOS)
        @Test("Dock default stays hidden")
        func dockDefaultIsHidden() throws {
            let defaults = try #require(UserDefaults(suiteName: #function))
            defaults.removePersistentDomain(forName: #function)
            defer { defaults.removePersistentDomain(forName: #function) }

            #expect(SaneSalesMacApp.defaultShowDockPreference(userDefaults: defaults) == false)
            defaults.set(true, forKey: "showInDock")
            #expect(SaneSalesMacApp.defaultShowDockPreference(userDefaults: defaults))
        }

        @Test("Menu bar window action uses shared main-window path")
        func menuBarWindowActionUsesSharedMainWindowPath() throws {
            let projectRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let source = try String(
                contentsOf: projectRoot.appendingPathComponent("macOS/MenuBarManager.swift"),
                encoding: .utf8
            )

            #expect(source.contains("@objc private func menuShowWindow()"))
            #expect(source.contains("WindowActionStorage.shared.showMainWindow()"))
        }

        @Test("App Store menu source gates update checks out")
        func appStoreMenuSourceGatesUpdateChecksOut() throws {
            let projectRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let menuSource = try String(
                contentsOf: projectRoot.appendingPathComponent("macOS/MenuBarManager.swift"),
                encoding: .utf8
            )
            let managerSource = try String(
                contentsOf: projectRoot.appendingPathComponent("Core/SalesManager.swift"),
                encoding: .utf8
            )

            #expect(menuSource.contains("#if !APP_STORE"))
            #expect(menuSource.contains("SaneSalesContextMenu.make"))
            #expect(menuSource.contains("SaneStandardMenu.addCoreUtilityItems"))
            #expect(menuSource.contains("directUpdateAction"))
            #expect(managerSource.contains("SalesSetupFlowPolicy.welcomeOverride"))
            #expect(managerSource.contains("UserDefaults.standard.set(hasSeenWelcomeOverride, forKey: \"hasSeenWelcome\")"))
        }
    #endif
}

struct AppStoreReviewPathTests {
    @Test("SaneSales App Store IAP metadata is explicit")
    func saneSalesIapMetadataIsExplicit() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifest = try String(contentsOf: projectRoot.appendingPathComponent(".saneprocess"), encoding: .utf8)

        #expect(manifest.contains("display_name: \"SaneSales Pro Unlock\""))
        #expect(manifest.contains("description: \"Unlock Pro analytics with one purchase.\""))
        #expect(manifest.localizedCaseInsensitiveContains("one-time non-consumable StoreKit purchase"))
    }

    @Test("App Store metadata leads with the buyer wedge")
    func appStoreMetadataLeadsWithBuyerWedge() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifest = try String(contentsOf: projectRoot.appendingPathComponent(".saneprocess"), encoding: .utf8)

        #expect(manifest.contains("subtitle: \"Private Revenue Tracker\""))
        #expect(manifest.contains("Track Lemon Squeezy, Gumroad, and Stripe revenue"))
        #expect(manifest.contains("makers who sell from more than one storefront"))
        #expect(manifest.contains("lemon squeezy,gumroad,stripe,revenue,orders,sales"))
    }

    @Test("Settings checkout tracking is source specific")
    func settingsCheckoutTrackingIsSourceSpecific() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let settingsSource = try String(
            contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"),
            encoding: .utf8
        )

        #expect(settingsSource.contains("appstore_purchase_started"))
        #expect(settingsSource.contains("direct_checkout_opened"))
        #expect(!settingsSource.contains("EventTracker.log(\"checkout_clicked\", app: \"sanesales\")"))
    }

    @Test("Website home page leads with provider-specific buyer intent")
    func websiteHomePageLeadsWithProviderSpecificBuyerIntent() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let homePage = try String(
            contentsOf: projectRoot.appendingPathComponent("docs/index.html"),
            encoding: .utf8
        )

        #expect(homePage.contains("Private native revenue tracker for indie sellers using Lemon Squeezy, Gumroad, and Stripe"))
        #expect(homePage.contains("lemon squeezy dashboard, gumroad sales tracker, stripe revenue widget"))
        #expect(homePage.contains("website_buy_hero_clicked"))
        #expect(homePage.contains("website_buy_pricing_clicked"))
    }

    @Test("iOS review notes match real Pro entry points")
    func saneSalesIosReviewNotesMatchCode() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifest = try String(contentsOf: projectRoot.appendingPathComponent(".saneprocess"), encoding: .utf8)
        let settingsSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"), encoding: .utf8)
        let onboardingSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/ContentView.swift"), encoding: .utf8)

        #expect(manifest.localizedCaseInsensitiveContains("Settings tab and use the License section"))
        #expect(manifest.localizedCaseInsensitiveContains("tap “Unlock Pro” on the setup screen") || manifest.localizedCaseInsensitiveContains("tap \"Unlock Pro\" on the setup screen"))
        #expect(settingsSource.contains("GlassSection(\"License\""))
        #expect(settingsSource.contains("settings.license.unlockProButton"))
        #expect(onboardingSource.contains("onboarding.unlockProButton"))
        #expect(onboardingSource.contains("if manager.hasLiveProviderAccess"))
        #expect(onboardingSource.contains("lockedProviderSection"))
        #expect(onboardingSource.contains("onboarding.enterLicenseKeyButton"))
    }

    @Test("Basic and demo provider paths do not expose live key entry")
    func basicAndDemoProviderPathsDoNotExposeLiveKeyEntry() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let managerSource = try String(contentsOf: projectRoot.appendingPathComponent("Core/SalesManager.swift"), encoding: .utf8)
        let settingsSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"), encoding: .utf8)
        let onboardingSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/ContentView.swift"), encoding: .utf8)
        let dashboardSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/DashboardView.swift"), encoding: .utf8)
        let ordersSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/OrdersListView.swift"), encoding: .utf8)
        let productsSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/ProductsView.swift"), encoding: .utf8)

        #expect(managerSource.contains("guard hasLiveProviderAccess else { return }"))
        #expect(managerSource.contains("loadCachedDataIfNeeded()"))
        #expect(settingsSource.contains("startProviderConnection(provider)"))
        #expect(onboardingSource.contains("if manager.hasLiveProviderAccess"))
        #expect(dashboardSource.contains("isPro: manager.hasLiveProviderAccess"))
        #expect(ordersSource.contains("isPro: manager.hasLiveProviderAccess"))
        #expect(productsSource.contains("manager.hasLiveProviderAccess ? manager.metrics : manager.planScopedMetrics"))
    }

    @Test("App Store screenshot capture keeps Mini visual fixtures release-safe")
    func appStoreScreenshotCaptureFixturesStayReleaseSafe() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let captureScript = try String(
            contentsOf: projectRoot.appendingPathComponent("scripts/capture_appstore_screenshots.sh"),
            encoding: .utf8
        )
        let watchSource = try String(
            contentsOf: projectRoot.appendingPathComponent("Watch/WatchDashboardView.swift"),
            encoding: .utf8
        )

        #expect(captureScript.contains("IOS_SCREENSHOT_DELAY=\"${IOS_SCREENSHOT_DELAY:-8}\""))
        #expect(captureScript.contains("WATCH_SCREENSHOT_DELAY=\"${WATCH_SCREENSHOT_DELAY:-5}\""))
        #expect(captureScript.contains("width=1280"))
        #expect(captureScript.contains("height=900"))
        #expect(watchSource.contains("SharedStore.isProEnabled(defaults: defaults) || useDemoIfEmpty || forceProMode"))
        #expect(watchSource.contains("environment[\"SANEAPPS_FORCE_PRO_MODE\"] == \"1\" || arguments.contains(\"--force-pro-mode\")"))
        #expect(watchSource.contains("watchRecentScreenshotContent(snapshot: snapshot)"))
        #expect(watchSource.contains("snapshot.recentRows.prefix(4)"))
        #expect(watchSource.contains(".padding(.top, max(38, proxy.safeAreaInsets.top + 22))"))
    }

    @Test("Marketing video tooling is repeatable and Mini-first")
    func marketingVideoToolingIsRepeatableAndMiniFirst() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let captureScript = try String(
            contentsOf: projectRoot.appendingPathComponent("scripts/capture_demo_videos.sh"),
            encoding: .utf8
        )
        let buildScript = try String(
            contentsOf: projectRoot.appendingPathComponent("scripts/build_launch_video.py"),
            encoding: .utf8
        )
        let website = try String(
            contentsOf: projectRoot.appendingPathComponent("docs/index.html"),
            encoding: .utf8
        )

        #expect(captureScript.contains("require_mini_host"))
        #expect(captureScript.contains("SANE_ALLOW_LOCAL_VIDEO_CAPTURE"))
        #expect(captureScript.contains("write_capture_receipt"))
        #expect(captureScript.contains("EXTRA_APP_ARGS"))
        #expect(buildScript.contains("launch-week-pro-all-devices.mp4"))
        #expect(buildScript.contains("sanesales-launch-video-poster.png"))
        #expect(buildScript.contains("launch-week-pro-contact-sheet.png"))
        #expect(buildScript.contains("launch-week-pro-video-contact-sheet.jpg"))
        #expect(buildScript.contains("APP_ICON_SOURCE = ROOT / \"Resources\" / \"Assets.xcassets\" / \"AppIcon.appiconset\" / \"icon_1024x1024.png\""))
        #expect(buildScript.contains("def logo_icon(size: int) -> Image.Image:"))
        #expect(buildScript.contains("saturation = cyan - r"))
        #expect(buildScript.contains("if cyan < 78 or saturation < 30:"))
        #expect(buildScript.contains("icon_size = 96"))
        #expect(buildScript.contains("ACCENT_BRIGHT = (82, 224, 240)"))
        #expect(buildScript.contains("def callout(draw: ImageDraw.ImageDraw"))
        #expect(!buildScript.contains("def badge("))
        #expect(buildScript.contains("LEFT_X = 126"))
        #expect(buildScript.contains("PROOF_X = 860"))
        #expect(buildScript.contains("MUSIC_SOURCE = VIDEO_DIR / \"pulse-ledger.mp3\""))
        #expect(buildScript.contains("-stream_loop"))
        #expect(buildScript.contains("loudnorm=I=-18"))
        #expect(buildScript.contains("Tired of sales apps that spy and charge forever?"))
        #expect(buildScript.contains("(\"slide-02-privacy.png\", slide_privacy)"))
        #expect(buildScript.contains("Track sales privately.\\nNo subscription."))
        #expect(!buildScript.contains("Private tracking."))
        #expect(buildScript.contains("There is a cleaner way."))
        #expect(buildScript.contains("See what sold today."))
        #expect(buildScript.contains("Launch week special."))
        #expect(!buildScript.contains("Launch offer:"))
        #expect(buildScript.contains("font_obj.getmetrics()"))
        #expect(buildScript.contains("Everything important in one place"))
        #expect(buildScript.contains("No customer lists sent to SaneApps"))
        #expect(buildScript.contains("No analytics cloud collecting your history"))
        #expect(buildScript.contains("concat=n={len(slides)}:v=1:a=0[vout]"))
        #expect(buildScript.contains("fade=t=in"))
        #expect(!buildScript.contains("xfade=transition="))
        #expect(!buildScript.contains("License checks only verify Pro access"))
        #expect(!buildScript.contains("Provider keys stay in iCloud Keychain"))
        #expect(!buildScript.contains("No SaneApps sales-data server"))
        #expect(buildScript.contains("CHART_ASSET_CHECKS"))
        #expect(buildScript.contains("chart QA failed"))
        #expect(buildScript.contains("tile=4x2"))
        #expect(website.contains("Private by Design"))
        #expect(website.contains("SaneApps never receives your customer lists, orders, or revenue history"))
        #expect(!website.contains("Public Code & iCloud Keychain"))
        #expect(!website.contains("Provider keys are saved in iCloud Keychain"))
        #expect(!website.contains("brew install --cask sane-apps/tap/sanesales"))
        #expect(!website.contains("No server in the middle"))
        #expect(!website.contains("No middleman."))
        #expect(!website.contains("Made by a cool dev"))
        #expect(!website.contains("FOSS alternative"))
    }

    @Test("macOS review notes match the real welcome-screen Pro entry point")
    func saneSalesMacReviewNotesMatchCode() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifest = try String(contentsOf: projectRoot.appendingPathComponent(".saneprocess"), encoding: .utf8)
        let macAppSource = try String(contentsOf: projectRoot.appendingPathComponent("macOS/SaneSalesMacApp.swift"), encoding: .utf8)
        let settingsSource = try String(contentsOf: projectRoot.appendingPathComponent("iOS/Views/SettingsView.swift"), encoding: .utf8)
        let welcomeGateSource = try String(
            contentsOf: saneUIRoot(from: projectRoot).appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(manifest.localizedCaseInsensitiveContains("click “Unlock Pro” on the welcome screen") || manifest.localizedCaseInsensitiveContains("click \"Unlock Pro\" on the welcome screen"))
        #expect(manifest.localizedCaseInsensitiveContains("open Settings and select the License tab"))
        #expect(macAppSource.contains("WelcomeGateView("))
        #expect(settingsSource.contains("GlassSection(\"License\""))
        #expect(welcomeGateSource.contains("Text(licenseService.isPurchasing ? \"Processing...\" : \"Unlock Pro — \\(licenseService.displayPriceLabel)\")"))
    }
}

struct FreeTierPolicyTests {
    @Test("Basic tier locks live dashboard ranges until Pro access")
    func basicTierLocksLiveDashboardRangesUntilProAccess() {
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.today, isPro: false))
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.sevenDays, isPro: false))
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.thirtyDays, isPro: false))
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.allTime, isPro: false))
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.custom, isPro: false))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.today, isPro: true))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.allTime, isPro: true))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.custom, isPro: true))
    }

    @Test("Free tier order preview stays capped to a small recent slice")
    func freeTierOrderPreviewLimitStaysSmall() {
        #expect(SaneSalesFreeTierPolicy.recentOrderPreviewLimit == 20)
    }

    @Test("Free tier always defaults to today")
    func freeTierPreferredDashboardRangeStaysOnToday() {
        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .today,
            isPro: false,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .today)

        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .allTime,
            isPro: false,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .today)

        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .allTime,
            isPro: true,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .allTime)
    }

    @Test("Pro orders default to all history when today is empty")
    func proOrdersDefaultToAllHistoryWhenTodayIsEmpty() {
        #expect(SaneSalesFreeTierPolicy.preferredOrdersRange(
            currentRange: .today,
            isPro: true,
            isSearching: false,
            visibleOrderCount: 0,
            availableOrderCount: 12
        ) == .allTime)

        #expect(SaneSalesFreeTierPolicy.preferredOrdersRange(
            currentRange: .today,
            isPro: true,
            isSearching: true,
            visibleOrderCount: 0,
            availableOrderCount: 12
        ) == .today)

        #expect(SaneSalesFreeTierPolicy.preferredOrdersRange(
            currentRange: .custom,
            isPro: true,
            isSearching: false,
            visibleOrderCount: 0,
            availableOrderCount: 12
        ) == .custom)

        #expect(SaneSalesFreeTierPolicy.preferredOrdersRange(
            currentRange: .allTime,
            isPro: false,
            isSearching: false,
            visibleOrderCount: 0,
            availableOrderCount: 12
        ) == .today)
    }

    @Test("Legacy trial state does not authorize live provider access")
    @MainActor
    func legacyTrialStateDoesNotAuthorizeLiveProviderAccess() {
        let manager = SalesManager()
        manager.resetForUITests()
        manager.isLemonSqueezyConnected = true
        let now = Date(timeIntervalSince1970: 1_775_520_000)

        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: false, now: now)

        #expect(!manager.isPro)
        #expect(!manager.hasLiveProviderAccess)
        #expect(!manager.trialState.isActive)
        #expect(manager.needsProForAdditionalProvider)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Basic requires Pro for all live provider connections")
    @MainActor
    func basicRequiresProForAllLiveProviderConnections() {
        let manager = SalesManager()
        manager.resetForUITests()
        manager.isLemonSqueezyConnected = true
        let now = Date(timeIntervalSince1970: 1_775_520_000)

        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: false, now: now)

        #expect(!manager.isPro)
        #expect(!manager.trialState.isActive)
        #expect(manager.needsProForAdditionalProvider)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Demo mode does not bypass Pro for live provider connections")
    @MainActor
    func demoModeDoesNotBypassProForLiveProviderConnections() {
        let manager = SalesManager()
        manager.resetForUITests()
        let now = Date(timeIntervalSince1970: 1_775_520_000)

        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true, now: now)

        #expect(manager.isDemoModeActive)
        #expect(manager.isPro)
        #expect(!manager.hasLiveProviderAccess)
        #expect(!manager.trialState.isActive)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Basic blocks refresh before fetching live data")
    @MainActor
    func basicBlocksRefreshBeforeFetchingLiveData() async {
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }
        manager.isLemonSqueezyConnected = true
        manager.metrics = SalesMetrics(
            todayRevenue: 900,
            todayOrders: 1,
            thirtyDayRevenue: 900,
            thirtyDayOrders: 1,
            monthRevenue: 900,
            monthOrders: 1,
            allTimeRevenue: 900,
            allTimeOrders: 1,
            dailyBreakdown: [],
            productBreakdown: []
        )

        await manager.refresh()

        #expect(!manager.isPro)
        #expect(!manager.trialState.isActive)
        #expect(manager.metrics.allTimeRevenue == 0)
        if case let .proRequired(feature)? = manager.error {
            #expect(feature == "Live sales tracking")
        } else {
            Issue.record("Expected refresh to require Pro")
        }
    }

    @Test("Demo mode does not grant live refresh access")
    @MainActor
    func demoModeDoesNotGrantLiveRefreshAccess() async {
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }
        manager.isLemonSqueezyConnected = true
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)

        await manager.refresh()

        #expect(manager.isDemoModeActive)
        #expect(!manager.hasLiveProviderAccess)
        if case let .proRequired(feature)? = manager.error {
            #expect(feature == "Live sales tracking")
        } else {
            Issue.record("Expected demo mode refresh with live provider to require Pro")
        }
    }

    @Test("Demo fixtures still show sample data without granting live access")
    @MainActor
    func demoFixturesShowSampleDataWithoutGrantingLiveAccess() {
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }

        manager.enableDemoMode()
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)

        #expect(manager.isDemoModeActive)
        #expect(manager.isPro)
        #expect(!manager.hasLiveProviderAccess)
        #expect(!manager.orders.isEmpty)
        #expect(!manager.products.isEmpty)
        #expect(!manager.stores.isEmpty)
    }

    @Test("Demo provider deletion cannot reset Pro gate")
    @MainActor
    func demoProviderDeletionCannotResetProGate() {
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }

        manager.enableDemoMode()
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)
        manager.removeLemonSqueezyAPIKey()
        manager.removeGumroadAPIKey()
        manager.removeStripeAPIKey()
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)

        #expect(!manager.trialState.isActive)
        #expect(!manager.hasLiveProviderAccess)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Deleting one demo provider cannot reconnect it as live without Pro")
    @MainActor
    func deletingOneDemoProviderCannotReconnectItAsLiveWithoutPro() {
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }

        manager.enableDemoMode()
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)
        manager.removeLemonSqueezyAPIKey()
        manager.updateProAccess(isPaidPro: false, forcePro: false, demoModeEnabled: true)

        #expect(manager.connectedProviders.contains(.gumroad))
        #expect(manager.connectedProviders.contains(.stripe))
        #expect(!manager.connectedProviders.contains(.lemonSqueezy))
        #expect(!manager.trialState.isActive)
        #expect(!manager.hasLiveProviderAccess)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Basic tier requires Pro for every live provider connection")
    @MainActor
    func basicTierRequiresProForEveryLiveProviderConnection() {
        let manager = SalesManager()
        manager.resetForUITests()

        #expect(manager.needsProForAdditionalProvider)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
        #expect(manager.requiresProForProviderConnection(.gumroad))
        #expect(manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Paid Pro allows multiple providers")
    @MainActor
    func paidProAllowsMultipleProviders() {
        let manager = SalesManager()
        manager.resetForUITests()
        manager.isLemonSqueezyConnected = true
        manager.updateProAccess(isPaidPro: true, forcePro: false, demoModeEnabled: false)

        #expect(!manager.needsProForAdditionalProvider)
        #expect(!manager.requiresProForProviderConnection(.gumroad))
        #expect(!manager.requiresProForProviderConnection(.stripe))
    }

    @Test("Unpaid live access reset clears provider credentials and returns to demo")
    @MainActor
    func unpaidLiveAccessResetClearsProviderCredentialsAndReturnsToDemo() {
        setenv("SANEAPPS_BYPASS_KEYCHAIN_IN_DEBUG", "1", 1)
        defer { unsetenv("SANEAPPS_BYPASS_KEYCHAIN_IN_DEBUG") }
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }

        KeychainService.save(string: "test_ls_key", account: KeychainService.lemonSqueezyAPIKey)
        manager.isLemonSqueezyConnected = true
        manager.orders = DemoData.allOrders
        manager.products = DemoData.allProducts
        manager.stores = DemoData.allStores
        manager.metrics = SalesMetrics.compute(from: manager.orders)

        manager.resetUnpaidLiveAccessToDemoIfNeeded(isPaidOrForced: false)

        #expect(!KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey))
        #expect(manager.isDemoModeActive)
        #expect(manager.isPro)
        #expect(!manager.hasLiveProviderAccess)
        #expect(!manager.orders.isEmpty)
        #expect(manager.requiresProForProviderConnection(.lemonSqueezy))
    }

    @Test("Paid live access reset preserves provider credentials")
    @MainActor
    func paidLiveAccessResetPreservesProviderCredentials() {
        setenv("SANEAPPS_BYPASS_KEYCHAIN_IN_DEBUG", "1", 1)
        defer { unsetenv("SANEAPPS_BYPASS_KEYCHAIN_IN_DEBUG") }
        let manager = SalesManager()
        manager.resetForUITests()
        defer { SalesManager.resetUITestPersistentState() }

        KeychainService.save(string: "test_ls_key", account: KeychainService.lemonSqueezyAPIKey)
        manager.isLemonSqueezyConnected = true

        manager.resetUnpaidLiveAccessToDemoIfNeeded(isPaidOrForced: true)

        #expect(KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey))
        #expect(manager.isLemonSqueezyConnected)
    }

    @Test("Shared Pro flag only recognizes paid widget keys")
    func sharedProFlagOnlyRecognizesPaidWidgetKeys() {
        let suiteName = "tests.sanesales.sharedstore.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated defaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(!SharedStore.isProEnabled(defaults: defaults))

        defaults.set(true, forKey: SharedStore.paidProEnabledKey)
        #expect(SharedStore.isProEnabled(defaults: defaults))

        defaults.removeObject(forKey: SharedStore.paidProEnabledKey)
        defaults.set(true, forKey: SharedStore.proEnabledKey)
        #expect(!SharedStore.isProEnabled(defaults: defaults))

        defaults.removeObject(forKey: SharedStore.proEnabledKey)
        defaults.set(true, forKey: SharedStore.macOSWidgetsPaidProEnabledKey)
        #expect(SharedStore.isProEnabled(defaults: defaults))

        defaults.removeObject(forKey: SharedStore.macOSWidgetsPaidProEnabledKey)
        defaults.set(true, forKey: SharedStore.macOSWidgetsProEnabledKey)
        #expect(!SharedStore.isProEnabled(defaults: defaults))
    }
}

struct SaneSalesTrialPolicyTests {
    @Test("Retired trial policy never starts before live data is connected")
    func retiredTrialPolicyNeverStartsBeforeLiveDataConnection() throws {
        let suiteName = "tests.sanesales.trial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = SaneSalesTrialPolicy.ensureTrialStartedIfNeeded(
            defaults: defaults,
            now: Date(timeIntervalSince1970: 1_775_520_000),
            isPaidPro: false,
            hasConnectedProviders: false,
            demoModeEnabled: false
        )

        #expect(!state.isActive)
        #expect(defaults.object(forKey: SaneSalesTrialPolicy.trialStartedAtKey) == nil)
    }

    @Test("Retired trial policy does not start for live data")
    func retiredTrialPolicyDoesNotStartForLiveData() throws {
        let suiteName = "tests.sanesales.trial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date(timeIntervalSince1970: 1_775_520_000)

        let state = SaneSalesTrialPolicy.ensureTrialStartedIfNeeded(
            defaults: defaults,
            now: now,
            isPaidPro: false,
            hasConnectedProviders: true,
            demoModeEnabled: false
        )

        #expect(!state.isActive)
        #expect(defaults.object(forKey: SaneSalesTrialPolicy.trialStartedAtKey) == nil)
    }

    @Test("Paid Pro and demo mode keep retired trial unused")
    func paidProAndDemoModeKeepRetiredTrialUnused() throws {
        let suiteName = "tests.sanesales.trial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date(timeIntervalSince1970: 1_775_520_000)

        _ = SaneSalesTrialPolicy.ensureTrialStartedIfNeeded(
            defaults: defaults,
            now: now,
            isPaidPro: true,
            hasConnectedProviders: true,
            demoModeEnabled: false
        )
        #expect(defaults.object(forKey: SaneSalesTrialPolicy.trialStartedAtKey) == nil)

        _ = SaneSalesTrialPolicy.ensureTrialStartedIfNeeded(
            defaults: defaults,
            now: now,
            isPaidPro: false,
            hasConnectedProviders: true,
            demoModeEnabled: true
        )
        #expect(defaults.object(forKey: SaneSalesTrialPolicy.trialStartedAtKey) == nil)
    }
}

// MARK: - Test-visible LS types (mirror private types for parsing tests)

struct TestOrdersResponse: Decodable {
    let data: [TestOrderItem]
    let meta: TestMeta
}

struct TestOrderItem: Decodable {
    let id: String
    let attributes: TestOrderAttributes
}

struct TestOrderAttributes: Decodable {
    let status: String
    let total: Int
    let currency: String
    let userEmail: String?
    let userName: String?
    let firstOrderItem: TestFirstOrderItem?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case status, total, currency
        case userEmail = "user_email"
        case userName = "user_name"
        case firstOrderItem = "first_order_item"
        case createdAt = "created_at"
    }
}

struct TestFirstOrderItem: Decodable {
    let productName: String
    let variantName: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case variantName = "variant_name"
    }
}

struct TestMeta: Decodable {
    let page: TestPageInfo
}

struct TestPageInfo: Decodable {
    let lastPage: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let camelCase = try container.decodeIfPresent(Int.self, forKey: .lastPage) {
            lastPage = camelCase
            return
        }
        if let snakeCase = try container.decodeIfPresent(Int.self, forKey: .lastPageSnakeCase) {
            lastPage = snakeCase
            return
        }
        throw DecodingError.keyNotFound(
            CodingKeys.lastPage,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing lastPage/last_page")
        )
    }

    private enum CodingKeys: String, CodingKey {
        case lastPage
        case lastPageSnakeCase = "last_page"
    }
}

struct TestStoresResponse: Decodable {
    let data: [TestStoreItem]
}

struct TestStoreItem: Decodable {
    let id: String
    let attributes: TestStoreAttributes
}

struct TestStoreAttributes: Decodable {
    let name: String
    let slug: String?
    let currency: String
    let totalRevenue: Int
    let thirtyDayRevenue: Int
    let totalSales: Int
    let thirtyDaySales: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, slug, currency
        case totalRevenue = "total_revenue"
        case thirtyDayRevenue = "thirty_day_revenue"
        case totalSales = "total_sales"
        case thirtyDaySales = "thirty_day_sales"
        case createdAt = "created_at"
    }
}

private func loadSeededLemonSqueezyKey() -> String? {
    let environment = ProcessInfo.processInfo.environment

    if let inline = environment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !inline.isEmpty
    {
        return inline
    }

    if let encoded = environment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !encoded.isEmpty,
        let data = Data(base64Encoded: encoded),
        let decoded = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !decoded.isEmpty
    {
        return decoded
    }

    let fallbackURL = URL(fileURLWithPath: "/tmp/saneapps_test_lemonsqueezy_api_key.b64")
    if let encoded = try? String(contentsOf: fallbackURL, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !encoded.isEmpty,
        let data = Data(base64Encoded: encoded),
        let decoded = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !decoded.isEmpty
    {
        return decoded
    }

    return nil
}

private func saneUIRoot(from projectRoot: URL) throws -> URL {
    let relativeRoot = projectRoot
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("infra/SaneUI")
    if FileManager.default.fileExists(atPath: relativeRoot.appendingPathComponent("Sources/SaneUI").path) {
        return relativeRoot
    }

    let canonicalRoot = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("SaneApps/infra/SaneUI")
    if FileManager.default.fileExists(atPath: canonicalRoot.appendingPathComponent("Sources/SaneUI").path) {
        return canonicalRoot
    }

    throw CocoaError(.fileNoSuchFile)
}
