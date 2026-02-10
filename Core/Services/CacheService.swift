import Foundation

/// Offline cache using UserDefaults. Stores last-fetched data for display when offline.
actor CacheService {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let orders = "cached_orders"
        static let products = "cached_products"
        static let store = "cached_store"
        static let lastUpdated = "cache_last_updated"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Orders

    func cacheOrders(_ orders: [Order]) {
        guard let data = try? encoder.encode(orders) else { return }
        defaults.set(data, forKey: Keys.orders)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdated)
    }

    func loadCachedOrders() -> [Order]? {
        guard let data = defaults.data(forKey: Keys.orders) else { return nil }
        return try? decoder.decode([Order].self, from: data)
    }

    // MARK: - Products

    func cacheProducts(_ products: [Product]) {
        guard let data = try? encoder.encode(products) else { return }
        defaults.set(data, forKey: Keys.products)
    }

    func loadCachedProducts() -> [Product]? {
        guard let data = defaults.data(forKey: Keys.products) else { return nil }
        return try? decoder.decode([Product].self, from: data)
    }

    // MARK: - Store

    func cacheStore(_ store: Store) {
        guard let data = try? encoder.encode(store) else { return }
        defaults.set(data, forKey: Keys.store)
    }

    func loadCachedStore() -> Store? {
        guard let data = defaults.data(forKey: Keys.store) else { return nil }
        return try? decoder.decode(Store.self, from: data)
    }

    // MARK: - Metadata

    var lastUpdated: Date? {
        let ts = defaults.double(forKey: Keys.lastUpdated)
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
        defaults.removeObject(forKey: Keys.orders)
        defaults.removeObject(forKey: Keys.products)
        defaults.removeObject(forKey: Keys.store)
        defaults.removeObject(forKey: Keys.lastUpdated)
    }
}
