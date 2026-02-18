import Foundation

enum SharedStore {
    static let appGroupID = "group.com.sanesales.app"

    static let cachedOrdersKey = "cached_orders"
    static let cachedProductsKey = "cached_products"
    static let cachedStoreKey = "cached_store"
    static let cacheLastUpdatedKey = "cache_last_updated"

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
