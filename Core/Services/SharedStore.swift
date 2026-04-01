import Foundation

enum SharedStore {
    static let appGroupID = "group.com.sanesales.app"

    static let cachedOrdersKey = "cached_orders"
    static let cachedProductsKey = "cached_products"
    static let cachedStoreKey = "cached_store"
    static let cacheLastUpdatedKey = "cache_last_updated"
    static let proEnabledKey = "pro_enabled"
    static let macOSWidgetsProEnabledKey = "macos_widgets_pro_enabled"

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func isProEnabled(defaults: UserDefaults = userDefaults()) -> Bool {
        defaults.bool(forKey: proEnabledKey) || defaults.bool(forKey: macOSWidgetsProEnabledKey)
    }
}
