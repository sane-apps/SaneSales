import Foundation
import Testing

@testable import SaneSales

struct CacheTests {
    private let cache = CacheService(defaults: UserDefaults(suiteName: "SaneSalesTests")!)

    private func makeOrder(
        id: String = "1",
        total: Int = 500,
        date: Date = Date(),
        provider: SalesProviderType = .lemonSqueezy
    ) -> Order {
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
            createdAt: date,
            refundedAt: nil,
            refundedAmount: nil,
            provider: provider,
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

    @Test("Shared snapshot excludes customer and receipt data")
    func sharedSnapshotExcludesPrivateOrderFields() throws {
        let suiteName = "SaneSalesSharedSnapshotTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let order = makeOrder(id: "private-order-1")
        SharedStore.writeSalesSnapshot(from: [order], defaults: defaults)

        let snapshot = try #require(SharedStore.loadSalesSnapshot(defaults: defaults))
        #expect(snapshot.todayOrders == 1)
        #expect(snapshot.recentRows.first?.productName == "Product")

        let data = try #require(defaults.data(forKey: SharedStore.salesSnapshotKey))
        let encoded = String(decoding: data, as: UTF8.self)
        #expect(!encoded.contains("test@test.com"))
        #expect(!encoded.contains("private-order-1"))
        #expect(defaults.data(forKey: SharedStore.cachedOrdersKey) == nil)
    }

    @Test("Legacy app group cache migrates to app-local cache and sanitized snapshot")
    func legacyAppGroupCacheMigratesToAppLocalCacheAndSanitizedSnapshot() async throws {
        let standardSuiteName = "SaneSalesStandardCacheTests.\(UUID().uuidString)"
        let legacySuiteName = "SaneSalesLegacyCacheTests.\(UUID().uuidString)"
        let standardDefaults = try #require(UserDefaults(suiteName: standardSuiteName))
        let legacyDefaults = try #require(UserDefaults(suiteName: legacySuiteName))
        standardDefaults.removePersistentDomain(forName: standardSuiteName)
        legacyDefaults.removePersistentDomain(forName: legacySuiteName)
        defer {
            standardDefaults.removePersistentDomain(forName: standardSuiteName)
            legacyDefaults.removePersistentDomain(forName: legacySuiteName)
        }

        let orders = [
            makeOrder(id: "legacy-private-order", total: 1_200),
            makeOrder(id: "legacy-stripe-order", total: 3_000, provider: .stripe)
        ]
        let data = try JSONEncoder().encode(orders)
        legacyDefaults.set(data, forKey: SharedStore.cachedOrdersKey)

        let cache = CacheService(defaults: standardDefaults, legacyDefaults: legacyDefaults)
        let loaded = try #require(await cache.loadCachedOrders())

        #expect(loaded.count == 2)
        #expect(standardDefaults.data(forKey: SharedStore.cachedOrdersKey) != nil)
        #expect(legacyDefaults.data(forKey: SharedStore.cachedOrdersKey) == nil)

        let snapshot = try #require(SharedStore.loadSalesSnapshot(defaults: legacyDefaults))
        #expect(snapshot.todayOrders == 2)
        #expect(snapshot.allTimeOrders == 2)
        #expect(snapshot.allTimeRevenue == 4_200)
        #expect(snapshot.providerRows.count == 2)

        let encodedSnapshot = String(decoding: try #require(legacyDefaults.data(forKey: SharedStore.salesSnapshotKey)), as: UTF8.self)
        #expect(!encodedSnapshot.contains("test@test.com"))
        #expect(!encodedSnapshot.contains("legacy-private-order"))
    }

    @Test("Corrupt cached order payload is discarded")
    func corruptCachedOrderPayloadIsDiscarded() async throws {
        let suiteName = "SaneSalesCorruptCacheTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("not-json".utf8), forKey: SharedStore.cachedOrdersKey)

        let cache = CacheService(defaults: defaults)
        let loaded = await cache.loadCachedOrders()

        #expect(loaded == nil)
        #expect(defaults.data(forKey: SharedStore.cachedOrdersKey) == nil)
    }

    @Test("Shared snapshot carries watch aggregates beyond today")
    func sharedSnapshotCarriesWatchAggregatesBeyondToday() throws {
        let suiteName = "SaneSalesSharedAggregateTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let olderDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        SharedStore.writeSalesSnapshot(
            from: [
                makeOrder(id: "today", total: 500),
                makeOrder(id: "older", total: 1_500, date: olderDate)
            ],
            defaults: defaults
        )

        let snapshot = try #require(SharedStore.loadSalesSnapshot(defaults: defaults))
        #expect(snapshot.todayOrders == 1)
        #expect(snapshot.thirtyDayOrders == 2)
        #expect(snapshot.thirtyDayRevenue == 2_000)
        #expect(snapshot.allTimeOrders == 2)
        #expect(snapshot.allTimeRevenue == 2_000)
    }
}
