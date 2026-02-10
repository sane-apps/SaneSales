import Foundation

/// A product listed on a sales platform.
struct Product: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let slug: String?
    let description: String?
    let price: Int // cents
    var currency: String
    let status: ProductStatus
    let createdAt: Date
    let provider: SalesProviderType

    // Images
    let thumbURL: URL?
    let largeThumbURL: URL?

    // Links
    let buyNowURL: URL?
    let storeURL: URL?

    // Formatted
    let priceFormatted: String?
    let statusFormatted: String?

    // Stats (from Gumroad/LS)
    let totalSales: Int?
    let totalRevenue: Int? // cents

    // Gumroad-specific
    let gumroadProductID: String?

    // Stripe-specific
    let stripeProductID: String?
    let stripeDefaultPrice: String?

    var displayPrice: String {
        if let formatted = priceFormatted { return formatted }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: Decimal(price) / 100 as NSDecimalNumber) ?? "$\(price / 100)"
    }
}

enum ProductStatus: String, Codable, Sendable {
    case published
    case draft
    case archived
    case active // Stripe uses "active"
    case inactive // Stripe
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ProductStatus(rawValue: raw) ?? .unknown
    }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .published, .active: "checkmark.circle.fill"
        case .draft: "pencil.circle.fill"
        case .archived, .inactive: "archivebox.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}
