import Foundation

/// A single order from a sales platform (LemonSqueezy, Gumroad, Stripe).
struct Order: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let orderNumber: Int?
    let status: OrderStatus
    let total: Int // cents
    let subtotal: Int? // cents
    let tax: Int? // cents
    let discountTotal: Int? // cents
    let currency: String
    let customerEmail: String
    let customerName: String
    let productName: String
    let variantName: String?
    let createdAt: Date
    let refundedAt: Date?
    let refundedAmount: Int? // cents (partial refunds)
    let provider: SalesProviderType

    // Formatted strings from API (LS provides these server-side)
    let totalFormatted: String?
    let subtotalFormatted: String?
    let taxFormatted: String?
    let discountTotalFormatted: String?

    // Tax details
    let taxName: String?
    let taxRate: String?
    let taxInclusive: Bool?

    // Receipt
    let receiptURL: URL?

    // Identifier (LS order identifier string, e.g. "XXXX-XXXX-XXXX")
    let identifier: String?

    // Gumroad-specific
    let gumroadSaleID: String?
    let ipCountry: String?

    // Stripe-specific
    let stripePaymentIntentID: String?
    let paymentMethod: String?

    var isRefunded: Bool {
        status == .refunded || refundedAt != nil || (refundedAmount ?? 0) > 0
    }

    var totalDecimal: Decimal {
        Decimal(total) / 100
    }

    var netTotal: Int {
        max(0, total - (refundedAmount ?? 0))
    }

    var displayTotal: String {
        if let formatted = totalFormatted { return formatted }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: totalDecimal as NSDecimalNumber) ?? "$\(totalDecimal)"
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(createdAt, equalTo: Date(), toGranularity: .month)
    }
}

enum OrderStatus: String, Codable, Sendable {
    case paid
    case refunded
    case pending
    case failed
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = OrderStatus(rawValue: raw) ?? .unknown
    }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .paid: "checkmark.circle.fill"
        case .refunded: "arrow.uturn.backward.circle.fill"
        case .pending: "clock.fill"
        case .failed: "xmark.circle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    var tintColor: String {
        switch self {
        case .paid: "green"
        case .refunded: "orange"
        case .pending: "yellow"
        case .failed: "red"
        case .unknown: "gray"
        }
    }
}

enum SalesProviderType: String, Codable, Sendable {
    case lemonSqueezy = "lemonsqueezy"
    case gumroad
    case stripe

    var displayName: String {
        switch self {
        case .lemonSqueezy: "Lemon Squeezy"
        case .gumroad: "Gumroad"
        case .stripe: "Stripe"
        }
    }

    var icon: String {
        switch self {
        case .lemonSqueezy: "cart.fill"
        case .gumroad: "bag.fill"
        case .stripe: "creditcard.fill"
        }
    }
}
