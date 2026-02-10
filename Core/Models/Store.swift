import Foundation

/// A store/account on a sales platform.
struct Store: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let slug: String?
    let currency: String
    let totalRevenue: Int // cents
    let thirtyDayRevenue: Int // cents
    let provider: SalesProviderType

    // Extended fields
    let url: URL?
    let avatarURL: URL?
    let plan: String?
    let country: String?
    let countryNicename: String?
    let totalSales: Int?
    let thirtyDaySales: Int?
    let createdAt: Date?

    // Gumroad-specific
    let gumroadUserID: String?

    // Stripe-specific
    let stripeAccountID: String?
    let stripeEmail: String?

    var totalRevenueFormatted: String {
        formatCents(totalRevenue)
    }

    var thirtyDayRevenueFormatted: String {
        formatCents(thirtyDayRevenue)
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }
}
