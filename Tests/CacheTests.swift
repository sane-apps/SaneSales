import Foundation
import Testing

@testable import SaneSales

struct CacheTests {
    private let cache = CacheService(defaults: UserDefaults(suiteName: "SaneSalesTests")!)

    private func makeOrder(id: String = "1", total: Int = 500) -> Order {
        Order(
            id: id,
            orderNumber: nil,
            status: .paid,
            total: total,
            subtotal: nil,
            tax: nil,
            discountTotal: nil,
            currency: "USD",
            customerEmail: "test@test.com",
            customerName: "Test",
            productName: "Product",
            variantName: nil,
            createdAt: Date(),
            refundedAt: nil,
            refundedAmount: nil,
            provider: .lemonSqueezy,
            totalFormatted: nil,
            subtotalFormatted: nil,
            taxFormatted: nil,
            discountTotalFormatted: nil,
            taxName: nil,
            taxRate: nil,
            taxInclusive: nil,
            receiptURL: nil,
            identifier: nil,
            gumroadSaleID: nil,
            ipCountry: nil,
            stripePaymentIntentID: nil,
            paymentMethod: nil
        )
    }

    @Test("Caches and loads orders")
    func cacheOrders() async {
        let orders = [makeOrder(id: "1"), makeOrder(id: "2")]
        await cache.cacheOrders(orders)
        let loaded = await cache.loadCachedOrders()
        #expect(loaded?.count == 2)
        #expect(loaded?[0].id == "1")
    }

    @Test("Caches and loads products")
    func cacheProducts() async {
        let products = [
            Product(
                id: "p1", name: "Test", slug: nil, description: nil,
                price: 500, currency: "USD", status: .published, createdAt: Date(),
                provider: .lemonSqueezy, thumbURL: nil, largeThumbURL: nil,
                buyNowURL: nil, storeURL: nil, priceFormatted: nil,
                statusFormatted: nil, totalSales: nil, totalRevenue: nil,
                gumroadProductID: nil, stripeProductID: nil, stripeDefaultPrice: nil
            )
        ]
        await cache.cacheProducts(products)
        let loaded = await cache.loadCachedProducts()
        #expect(loaded?.count == 1)
        #expect(loaded?[0].name == "Test")
    }

    @Test("Caches and loads store")
    func cacheStore() async {
        let store = Store(
            id: "s1", name: "My Store", slug: "my-store", currency: "USD",
            totalRevenue: 50000, thirtyDayRevenue: 10000, provider: .lemonSqueezy,
            url: nil, avatarURL: nil, plan: nil, country: nil, countryNicename: nil,
            totalSales: nil, thirtyDaySales: nil, createdAt: nil,
            gumroadUserID: nil, stripeAccountID: nil, stripeEmail: nil
        )
        await cache.cacheStore(store)
        let loaded = await cache.loadCachedStore()
        #expect(loaded?.name == "My Store")
        #expect(loaded?.totalRevenue == 50000)
    }

    @Test("Last updated tracks cache time")
    func lastUpdated() async {
        let before = Date()
        await cache.cacheOrders([makeOrder()])
        let updated = await cache.lastUpdated
        #expect(updated != nil)
        #expect(updated! >= before)
    }

    @Test("Clear cache removes all data")
    func clearCache() async {
        await cache.cacheOrders([makeOrder()])
        await cache.clearCache()
        let loaded = await cache.loadCachedOrders()
        #expect(loaded == nil)
        let updated = await cache.lastUpdated
        #expect(updated == nil)
    }
}
