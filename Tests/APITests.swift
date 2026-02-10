import Foundation
import Testing

@testable import SaneSales

struct APITests {
    // MARK: - Order Parsing

    @Test("Parses LemonSqueezy order JSON correctly")
    func parsesOrderJSON() throws {
        let json = """
        {
            "data": [{
                "id": "123",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 500,
                    "currency": "USD",
                    "user_email": "test@example.com",
                    "user_name": "Test User",
                    "first_order_item": {
                        "product_name": "SaneBar",
                        "variant_name": "Standard"
                    },
                    "created_at": "2026-01-15T10:30:00Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data.count == 1)
        let attrs = response.data[0].attributes
        #expect(attrs.status == "paid")
        #expect(attrs.total == 500)
        #expect(attrs.currency == "USD")
        #expect(attrs.userEmail == "test@example.com")
        #expect(attrs.userName == "Test User")
        #expect(attrs.firstOrderItem?.productName == "SaneBar")
        #expect(attrs.firstOrderItem?.variantName == "Standard")
    }

    @Test("Handles missing optional fields gracefully")
    func handlesMissingOptionalFields() throws {
        let json = """
        {
            "data": [{
                "id": "456",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 1000,
                    "currency": "EUR",
                    "user_email": "user@test.com",
                    "user_name": "Another User",
                    "created_at": "2026-02-01T08:00:00Z"
                }
            }],
            "meta": {
                "page": {
                    "lastPage": 1
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)

        #expect(response.data[0].attributes.firstOrderItem == nil)
    }

    @Test("Parses ISO8601 dates with fractional seconds")
    func parsesDateWithFractionalSeconds() throws {
        let json = """
        {
            "data": [{
                "id": "789",
                "type": "orders",
                "attributes": {
                    "status": "paid",
                    "total": 500,
                    "currency": "USD",
                    "user_email": "a@b.com",
                    "user_name": "A B",
                    "created_at": "2026-01-15T10:30:00.123Z"
                }
            }],
            "meta": { "page": { "lastPage": 1 } }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder.lemonSqueezy.decode(TestOrdersResponse.self, from: data)
        #expect(response.data[0].attributes.createdAt != nil)
    }

    // MARK: - Order Status

    @Test("OrderStatus handles unknown values")
    func orderStatusUnknown() throws {
        let json = """
        "something_new"
        """
        let data = json.data(using: .utf8)!
        let status = try JSONDecoder().decode(OrderStatus.self, from: data)
        #expect(status == .unknown)
    }
}

// MARK: - Test-visible LS types (mirror private types for parsing tests)

struct TestOrdersResponse: Decodable {
    let data: [TestOrderItem]
    let meta: TestMeta
}

struct TestOrderItem: Decodable {
    let id: String
    let attributes: TestOrderAttributes
}

struct TestOrderAttributes: Decodable {
    let status: String
    let total: Int
    let currency: String
    let userEmail: String
    let userName: String
    let firstOrderItem: TestFirstOrderItem?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case status, total, currency
        case userEmail = "user_email"
        case userName = "user_name"
        case firstOrderItem = "first_order_item"
        case createdAt = "created_at"
    }
}

struct TestFirstOrderItem: Decodable {
    let productName: String
    let variantName: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case variantName = "variant_name"
    }
}

struct TestMeta: Decodable {
    let page: TestPageInfo
}

struct TestPageInfo: Decodable {
    let lastPage: Int
}
