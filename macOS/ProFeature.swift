import SaneUI

// MARK: - Pro Feature Definitions (macOS only)

enum ProFeature: String, ProFeatureDescribing, CaseIterable {
    case multipleProviders = "Multiple Providers"
    case charts = "Revenue Charts"
    case orderHistory = "Order History"
    case csvExport = "CSV Export"
    case menuBar = "Menu Bar"
    case widgets = "Widgets"

    var id: String { rawValue }
    var featureName: String { rawValue }

    var featureDescription: String {
        switch self {
        case .multipleProviders:
            "Connect LemonSqueezy, Gumroad, and Stripe simultaneously"
        case .charts:
            "Visualize revenue trends with interactive charts"
        case .orderHistory:
            "Browse and search all your orders"
        case .csvExport:
            "Export sales data as CSV for spreadsheets"
        case .menuBar:
            "Quick revenue glance from your menu bar"
        case .widgets:
            "Revenue widgets for Desktop, Notification Center, and Watch"
        }
    }

    var featureIcon: String {
        switch self {
        case .multipleProviders: "link.badge.plus"
        case .charts: "chart.line.uptrend.xyaxis"
        case .orderHistory: "list.bullet.rectangle"
        case .csvExport: "tablecells"
        case .menuBar: "menubar.rectangle"
        case .widgets: "widget.small"
        }
    }
}
