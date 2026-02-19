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
        refundedAmount: Int? = nil
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

    private func revenue(from orders: [Order], daysBack: Int, untilDaysBack: Int = 0, now: Date) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysBack, to: now) ?? now
        let end = untilDaysBack == 0 ? now : (cal.date(byAdding: .day, value: -untilDaysBack, to: now) ?? now)

        return orders
            .filter { $0.status == .paid && $0.createdAt >= start && $0.createdAt < end }
            .reduce(0) { $0 + $1.netTotal }
    }
}
