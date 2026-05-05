import Charts
import SaneUI
import SwiftUI

struct ProductsView: View {
    @Environment(SalesManager.self) private var manager
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State private var selectedAngle: Int?
    @State private var selectedProduct: ProductSales?

    private struct SummaryItem: Identifiable {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var id: String {
            title
        }
    }

    private enum WidthClass {
        case compact
        case regular
        case wide

        init(width: CGFloat) {
            switch width {
            case ..<760:
                self = .compact
            case ..<1100:
                self = .regular
            default:
                self = .wide
            }
        }
    }

    private var scopedMetrics: SalesMetrics {
        manager.isPro ? manager.metrics : manager.planScopedMetrics
    }

    private var productSalesByName: [String: ProductSales] {
        Dictionary(uniqueKeysWithValues: scopedMetrics.productBreakdown.map { ($0.productName, $0) })
    }

    private var hasRevenueBreakdown: Bool {
        !scopedMetrics.productBreakdown.isEmpty
    }

    private var sortedProducts: [Product] {
        manager.products.sorted { lhs, rhs in
            let lhsRevenue = productSalesByName[lhs.name]?.revenue ?? -1
            let rhsRevenue = productSalesByName[rhs.name]?.revenue ?? -1
            if lhsRevenue != rhsRevenue {
                return lhsRevenue > rhsRevenue
            }
            if lhs.provider != rhs.provider {
                return lhs.provider.displayName < rhs.provider.displayName
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                GeometryReader { proxy in
                    let widthClass = WidthClass(width: proxy.size.width)

                    Group {
                        if manager.products.isEmpty, !manager.isLoading {
                            emptyProductsState(widthClass: widthClass)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    productsOverview(widthClass)

                                    if !manager.isPro && !hasRevenueBreakdown {
                                        noSalesCallout
                                    }

                                    if widthClass == .wide, scopedMetrics.productBreakdown.count >= 3 {
                                        HStack(alignment: .top, spacing: 16) {
                                            revenueChart(widthClass)
                                                .frame(width: min(max(proxy.size.width * 0.38, 340), 420))

                                            catalogSection
                                                .frame(maxWidth: .infinity, alignment: .top)
                                        }
                                    } else {
                                        catalogSection

                                        if hasRevenueBreakdown {
                                            revenueChart(widthClass)
                                        }
                                    }
                                }
                                .padding(.horizontal, widthClass == .compact ? 16 : 20)
                                .padding(.top, 12)
                                .padding(.bottom, productsBottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                                .frame(minHeight: proxy.size.height, alignment: .top)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Products")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: SaneSalesIOSChrome.floatingTabBarClearance)
                }
            #endif
                .refreshable {
                    await manager.refresh()
                }
        }
    }

    private func productsOverview(_ widthClass: WidthClass) -> some View {
        let summary = [
            SummaryItem(title: "Products", value: "\(manager.products.count)", icon: "shippingbox.fill", color: .salesGreen),
            SummaryItem(title: "Providers", value: "\(manager.connectedProviders.count)", icon: "link.circle.fill", color: .salesGold),
            SummaryItem(title: manager.isPro ? "Revenue" : "Sales Today", value: formatCents(totalRevenue), icon: "dollarsign.circle.fill", color: .metricAllTime),
        ]

        if widthClass == .compact {
            return AnyView(
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        summaryCard(summary[0], widthClass: widthClass)
                        summaryCard(summary[1], widthClass: widthClass)
                    }

                    summaryCard(summary[2], widthClass: widthClass, fillsWidth: true)
                }
            )
        }

        return AnyView(
            HStack(spacing: 8) {
                ForEach(summary) { item in
                    summaryCard(item, widthClass: widthClass, fillsWidth: true)
                }
            }
        )
    }

    private func summaryCard(
        _ item: SummaryItem,
        widthClass: WidthClass,
        fillsWidth: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: widthClass == .compact ? 6 : 7) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.color)
                    .font(.system(size: widthClass == .compact ? 11 : 13, weight: .semibold))
                Text(item.title)
                    .font(widthClass == .compact ? .system(size: 11, weight: .semibold) : .saneCallout)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            Text(item.value)
                .font(widthClass == .compact ? .system(size: 15, weight: .bold, design: .rounded) : .saneSubheadlineBold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
        .padding(.horizontal, widthClass == .compact ? 12 : 14)
        .padding(.vertical, widthClass == .compact ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.salesPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    // MARK: - Revenue Chart

    private func revenueChart(_ widthClass: WidthClass) -> some View {
        GlassSection(manager.isPro ? "Revenue by Product" : "Today's Sales by Product", icon: "chart.pie", iconColor: .salesGold) {
            Group {
                if compactChartLayout, widthClass != .compact {
                    HStack(alignment: .center, spacing: 20) {
                        donutChart(widthClass)
                            .frame(width: 220, height: 220)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Revenue mix")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(manager.isPro ? "Use the chart for the split and the catalog for product details." : "Trial and Pro show live product winners. Demo mode remains available anytime.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            customLegend
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 16) {
                        donutChart(widthClass)
                            .frame(height: widthClass == .compact ? 144 : 220)
                            .padding(.horizontal, widthClass == .compact ? 8 : 14)
                            .padding(.top, widthClass == .compact ? 8 : 14)

                        customLegend
                            .padding(.horizontal, widthClass == .compact ? 8 : 14)
                            .padding(.bottom, widthClass == .compact ? 8 : 14)
                    }
                }
            }
        }
        .onChange(of: selectedAngle) { _, newValue in
            withAnimation(.spring(response: 0.3)) {
                selectedProduct = findProduct(at: newValue)
            }
        }
    }

    private func donutChart(_ widthClass: WidthClass) -> some View {
        ZStack {
            Chart(scopedMetrics.productBreakdown) { product in
                SectorMark(
                    angle: .value("Revenue", product.revenue),
                    innerRadius: .ratio(compactChartLayout ? 0.64 : 0.58),
                    outerRadius: .ratio(selectedProduct?.id == product.id ? 0.95 : 0.85),
                    angularInset: 1.5
                )
                .foregroundStyle(chartColor(for: product))
                .opacity(selectedProduct == nil || selectedProduct?.id == product.id ? 1.0 : 0.3)
                .cornerRadius(4)
            }
            .chartAngleSelection(value: $selectedAngle)
            .chartLegend(.hidden)
            .chartBackground { _ in
                donutCenter(widthClass)
            }
            .animation(.spring(response: 0.3), value: selectedProduct?.id)
        }
        .accessibilityLabel("Revenue breakdown by product, \(scopedMetrics.productBreakdown.count) products")
    }

    @ViewBuilder
    private func donutCenter(_ widthClass: WidthClass) -> some View {
        let useCompactAmount = compactChartLayout || widthClass == .compact
        let titleSize: CGFloat = widthClass == .compact ? 10 : (compactChartLayout ? 11 : 12)
        let amountSize: CGFloat = widthClass == .compact ? 15 : (compactChartLayout ? 18 : 20)
        let centerWidth: CGFloat = widthClass == .compact ? 88 : (compactChartLayout ? 110 : 132)

        if let selected = selectedProduct {
            VStack(spacing: 2) {
                Text(selected.productName)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(useCompactAmount ? compactChartAmount(selected.revenue) : formatCents(selected.revenue))
                    .font(.system(size: amountSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("\(selected.orderCount) sales")
                    .font(widthClass == .compact ? .system(size: 10, weight: .medium) : .saneCallout)
                    .foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: centerWidth)
            .padding(.horizontal, widthClass == .compact ? 4 : 8)
            .transition(.opacity)
        } else {
            VStack(spacing: 2) {
                Text("Total")
                    .font(.system(size: titleSize, weight: .medium))
                    .foregroundStyle(Color.textMuted)
                Text(useCompactAmount ? compactChartAmount(totalRevenue) : formatCents(totalRevenue))
                    .font(.system(size: amountSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: centerWidth)
            .transition(.opacity)
        }
    }

    private var customLegend: some View {
        VStack(spacing: 0) {
            ForEach(Array(scopedMetrics.productBreakdown.enumerated()), id: \.element.id) { index, product in
                if index > 0 { GlassDivider() }
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedProduct?.id == product.id {
                            selectedProduct = nil
                        } else {
                            selectedProduct = product
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(chartColor(for: product))
                            .frame(width: 14, height: 14)

                        Text(product.productName)
                            .font(.saneSubheadline)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(formatCents(product.revenue))
                            .font(.saneSubheadlineBold)
                            .foregroundStyle(.primary)
                    }
                    .frame(minHeight: 40)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                    .opacity(selectedProduct == nil || selectedProduct?.id == product.id ? 1.0 : 0.4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private let chartColorPalette: [Color] = [
        .salesGreen, .blue, .salesGold, .teal, .mint, .cyan, .indigo,
    ]

    private func chartColor(for product: ProductSales) -> Color {
        guard let index = scopedMetrics.productBreakdown.firstIndex(where: { $0.id == product.id }) else {
            return .salesGreen
        }
        return chartColorPalette[index % chartColorPalette.count]
    }

    private var totalRevenue: Int {
        scopedMetrics.productBreakdown.reduce(0) { $0 + $1.revenue }
    }

    private var compactChartLayout: Bool {
        scopedMetrics.productBreakdown.count <= 2
    }

    private func productsBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        #if os(iOS)
            return max(16, safeAreaBottom + 18)
        #else
            return 12
        #endif
    }

    private func findProduct(at value: Int?) -> ProductSales? {
        guard let value else { return nil }
        var cumulative = 0
        for product in scopedMetrics.productBreakdown {
            cumulative += product.revenue
            if value <= cumulative {
                return product
            }
        }
        return nil
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = manager.primaryCurrency
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }

    private func compactChartAmount(_ cents: Int) -> String {
        let amount = Double(cents) / 100
        let absAmount = abs(amount)

        if absAmount < 1000 {
            return formatCents(cents)
        }

        let symbolFormatter = NumberFormatter()
        symbolFormatter.numberStyle = .currency
        symbolFormatter.currencyCode = manager.primaryCurrency
        let symbol = symbolFormatter.currencySymbol ?? "$"

        let divisor: Double
        let suffix: String
        if absAmount >= 1_000_000 {
            divisor = 1_000_000
            suffix = "M"
        } else {
            divisor = 1000
            suffix = "K"
        }

        let abbreviatedValue = amount / divisor
        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.minimumFractionDigits = 0
        decimalFormatter.maximumFractionDigits = abs(abbreviatedValue) < 100 ? 1 : 0

        let valueText = decimalFormatter.string(from: NSNumber(value: abbreviatedValue))
            ?? String(format: "%.1f", abbreviatedValue)
        return "\(symbol)\(valueText)\(suffix)"
    }

    private func emptyProductsState(widthClass: WidthClass) -> some View {
        VStack {
            Spacer(minLength: widthClass == .compact ? 28 : 40)

            VStack(spacing: 18) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.salesGold)

                VStack(spacing: 8) {
                    Text("No Products Yet")
                        .font(.system(size: widthClass == .compact ? 28 : 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Connect a provider to turn this into your catalog, today's product revenue view, and product-level sales feed.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)
                }

                VStack(alignment: .leading, spacing: 8) {
                    emptyStateDetailRow("See which products drive the most revenue")
                    emptyStateDetailRow("Track status, pricing, and sales count in one place")
                    emptyStateDetailRow("Connect live data to start a 7-day Pro trial")
                }
                .frame(maxWidth: 520, alignment: .leading)

                if manager.connectedProviders.isEmpty {
                    Text("Choose the store you already use. SaneSales will pull in your catalog first, then the revenue breakdown fills in.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)

                    emptyStateProviderActions(widthClass: widthClass)
                } else {
                    HStack(spacing: 10) {
                        Button("Refresh Now") {
                            Task { await manager.refresh() }
                        }
                        .buttonStyle(SaneActionButtonStyle(prominent: true))

                        Button("Open Provider Settings") {
                            queueSettingsRoute(for: manager.connectedProviders.first)
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }
            }
            .padding(.horizontal, widthClass == .compact ? 20 : 26)
            .padding(.vertical, widthClass == .compact ? 24 : 28)
            .frame(maxWidth: 660)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.salesPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.salesPanelStroke, lineWidth: 1)
                    )
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
    }

    private var noSalesCallout: some View {
        GlassSection("No Product Sales Today", icon: "sparkles", iconColor: .salesGold) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Demo mode lets you explore product reporting. Connect live data to start your 7-day trial, then unlock Pro to keep live product revenue tracking.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Upgrade to Pro when you want longer history, product trends, and deeper comparisons.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func emptyStateProviderActions(widthClass: WidthClass) -> some View {
        let columns = widthClass == .compact
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach([SalesProviderType.lemonSqueezy, .gumroad, .stripe], id: \.self) { provider in
                Button {
                    queueSettingsRoute(for: provider)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: provider.icon)
                            .foregroundStyle(provider.brandColor)
                        Text(provider.displayName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaneActionButtonStyle(prominent: provider == .lemonSqueezy))
            }
        }
        .frame(maxWidth: 620)
    }

    private func emptyStateDetailRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.salesGreen)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func queueSettingsRoute(for provider: SalesProviderType?) {
        if let provider {
            pendingSettingsRoute = "provider:\(provider.rawValue)"
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
        }
    }

    // MARK: - Product Catalog

    private var catalogSection: some View {
        GlassSection("Catalog", icon: "square.grid.2x2", iconColor: .blue) {
            VStack(spacing: 0) {
                ForEach(Array(sortedProducts.enumerated()), id: \.element.id) { index, product in
                    if index > 0 { GlassDivider() }
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let scopedSales = productSalesByName[product.name]

        return HStack(spacing: 12) {
            // Thumbnail
            if let thumbURL = product.thumbURL {
                AsyncImage(url: thumbURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(product.provider.brandColor.opacity(0.1))
                        .overlay(
                            Image(systemName: "shippingbox")
                                .foregroundStyle(product.provider.brandColor)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(product.provider.brandColor.opacity(0.1))
                    .overlay(
                        Image(systemName: product.provider.icon)
                            .font(.saneCallout)
                            .foregroundStyle(product.provider.brandColor)
                    )
                    .frame(width: 44, height: 44)
            }

            // Name + Status
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.saneSubheadlineBold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    SalesBadge(
                        product.statusFormatted ?? product.status.displayName,
                        color: product.status == .published || product.status == .active ? .salesSuccess : .salesWarning,
                        icon: product.status.icon
                    )
                    if manager.connectedProviders.count > 1 {
                        ProviderDot(provider: product.provider)
                    }
                }
                Text(product.displayPrice)
                    .font(.saneCallout)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            // Revenue + Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(scopedSales.map { formatCents($0.revenue) } ?? product.displayPrice)
                    .font(.subheadline.weight(.bold))
                Text(productRowDetailText(for: product, scopedSales: scopedSales))
                    .font(.saneCallout)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .opacity(manager.isPro || scopedSales != nil ? 1.0 : 0.78)
    }

    private func productRowDetailText(for product: Product, scopedSales: ProductSales?) -> String {
        if let scopedSales {
            return manager.isPro
                ? "\(scopedSales.orderCount) \(scopedSales.orderCount == 1 ? "sale" : "sales")"
                : "\(scopedSales.orderCount) \(scopedSales.orderCount == 1 ? "sale today" : "sales today")"
        }

        if manager.isPro, let totalSales = product.totalSales {
            return "\(totalSales) lifetime"
        }

        return manager.isPro ? "No sales yet" : "No sales today"
    }
}
