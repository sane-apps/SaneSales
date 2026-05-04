import Foundation
import Testing

@testable import SaneSales

struct MetricsTests {
    // MARK: - Helpers

    private func makeOrder(
        id: String = UUID().uuidString,
        total: Int = 500,
        status: OrderStatus = .paid,
        productName: String = "TestProduct",
        date: Date = Date(),
        refundedAmount: Int? = nil,
        provider: SalesProviderType = .lemonSqueezy
    ) -> Order {
        Order(
            id: id,
            orderNumber: nil,
            status: status,
            total: total,
            subtotal: nil,
            tax: nil,
            discountTotal: nil,
            currency: "USD",
            customerEmail: "test@example.com",
            customerName: "Test User",
            productName: productName,
            variantName: nil,
            createdAt: date,
            refundedAt: nil,
            refundedAmount: refundedAmount,
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

    // MARK: - Tests

    @Test("Empty orders produce zero metrics")
    func emptyMetrics() {
        let metrics = SalesMetrics.compute(from: [])
        #expect(metrics.todayRevenue == 0)
        #expect(metrics.todayOrders == 0)
        #expect(metrics.thirtyDayRevenue == 0)
        #expect(metrics.thirtyDayOrders == 0)
        #expect(metrics.monthRevenue == 0)
        #expect(metrics.allTimeRevenue == 0)
        #expect(metrics.dailyBreakdown.isEmpty)
        #expect(metrics.productBreakdown.isEmpty)
    }

    @Test("Today's orders counted correctly")
    func todayOrders() {
        let orders = [
            makeOrder(total: 500),
            makeOrder(total: 1000)
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.todayRevenue == 1500)
        #expect(metrics.todayOrders == 2)
    }

    @Test("Refunded orders excluded from metrics")
    func refundedExcluded() {
        let orders = [
            makeOrder(total: 500, status: .paid),
            makeOrder(total: 1000, status: .refunded)
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.allTimeRevenue == 500)
        #expect(metrics.allTimeOrders == 1)
    }

    @Test("Partial refunds reduce revenue")
    func partialRefundsReduceRevenue() {
        let orders = [
            makeOrder(total: 1000, refundedAmount: 250),
            makeOrder(total: 500)
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.allTimeRevenue == 1250)
        #expect(metrics.allTimeOrders == 2)
    }

    @Test("Product breakdown groups correctly")
    func productBreakdown() {
        let orders = [
            makeOrder(total: 500, productName: "SaneBar"),
            makeOrder(total: 500, productName: "SaneBar"),
            makeOrder(total: 1000, productName: "SaneClip")
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.productBreakdown.count == 2)

        let saneBar = metrics.productBreakdown.first { $0.productName == "SaneBar" }
        #expect(saneBar?.revenue == 1000)
        #expect(saneBar?.orderCount == 2)

        let saneClip = metrics.productBreakdown.first { $0.productName == "SaneClip" }
        #expect(saneClip?.revenue == 1000)
        #expect(saneClip?.orderCount == 1)
    }

    @Test("Daily breakdown sorted newest first")
    func dailyBreakdown() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let orders = [
            makeOrder(total: 500, date: yesterday),
            makeOrder(total: 1000)
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.dailyBreakdown.count == 2)
        #expect(metrics.dailyBreakdown.first!.date > metrics.dailyBreakdown.last!.date)
    }

    @Test("Latest paid order ignores refunds and can filter by provider")
    @MainActor
    func latestPaidOrderUsesNewestPaidSale() {
        let calendar = Calendar.current
        let olderPaid = makeOrder(
            id: "older-paid",
            total: 900,
            date: calendar.date(byAdding: .day, value: -3, to: Date())!,
            provider: .lemonSqueezy
        )
        let newestRefunded = makeOrder(
            id: "newest-refunded",
            total: 5000,
            status: .refunded,
            provider: .stripe
        )
        let newestPaid = makeOrder(
            id: "newest-paid",
            total: 1900,
            date: calendar.date(byAdding: .day, value: -1, to: Date())!,
            provider: .gumroad
        )

        let manager = SalesManager()
        manager.resetForUITests()
        manager.orders = [olderPaid, newestRefunded, newestPaid]

        #expect(manager.latestPaidOrder()?.id == "newest-paid")
        #expect(manager.latestPaidOrder(filteredBy: .lemonSqueezy)?.id == "older-paid")
        #expect(manager.latestPaidOrder(filteredBy: .stripe) == nil)
    }

    @Test("Month revenue includes this month only")
    func monthRevenue() {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let orders = [
            makeOrder(total: 500),
            makeOrder(total: 1000, date: lastMonth)
        ]
        let metrics = SalesMetrics.compute(from: orders)
        #expect(metrics.monthRevenue == 500)
        #expect(metrics.allTimeRevenue == 1500)
    }

    // MARK: - Order Model

    @Test("Order formats currency correctly")
    func orderFormatting() {
        let order = makeOrder(total: 1250)
        #expect(order.totalDecimal == 12.50)
        #expect(order.isToday)
    }

    @Test("Multi-provider orders aggregate correctly")
    func multiProviderAggregation() {
        let lsOrder = makeOrder(total: 500, productName: "SaneBar")
        let grOrder = Order(
            id: "gr-1",
            orderNumber: nil,
            status: .paid,
            total: 300,
            subtotal: nil,
            tax: nil,
            discountTotal: nil,
            currency: "USD",
            customerEmail: "buyer@example.com",
            customerName: "Buyer",
            productName: "SaneBar",
            variantName: nil,
            createdAt: Date(),
            refundedAt: nil,
            refundedAmount: nil,
            provider: .gumroad,
            totalFormatted: nil,
            subtotalFormatted: nil,
            taxFormatted: nil,
            discountTotalFormatted: nil,
            taxName: nil,
            taxRate: nil,
            taxInclusive: nil,
            receiptURL: nil,
            identifier: nil,
            gumroadSaleID: "sale_abc",
            ipCountry: "US",
            stripePaymentIntentID: nil,
            paymentMethod: nil
        )
        let metrics = SalesMetrics.compute(from: [lsOrder, grOrder])
        #expect(metrics.allTimeRevenue == 800)
        #expect(metrics.allTimeOrders == 2)
        #expect(metrics.productBreakdown.count == 1)
        #expect(metrics.productBreakdown.first?.orderCount == 2)
    }

    @Test("Demo data trends positive for previews")
    func demoDataHasPositiveMomentum() {
        let now = Date()
        let cal = Calendar.current
        let orders = DemoData.allOrders
        let metrics = SalesMetrics.compute(from: orders)

        let todayRevenue = metrics.dailyBreakdown.first(where: { cal.isDateInToday($0.date) })?.revenue ?? 0
        let yesterdayRevenue = metrics.dailyBreakdown.first(where: { cal.isDateInYesterday($0.date) })?.revenue ?? 0

        #expect(todayRevenue > yesterdayRevenue)
        #expect(revenue(from: orders, daysBack: 7, now: now) > revenue(from: orders, daysBack: 14, untilDaysBack: 7, now: now))
        #expect(revenue(from: orders, daysBack: 30, now: now) > revenue(from: orders, daysBack: 60, untilDaysBack: 30, now: now))
    }


    @Test("Custom range helpers normalize dates and fill missing days")
    func customRangeHelpers() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8))!
        let interval = SaneSalesDateRangeStore.normalizedInterval(start: start, end: end, maximumDate: start)

        #expect(calendar.isDate(interval.start, inSameDayAs: end))
        #expect(calendar.isDate(interval.end, inSameDayAs: start))
        #expect(SaneSalesDateRangeStore.dayCount(in: interval) == 3)

        let orders = [
            makeOrder(id: "one", total: 500, date: calendar.date(byAdding: .hour, value: 9, to: end)!),
            makeOrder(id: "two", total: 1200, date: calendar.date(byAdding: .hour, value: 12, to: start)!)
        ]
        let series = SaneSalesDateRangeStore.dailySeries(from: orders, in: interval)

        #expect(series.count == 3)
        #expect(series[0].revenue == 500)
        #expect(series[1].revenue == 0)
        #expect(series[2].revenue == 1200)
    }

    @Test("Launch overrides persist a custom screenshot range before the view tree loads")
    func launchOverridesPersistCustomRange() {
        let suiteName = "SaneSalesLaunchOverridesTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 12))!

        SaneSalesLaunchOverrides.applyPersistentUIState(
            arguments: [
                "SaneSales",
                "--force-pro-mode",
                "--screenshot-custom-range-start", "2026-04-04",
                "--screenshot-custom-range-end", "2026-04-18"
            ],
            userDefaults: defaults,
            now: now,
            calendar: calendar
        )

        #expect(defaults.string(forKey: SaneSalesDateRangeStore.selectedRangeKey) == TimeRange.custom.rawValue)

        let storedStart = Date(timeIntervalSince1970: defaults.double(forKey: SaneSalesDateRangeStore.customStartKey))
        let storedEnd = Date(timeIntervalSince1970: defaults.double(forKey: SaneSalesDateRangeStore.customEndKey))

        #expect(calendar.isDate(storedStart, inSameDayAs: calendar.date(from: DateComponents(year: 2026, month: 4, day: 4))!))
        #expect(calendar.isDate(storedEnd, inSameDayAs: calendar.date(from: DateComponents(year: 2026, month: 4, day: 18))!))
    }

    @Test("Sales manager filters plan scoped orders inside a selected interval")
    @MainActor
    func salesManagerIntervalFiltering() {
        let manager = SalesManager()
        manager.resetForUITests()
        manager.isPro = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let inRangeDate = calendar.date(byAdding: .day, value: -2, to: today)!
        let outOfRangeDate = calendar.date(byAdding: .day, value: -10, to: today)!

        manager.orders = [
            makeOrder(id: "recent", total: 900, date: inRangeDate),
            makeOrder(id: "older", total: 700, date: outOfRangeDate)
        ]

        let interval = SaneSalesDateRangeStore.normalizedInterval(
            start: calendar.date(byAdding: .day, value: -3, to: today)!,
            end: today,
            maximumDate: today
        )

        let filtered = manager.planScopedOrders(filteredBy: nil, in: interval)
        #expect(filtered.map(\.id) == ["recent"])
        #expect(manager.metrics(filteredBy: nil, in: interval, scopedToPlan: true).allTimeRevenue == 900)
    }

    private func revenue(from orders: [Order], daysBack: Int, untilDaysBack: Int = 0, now: Date) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysBack, to: now) ?? now
        let end = untilDaysBack == 0 ? now : (cal.date(byAdding: .day, value: -untilDaysBack, to: now) ?? now)

        return orders
            .filter { $0.status == .paid && $0.createdAt >= start && $0.createdAt < end }
            .reduce(0) { $0 + $1.netTotal }
    }
}
