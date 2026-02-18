import Foundation

/// Offline cache using UserDefaults. Stores last-fetched data for display when offline.
actor CacheService {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = SharedStore.userDefaults()) {
        self.defaults = defaults
    }

    // MARK: - Orders

    func cacheOrders(_ orders: [Order]) {
        guard let data = try? encoder.encode(orders) else { return }
        defaults.set(data, forKey: SharedStore.cachedOrdersKey)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedStore.cacheLastUpdatedKey)
    }

    func loadCachedOrders() -> [Order]? {
        guard let data = defaults.data(forKey: SharedStore.cachedOrdersKey) else { return nil }
        return try? decoder.decode([Order].self, from: data)
    }

    // MARK: - Products

    func cacheProducts(_ products: [Product]) {
        guard let data = try? encoder.encode(products) else { return }
        defaults.set(data, forKey: SharedStore.cachedProductsKey)
    }

    func loadCachedProducts() -> [Product]? {
        guard let data = defaults.data(forKey: SharedStore.cachedProductsKey) else { return nil }
        return try? decoder.decode([Product].self, from: data)
    }

    // MARK: - Store

    func cacheStore(_ store: Store) {
        guard let data = try? encoder.encode(store) else { return }
        defaults.set(data, forKey: SharedStore.cachedStoreKey)
    }

    func loadCachedStore() -> Store? {
        guard let data = defaults.data(forKey: SharedStore.cachedStoreKey) else { return nil }
        return try? decoder.decode(Store.self, from: data)
    }

    // MARK: - Metadata

    var lastUpdated: Date? {
        let ts = defaults.double(forKey: SharedStore.cacheLastUpdatedKey)
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
    }
}
