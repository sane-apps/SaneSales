import Foundation
import Testing

@testable import SaneSales

struct ProviderTests {
    @Test("Stripe: partial refunds reduce netTotal")
    func stripePartialRefunds() async throws {
        let mockSessionID = UUID().uuidString
        let session = makeMockSession(sessionID: mockSessionID)
        defer { MockURLProtocol.removeHandler(sessionID: mockSessionID) }

        MockURLProtocol.withHandler(sessionID: mockSessionID) { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            switch url.path {
            case "/v1/charges":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    {
                      "data": [
                        {
                          "id": "ch_1",
                          "amount": 1000,
                          "amount_refunded": 250,
                          "currency": "usd",
                          "created": 1700000000,
                          "customer": null,
                          "description": "Test Charge",
                          "paid": true,
                          "refunded": false,
                          "status": "succeeded",
                          "receipt_url": "https://example.com/receipt",
                          "payment_intent": "pi_1",
                          "billing_details": { "email": "buyer@example.com", "name": "Buyer", "phone": null, "address": null },
                          "payment_method_details": {
                            "card": { "brand": "visa", "last4": "4242", "exp_month": 12, "exp_year": 2030 }
                          }
                        }
                      ],
                      "has_more": false
                    }
                    """
                )
            case "/v1/products":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    { "data": [], "has_more": false }
                    """
                )
            case "/v1/account":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    {
                      "id": "acct_123",
                      "email": "owner@example.com",
                      "country": "US",
                      "default_currency": "usd",
                      "charges_enabled": true,
                      "business_profile": { "name": "Test", "url": "https://example.com" },
                      "created": 1700000000
                    }
                    """
                )
            case "/v1/balance":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    {
                      "available": [{ "amount": 100, "currency": "usd" }],
                      "pending": [{ "amount": 200, "currency": "usd" }]
                    }
                    """
                )
            default:
                return (HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
            }
        }

        let provider = StripeProvider(apiKey: "sk_test_123", session: session)
        let orders = try await provider.fetchAllOrders()

        #expect(orders.count == 1)
        #expect(orders[0].status == .paid)
        #expect(orders[0].total == 1000)
        #expect(orders[0].refundedAmount == 250)
        #expect(orders[0].netTotal == 750)
    }

    @Test("Gumroad: follows next_page_url pagination")
    func gumroadPagination() async throws {
        let mockSessionID = UUID().uuidString
        let session = makeMockSession(sessionID: mockSessionID)
        let requests = RequestRecorder()
        defer { MockURLProtocol.removeHandler(sessionID: mockSessionID) }

        MockURLProtocol.withHandler(sessionID: mockSessionID) { request in
            requests.record(request)

            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let hasAccessToken = query.contains(where: { $0.name == "access_token" })
            #expect(hasAccessToken)

            switch url.path {
            case "/v2/sales":
                let hasPageKey = query.contains(where: { $0.name == "page_key" })
                if hasPageKey {
                    return try makeJSONResponse(
                        url: url,
                        json: """
                        {
                          "success": true,
                          "sales": [
                            {
                              "id": "sale_2",
                              "email": "buyer2@example.com",
                              "full_name": "Buyer Two",
                              "product_name": "Second Product",
                              "variant_name": null,
                              "price": 500,
                              "currency": "USD",
                              "refunded": false,
                              "formatted_display_price": "$5",
                              "order_id": "ord_2",
                              "ip_country": "US",
                              "created_at": "2026-01-16T10:30:00Z"
                            }
                          ],
                          "next_page_url": null
                        }
                        """
                    )
                } else {
                    return try makeJSONResponse(
                        url: url,
                        json: """
                        {
                          "success": true,
                          "sales": [
                            {
                              "id": "sale_1",
                              "email": "buyer1@example.com",
                              "full_name": "Buyer One",
                              "product_name": "First Product",
                              "variant_name": null,
                              "price": 1000,
                              "currency": "USD",
                              "refunded": false,
                              "formatted_display_price": "$10",
                              "order_id": "ord_1",
                              "ip_country": "US",
                              "created_at": "2026-01-15T10:30:00.123Z"
                            }
                          ],
                          "next_page_url": "https://api.gumroad.com/v2/sales?page_key=abc"
                        }
                        """
                    )
                }
            case "/v2/products":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    { "success": true, "products": [] }
                    """
                )
            case "/v2/user":
                return try makeJSONResponse(
                    url: url,
                    json: """
                    { "success": true, "user": { "user_id": "u1", "name": "Test", "display_name": "Test", "url": "https://gumroad.com/test", "profile_url": null } }
                    """
                )
            default:
                return (HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
            }
        }

        let provider = GumroadProvider(apiKey: "gr_test_123", session: session)
        let orders = try await provider.fetchAllOrders()

        #expect(orders.count == 2)
        #expect(Set(orders.map(\.id)) == Set(["sale_1", "sale_2"]))

        let recorded = requests.snapshot()
        #expect(recorded.count >= 2)
    }
}

// MARK: - Mock URL loading

private final class MockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static var handlers: [String: Handler] = [:]
    private static let lock = NSLock()

    static func withHandler(sessionID: String, _ handler: @escaping Handler) {
        lock.lock()
        handlers[sessionID] = handler
        lock.unlock()
    }

    static func removeHandler(sessionID: String) {
        lock.lock()
        handlers.removeValue(forKey: sessionID)
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client else { return }

        let sessionID = request.value(forHTTPHeaderField: "X-Mock-Session") ?? ""
        let handler: Handler?

        Self.lock.lock()
        handler = Self.handlers[sessionID]
        Self.lock.unlock()

        guard let handler else {
            client.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: data)
            client.urlProtocolDidFinishLoading(self)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeMockSession(sessionID: String) -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    config.httpAdditionalHeaders = ["X-Mock-Session": sessionID]
    return URLSession(configuration: config)
}

private func makeJSONResponse(url: URL, json: String) throws -> (HTTPURLResponse, Data) {
    let data = try #require(json.data(using: .utf8))
    let response = try #require(HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    ))
    return (response, data)
}

private final class RequestRecorder {
    private var requests: [URLRequest] = []
    private let lock = NSLock()

    func record(_ request: URLRequest) {
        lock.lock()
        requests.append(request)
        lock.unlock()
    }

    func snapshot() -> [URLRequest] {
        lock.lock()
        let copy = requests
        lock.unlock()
        return copy
    }
}
