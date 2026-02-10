import Foundation

/// Stripe API adapter. Actor for thread-safe network access.
/// Uses Charges API for sales, Products for catalog, Account for store info, Balance for funds.
actor StripeProvider: SalesProvider {
    let providerType: SalesProviderType = .stripe

    private let baseURL = URL(string: "https://api.stripe.com/v1")!
    private let session: URLSession
    private var apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Orders (via Charges)

    func fetchOrders(page _: Int = 1, pageSize: Int = 100) async throws -> OrdersPage {
        // Stripe uses cursor-based pagination, not page numbers.
        // For SalesProvider compatibility, page 1 = first fetch, page N = Nth batch.
        // We handle full pagination in fetchAllOrders() instead.
        let data = try await request(path: "charges", queryItems: [
            URLQueryItem(name: "limit", value: "\(pageSize)")
        ])
        let response = try JSONDecoder.stripe.decode(StripeList<StripeCharge>.self, from: data)

        let orders = response.data.compactMap(order(from:))

        return OrdersPage(
            orders: orders,
            currentPage: 1,
            lastPage: response.hasMore ? 2 : 1,
            hasMore: response.hasMore
        )
    }

    /// Fetch all charges across all pages using cursor-based pagination.
    func fetchAllOrders() async throws -> [Order] {
        var allOrders: [Order] = []
        var cursor: String?

        while true {
            var queryItems = [URLQueryItem(name: "limit", value: "100")]
            if let cursor {
                queryItems.append(URLQueryItem(name: "starting_after", value: cursor))
            }

            let data = try await request(path: "charges", queryItems: queryItems)
            let response = try JSONDecoder.stripe.decode(StripeList<StripeCharge>.self, from: data)

            let orders = response.data.compactMap(order(from:))

            allOrders.append(contentsOf: orders)

            if !response.hasMore { break }
            cursor = response.data.last?.id
        }

        return allOrders
    }

    // MARK: - Products

    func fetchProducts() async throws -> [Product] {
        var allProducts: [StripeProduct] = []
        var cursor: String?

        while true {
            var queryItems = [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "active", value: "true")
            ]
            if let cursor {
                queryItems.append(URLQueryItem(name: "starting_after", value: cursor))
            }

            let data = try await request(path: "products", queryItems: queryItems)
            let response = try JSONDecoder.stripe.decode(StripeList<StripeProduct>.self, from: data)
            allProducts.append(contentsOf: response.data)

            if !response.hasMore { break }
            cursor = response.data.last?.id
        }

        return allProducts.map { product in
            Product(
                id: product.id,
                name: product.name,
                slug: nil,
                description: product.description,
                price: 0, // Stripe prices are separate objects
                currency: "USD",
                status: product.active ? .active : .inactive,
                createdAt: Date(timeIntervalSince1970: TimeInterval(product.created)),
                provider: .stripe,
                thumbURL: product.images.first.flatMap(URL.init(string:)),
                largeThumbURL: product.images.first.flatMap(URL.init(string:)),
                buyNowURL: nil,
                storeURL: nil,
                priceFormatted: "—",
                statusFormatted: product.active ? "Active" : "Inactive",
                totalSales: nil,
                totalRevenue: nil,
                gumroadProductID: nil,
                stripeProductID: product.id,
                stripeDefaultPrice: product.defaultPrice
            )
        }
    }

    // MARK: - Store (via Account + Balance)

    func fetchStore() async throws -> Store {
        let accountData = try await request(path: "account")
        let account = try JSONDecoder.stripe.decode(StripeAccount.self, from: accountData)

        let balanceData = try await request(path: "balance")
        let balance = try JSONDecoder.stripe.decode(StripeBalance.self, from: balanceData)

        let availableUSD = balance.available.first(where: { $0.currency == "usd" })?.amount ?? 0
        let pendingUSD = balance.pending.first(where: { $0.currency == "usd" })?.amount ?? 0

        return Store(
            id: account.id,
            name: account.businessProfile?.name ?? "Stripe Account",
            slug: nil,
            currency: account.defaultCurrency.uppercased(),
            totalRevenue: availableUSD + pendingUSD,
            thirtyDayRevenue: 0, // Stripe doesn't provide this; computed from orders
            provider: .stripe,
            url: account.businessProfile?.url.flatMap(URL.init(string:)),
            avatarURL: nil,
            plan: nil,
            country: account.country,
            countryNicename: nil,
            totalSales: nil,
            thirtyDaySales: nil,
            createdAt: account.created.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            gumroadUserID: nil,
            stripeAccountID: account.id,
            stripeEmail: account.email
        )
    }

    // MARK: - Validation

    func validateAPIKey(_ key: String) async throws -> Bool {
        let oldKey = apiKey
        apiKey = key
        do {
            do {
                _ = try await request(path: "account")
            } catch SalesAPIError.serverError(let statusCode) where statusCode == 404 {
                // Fallback in case /account is unavailable for a given key/environment.
                _ = try await request(path: "charges", queryItems: [URLQueryItem(name: "limit", value: "1")])
            }
            return true
        } catch SalesAPIError.invalidAPIKey {
            apiKey = oldKey
            return false
        } catch {
            apiKey = oldKey
            throw error
        }
    }

    // MARK: - Mapping

    private func order(from charge: StripeCharge) -> Order? {
        guard charge.paid else { return nil }

        let isFullyRefunded = charge.refunded || (charge.amount > 0 && charge.amountRefunded >= charge.amount)

        return Order(
            id: charge.id,
            orderNumber: nil,
            status: isFullyRefunded ? .refunded : .paid,
            total: charge.amount,
            subtotal: nil,
            tax: nil,
            discountTotal: nil,
            currency: charge.currency.uppercased(),
            customerEmail: charge.billingDetails?.email ?? "",
            customerName: charge.billingDetails?.name ?? "Unknown",
            productName: charge.description ?? "Stripe Payment",
            variantName: nil,
            createdAt: Date(timeIntervalSince1970: TimeInterval(charge.created)),
            refundedAt: nil,
            refundedAmount: charge.amountRefunded > 0 ? charge.amountRefunded : nil,
            provider: .stripe,
            totalFormatted: nil,
            subtotalFormatted: nil,
            taxFormatted: nil,
            discountTotalFormatted: nil,
            taxName: nil,
            taxRate: nil,
            taxInclusive: nil,
            receiptURL: charge.receiptUrl.flatMap(URL.init(string:)),
            identifier: nil,
            gumroadSaleID: nil,
            ipCountry: nil,
            stripePaymentIntentID: charge.paymentIntent,
            paymentMethod: charge.paymentMethodDetails?.card?.brand
        )
    }

    // MARK: - Networking

    private func request(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var req = URLRequest(url: components.url!)
        // Stripe uses Basic Auth: base64("sk_xxx:")
        let authString = "\(apiKey):"
        let authData = authString.data(using: .utf8)!
        req.setValue("Basic \(authData.base64EncodedString())", forHTTPHeaderField: "Authorization")

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

// MARK: - Stripe Response Types

private struct StripeList<T: Decodable>: Decodable {
    let data: [T]
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
    }
}

private struct StripeCharge: Decodable {
    let id: String
    let amount: Int
    let amountRefunded: Int
    let currency: String
    let created: Int
    let customer: String?
    let description: String?
    let paid: Bool
    let refunded: Bool
    let status: String
    let receiptUrl: String?
    let paymentIntent: String?
    let billingDetails: StripeBillingDetails?
    let paymentMethodDetails: StripePaymentMethodDetails?

    enum CodingKeys: String, CodingKey {
        case id, amount, currency, created, customer, description, paid, refunded, status
        case amountRefunded = "amount_refunded"
        case receiptUrl = "receipt_url"
        case paymentIntent = "payment_intent"
        case billingDetails = "billing_details"
        case paymentMethodDetails = "payment_method_details"
    }
}

private struct StripeBillingDetails: Decodable {
    let email: String?
    let name: String?
    let phone: String?
    let address: StripeAddress?
}

private struct StripeAddress: Decodable {
    let city: String?
    let country: String?
    let line1: String?
    let postalCode: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case city, country, line1, state
        case postalCode = "postal_code"
    }
}

private struct StripePaymentMethodDetails: Decodable {
    let card: StripeCardDetails?
}

private struct StripeCardDetails: Decodable {
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int

    enum CodingKeys: String, CodingKey {
        case brand, last4
        case expMonth = "exp_month"
        case expYear = "exp_year"
    }
}

private struct StripeProduct: Decodable {
    let id: String
    let name: String
    let description: String?
    let active: Bool
    let defaultPrice: String?
    let images: [String]
    let created: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, active, images, created
        case defaultPrice = "default_price"
    }
}

private struct StripeAccount: Decodable {
    let id: String
    let email: String?
    let country: String?
    let defaultCurrency: String
    let chargesEnabled: Bool
    let businessProfile: StripeBusinessProfile?
    let created: Int?

    enum CodingKeys: String, CodingKey {
        case id, email, country, created
        case defaultCurrency = "default_currency"
        case chargesEnabled = "charges_enabled"
        case businessProfile = "business_profile"
    }
}

private struct StripeBusinessProfile: Decodable {
    let name: String?
    let url: String?
}

private struct StripeBalance: Decodable {
    let available: [StripeBalanceAmount]
    let pending: [StripeBalanceAmount]
}

private struct StripeBalanceAmount: Decodable {
    let amount: Int
    let currency: String
}

extension JSONDecoder {
    static let stripe: JSONDecoder = {
        let decoder = JSONDecoder()
        // Do NOT use .convertFromSnakeCase — manual CodingKeys handle snake_case already.
        // Combining both causes double-conversion (e.g., "receipt_url" → "receiptUrl" by decoder,
        // then CodingKeys looks for "receipt_url" which no longer exists → decode failure).
        return decoder
    }()
}
