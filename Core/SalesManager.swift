import Foundation
import SwiftUI
#if canImport(WidgetKit)
    import WidgetKit
#endif

enum SalesSetupFlowPolicy {
    static func welcomeOverride(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool? {
        if arguments.contains("--force-onboarding") {
            return false
        }

        if arguments.contains("--skip-onboarding") || environment["SANEAPPS_SKIP_ONBOARDING"] == "1" {
            return true
        }

        return nil
    }

    static func hasUsableContent(ordersCount: Int, productsCount: Int) -> Bool {
        ordersCount > 0 || productsCount > 0
    }

    static func shouldTreatInitialRefreshFailureAsConnectionFailure(
        error: SalesAPIError?,
        ordersCount: Int,
        productsCount: Int
    ) -> Bool {
        error != nil && !hasUsableContent(ordersCount: ordersCount, productsCount: productsCount)
    }

    static func shouldShowInitialSetup(
        hasSeenWelcome: Bool,
        demoModeEnabled: Bool,
        hasConnectedProviders: Bool,
        hasAnyData: Bool,
        hasError: Bool,
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        if arguments.contains("--force-onboarding") {
            return true
        }

        if arguments.contains("--skip-onboarding") || environment["SANEAPPS_SKIP_ONBOARDING"] == "1" {
            return false
        }

        if arguments.contains("--demo") || demoModeEnabled {
            return false
        }

        if !hasSeenWelcome || !hasConnectedProviders {
            return true
        }

        if hasError && !hasAnyData {
            return true
        }

        return false
    }
}

/// Central state manager for all sales data. Coordinates providers, caching, and UI state.
@MainActor
@Observable
final class SalesManager {
    // MARK: - State

    var orders: [Order] = []
    var products: [Product] = []
    var stores: [Store] = []
    var metrics: SalesMetrics = .empty

    var isLoading = false
    var error: SalesAPIError?
    var lastUpdated: Date?

    // Per-provider connection state (stored, not computed — SwiftUI can't observe Keychain reads)
    var isLemonSqueezyConnected = false
    var isGumroadConnected = false
    var isStripeConnected = false

    /// Set by the app entry point — used for Pro feature gating across the app.
    /// Each platform syncs this from its active licensing backend.
    var isPro: Bool = false {
        didSet {
            #if os(macOS)
                let defaults = SharedStore.userDefaults()
                defaults.set(isPro, forKey: SharedStore.macOSWidgetsProEnabledKey)
            #endif
            reloadWidgets()
        }
    }

    var isAnyConnected: Bool {
        isLemonSqueezyConnected || isGumroadConnected || isStripeConnected
    }

    /// Most common currency across all orders (falls back to store currency, then USD).
    var primaryCurrency: String {
        guard !orders.isEmpty else {
            return stores.first?.currency ?? "USD"
        }
        let counts = Dictionary(grouping: orders, by: \.currency).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "USD"
    }

    var connectedProviders: [SalesProviderType] {
        var result: [SalesProviderType] = []
        if isLemonSqueezyConnected { result.append(.lemonSqueezy) }
        if isGumroadConnected { result.append(.gumroad) }
        if isStripeConnected { result.append(.stripe) }
        return result
    }

    /// True when a free-tier user tries to add a second provider.
    /// Used by the UI to show the Pro upsell instead of connecting.
    var needsProForAdditionalProvider: Bool {
        false
    }

    var planScopedOrders: [Order] {
        guard !isPro else { return orders }
        let calendar = Calendar.current
        return orders.filter { calendar.isDateInToday($0.createdAt) }
    }

    var planScopedMetrics: SalesMetrics {
        SalesMetrics.compute(from: planScopedOrders)
    }

    func allOrders(filteredBy provider: SalesProviderType?) -> [Order] {
        guard let provider else { return orders }
        return orders.filter { $0.provider == provider }
    }

    func planScopedOrders(filteredBy provider: SalesProviderType?) -> [Order] {
        let source = planScopedOrders
        guard let provider else { return source }
        return source.filter { $0.provider == provider }
    }

    /// Convenience for backward compat (onboarding checks this)
    var isConnected: Bool { isAnyConnected }

    // MARK: - Providers

    private var lemonSqueezyProvider: LemonSqueezyProvider?
    private var gumroadProvider: GumroadProvider?
    private var stripeProvider: StripeProvider?
    private let cache = CacheService()

    init() {
        applyLaunchBootstrapIfNeeded()

        if CommandLine.arguments.contains("--force-onboarding") {
            return
        }

        if CommandLine.arguments.contains("--demo")
            || UserDefaults.standard.bool(forKey: "demo_mode") {
            DemoData.loadInto(manager: self, connectedProviders: demoConnectedProviders())
            return
        }
        isLemonSqueezyConnected = KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey)
        isGumroadConnected = KeychainService.exists(account: KeychainService.gumroadAPIKey)
        isStripeConnected = KeychainService.exists(account: KeychainService.stripeAPIKey)
        loadCachedData()
        configureProviders()
    }

    private func applyLaunchBootstrapIfNeeded() {
        let environment = ProcessInfo.processInfo.environment

        if let hasSeenWelcomeOverride = SalesSetupFlowPolicy.welcomeOverride(
            arguments: CommandLine.arguments,
            environment: environment
        ) {
            UserDefaults.standard.set(hasSeenWelcomeOverride, forKey: "hasSeenWelcome")
        }

        #if DEBUG
            seedProviderKey(
                from: environment["SANEAPPS_TEST_LEMONSQUEEZY_API_KEY_B64"],
                account: KeychainService.lemonSqueezyAPIKey
            )
            seedProviderKey(
                from: environment["SANEAPPS_TEST_GUMROAD_API_KEY_B64"],
                account: KeychainService.gumroadAPIKey
            )
            seedProviderKey(
                from: environment["SANEAPPS_TEST_STRIPE_API_KEY_B64"],
                account: KeychainService.stripeAPIKey
            )
        #endif
    }

    private func seedProviderKey(from encodedValue: String?, account: String) {
        guard let encodedValue,
              let data = Data(base64Encoded: encodedValue),
              let decoded = String(data: data, encoding: .utf8),
              !decoded.isEmpty
        else { return }

        KeychainService.save(string: decoded, account: account)
    }

    // MARK: - Configuration

    func configureProviders() {
        if let key = KeychainService.loadString(account: KeychainService.lemonSqueezyAPIKey) {
            lemonSqueezyProvider = LemonSqueezyProvider(apiKey: key)
        }
        if let key = KeychainService.loadString(account: KeychainService.gumroadAPIKey) {
            gumroadProvider = GumroadProvider(apiKey: key)
        }
        if let key = KeychainService.loadString(account: KeychainService.stripeAPIKey) {
            stripeProvider = StripeProvider(apiKey: key)
        }
    }

    // MARK: - LemonSqueezy Key Management

    func setLemonSqueezyAPIKey(_ key: String) async -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            error = .invalidAPIKey
            return false
        }

        let provider = LemonSqueezyProvider(apiKey: normalizedKey)
        do {
            let valid = try await provider.validateAPIKey(normalizedKey)
            if valid {
                KeychainService.save(string: normalizedKey, account: KeychainService.lemonSqueezyAPIKey)
                lemonSqueezyProvider = provider
                isLemonSqueezyConnected = true
                await refresh()
                if SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
                    error: error,
                    ordersCount: orders.count,
                    productsCount: products.count
                ) {
                    return false
                }
                return true
            }
            error = .invalidAPIKey
            return false
        } catch {
            self.error = error as? SalesAPIError ?? .networkError(underlying: error)
            return false
        }
    }

    func removeLemonSqueezyAPIKey() {
        KeychainService.delete(account: KeychainService.lemonSqueezyAPIKey)
        lemonSqueezyProvider = nil
        isLemonSqueezyConnected = false
        removeProviderData(for: .lemonSqueezy)
        reloadWidgets()
    }

    // MARK: - Gumroad Key Management

    func setGumroadAPIKey(_ key: String) async -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            error = .invalidAPIKey
            return false
        }

        let provider = GumroadProvider(apiKey: normalizedKey)
        do {
            let valid = try await provider.validateAPIKey(normalizedKey)
            if valid {
                KeychainService.save(string: normalizedKey, account: KeychainService.gumroadAPIKey)
                gumroadProvider = provider
                isGumroadConnected = true
                await refresh()
                if SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
                    error: error,
                    ordersCount: orders.count,
                    productsCount: products.count
                ) {
                    return false
                }
                return true
            }
            error = .invalidAPIKey
            return false
        } catch {
            self.error = error as? SalesAPIError ?? .networkError(underlying: error)
            return false
        }
    }

    func removeGumroadAPIKey() {
        KeychainService.delete(account: KeychainService.gumroadAPIKey)
        gumroadProvider = nil
        isGumroadConnected = false
        removeProviderData(for: .gumroad)
        reloadWidgets()
    }

    // MARK: - Stripe Key Management

    func setStripeAPIKey(_ key: String) async -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            error = .invalidAPIKey
            return false
        }

        let provider = StripeProvider(apiKey: normalizedKey)
        do {
            let valid = try await provider.validateAPIKey(normalizedKey)
            if valid {
                KeychainService.save(string: normalizedKey, account: KeychainService.stripeAPIKey)
                stripeProvider = provider
                isStripeConnected = true
                await refresh()
                if SalesSetupFlowPolicy.shouldTreatInitialRefreshFailureAsConnectionFailure(
                    error: error,
                    ordersCount: orders.count,
                    productsCount: products.count
                ) {
                    return false
                }
                return true
            }
            error = .invalidAPIKey
            return false
        } catch {
            self.error = error as? SalesAPIError ?? .networkError(underlying: error)
            return false
        }
    }

    func removeStripeAPIKey() {
        KeychainService.delete(account: KeychainService.stripeAPIKey)
        stripeProvider = nil
        isStripeConnected = false
        removeProviderData(for: .stripe)
        reloadWidgets()
    }

    // MARK: - Data Loading (Multi-Provider)

    func refresh() async {
        guard isAnyConnected else {
            error = .noAPIKey
            return
        }

        isLoading = true
        error = nil

        var allOrders: [Order] = []
        var allProducts: [Product] = []
        var allStores: [Store] = []

        // Fetch from all connected providers concurrently
        await withTaskGroup(of: ProviderResult.self) { group in
            if let provider = lemonSqueezyProvider {
                group.addTask { await Self.fetchProvider(provider) }
            }
            if let provider = gumroadProvider {
                group.addTask { await Self.fetchProvider(provider) }
            }
            if let provider = stripeProvider {
                group.addTask { await Self.fetchProvider(provider) }
            }

            for await result in group {
                allOrders.append(contentsOf: result.orders)
                allProducts.append(contentsOf: result.products)
                if let store = result.store { allStores.append(store) }
                if let err = result.error {
                    // Store first error but don't stop other providers
                    if self.error == nil {
                        self.error = err
                    }
                }
            }
        }

        // Sort orders newest first
        allOrders.sort { $0.createdAt > $1.createdAt }

        orders = allOrders
        products = allProducts
        stores = allStores
        metrics = SalesMetrics.compute(from: allOrders)
        lastUpdated = Date()

        await cache.cacheOrders(allOrders)
        await cache.cacheProducts(allProducts)
        if let firstStore = allStores.first {
            await cache.cacheStore(firstStore)
        }

        isLoading = false
        reloadWidgets()
    }

    /// Fetch all data from a single provider. Runs off MainActor.
    private nonisolated static func fetchProvider(_ provider: any SalesProvider) async -> ProviderResult {
        var result = ProviderResult()
        do {
            async let fetchedOrders = provider.fetchAllOrders()
            async let fetchedProducts = provider.fetchProducts()
            async let fetchedStore = provider.fetchStore()

            let (orders, products, store) = try await (fetchedOrders, fetchedProducts, fetchedStore)
            result.orders = orders
            result.store = store

            // Fix product currencies: LS and Stripe products don't have currency in API,
            // so providers hardcode "USD". Replace with actual store currency.
            let storeCurrency = store.currency
            result.products = products.map { product in
                guard product.provider == .lemonSqueezy || product.provider == .stripe,
                      product.currency == "USD", storeCurrency != "USD"
                else { return product }
                var updated = product
                updated.currency = storeCurrency
                return updated
            }
        } catch {
            if let apiError = error as? SalesAPIError {
                result.error = apiError
            } else if error is DecodingError {
                result.error = .decodingError(underlying: error)
            } else {
                result.error = .networkError(underlying: error)
            }
        }
        return result
    }

    // MARK: - Helpers

    private func removeProviderData(for provider: SalesProviderType) {
        orders.removeAll { $0.provider == provider }
        products.removeAll { $0.provider == provider }
        stores.removeAll { $0.provider == provider }
        metrics = SalesMetrics.compute(from: orders)
        if !isAnyConnected {
            Task { await cache.clearCache() }
        }
    }

    // MARK: - Cache

    private func loadCachedData() {
        Task {
            if let cached = await cache.loadCachedOrders() {
                orders = cached
                metrics = SalesMetrics.compute(from: cached)
            }
            if let cached = await cache.loadCachedProducts() {
                products = cached
            }
            if let cached = await cache.loadCachedStore() {
                stores = [cached]
            }
            lastUpdated = await cache.lastUpdated
        }
    }

    // MARK: - Search & Filter

    func filteredOrders(search: String, provider: SalesProviderType? = nil) -> [Order] {
        var result = planScopedOrders(filteredBy: provider)
        guard !search.isEmpty else { return result }
        let query = search.lowercased()
        return result.filter {
            $0.customerName.lowercased().contains(query)
                || $0.customerEmail.lowercased().contains(query)
                || $0.productName.lowercased().contains(query)
                || ($0.identifier?.lowercased().contains(query) ?? false)
                || ($0.paymentMethod?.lowercased().contains(query) ?? false)
        }
    }

    func storeFor(_ provider: SalesProviderType) -> Store? {
        stores.first { $0.provider == provider }
    }

    // MARK: - Demo Mode

    func enableDemoMode() {
        UserDefaults.standard.set(true, forKey: "demo_mode")
        DemoData.loadInto(manager: self, connectedProviders: demoConnectedProviders())
        reloadWidgets()
    }

    func disableDemoMode() {
        UserDefaults.standard.set(false, forKey: "demo_mode")

        orders = []
        products = []
        stores = []
        metrics = .empty
        lastUpdated = nil

        isLemonSqueezyConnected = KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey)
        isGumroadConnected = KeychainService.exists(account: KeychainService.gumroadAPIKey)
        isStripeConnected = KeychainService.exists(account: KeychainService.stripeAPIKey)
        configureProviders()

        Task {
            await cache.clearCache()
            if isAnyConnected {
                await refresh()
            } else {
                reloadWidgets()
            }
        }
    }

    func resetForUITests() {
        UserDefaults.standard.set(false, forKey: "demo_mode")
        UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
        UserDefaults.standard.removeObject(forKey: "pendingSettingsRoute")
        UserDefaults.standard.removeObject(forKey: "selectedTimeRange")

        KeychainService.delete(account: KeychainService.lemonSqueezyAPIKey)
        KeychainService.delete(account: KeychainService.gumroadAPIKey)
        KeychainService.delete(account: KeychainService.stripeAPIKey)

        lemonSqueezyProvider = nil
        gumroadProvider = nil
        stripeProvider = nil

        isLemonSqueezyConnected = false
        isGumroadConnected = false
        isStripeConnected = false

        orders = []
        products = []
        stores = []
        metrics = .empty
        lastUpdated = nil
        error = nil
        isLoading = false

        Task { await cache.clearCache() }
        reloadWidgets()
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func demoConnectedProviders(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Set<SalesProviderType> {
        if let argument = arguments.first(where: { $0.hasPrefix("--demo-connected-provider=") }) {
            let rawValue = String(argument.dropFirst("--demo-connected-provider=".count))
            if let provider = SalesProviderType(rawValue: rawValue) {
                return [provider]
            }
        }

        if let environmentValue = environment["SANEAPPS_DEMO_CONNECTED_PROVIDERS"] {
            let providers = Set(
                environmentValue
                    .split(separator: ",")
                    .compactMap { SalesProviderType(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            )
            if !providers.isEmpty {
                return providers
            }
        }

        return Set(SalesProviderType.allCases)
    }
}

// MARK: - Provider Result

private struct ProviderResult: Sendable {
    var orders: [Order] = []
    var products: [Product] = []
    var store: Store?
    var error: SalesAPIError?
}
