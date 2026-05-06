import Foundation

/// Offline cache using UserDefaults. Stores last-fetched data for display when offline.
actor CacheService {
    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, legacyDefaults: UserDefaults? = nil) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults ?? (defaults === UserDefaults.standard ? SharedStore.userDefaults() : nil)
    }

    // MARK: - Orders

    func cacheOrders(_ orders: [Order]) {
        guard let data = try? encoder.encode(orders) else { return }
        defaults.set(data, forKey: SharedStore.cachedOrdersKey)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedStore.cacheLastUpdatedKey)
    }

    func loadCachedOrders() -> [Order]? {
        if let data = defaults.data(forKey: SharedStore.cachedOrdersKey) {
            guard let orders = try? decoder.decode([Order].self, from: data) else {
                defaults.removeObject(forKey: SharedStore.cachedOrdersKey)
                return nil
            }
            return orders
        }

        guard let legacyDefaults,
              legacyDefaults !== defaults,
              let data = legacyDefaults.data(forKey: SharedStore.cachedOrdersKey),
              let orders = try? decoder.decode([Order].self, from: data)
        else { return nil }

        cacheOrders(orders)
        SharedStore.writeSalesSnapshot(from: orders, defaults: legacyDefaults)
        legacyDefaults.removeObject(forKey: SharedStore.cachedOrdersKey)
        return orders
    }

    // MARK: - Products

    func cacheProducts(_ products: [Product]) {
        guard let data = try? encoder.encode(products) else { return }
        defaults.set(data, forKey: SharedStore.cachedProductsKey)
    }

    func loadCachedProducts() -> [Product]? {
        if let data = defaults.data(forKey: SharedStore.cachedProductsKey) {
            guard let products = try? decoder.decode([Product].self, from: data) else {
                defaults.removeObject(forKey: SharedStore.cachedProductsKey)
                return nil
            }
            return products
        }

        guard let legacyDefaults,
              legacyDefaults !== defaults,
              let data = legacyDefaults.data(forKey: SharedStore.cachedProductsKey),
              let products = try? decoder.decode([Product].self, from: data)
        else { return nil }

        cacheProducts(products)
        legacyDefaults.removeObject(forKey: SharedStore.cachedProductsKey)
        return products
    }

    // MARK: - Store

    func cacheStore(_ store: Store) {
        guard let data = try? encoder.encode(store) else { return }
        defaults.set(data, forKey: SharedStore.cachedStoreKey)
    }

    func cacheSalesData(orders: [Order], products: [Product], stores: [Store]) {
        cacheOrders(orders)
        cacheProducts(products)
        if let firstStore = stores.first {
            cacheStore(firstStore)
        } else {
            defaults.removeObject(forKey: SharedStore.cachedStoreKey)
        }
    }

    func loadCachedStore() -> Store? {
        if let data = defaults.data(forKey: SharedStore.cachedStoreKey) {
            guard let store = try? decoder.decode(Store.self, from: data) else {
                defaults.removeObject(forKey: SharedStore.cachedStoreKey)
                return nil
            }
            return store
        }

        guard let legacyDefaults,
              legacyDefaults !== defaults,
              let data = legacyDefaults.data(forKey: SharedStore.cachedStoreKey),
              let store = try? decoder.decode(Store.self, from: data)
        else { return nil }

        cacheStore(store)
        legacyDefaults.removeObject(forKey: SharedStore.cachedStoreKey)
        return store
    }

    // MARK: - Metadata

    var lastUpdated: Date? {
        var ts = defaults.double(forKey: SharedStore.cacheLastUpdatedKey)
        if ts <= 0, let legacyDefaults, legacyDefaults !== defaults {
            ts = legacyDefaults.double(forKey: SharedStore.cacheLastUpdatedKey)
        }
        guard ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    var lastUpdatedFormatted: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func clearCache() {
        defaults.removeObject(forKey: SharedStore.cachedOrdersKey)
        defaults.removeObject(forKey: SharedStore.cachedProductsKey)
        defaults.removeObject(forKey: SharedStore.cachedStoreKey)
        defaults.removeObject(forKey: SharedStore.cacheLastUpdatedKey)
        SharedStore.clearSharedSalesData()
    }
}
