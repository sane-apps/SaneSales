import Foundation
import SaneUI
import Testing

@testable import SaneSales

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
        let data = json.data(using: .utf8)!
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
        let data = json.data(using: .utf8)!
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
        let data = json.data(using: .utf8)!
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
        let data = json.data(using: .utf8)!
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
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder.lemonSqueezy.decode(TestStoresResponse.self, from: data)

        #expect(response.data.count == 1)
        #expect(response.data[0].attributes.name == "SaneApps")
        #expect(response.data[0].attributes.createdAt != nil)
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
        let data = json.data(using: .utf8)!
        let status = try JSONDecoder().decode(OrderStatus.self, from: data)
        #expect(status == .unknown)
    }
}

struct AppStartupPolicyTests {
    @Test("iOS setup flow shows onboarding for first launch or broken startup")
    func iosSetupFlowShowsOnboardingWhenNeeded() {
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

    #if os(macOS)
        @Test("Dock default stays hidden")
        func dockDefaultIsHidden() {
            let defaults = UserDefaults(suiteName: #function)!
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
            let source = try String(
                contentsOf: projectRoot.appendingPathComponent("macOS/MenuBarManager.swift"),
                encoding: .utf8
            )

            #expect(source.contains("#if !APP_STORE"))
            #expect(source.contains("Check for Updates"))
        }
    #endif
}

struct FreeTierPolicyTests {
    @Test("Free tier keeps recent dashboard ranges open")
    func freeTierDashboardRangesStayUseful() {
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.today, isPro: false))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.sevenDays, isPro: false))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.thirtyDays, isPro: false))
        #expect(SaneSalesFreeTierPolicy.locksDashboardRange(.allTime, isPro: false))
        #expect(!SaneSalesFreeTierPolicy.locksDashboardRange(.allTime, isPro: true))
    }

    @Test("Free tier order preview stays capped to a small recent slice")
    func freeTierOrderPreviewLimitStaysSmall() {
        #expect(SaneSalesFreeTierPolicy.recentOrderPreviewLimit == 20)
    }

    @Test("Free tier defaults to a recent snapshot when today is empty")
    func freeTierPreferredDashboardRangeAvoidsDeadFirstImpression() {
        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .today,
            isPro: false,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .sevenDays)

        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .today,
            isPro: false,
            todayOrders: 2,
            thirtyDayOrders: 12
        ) == .today)

        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .allTime,
            isPro: false,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .sevenDays)

        #expect(SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: .allTime,
            isPro: true,
            todayOrders: 0,
            thirtyDayOrders: 12
        ) == .allTime)
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
       !inline.isEmpty {
        return inline
    }

    if let encoded = environment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !encoded.isEmpty,
       let data = Data(base64Encoded: encoded),
       let decoded = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !decoded.isEmpty {
        return decoded
    }

    let fallbackURL = URL(fileURLWithPath: "/tmp/saneapps_test_lemonsqueezy_api_key.b64")
    if let encoded = try? String(contentsOf: fallbackURL, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !encoded.isEmpty,
       let data = Data(base64Encoded: encoded),
       let decoded = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !decoded.isEmpty {
        return decoded
    }

    return nil
}
