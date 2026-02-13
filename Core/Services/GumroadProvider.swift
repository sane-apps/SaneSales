import Foundation

/// Gumroad API adapter. Actor for thread-safe network access.
/// Uses v2 REST API with access_token authentication.
actor GumroadProvider: SalesProvider {
    let providerType: SalesProviderType = .gumroad

    private let baseURL = URL(string: "https://api.gumroad.com/v2")!
    private let session: URLSession
    private var apiKey: String // Gumroad "access_token"

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Orders (via Sales endpoint)

    func fetchOrders(page: Int = 1, pageSize _: Int = 100) async throws -> OrdersPage {
        let result = try await fetchSalesPage(page: page)
        let hasMore = result.nextPageURL != nil
        return OrdersPage(
            orders: result.orders,
            currentPage: page,
            lastPage: hasMore ? page + 1 : page,
            hasMore: hasMore
        )
    }

    /// Fetch all sales across all pages.
    func fetchAllOrders() async throws -> [Order] {
        var allOrders: [Order] = []
        var nextPageURL: URL?

        while true {
            let result = if let nextPageURL {
                try await fetchSalesPage(url: nextPageURL)
            } else {
                try await fetchSalesPage()
            }
            allOrders.append(contentsOf: result.orders)

            guard let next = result.nextPageURL else { break }
            nextPageURL = next
        }

        return allOrders
    }

    private struct GumroadSalesPageResult {
        let orders: [Order]
        let nextPageURL: URL?
    }

    private func fetchSalesPage() async throws -> GumroadSalesPageResult {
        let data = try await request(path: "sales")
        return try parseSalesResponse(data)
    }

    private func fetchSalesPage(page: Int) async throws -> GumroadSalesPageResult {
        let data = try await request(path: "sales", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
        return try parseSalesResponse(data)
    }

    private func fetchSalesPage(url: URL) async throws -> GumroadSalesPageResult {
        let data = try await request(url: url)
        return try parseSalesResponse(data)
    }

    private func parseSalesResponse(_ data: Data) throws -> GumroadSalesPageResult {
        let response: GumroadSalesResponse
        do {
            response = try JSONDecoder.gumroad.decode(GumroadSalesResponse.self, from: data)
        } catch {
            throw SalesAPIError.decodingError(underlying: error)
        }

        guard response.success else {
            throw SalesAPIError.serverError(statusCode: 400)
        }

        let orders = response.sales.map { sale -> Order in
            let email = sale.email ?? ""
            let name = sale.fullName ?? (email.isEmpty ? "Unknown" : email)
            let priceCents = sale.price // Gumroad returns price in cents
            return Order(
                id: sale.id,
                orderNumber: nil,
                status: (sale.refunded ?? false) ? .refunded : .paid,
                total: priceCents,
                subtotal: nil,
                tax: nil,
                discountTotal: nil,
                currency: sale.currency ?? "USD",
                customerEmail: email,
                customerName: name,
                productName: sale.productName ?? "Gumroad Sale",
                variantName: sale.variantName,
                createdAt: sale.createdAt,
                refundedAt: nil,
                refundedAmount: nil,
                provider: .gumroad,
                totalFormatted: sale.formattedDisplayPrice,
                subtotalFormatted: nil,
                taxFormatted: nil,
                discountTotalFormatted: nil,
                taxName: nil,
                taxRate: nil,
                taxInclusive: nil,
                receiptURL: nil,
                identifier: sale.orderId,
                gumroadSaleID: sale.id,
                ipCountry: sale.ipCountry,
                stripePaymentIntentID: nil,
                paymentMethod: nil
            )
        }

        let nextPageURL = response.nextPageUrl
            .flatMap { $0.isEmpty ? nil : $0 }
            .flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteURL }

        return GumroadSalesPageResult(
            orders: orders,
            nextPageURL: nextPageURL
        )
    }

    // MARK: - Products

    func fetchProducts() async throws -> [Product] {
        let data = try await request(path: "products")
        let response: GumroadProductsResponse
        do {
            response = try JSONDecoder.gumroad.decode(GumroadProductsResponse.self, from: data)
        } catch {
            throw SalesAPIError.decodingError(underlying: error)
        }

        guard response.success else {
            throw SalesAPIError.serverError(statusCode: 400)
        }

        return response.products.map { product in
            Product(
                id: product.id,
                name: product.name,
                slug: product.customPermalink,
                description: product.description,
                price: product.price, // cents
                currency: product.currency ?? "USD",
                status: product.published ? .published : .draft,
                createdAt: Date(), // Gumroad doesn't return created_at for products
                provider: .gumroad,
                thumbURL: product.thumbnail?.url.flatMap(URL.init(string:)),
                largeThumbURL: product.preview?.url.flatMap(URL.init(string:)),
                buyNowURL: product.shortUrl.flatMap(URL.init(string:)),
                storeURL: nil,
                priceFormatted: product.formattedPrice,
                statusFormatted: product.published ? "Published" : "Draft",
                totalSales: product.salesCount,
                totalRevenue: product.salesUsdCents,
                gumroadProductID: product.id,
                stripeProductID: nil,
                stripeDefaultPrice: nil
            )
        }
    }

    // MARK: - Store (via User endpoint)

    func fetchStore() async throws -> Store {
        let data = try await request(path: "user")
        let response: GumroadUserResponse
        do {
            response = try JSONDecoder.gumroad.decode(GumroadUserResponse.self, from: data)
        } catch {
            throw SalesAPIError.decodingError(underlying: error)
        }

        guard response.success, let user = response.user else {
            throw SalesAPIError.serverError(statusCode: 400)
        }

        return Store(
            id: user.userId,
            name: user.displayName ?? user.name ?? "Gumroad Store",
            slug: user.url?.components(separatedBy: "/").last,
            currency: "USD",
            totalRevenue: 0, // Not provided by user endpoint; computed from sales
            thirtyDayRevenue: 0,
            provider: .gumroad,
            url: user.url.flatMap(URL.init(string:)),
            avatarURL: user.profileUrl.flatMap(URL.init(string:)),
            plan: nil,
            country: nil,
            countryNicename: nil,
            totalSales: nil,
            thirtyDaySales: nil,
            createdAt: nil,
            gumroadUserID: user.userId,
            stripeAccountID: nil,
            stripeEmail: nil
        )
    }

    // MARK: - Validation

    func validateAPIKey(_ key: String) async throws -> Bool {
        let oldKey = apiKey
        apiKey = key
        do {
            let data = try await request(path: "user")
            let response = try JSONDecoder.gumroad.decode(GumroadUserResponse.self, from: data)
            return response.success
        } catch SalesAPIError.invalidAPIKey {
            apiKey = oldKey
            return false
        } catch {
            apiKey = oldKey
            throw error
        }
    }

    // MARK: - Networking

    private func request(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        var items = queryItems
        items.append(URLQueryItem(name: "access_token", value: apiKey))
        components.queryItems = items
        guard let url = components.url else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        return try await request(url: url)
    }

    private func request(url: URL) async throws -> Data {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "access_token" }
        items.append(URLQueryItem(name: "access_token", value: apiKey))
        components.queryItems = items

        guard let resolvedURL = components.url else {
            throw SalesAPIError.networkError(underlying: URLError(.badURL))
        }
        var req = URLRequest(url: resolvedURL)
        req.setValue("application/json", forHTTPHeaderField: "Accept")

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

// MARK: - Gumroad Response Types

private struct GumroadSalesResponse: Decodable {
    let success: Bool
    let sales: [GumroadSale]
    let nextPageUrl: String?

    enum CodingKeys: String, CodingKey {
        case success, sales
        case nextPageUrl = "next_page_url"
    }
}

private struct GumroadSale: Decodable {
    let id: String
    let email: String?
    let fullName: String?
    let productName: String?
    let variantName: String?
    let price: Int // cents
    let currency: String?
    let refunded: Bool?
    let formattedDisplayPrice: String?
    let orderId: String?
    let ipCountry: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, price, currency, refunded
        case fullName = "full_name"
        case productName = "product_name"
        case variantName = "variant_name"
        case formattedDisplayPrice = "formatted_display_price"
        case orderId = "order_id"
        case ipCountry = "ip_country"
        case createdAt = "created_at"
    }
}

private struct GumroadProductsResponse: Decodable {
    let success: Bool
    let products: [GumroadProduct]
}

private struct GumroadProduct: Decodable {
    let id: String
    let name: String
    let description: String?
    let customPermalink: String?
    let price: Int // cents
    let currency: String?
    let published: Bool
    let formattedPrice: String?
    let shortUrl: String?
    let salesCount: Int?
    let salesUsdCents: Int?
    let thumbnail: GumroadMedia?
    let preview: GumroadMedia?

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, currency, published, thumbnail, preview
        case customPermalink = "custom_permalink"
        case formattedPrice = "formatted_price"
        case shortUrl = "short_url"
        case salesCount = "sales_count"
        case salesUsdCents = "sales_usd_cents"
    }
}

private struct GumroadMedia: Decodable {
    let url: String?
}

private struct GumroadUserResponse: Decodable {
    let success: Bool
    let user: GumroadUser?
}

private struct GumroadUser: Decodable {
    let userId: String
    let name: String?
    let displayName: String?
    let url: String?
    let profileUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, url
        case userId = "user_id"
        case displayName = "display_name"
        case profileUrl = "profile_url"
    }
}

extension JSONDecoder {
    static let gumroad: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            // Gumroad uses ISO 8601 format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) {
                return date
            }
            // Fallback: try "yyyy-MM-dd'T'HH:mm:ssZ"
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = df.date(from: string) {
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
