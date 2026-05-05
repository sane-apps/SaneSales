import Foundation

enum SharedStore {
    static let appGroupID = "group.com.sanesales.app"

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
}
