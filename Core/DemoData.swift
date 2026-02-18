// frozen_string_literal: true
import Foundation

/// Generates realistic fake data for screenshots and App Store previews.
/// Launched via `--demo` argument. Uses a fictional indie studio across all 3 providers.
enum DemoData {
        // MARK: - Public API

        @MainActor static func loadInto(manager: SalesManager) {
            manager.orders = allOrders.sorted { $0.createdAt > $1.createdAt }
            manager.products = allProducts
            manager.stores = allStores
            manager.metrics = SalesMetrics.compute(from: manager.orders)
            manager.isLemonSqueezyConnected = true
            manager.isGumroadConnected = true
            manager.isStripeConnected = true
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
                gumroadUserID: nil, stripeAccountID: "acct_demo", stripeEmail: "hello@pixelstudio.dev"
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

            // --- Today's orders (5 orders = $226) ---
            orders.append(makeOrder(id: counter, product: "PixelSnap", total: 2900, provider: .lemonSqueezy,
                                    customer: "Emma Wilson", email: "emma.w@gmail.com",
                                    date: cal.date(byAdding: .hour, value: -1, to: now)!))
            counter += 1
            orders.append(makeOrder(id: counter, product: "ScreenFlow Pro", total: 4900, provider: .gumroad,
                                    customer: "Carlos Mendez", email: "carlos@mendez.dev",
                                    date: cal.date(byAdding: .hour, value: -3, to: now)!))
            counter += 1
            orders.append(makeOrder(id: counter, product: "IconForge", total: 7900, provider: .lemonSqueezy,
                                    customer: "Aisha Patel", email: "aisha@pixelworks.io",
                                    date: cal.date(byAdding: .hour, value: -5, to: now)!))
            counter += 1
            orders.append(makeOrder(id: counter, product: "ColorKit", total: 1900, provider: .stripe,
                                    customer: "James O'Brien", email: "james.ob@proton.me",
                                    date: cal.date(byAdding: .hour, value: -7, to: now)!))
            counter += 1
            orders.append(makeOrder(id: counter, product: "PixelSnap", total: 2900, provider: .lemonSqueezy,
                                    customer: "Yuki Tanaka", email: "yuki.t@icloud.com",
                                    date: cal.date(byAdding: .hour, value: -9, to: now)!))
            counter += 1

            // --- This month (spread across ~25 days) ---
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            for day in 1 ..< cal.component(.day, from: now) {
                guard let dayDate = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
                let ordersThisDay = Int.random(in: 4 ... 12)
                for _ in 0 ..< ordersThisDay {
                    let (product, total, provider) = randomProduct()
                    let (name, email) = randomCustomer()
                    let hour = Int.random(in: 8 ... 22)
                    let minute = Int.random(in: 0 ... 59)
                    var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
                    comps.hour = hour
                    comps.minute = minute
                    let orderDate = cal.date(from: comps) ?? dayDate

                    // Skip if this would be in the future
                    guard orderDate < now else { continue }

                    orders.append(makeOrder(id: counter, product: product, total: total, provider: provider,
                                            customer: name, email: email, date: orderDate))
                    counter += 1
                }
            }

            // --- Older orders (past 90 days, sparser) ---
            for daysAgo in 31 ... 90 {
                guard let dayDate = cal.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let ordersThisDay = Int.random(in: 2 ... 8)
                for _ in 0 ..< ordersThisDay {
                    let (product, total, provider) = randomProduct()
                    let (name, email) = randomCustomer()
                    let hour = Int.random(in: 8 ... 22)
                    var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
                    comps.hour = hour
                    let orderDate = cal.date(from: comps) ?? dayDate
                    orders.append(makeOrder(id: counter, product: product, total: total, provider: provider,
                                            customer: name, email: email, date: orderDate))
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

        private static func randomProduct() -> (name: String, total: Int, provider: SalesProviderType) {
            let products: [(String, Int, SalesProviderType)] = [
                ("PixelSnap", 2900, .lemonSqueezy),
                ("ScreenFlow Pro", 4900, .gumroad),
                ("ColorKit", 1900, .stripe),
                ("IconForge", 7900, .lemonSqueezy)
            ]
            return products.randomElement()!
        }

        private static func randomCustomer() -> (name: String, email: String) {
            let customers = [
                ("Alex Johnson", "alex.j@gmail.com"),
                ("Sarah Chen", "sarah.chen@outlook.com"),
                ("Marcus Rivera", "marcus@rivera.dev"),
                ("Priya Sharma", "priya.s@yahoo.com"),
                ("James O'Brien", "james.ob@proton.me"),
                ("Yuki Tanaka", "yuki.t@icloud.com"),
                ("Fatima Hassan", "fatima.h@gmail.com"),
                ("Lucas Schmidt", "lucas@schmidt.io"),
                ("Olivia Park", "olivia.park@gmail.com"),
                ("Noah Williams", "noah.w@hey.com"),
                ("Mia Anderson", "mia.a@fastmail.com"),
                ("Ethan Brown", "ethan.b@gmail.com"),
                ("Sofia Garcia", "sofia.g@outlook.com"),
                ("Liam Davis", "liam.d@proton.me"),
                ("Isabella Martinez", "isabella.m@gmail.com"),
                ("Benjamin Lee", "ben.lee@icloud.com"),
                ("Charlotte Wang", "charlotte.w@hey.com"),
                ("Daniel Kim", "daniel.k@gmail.com"),
                ("Amelia Taylor", "amelia.t@fastmail.com"),
                ("Oliver White", "oliver.w@gmail.com")
            ]
            return customers.randomElement()!
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
