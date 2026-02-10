import Foundation

/// Protocol for sales platform API adapters.
/// Each provider (LemonSqueezy, Gumroad, Stripe) implements this.
protocol SalesProvider: Sendable {
    var providerType: SalesProviderType { get }

    func fetchOrders(page: Int, pageSize: Int) async throws -> OrdersPage
    func fetchAllOrders() async throws -> [Order]
    func fetchProducts() async throws -> [Product]
    func fetchStore() async throws -> Store
    func validateAPIKey(_ key: String) async throws -> Bool
}

struct OrdersPage: Sendable {
    let orders: [Order]
    let currentPage: Int
    let lastPage: Int
    let hasMore: Bool
}

enum SalesAPIError: Error, LocalizedError {
    case invalidAPIKey
    case rateLimited
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case serverError(statusCode: Int)
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "Invalid API key. Check your key in Settings."
        case .rateLimited:
            "Rate limited. Try again in a moment."
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case .decodingError:
            "Failed to parse response from server."
        case let .serverError(code):
            "Server error (\(code)). Try again later."
        case .noAPIKey:
            "No API key configured. Add one in Settings."
        }
    }
}
