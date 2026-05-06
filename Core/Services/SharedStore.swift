import Foundation

enum SharedStore {
    static let appGroupID = "group.com.sanesales.app"

    static let salesSnapshotKey = "sales_snapshot"
    static let cachedOrdersKey = "cached_orders"
    static let cachedProductsKey = "cached_products"
    static let cachedStoreKey = "cached_store"
    static let cacheLastUpdatedKey = "cache_last_updated"
    static let proEnabledKey = "pro_enabled"
    static let macOSWidgetsProEnabledKey = "macos_widgets_pro_enabled"
    static let paidProEnabledKey = "paid_pro_enabled"
    static let macOSWidgetsPaidProEnabledKey = "macos_widgets_paid_pro_enabled"

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func isProEnabled(defaults: UserDefaults = userDefaults()) -> Bool {
        defaults.bool(forKey: paidProEnabledKey) ||
            defaults.bool(forKey: macOSWidgetsPaidProEnabledKey) ||
            defaults.bool(forKey: proEnabledKey) ||
            defaults.bool(forKey: macOSWidgetsProEnabledKey) ||
            SaneSalesTrialPolicy.isTrialActive(defaults: defaults)
    }

    static func setPaidProEnabled(_ enabled: Bool, defaults: UserDefaults = userDefaults()) {
        defaults.set(enabled, forKey: paidProEnabledKey)
        defaults.set(enabled, forKey: macOSWidgetsPaidProEnabledKey)
        defaults.set(enabled, forKey: proEnabledKey)
        defaults.set(enabled, forKey: macOSWidgetsProEnabledKey)
    }

    static func writeSalesSnapshot(from orders: [Order], defaults: UserDefaults = userDefaults()) {
        let snapshot = SharedSalesSnapshot.make(from: orders, lastUpdated: Date())
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: salesSnapshotKey)
        defaults.set(snapshot.lastUpdated.timeIntervalSince1970, forKey: cacheLastUpdatedKey)
    }

    static func loadSalesSnapshot(defaults: UserDefaults = userDefaults()) -> SharedSalesSnapshot? {
        guard let data = defaults.data(forKey: salesSnapshotKey) else { return nil }
        guard let snapshot = try? JSONDecoder().decode(SharedSalesSnapshot.self, from: data) else {
            defaults.removeObject(forKey: salesSnapshotKey)
            return nil
        }
        return snapshot
    }

    static func clearSharedSalesData(defaults: UserDefaults = userDefaults()) {
        defaults.removeObject(forKey: salesSnapshotKey)
        defaults.removeObject(forKey: cachedOrdersKey)
        defaults.removeObject(forKey: cachedProductsKey)
        defaults.removeObject(forKey: cachedStoreKey)
        defaults.removeObject(forKey: cacheLastUpdatedKey)
    }

    static func clearLegacyRawCache(defaults: UserDefaults = userDefaults()) {
        defaults.removeObject(forKey: cachedOrdersKey)
        defaults.removeObject(forKey: cachedProductsKey)
        defaults.removeObject(forKey: cachedStoreKey)
    }
}

struct SharedSalesSnapshot: Codable, Equatable, Sendable {
    let todayRevenue: Int
    let todayOrders: Int
    let thirtyDayRevenue: Int
    let thirtyDayOrders: Int
    let monthRevenue: Int
    let monthOrders: Int
    let allTimeRevenue: Int
    let allTimeOrders: Int
    let currency: String
    let providerRows: [SharedProviderSalesRow]
    let recentRows: [SharedRecentSaleRow]
    let lastUpdated: Date

    static func make(from orders: [Order], lastUpdated: Date) -> SharedSalesSnapshot {
        let metrics = SalesMetrics.compute(from: orders)
        let currency = dominantCurrency(for: orders)
        let paidOrders = orders.filter { $0.status == .paid }
        let providerRows = Dictionary(grouping: paidOrders, by: \.provider)
            .map { provider, providerOrders in
                SharedProviderSalesRow(
                    provider: provider,
                    orderCount: providerOrders.count,
                    revenueCents: providerOrders.reduce(0) { $0 + $1.netTotal },
                    currency: dominantCurrency(for: providerOrders)
                )
            }
            .sorted { $0.revenueCents > $1.revenueCents }

        let recentRows = orders
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(15)
            .map {
                SharedRecentSaleRow(
                    productName: $0.productName,
                    provider: $0.provider,
                    amountCents: $0.netTotal,
                    currency: $0.currency,
                    createdAt: $0.createdAt
                )
            }

        return SharedSalesSnapshot(
            todayRevenue: metrics.todayRevenue,
            todayOrders: metrics.todayOrders,
            thirtyDayRevenue: metrics.thirtyDayRevenue,
            thirtyDayOrders: metrics.thirtyDayOrders,
            monthRevenue: metrics.monthRevenue,
            monthOrders: metrics.monthOrders,
            allTimeRevenue: metrics.allTimeRevenue,
            allTimeOrders: metrics.allTimeOrders,
            currency: currency,
            providerRows: providerRows,
            recentRows: recentRows,
            lastUpdated: lastUpdated
        )
    }

    private static func dominantCurrency(for orders: [Order]) -> String {
        Dictionary(grouping: orders, by: \.currency)
            .mapValues(\.count)
            .max(by: { $0.value < $1.value })?.key ?? "USD"
    }
}

struct SharedProviderSalesRow: Codable, Equatable, Sendable {
    let provider: SalesProviderType
    let orderCount: Int
    let revenueCents: Int
    let currency: String
}

struct SharedRecentSaleRow: Codable, Equatable, Sendable {
    let productName: String
    let provider: SalesProviderType
    let amountCents: Int
    let currency: String
    let createdAt: Date
}
