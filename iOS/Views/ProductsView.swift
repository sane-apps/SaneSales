import Charts
import SwiftUI

struct ProductsView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedAngle: Int?
    @State private var selectedProduct: ProductSales?

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                Group {
                    if manager.products.isEmpty, !manager.isLoading {
                        ContentUnavailableView("No Products", systemImage: "shippingbox",
                                               description: Text("Product data will appear after connecting a provider."))
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                if !manager.metrics.productBreakdown.isEmpty {
                                    revenueChart
                                }
                                catalogSection
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Products")
            .refreshable {
                await manager.refresh()
            }
        }
    }

    // MARK: - Revenue Chart

    private var revenueChart: some View {
        GlassSection("Revenue by Product", icon: "chart.pie", iconColor: .salesGold) {
            VStack(spacing: 16) {
                // Donut chart with center label
                ZStack {
                    Chart(manager.metrics.productBreakdown) { product in
                        SectorMark(
                            angle: .value("Revenue", product.revenue),
                            innerRadius: .ratio(0.58),
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
                        donutCenter
                    }
                    .animation(.spring(response: 0.3), value: selectedProduct?.id)
                }
                .frame(height: 220)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .accessibilityLabel("Revenue breakdown by product, \(manager.metrics.productBreakdown.count) products")

                // Custom legend
                customLegend
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .onChange(of: selectedAngle) { _, newValue in
            withAnimation(.spring(response: 0.3)) {
                selectedProduct = findProduct(at: newValue)
            }
        }
    }

    @ViewBuilder
    private var donutCenter: some View {
        if let selected = selectedProduct {
            VStack(spacing: 2) {
                Text(selected.productName)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(formatCents(selected.revenue))
                    .font(.title3.weight(.bold))
                Text("\(selected.orderCount) sales")
                    .font(.saneCallout)
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 8)
            .transition(.opacity)
        } else {
            VStack(spacing: 2) {
                Text("Total")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.textMuted)
                Text(formatCents(totalRevenue))
                    .font(.title3.weight(.bold))
            }
            .transition(.opacity)
        }
    }

    private var customLegend: some View {
        VStack(spacing: 0) {
            ForEach(Array(manager.metrics.productBreakdown.enumerated()), id: \.element.id) { index, product in
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
                    .frame(minHeight: 44)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                    .opacity(selectedProduct == nil || selectedProduct?.id == product.id ? 1.0 : 0.4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private let chartColorPalette: [Color] = [
        .salesGreen, .blue, .salesGold, .teal, .mint, .cyan, .indigo
    ]

    private func chartColor(for product: ProductSales) -> Color {
        guard let index = manager.metrics.productBreakdown.firstIndex(where: { $0.id == product.id }) else {
            return .salesGreen
        }
        return chartColorPalette[index % chartColorPalette.count]
    }

    private var totalRevenue: Int {
        manager.metrics.productBreakdown.reduce(0) { $0 + $1.revenue }
    }

    private func findProduct(at value: Int?) -> ProductSales? {
        guard let value else { return nil }
        var cumulative = 0
        for product in manager.metrics.productBreakdown {
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

    // MARK: - Product Catalog

    private var catalogSection: some View {
        GlassSection("Catalog", icon: "square.grid.2x2", iconColor: .blue) {
            VStack(spacing: 0) {
                ForEach(Array(manager.products.enumerated()), id: \.element.id) { index, product in
                    if index > 0 { GlassDivider() }
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 12) {
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
                        color: product.status == .published || product.status == .active ? .salesSuccess : .secondary,
                        icon: product.status.icon
                    )
                    if manager.connectedProviders.count > 1 {
                        ProviderDot(provider: product.provider)
                    }
                }
            }

            Spacer()

            // Price + Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
                if let sales = product.totalSales {
                    Text("\(sales) sales")
                        .font(.saneCallout)
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
