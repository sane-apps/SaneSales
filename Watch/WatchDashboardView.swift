import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class WatchDashboardViewModel: ObservableObject {
    @Published private(set) var snapshot: WatchSalesSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var usingDemoData = false

    func refresh(useDemoIfEmpty: Bool = false) {
        isLoading = true

        let orders = loadOrders()
        let resolvedOrders: [Order]
        if orders.isEmpty, useDemoIfEmpty {
            resolvedOrders = demoOrders()
            usingDemoData = true
        } else {
            resolvedOrders = orders
            usingDemoData = false
        }

        guard !resolvedOrders.isEmpty else {
            snapshot = nil
            isLoading = false
            return
        }

        let metrics = SalesMetrics.compute(from: resolvedOrders)
        let currency = dominantCurrency(for: resolvedOrders)
        let providerRows = providerRows(from: resolvedOrders)
        let recentRows = resolvedOrders.sorted(by: { $0.createdAt > $1.createdAt }).prefix(15).map {
            WatchRecentSaleRow(
                productName: $0.productName,
                provider: $0.provider,
                amountCents: $0.netTotal,
                currency: $0.currency,
                createdAt: $0.createdAt
            )
        }

        let defaults = SharedStore.userDefaults()
        let lastUpdated = defaults.double(forKey: SharedStore.cacheLastUpdatedKey)
        let lastUpdatedDate = lastUpdated > 0 ? Date(timeIntervalSince1970: lastUpdated) : nil

        snapshot = WatchSalesSnapshot(
            metrics: metrics,
            currency: currency,
            providerRows: providerRows,
            recentRows: recentRows,
            lastUpdated: lastUpdatedDate
        )

        isLoading = false
    }

    private func loadOrders() -> [Order] {
        let defaults = SharedStore.userDefaults()
        guard let data = defaults.data(forKey: SharedStore.cachedOrdersKey) else { return [] }
        return (try? JSONDecoder().decode([Order].self, from: data)) ?? []
    }

    private func dominantCurrency(for orders: [Order]) -> String {
        Dictionary(grouping: orders, by: \.currency)
            .mapValues(\.count)
            .max(by: { $0.value < $1.value })?.key ?? "USD"
    }

    private func providerRows(from orders: [Order]) -> [WatchProviderRow] {
        let grouped = Dictionary(grouping: orders.filter { $0.status == .paid }, by: \.provider)
        return grouped.map { provider, providerOrders in
            WatchProviderRow(
                provider: provider,
                orderCount: providerOrders.count,
                revenueCents: providerOrders.reduce(0) { $0 + $1.netTotal },
                currency: dominantCurrency(for: providerOrders)
            )
        }
        .sorted(by: { $0.revenueCents > $1.revenueCents })
    }

    private func demoOrders() -> [Order] {
        let now = Date()
        return [
            // 5 products x 3 providers = 15 orders.
            // Each product appears multiple times across different sources.
            // Product 1
            makeDemoOrder(id: "watch_demo_p1_ls", product: "SaneBar", cents: 1900, currency: "USD", provider: .lemonSqueezy, createdAt: now.addingTimeInterval(-8 * 60)),
            makeDemoOrder(id: "watch_demo_p1_gr", product: "SaneBar", cents: 1800, currency: "USD", provider: .gumroad, createdAt: now.addingTimeInterval(-14 * 60)),
            makeDemoOrder(id: "watch_demo_p1_st", product: "SaneBar", cents: 1700, currency: "USD", provider: .stripe, createdAt: now.addingTimeInterval(-20 * 60)),
            // Product 2
            makeDemoOrder(id: "watch_demo_p2_ls", product: "SaneClip", cents: 1200, currency: "USD", provider: .lemonSqueezy, createdAt: now.addingTimeInterval(-26 * 60)),
            makeDemoOrder(id: "watch_demo_p2_gr", product: "SaneClip", cents: 1150, currency: "USD", provider: .gumroad, createdAt: now.addingTimeInterval(-32 * 60)),
            makeDemoOrder(id: "watch_demo_p2_st", product: "SaneClip", cents: 1100, currency: "USD", provider: .stripe, createdAt: now.addingTimeInterval(-38 * 60)),
            // Product 3
            makeDemoOrder(id: "watch_demo_p3_ls", product: "SaneSales", cents: 699, currency: "USD", provider: .lemonSqueezy, createdAt: now.addingTimeInterval(-44 * 60)),
            makeDemoOrder(id: "watch_demo_p3_gr", product: "SaneSales", cents: 699, currency: "USD", provider: .gumroad, createdAt: now.addingTimeInterval(-50 * 60)),
            makeDemoOrder(id: "watch_demo_p3_st", product: "SaneSales", cents: 699, currency: "USD", provider: .stripe, createdAt: now.addingTimeInterval(-56 * 60)),
            // Product 4
            makeDemoOrder(id: "watch_demo_p4_ls", product: "SaneSync", cents: 2900, currency: "USD", provider: .lemonSqueezy, createdAt: now.addingTimeInterval(-62 * 60)),
            makeDemoOrder(id: "watch_demo_p4_gr", product: "SaneSync", cents: 2800, currency: "USD", provider: .gumroad, createdAt: now.addingTimeInterval(-68 * 60)),
            makeDemoOrder(id: "watch_demo_p4_st", product: "SaneSync", cents: 2700, currency: "USD", provider: .stripe, createdAt: now.addingTimeInterval(-74 * 60)),
            // Product 5
            makeDemoOrder(id: "watch_demo_p5_ls", product: "SaneHosts", cents: 4900, currency: "USD", provider: .lemonSqueezy, createdAt: now.addingTimeInterval(-80 * 60)),
            makeDemoOrder(id: "watch_demo_p5_gr", product: "SaneHosts", cents: 4700, currency: "USD", provider: .gumroad, createdAt: now.addingTimeInterval(-86 * 60)),
            makeDemoOrder(id: "watch_demo_p5_st", product: "SaneHosts", cents: 4500, currency: "USD", provider: .stripe, createdAt: now.addingTimeInterval(-92 * 60))
        ]
    }

    private func makeDemoOrder(
        id: String,
        product: String,
        cents: Int,
        currency: String,
        provider: SalesProviderType,
        createdAt: Date
    ) -> Order {
        Order(
            id: id,
            orderNumber: nil,
            status: .paid,
            total: cents,
            subtotal: cents,
            tax: 0,
            discountTotal: 0,
            currency: currency,
            customerEmail: "watch@saneapps.com",
            customerName: "Watch Demo",
            productName: product,
            variantName: nil,
            createdAt: createdAt,
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
}

struct WatchDashboardView: View {
    @ObservedObject var viewModel: WatchDashboardViewModel
    private let focusRecentOnAppear = CommandLine.arguments.contains("--focus-recent")

    var body: some View {
        ZStack {
            WatchSaneBackground()
                .ignoresSafeArea()

            if let snapshot = viewModel.snapshot {
                GeometryReader { proxy in
                    watchContent(snapshot: snapshot, width: proxy.size.width)
                }
            } else {
                emptyState
            }
        }
    }

    private func watchContent(snapshot: WatchSalesSnapshot, width: CGFloat) -> some View {
        let contentWidth = max(120, width - (WatchLayout.horizontalPadding * 2))
        let sectionSpacing = WatchLayout.sectionSpacing(for: contentWidth)
        let primaryHeight = WatchLayout.primaryCardHeight(for: contentWidth)
        let miniHeight = WatchLayout.miniCardHeight(for: contentWidth)
        let cornerRadius = WatchLayout.cardCornerRadius(for: contentWidth)

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    headerRow(snapshot: snapshot, width: contentWidth)

                    WatchGlassCard(cornerRadius: cornerRadius, accentColor: WatchPalette.salesGreen) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(WatchPalette.salesGreen)

                            Text(currencyString(cents: snapshot.metrics.todayRevenue, currency: snapshot.currency))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)

                            Text("\(snapshot.metrics.todayOrders) paid orders")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(WatchPalette.salesGreenSoft)
                        }
                    }
                    .frame(height: primaryHeight)

                    HStack(spacing: sectionSpacing / WatchLayout.phi) {
                        WatchMiniCard(
                            title: "Month",
                            value: currencyString(cents: snapshot.metrics.monthRevenue, currency: snapshot.currency, compact: true),
                            subtitle: "\(snapshot.metrics.monthOrders) orders",
                            cornerRadius: cornerRadius,
                            height: miniHeight,
                            accentColor: WatchPalette.brandBlue
                        )
                        WatchMiniCard(
                            title: "All Time",
                            value: currencyString(cents: snapshot.metrics.allTimeRevenue, currency: snapshot.currency, compact: true),
                            subtitle: "\(snapshot.metrics.allTimeOrders) orders",
                            cornerRadius: cornerRadius,
                            height: miniHeight,
                            accentColor: WatchPalette.salesGold
                        )
                    }

                    if !snapshot.providerRows.isEmpty {
                        WatchGlassCard(cornerRadius: cornerRadius, accentColor: WatchPalette.providerAccent) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Providers")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WatchPalette.providerAccent)
                                ForEach(snapshot.providerRows) { row in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(providerColor(row.provider))
                                            .frame(width: 6, height: 6)
                                        Text(row.provider.displayName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(providerColor(row.provider))
                                            .lineLimit(1)
                                        Spacer()
                                        Text(currencyString(cents: row.revenueCents, currency: row.currency, compact: true))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }

                    if !snapshot.recentRows.isEmpty {
                        let compactRecent = contentWidth < 172
                        let timeWidth = max(30, min(40, contentWidth * 0.19))
                        let amountWidth = max(52, min(68, contentWidth * 0.30))
                        WatchGlassCard(cornerRadius: cornerRadius, accentColor: WatchPalette.salesGreenSoft) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recent Sales")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WatchPalette.salesGreenSoft)
                                ForEach(snapshot.recentRows) { row in
                                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                                        Circle()
                                            .fill(providerColor(row.provider))
                                            .frame(width: 5, height: 5)

                                        Text(row.productName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.74)
                                            .layoutPriority(1)

                                        Spacer(minLength: 4)

                                        if !compactRecent {
                                            Text(row.createdAt, style: .time)
                                                .font(.system(size: 10, weight: .medium))
                                                .monospacedDigit()
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                                .frame(width: timeWidth, alignment: .trailing)
                                                .foregroundStyle(.white.opacity(0.92))
                                                .layoutPriority(2)
                                        }

                                        Text(currencyString(cents: row.amountCents, currency: row.currency, compact: true))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.78)
                                            .frame(width: amountWidth, alignment: .trailing)
                                            .foregroundStyle(.white)
                                            .layoutPriority(3)
                                    }
                                    .padding(.vertical, 1)
                                }
                            }
                        }
                        .id("recent-sales")
                    }
                }
                .padding(.horizontal, WatchLayout.horizontalPadding)
                .padding(.vertical, WatchLayout.verticalPadding)
            }
            .onAppear {
                guard focusRecentOnAppear else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("recent-sales", anchor: .top)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("SaneSales")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Open SaneSales on iPhone to sync sales data.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button {
                viewModel.refresh(useDemoIfEmpty: true)
            } label: {
                Text("Show Demo Data")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(WatchPalette.salesGreen.opacity(0.88))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private func headerRow(snapshot: WatchSalesSnapshot, width: CGFloat) -> some View {
        let logoSize = WatchLayout.logoSize(for: width)
        return HStack(spacing: 6) {
            WatchLogoView(size: logoSize)

            VStack(alignment: .leading, spacing: 1) {
                Text("SaneSales")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(snapshot.lastUpdatedText(usingDemoData: viewModel.usingDemoData))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WatchPalette.brandBlueSoft)
            }

            Spacer(minLength: 4)

            Button {
                viewModel.refresh(useDemoIfEmpty: viewModel.usingDemoData)
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(WatchPalette.salesGreen.opacity(0.45))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func providerColor(_ provider: SalesProviderType) -> Color {
        switch provider {
        case .lemonSqueezy:
            return Color(red: 0.988, green: 0.761, blue: 0.200)
        case .gumroad:
            return Color(red: 1.0, green: 0.565, blue: 0.910)
        case .stripe:
            return Color(red: 0.388, green: 0.357, blue: 1.0)
        }
    }

    private func currencyString(cents: Int, currency: String, compact: Bool = false) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = compact ? .currencyAccounting : .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = compact ? 0 : 2

        if compact, amount >= 1000 {
            let symbol = formatter.currencySymbol ?? "$"
            if amount >= 1_000_000 {
                return "\(symbol)\(compactNumber(amount / 1_000_000))M"
            }
            return "\(symbol)\(compactNumber(amount / 1000))K"
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func compactNumber(_ value: Double) -> String {
        let text = String(format: "%.1f", value)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}

private struct WatchLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size / 4, style: .continuous)
                .fill(Color.white.opacity(0.12))

            #if canImport(UIKit)
            if let coinImage = UIImage(named: "CoinColor_3x.png") ?? UIImage(named: "CoinColor_3x") {
                Image(uiImage: coinImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 1.8, height: size * 1.8)
                    .saturation(1.2)
            } else {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: size * 0.78, weight: .semibold))
                    .foregroundStyle(WatchPalette.salesGreen)
            }
            #else
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: size * 0.78, weight: .semibold))
                .foregroundStyle(WatchPalette.salesGreen)
            #endif
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
    }
}

private struct WatchGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let accentColor: Color
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 14, accentColor: Color = WatchPalette.brandBlue, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accentColor.opacity(0.44), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(0.92))
                    .frame(width: 26, height: 2)
                    .padding(.top, 7)
                    .padding(.leading, 10)
            }
            .shadow(color: WatchPalette.brandBlue.opacity(0.22), radius: 8, x: 0, y: 4)
    }
}

private struct WatchMiniCard: View {
    let title: String
    let value: String
    let subtitle: String
    let cornerRadius: CGFloat
    let height: CGFloat
    let accentColor: Color

    var body: some View {
        WatchGlassCard(cornerRadius: cornerRadius, accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(accentColor.opacity(0.88))
                    .lineLimit(1)
            }
        }
        .frame(height: height)
    }
}

private struct WatchSaneBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WatchPalette.deepNavy, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(WatchPalette.brandBlue.opacity(0.23))
                .frame(width: 140, height: 140)
                .blur(radius: 38)
                .offset(x: -46, y: -76)

            Circle()
                .fill(WatchPalette.salesGreen.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 44)
                .offset(x: 52, y: 78)
        }
    }
}

private enum WatchPalette {
    static let deepNavy = Color(red: 0.051, green: 0.082, blue: 0.145)
    static let brandBlue = Color(red: 0.31, green: 0.56, blue: 0.98)
    static let brandBlueSoft = Color(red: 0.60, green: 0.75, blue: 1.00)
    static let salesGreen = Color(red: 0.204, green: 0.690, blue: 0.384)
    static let salesGreenSoft = Color(red: 0.55, green: 0.90, blue: 0.70)
    static let salesGold = Color(red: 0.98, green: 0.78, blue: 0.34)
    static let providerAccent = Color(red: 0.74, green: 0.64, blue: 1.0)
}

private enum WatchLayout {
    static let phi: CGFloat = 1.61803398875
    static let horizontalPadding: CGFloat = 8
    static let verticalPadding: CGFloat = 8

    static func sectionSpacing(for width: CGFloat) -> CGFloat {
        max(6, min(11, width / (phi * phi * phi * 2.8)))
    }

    static func primaryCardHeight(for width: CGFloat) -> CGFloat {
        max(96, min(126, width / phi))
    }

    static func miniCardHeight(for width: CGFloat) -> CGFloat {
        max(60, min(82, primaryCardHeight(for: width) / phi))
    }

    static func cardCornerRadius(for width: CGFloat) -> CGFloat {
        max(12, min(18, width / (phi * phi * phi)))
    }

    static func logoSize(for width: CGFloat) -> CGFloat {
        max(20, min(24, width / (phi * phi * phi * phi)))
    }
}

struct WatchSalesSnapshot {
    let metrics: SalesMetrics
    let currency: String
    let providerRows: [WatchProviderRow]
    let recentRows: [WatchRecentSaleRow]
    let lastUpdated: Date?

    func lastUpdatedText(usingDemoData: Bool) -> String {
        if usingDemoData {
            return "Demo data"
        }
        guard let lastUpdated else { return "Waiting for sync" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: lastUpdated, relativeTo: .now))"
    }
}

struct WatchProviderRow: Identifiable {
    var id: SalesProviderType { provider }

    let provider: SalesProviderType
    let orderCount: Int
    let revenueCents: Int
    let currency: String
}

struct WatchRecentSaleRow: Identifiable {
    var id: String {
        "\(provider.rawValue)-\(productName)-\(createdAt.timeIntervalSince1970)"
    }

    let productName: String
    let provider: SalesProviderType
    let amountCents: Int
    let currency: String
    let createdAt: Date
}
