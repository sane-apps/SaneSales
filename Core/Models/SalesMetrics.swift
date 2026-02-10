import Foundation

/// Computed sales aggregations derived from raw orders.
struct SalesMetrics: Equatable, Sendable {
    let todayRevenue: Int
    let todayOrders: Int
    let thirtyDayRevenue: Int
    let thirtyDayOrders: Int
    let monthRevenue: Int
    let monthOrders: Int
    let allTimeRevenue: Int
    let allTimeOrders: Int
    let dailyBreakdown: [DailySales]
    let productBreakdown: [ProductSales]

    static let empty = SalesMetrics(
        todayRevenue: 0,
        todayOrders: 0,
        thirtyDayRevenue: 0,
        thirtyDayOrders: 0,
        monthRevenue: 0,
        monthOrders: 0,
        allTimeRevenue: 0,
        allTimeOrders: 0,
        dailyBreakdown: [],
        productBreakdown: []
    )

    /// Build metrics from a list of paid orders.
    static func compute(from orders: [Order]) -> SalesMetrics {
        let paid = orders.filter { $0.status == .paid }
        let calendar = Calendar.current
        let today = Date()

        let todayOrders = paid.filter { calendar.isDateInToday($0.createdAt) }
        let thirtyDayStart = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let thirtyDayOrders = paid.filter { $0.createdAt >= thirtyDayStart }
        let monthOrders = paid.filter { calendar.isDate($0.createdAt, equalTo: today, toGranularity: .month) }

        let daily = Dictionary(grouping: paid) { order in
            calendar.startOfDay(for: order.createdAt)
        }
        .map { date, orders in
            DailySales(
                date: date,
                revenue: orders.reduce(0) { $0 + $1.netTotal },
                orderCount: orders.count
            )
        }
        .sorted { $0.date > $1.date }

        let byProduct = Dictionary(grouping: paid) { $0.productName }
            .map { name, orders in
                ProductSales(
                    productName: name,
                    revenue: orders.reduce(0) { $0 + $1.netTotal },
                    orderCount: orders.count,
                    lastOrderDate: orders.map(\.createdAt).max() ?? today
                )
            }
            .sorted { $0.revenue > $1.revenue }

        return SalesMetrics(
            todayRevenue: todayOrders.reduce(0) { $0 + $1.netTotal },
            todayOrders: todayOrders.count,
            thirtyDayRevenue: thirtyDayOrders.reduce(0) { $0 + $1.netTotal },
            thirtyDayOrders: thirtyDayOrders.count,
            monthRevenue: monthOrders.reduce(0) { $0 + $1.netTotal },
            monthOrders: monthOrders.count,
            allTimeRevenue: paid.reduce(0) { $0 + $1.netTotal },
            allTimeOrders: paid.count,
            dailyBreakdown: daily,
            productBreakdown: byProduct
        )
    }
}

struct DailySales: Identifiable, Equatable, Sendable {
    var id: Date { date }
    let date: Date
    let revenue: Int // cents
    let orderCount: Int

    var revenueDecimal: Decimal {
        Decimal(revenue) / 100
    }
}

struct ProductSales: Identifiable, Equatable, Sendable {
    var id: String { productName }
    let productName: String
    let revenue: Int // cents
    let orderCount: Int
    let lastOrderDate: Date

    var revenueDecimal: Decimal {
        Decimal(revenue) / 100
    }
}
