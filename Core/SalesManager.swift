import Foundation
import SwiftUI

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

    /// Convenience for backward compat (onboarding checks this)
    var isConnected: Bool { isAnyConnected }

    // MARK: - Providers

    private var lemonSqueezyProvider: LemonSqueezyProvider?
    private var gumroadProvider: GumroadProvider?
    private var stripeProvider: StripeProvider?
    private let cache = CacheService()

    init() {
        #if DEBUG
            if CommandLine.arguments.contains("--demo")
                || UserDefaults.standard.bool(forKey: "demo_mode") {
                DemoData.loadInto(manager: self)
                return
            }
        #endif
        isLemonSqueezyConnected = KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey)
        isGumroadConnected = KeychainService.exists(account: KeychainService.gumroadAPIKey)
        isStripeConnected = KeychainService.exists(account: KeychainService.stripeAPIKey)
        loadCachedData()
        configureProviders()
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
        let provider = LemonSqueezyProvider(apiKey: key)
        do {
            let valid = try await provider.validateAPIKey(key)
            if valid {
                KeychainService.save(string: key, account: KeychainService.lemonSqueezyAPIKey)
                lemonSqueezyProvider = provider
                isLemonSqueezyConnected = true
                await refresh()
                return true
            }
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
    }

    // MARK: - Gumroad Key Management

    func setGumroadAPIKey(_ key: String) async -> Bool {
        let provider = GumroadProvider(apiKey: key)
        do {
            let valid = try await provider.validateAPIKey(key)
            if valid {
                KeychainService.save(string: key, account: KeychainService.gumroadAPIKey)
                gumroadProvider = provider
                isGumroadConnected = true
                await refresh()
                return true
            }
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
    }

    // MARK: - Stripe Key Management

    func setStripeAPIKey(_ key: String) async -> Bool {
        let provider = StripeProvider(apiKey: key)
        do {
            let valid = try await provider.validateAPIKey(key)
            if valid {
                KeychainService.save(string: key, account: KeychainService.stripeAPIKey)
                stripeProvider = provider
                isStripeConnected = true
                await refresh()
                return true
            }
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
        var result = orders
        if let provider {
            result = result.filter { $0.provider == provider }
        }
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
}

// MARK: - Provider Result

private struct ProviderResult: Sendable {
    var orders: [Order] = []
    var products: [Product] = []
    var store: Store?
    var error: SalesAPIError?
}
