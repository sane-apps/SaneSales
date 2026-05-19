// frozen_string_literal: true
import Foundation

/// Generates realistic fake data for screenshots and App Store previews.
/// Launched via `--demo` argument. Uses a fictional indie studio across all 3 providers.
enum DemoData {
        // MARK: - Public API

        @MainActor static func loadInto(
            manager: SalesManager,
            connectedProviders: Set<SalesProviderType> = Set(SalesProviderType.allCases)
        ) {
            let shouldDropTodayOrders = CommandLine.arguments.contains("--screenshot-no-today-orders")
            let calendar = Calendar.current
            let filteredOrders = allOrders
                .filter { connectedProviders.contains($0.provider) }
                .filter { !shouldDropTodayOrders || !calendar.isDateInToday($0.createdAt) }
                .sorted { $0.createdAt > $1.createdAt }
            let filteredProducts = allProducts.filter { connectedProviders.contains($0.provider) }
            let filteredStores = allStores.filter { connectedProviders.contains($0.provider) }

            manager.orders = filteredOrders
            manager.products = filteredProducts
            manager.stores = filteredStores
            manager.metrics = SalesMetrics.compute(from: filteredOrders)
            manager.isLemonSqueezyConnected = connectedProviders.contains(.lemonSqueezy)
            manager.isGumroadConnected = connectedProviders.contains(.gumroad)
            manager.isStripeConnected = connectedProviders.contains(.stripe)
            manager.lastUpdated = Date()
        }

        // MARK: - Stores

        static let allStores: [Store] = [
            Store(
                id: "ls-store-1", name: "Pixel Studio", slug: "pixelstudio",
                currency: "USD", totalRevenue: 1_247_500, thirtyDayRevenue: 189_500,
                provider: .lemonSqueezy, url: nil, avatarURL: nil,
                plan: "Growth", country: "US", countryNicename: "United States",
                totalSales: 1842, thirtyDaySales: 278, createdAt: date(2024, 3, 15),
                gumroadUserID: nil, stripeAccountID: nil, stripeEmail: nil
            ),
            Store(
                id: "gr-store-1", name: "Pixel Studio", slug: "pixelstudio",
                currency: "USD", totalRevenue: 634_200, thirtyDayRevenue: 97800,
                provider: .gumroad, url: nil, avatarURL: nil,
                plan: nil, country: "US", countryNicename: "United States",
                totalSales: 923, thirtyDaySales: 142, createdAt: date(2024, 6, 1),
                gumroadUserID: "gr-user-demo", stripeAccountID: nil, stripeEmail: nil
            ),
            Store(
                id: "st-store-1", name: "Pixel Studio", slug: nil,
                currency: "USD", totalRevenue: 458_300, thirtyDayRevenue: 72400,
                provider: .stripe, url: nil, avatarURL: nil,
                plan: nil, country: "US", countryNicename: "United States",
                totalSales: 614, thirtyDaySales: 97, createdAt: date(2024, 9, 10),
                gumroadUserID: nil, stripeAccountID: "acct_demo", stripeEmail: "hello@example.com"
            )
        ]

        // MARK: - Products

        static let allProducts: [Product] = [
            Product(
                id: "prod-1", name: "ScreenFlow Pro", slug: "screenflow-pro",
                description: "Professional screen recording for Mac",
                price: 4900, currency: "USD", status: .published,
                createdAt: date(2024, 3, 20), provider: .gumroad,
                thumbURL: nil, largeThumbURL: nil, buyNowURL: nil, storeURL: nil,
                priceFormatted: "$49.00", statusFormatted: "Published",
                totalSales: 923, totalRevenue: 634_200,
                gumroadProductID: "gum-prod-1", stripeProductID: nil, stripeDefaultPrice: nil
            ),
            Product(
                id: "prod-2", name: "PixelSnap", slug: "pixelsnap",
                description: "Measure anything on screen",
                price: 2900, currency: "USD", status: .published,
                createdAt: date(2024, 4, 10), provider: .lemonSqueezy,
                thumbURL: nil, largeThumbURL: nil, buyNowURL: nil, storeURL: nil,
                priceFormatted: "$29.00", statusFormatted: "Published",
                totalSales: 1204, totalRevenue: 879_200,
                gumroadProductID: nil, stripeProductID: nil, stripeDefaultPrice: nil
            ),
            Product(
                id: "prod-3", name: "ColorKit", slug: "colorkit",
                description: "Color picker and palette manager",
                price: 1900, currency: "USD", status: .published,
                createdAt: date(2024, 9, 15), provider: .stripe,
                thumbURL: nil, largeThumbURL: nil, buyNowURL: nil, storeURL: nil,
                priceFormatted: "$19.00", statusFormatted: "Active",
                totalSales: 614, totalRevenue: 458_300,
                gumroadProductID: nil, stripeProductID: "prod_demo3", stripeDefaultPrice: "price_demo3"
            ),
            Product(
                id: "prod-4", name: "IconForge", slug: "iconforge",
                description: "App icon generator for developers",
                price: 7900, currency: "USD", status: .published,
                createdAt: date(2024, 5, 1), provider: .lemonSqueezy,
                thumbURL: nil, largeThumbURL: nil, buyNowURL: nil, storeURL: nil,
                priceFormatted: "$79.00", statusFormatted: "Published",
                totalSales: 638, totalRevenue: 368_300,
                gumroadProductID: nil, stripeProductID: nil, stripeDefaultPrice: nil
            )
        ]

        // MARK: - Orders

        static var allOrders: [Order] {
            var orders: [Order] = []
            var counter = 1

            let now = Date()
            let cal = Calendar.current

            // Strong positive recent momentum for screenshots and onboarding demo:
            // today > yesterday, last 7 days > prior 7 days, last 30 days > prior 30 days.
            for sale in featuredRecentSales(now: now, calendar: cal) {
                orders.append(makeOrder(
                    id: counter,
                    product: sale.product.name,
                    total: sale.product.total,
                    provider: sale.product.provider,
                    customer: sale.customer.name,
                    email: sale.customer.email,
                    date: sale.date
                ))
                counter += 1
            }

            for sale in fixedMarketingRangeSales(calendar: cal) {
                orders.append(makeOrder(
                    id: counter,
                    product: sale.product.name,
                    total: sale.product.total,
                    provider: sale.product.provider,
                    customer: sale.customer.name,
                    email: sale.customer.email,
                    date: sale.date
                ))
                counter += 1
            }

            // Deterministic history over the prior 90 days, gradually ramping up.
            for daysAgo in 2 ... 90 {
                guard let dayDate = cal.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let momentum = 2 + ((90 - daysAgo) / 14) // 2...8, higher near present
                let weeklyPattern = [0, 2, 1, 4, 2, 5, 1][daysAgo % 7]
                let ordersThisDay = momentum + weeklyPattern

                for slot in 0 ..< ordersThisDay {
                    let product = demoProducts[(daysAgo + slot) % demoProducts.count]
                    let customer = demoCustomers[(counter + slot) % demoCustomers.count]
                    let total = product.total + demoOrderAdjustment(dayOffset: daysAgo, slot: slot)

                    var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
                    comps.hour = 9 + ((daysAgo + slot * 3) % 11) // 9am...7pm
                    comps.minute = (daysAgo * 7 + slot * 11) % 60
                    let orderDate = cal.date(from: comps) ?? dayDate

                    orders.append(makeOrder(
                        id: counter,
                        product: product.name,
                        total: total,
                        provider: product.provider,
                        customer: customer.name,
                        email: customer.email,
                        date: orderDate
                    ))
                    counter += 1
                }
            }

            return orders
        }

        // MARK: - Helpers

        private static func makeOrder(
            id: Int, product: String, total: Int, provider: SalesProviderType,
            customer: String, email: String, date: Date
        ) -> Order {
            Order(
                id: "demo-\(id)", orderNumber: 1000 + id, status: .paid,
                total: total, subtotal: total, tax: 0, discountTotal: 0,
                currency: "USD", customerEmail: email, customerName: customer,
                productName: product, variantName: nil, createdAt: date, refundedAt: nil, refundedAmount: nil,
                provider: provider,
                totalFormatted: formatCents(total), subtotalFormatted: formatCents(total),
                taxFormatted: "$0.00", discountTotalFormatted: nil,
                taxName: nil, taxRate: nil, taxInclusive: nil,
                receiptURL: nil, identifier: "DEMO-\(String(format: "%04d", id))",
                gumroadSaleID: provider == .gumroad ? "gr-sale-\(id)" : nil,
                ipCountry: nil,
                stripePaymentIntentID: provider == .stripe ? "pi_demo\(id)" : nil,
                paymentMethod: provider == .stripe ? "card" : nil
            )
        }

        private struct DemoProductTemplate {
            let name: String
            let total: Int
            let provider: SalesProviderType
        }

        private struct DemoCustomer {
            let name: String
            let email: String
        }

        private struct FeaturedSale {
            let product: DemoProductTemplate
            let customer: DemoCustomer
            let date: Date
        }

        private static let demoProducts: [DemoProductTemplate] = [
            DemoProductTemplate(name: "PixelSnap", total: 2900, provider: .lemonSqueezy),
            DemoProductTemplate(name: "ScreenFlow Pro", total: 4900, provider: .gumroad),
            DemoProductTemplate(name: "ColorKit", total: 1900, provider: .stripe),
            DemoProductTemplate(name: "IconForge", total: 7900, provider: .lemonSqueezy)
        ]

        private static let demoCustomers: [DemoCustomer] = [
            DemoCustomer(name: "Demo Buyer 01", email: "buyer01@example.com"),
            DemoCustomer(name: "Demo Buyer 02", email: "buyer02@example.com"),
            DemoCustomer(name: "Demo Buyer 03", email: "buyer03@example.com"),
            DemoCustomer(name: "Demo Buyer 04", email: "buyer04@example.com"),
            DemoCustomer(name: "Demo Buyer 05", email: "buyer05@example.com"),
            DemoCustomer(name: "Demo Buyer 06", email: "buyer06@example.com"),
            DemoCustomer(name: "Demo Buyer 07", email: "buyer07@example.com"),
            DemoCustomer(name: "Demo Buyer 08", email: "buyer08@example.com"),
            DemoCustomer(name: "Demo Buyer 09", email: "buyer09@example.com"),
            DemoCustomer(name: "Demo Buyer 10", email: "buyer10@example.com"),
            DemoCustomer(name: "Demo Buyer 11", email: "buyer11@example.com"),
            DemoCustomer(name: "Demo Buyer 12", email: "buyer12@example.com"),
            DemoCustomer(name: "Demo Buyer 13", email: "buyer13@example.com"),
            DemoCustomer(name: "Demo Buyer 14", email: "buyer14@example.com"),
            DemoCustomer(name: "Demo Buyer 15", email: "buyer15@example.com"),
            DemoCustomer(name: "Demo Buyer 16", email: "buyer16@example.com"),
            DemoCustomer(name: "Demo Buyer 17", email: "buyer17@example.com"),
            DemoCustomer(name: "Demo Buyer 18", email: "buyer18@example.com"),
            DemoCustomer(name: "Demo Buyer 19", email: "buyer19@example.com"),
            DemoCustomer(name: "Demo Buyer 20", email: "buyer20@example.com")
        ]

        private static func fixedMarketingRangeSales(calendar: Calendar) -> [FeaturedSale] {
            let dailyTotals = [2800, 2300, 2300, 1200, 1500, 1800, 2200, 3000, 2100, 3300, 2200, 2200, 1400, 2600, 3100]
            return dailyTotals.enumerated().flatMap { index, total in
                let day = 4 + index
                let dateBase = calendar.date(from: DateComponents(year: 2026, month: 4, day: day)) ?? Date()
                let product = demoProducts[index % demoProducts.count]
                let firstTotal = max(900, total / 2)
                let secondTotal = max(900, total - firstTotal)
                return [
                    FeaturedSale(product: DemoProductTemplate(name: product.name, total: firstTotal, provider: product.provider), customer: demoCustomers[(index * 2) % demoCustomers.count], date: calendar.date(byAdding: .hour, value: 10, to: dateBase) ?? dateBase),
                    FeaturedSale(product: DemoProductTemplate(name: product.name, total: secondTotal, provider: product.provider), customer: demoCustomers[(index * 2 + 1) % demoCustomers.count], date: calendar.date(byAdding: .hour, value: 15, to: dateBase) ?? dateBase)
                ]
            }
        }

        private static func featuredRecentSales(now: Date, calendar: Calendar) -> [FeaturedSale] {
            func dated(_ daysAgo: Int, _ hour: Int, _ minute: Int) -> Date {
                let base = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
                var comps = calendar.dateComponents([.year, .month, .day], from: base)
                comps.hour = hour
                comps.minute = minute
                return calendar.date(from: comps) ?? base
            }

            // Keep recent demo data obviously positive.
            return [
                // Today (10 orders)
                FeaturedSale(product: demoProducts[3], customer: demoCustomers[15], date: dated(0, 8, 45)),
                FeaturedSale(product: demoProducts[3], customer: demoCustomers[0], date: dated(0, 9, 20)),
                FeaturedSale(product: demoProducts[0], customer: demoCustomers[1], date: dated(0, 10, 12)),
                FeaturedSale(product: demoProducts[1], customer: demoCustomers[2], date: dated(0, 11, 5)),
                FeaturedSale(product: demoProducts[2], customer: demoCustomers[3], date: dated(0, 12, 40)),
                FeaturedSale(product: demoProducts[3], customer: demoCustomers[4], date: dated(0, 14, 15)),
                FeaturedSale(product: demoProducts[0], customer: demoCustomers[5], date: dated(0, 15, 28)),
                FeaturedSale(product: demoProducts[1], customer: demoCustomers[6], date: dated(0, 17, 9)),
                FeaturedSale(product: demoProducts[2], customer: demoCustomers[7], date: dated(0, 18, 32)),
                FeaturedSale(product: demoProducts[3], customer: demoCustomers[8], date: dated(0, 10, 45)),

                // Yesterday (6 orders, intentionally lower than today)
                FeaturedSale(product: demoProducts[0], customer: demoCustomers[9], date: dated(1, 9, 44)),
                FeaturedSale(product: demoProducts[1], customer: demoCustomers[10], date: dated(1, 11, 2)),
                FeaturedSale(product: demoProducts[2], customer: demoCustomers[11], date: dated(1, 12, 19)),
                FeaturedSale(product: demoProducts[0], customer: demoCustomers[12], date: dated(1, 14, 7)),
                FeaturedSale(product: demoProducts[1], customer: demoCustomers[13], date: dated(1, 15, 33)),
                FeaturedSale(product: demoProducts[2], customer: demoCustomers[14], date: dated(1, 17, 25))
            ]
        }

        private static func demoOrderAdjustment(dayOffset: Int, slot: Int) -> Int {
            let pattern = [-500, 0, 300, 700, -200, 1_100, 500]
            return pattern[(dayOffset + slot) % pattern.count]
        }

        private static func formatCents(_ cents: Int) -> String {
            let dollars = Double(cents) / 100.0
            return String(format: "$%.2f", dollars)
        }

        private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            return Calendar.current.date(from: comps)!
        }
}
