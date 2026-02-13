import Foundation

/// LemonSqueezy API adapter. Actor for thread-safe network access.
actor LemonSqueezyProvider: SalesProvider {
    let providerType: SalesProviderType = .lemonSqueezy

    private let baseURL = URL(string: "https://api.lemonsqueezy.com/v1")!
    private let session: URLSession
    private var apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func updateAPIKey(_ key: String) {
        apiKey = key
    }

    // MARK: - Orders

    func fetchOrders(page: Int = 1, pageSize: Int = 100) async throws -> OrdersPage {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("orders"), resolvingAgainstBaseURL: false) else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        components.queryItems = [
            URLQueryItem(name: "page[number]", value: "\(page)"),
            URLQueryItem(name: "page[size]", value: "\(pageSize)")
        ]

        guard let url = components.url else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        let data = try await request(url: url)
        let response = try JSONDecoder.lemonSqueezy.decode(LSOrdersResponse.self, from: data)

        let orders = response.data.map { item -> Order in
            let attrs = item.attributes
            return Order(
                id: item.id,
                orderNumber: attrs.orderNumber,
                status: OrderStatus(rawValue: attrs.status) ?? .unknown,
                total: attrs.total,
                subtotal: attrs.subtotal,
                tax: attrs.tax,
                discountTotal: attrs.discountTotal,
                currency: attrs.currency,
                customerEmail: attrs.userEmail,
                customerName: attrs.userName,
                productName: attrs.firstOrderItem?.productName ?? "Unknown",
                variantName: attrs.firstOrderItem?.variantName,
                createdAt: attrs.createdAt,
                refundedAt: attrs.refundedAt,
                refundedAmount: attrs.refundedAmount,
                provider: .lemonSqueezy,
                totalFormatted: attrs.totalFormatted,
                subtotalFormatted: attrs.subtotalFormatted,
                taxFormatted: attrs.taxFormatted,
                discountTotalFormatted: attrs.discountTotalFormatted,
                taxName: attrs.taxName,
                taxRate: attrs.taxRate,
                taxInclusive: attrs.taxInclusive,
                receiptURL: attrs.urls?.receipt.flatMap(URL.init(string:)),
                identifier: attrs.identifier,
                gumroadSaleID: nil,
                ipCountry: nil,
                stripePaymentIntentID: nil,
                paymentMethod: nil
            )
        }

        let lastPage = response.meta.page.lastPage
        return OrdersPage(
            orders: orders,
            currentPage: page,
            lastPage: lastPage,
            hasMore: page < lastPage
        )
    }

    /// Fetch all orders across all pages.
    func fetchAllOrders() async throws -> [Order] {
        var allOrders: [Order] = []
        var page = 1

        while true {
            let result = try await fetchOrders(page: page)
            allOrders.append(contentsOf: result.orders)
            if !result.hasMore { break }
            page += 1
        }

        return allOrders
    }

    // MARK: - Products

    func fetchProducts() async throws -> [Product] {
        let data = try await request(url: baseURL.appendingPathComponent("products"))
        let response = try JSONDecoder.lemonSqueezy.decode(LSProductsResponse.self, from: data)

        return response.data.map { item -> Product in
            let attrs = item.attributes
            return Product(
                id: item.id,
                name: attrs.name,
                slug: attrs.slug,
                description: attrs.description,
                price: attrs.price,
                currency: "USD",
                status: ProductStatus(rawValue: attrs.status) ?? .unknown,
                createdAt: attrs.createdAt,
                provider: .lemonSqueezy,
                thumbURL: attrs.thumbUrl.flatMap(URL.init(string:)),
                largeThumbURL: attrs.largeThumbUrl.flatMap(URL.init(string:)),
                buyNowURL: attrs.buyNowUrl.flatMap(URL.init(string:)),
                storeURL: nil,
                priceFormatted: attrs.priceFormatted,
                statusFormatted: attrs.statusFormatted,
                totalSales: nil,
                totalRevenue: nil,
                gumroadProductID: nil,
                stripeProductID: nil,
                stripeDefaultPrice: nil
            )
        }
    }

    // MARK: - Store

    func fetchStore() async throws -> Store {
        let data = try await request(url: baseURL.appendingPathComponent("stores"))
        let response = try JSONDecoder.lemonSqueezy.decode(LSStoresResponse.self, from: data)

        guard let item = response.data.first else {
            throw SalesAPIError.decodingError(underlying: DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "No store found")
            ))
        }

        let attrs = item.attributes
        return Store(
            id: item.id,
            name: attrs.name,
            slug: attrs.slug,
            currency: attrs.currency,
            totalRevenue: attrs.totalRevenue,
            thirtyDayRevenue: attrs.thirtyDayRevenue,
            provider: .lemonSqueezy,
            url: attrs.url.flatMap(URL.init(string:)),
            avatarURL: attrs.avatarUrl.flatMap(URL.init(string:)),
            plan: attrs.plan,
            country: attrs.country,
            countryNicename: attrs.countryNicename,
            totalSales: attrs.totalSales,
            thirtyDaySales: attrs.thirtyDaySales,
            createdAt: attrs.createdAt,
            gumroadUserID: nil,
            stripeAccountID: nil,
            stripeEmail: nil
        )
    }

    // MARK: - Validation

    func validateAPIKey(_ key: String) async throws -> Bool {
        let oldKey = apiKey
        apiKey = key
        do {
            _ = try await request(url: baseURL.appendingPathComponent("stores"))
            return true
        } catch SalesAPIError.invalidAPIKey {
            apiKey = oldKey
            return false
        } catch {
            apiKey = oldKey
            throw error
        }
    }

    // MARK: - Networking

    private func request(url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw SalesAPIError.networkError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SalesAPIError.networkError(underlying: URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200 ... 299:
            return data
        case 401:
            throw SalesAPIError.invalidAPIKey
        case 429:
            throw SalesAPIError.rateLimited
        default:
            throw SalesAPIError.serverError(statusCode: http.statusCode)
        }
    }
}

// MARK: - LemonSqueezy JSON:API Response Types

private struct LSOrdersResponse: Decodable {
    let data: [LSOrderItem]
    let meta: LSMeta
}

private struct LSProductsResponse: Decodable {
    let data: [LSProductItem]
}

private struct LSStoresResponse: Decodable {
    let data: [LSStoreItem]
}

private struct LSOrderItem: Decodable {
    let id: String
    let attributes: LSOrderAttributes
}

private struct LSOrderAttributes: Decodable {
    let status: String
    let orderNumber: Int
    let identifier: String
    let total: Int
    let subtotal: Int
    let tax: Int
    let discountTotal: Int
    let currency: String
    let userEmail: String
    let userName: String
    let taxName: String?
    let taxRate: String?
    let taxInclusive: Bool
    let totalFormatted: String
    let subtotalFormatted: String
    let taxFormatted: String
    let discountTotalFormatted: String
    let refundedAt: Date?
    let refundedAmount: Int?
    let firstOrderItem: LSFirstOrderItem?
    let urls: LSOrderURLs?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case status, total, subtotal, tax, currency, identifier, urls
        case orderNumber = "order_number"
        case discountTotal = "discount_total"
        case userEmail = "user_email"
        case userName = "user_name"
        case taxName = "tax_name"
        case taxRate = "tax_rate"
        case taxInclusive = "tax_inclusive"
        case totalFormatted = "total_formatted"
        case subtotalFormatted = "subtotal_formatted"
        case taxFormatted = "tax_formatted"
        case discountTotalFormatted = "discount_total_formatted"
        case refundedAt = "refunded_at"
        case refundedAmount = "refunded_amount"
        case firstOrderItem = "first_order_item"
        case createdAt = "created_at"
    }
}

private struct LSOrderURLs: Decodable {
    let receipt: String?
}

private struct LSFirstOrderItem: Decodable {
    let productName: String
    let variantName: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case variantName = "variant_name"
    }
}

private struct LSProductItem: Decodable {
    let id: String
    let attributes: LSProductAttributes
}

private struct LSProductAttributes: Decodable {
    let name: String
    let slug: String?
    let description: String?
    let price: Int
    let status: String
    let statusFormatted: String?
    let priceFormatted: String?
    let thumbUrl: String?
    let largeThumbUrl: String?
    let buyNowUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case name, slug, description, price, status
        case statusFormatted = "status_formatted"
        case priceFormatted = "price_formatted"
        case thumbUrl = "thumb_url"
        case largeThumbUrl = "large_thumb_url"
        case buyNowUrl = "buy_now_url"
        case createdAt = "created_at"
    }
}

private struct LSStoreItem: Decodable {
    let id: String
    let attributes: LSStoreAttributes
}

private struct LSStoreAttributes: Decodable {
    let name: String
    let slug: String?
    let currency: String
    let totalRevenue: Int
    let thirtyDayRevenue: Int
    let totalSales: Int
    let thirtyDaySales: Int
    let url: String?
    let avatarUrl: String?
    let plan: String?
    let country: String?
    let countryNicename: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, slug, currency, url, plan, country
        case totalRevenue = "total_revenue"
        case thirtyDayRevenue = "thirty_day_revenue"
        case totalSales = "total_sales"
        case thirtyDaySales = "thirty_day_sales"
        case avatarUrl = "avatar_url"
        case countryNicename = "country_nicename"
        case createdAt = "created_at"
    }
}

private struct LSMeta: Decodable {
    let page: LSPageInfo
}

private struct LSPageInfo: Decodable {
    let lastPage: Int
}

extension JSONDecoder {
    static let lemonSqueezy: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(string)"
            )
        }
        return decoder
    }()
}
