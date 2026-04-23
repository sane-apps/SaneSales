import SwiftUI

struct DashboardRangeAccessibilityModifier: ViewModifier {
    let range: TimeRange

    func body(content: Content) -> some View {
        switch range {
        case .today:
            content.accessibilityIdentifier("dashboard.range.today")
        case .sevenDays:
            content.accessibilityIdentifier("dashboard.range.sevenDays")
        case .thirtyDays:
            content.accessibilityIdentifier("dashboard.range.thirtyDays")
        case .allTime:
            content.accessibilityIdentifier("dashboard.range.allTime")
        case .custom:
            content.accessibilityIdentifier("dashboard.range.custom")
        }
    }
}


struct OrdersRangeAccessibilityModifier: ViewModifier {
    let range: TimeRange

    func body(content: Content) -> some View {
        switch range {
        case .today:
            content.accessibilityIdentifier("orders.range.today")
        case .sevenDays:
            content.accessibilityIdentifier("orders.range.sevenDays")
        case .thirtyDays:
            content.accessibilityIdentifier("orders.range.thirtyDays")
        case .allTime:
            content.accessibilityIdentifier("orders.range.allTime")
        case .custom:
            content.accessibilityIdentifier("orders.range.custom")
        }
    }
}

struct SettingsProviderManagementAccessibilityModifier: ViewModifier {
    let provider: SalesProviderType

    func body(content: Content) -> some View {
        switch provider {
        case .lemonSqueezy:
            content.accessibilityIdentifier("settings.provider.lemonsqueezy.manage")
        case .gumroad:
            content.accessibilityIdentifier("settings.provider.gumroad.manage")
        case .stripe:
            content.accessibilityIdentifier("settings.provider.stripe.manage")
        }
    }
}
