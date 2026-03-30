import SaneUI
import SwiftUI

extension DashboardView {
    @ViewBuilder
    func secondarySection(_ widthClass: WidthClass) -> some View {
        if widthClass.supportsSecondaryColumns {
            HStack(alignment: .top, spacing: DashboardLayout.sectionSpacing) {
                chartSection(widthClass)
                    .frame(maxWidth: .infinity, alignment: .top)

                topProductsSection
                    .frame(width: 340, alignment: .top)
            }
        } else {
            chartSection(widthClass)
            topProductsSection
        }
    }

    @ViewBuilder
    func chartSection(_ widthClass: WidthClass) -> some View {
        if !manager.isPro {
            GlassSection("Revenue Trend", icon: "chart.xyaxis.line", iconColor: .metricToday) {
                ZStack {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach([0.4, 0.6, 0.3, 0.8, 0.5, 0.9, 0.7], id: \.self) { height in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.salesGreen.opacity(0.3))
                                .frame(maxWidth: .infinity, minHeight: 20)
                                .frame(height: 146 * height)
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(height: widthClass == .compact ? 144 : 172)
                    .blur(radius: 8)

                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28))
                            .foregroundStyle(.teal)
                        Text("Revenue Charts")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Unlock interactive charts, all-time trends, and deeper comparisons.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                        Button {
                            showLockedFeature(event: "chart_locked_tap")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text("Unlock Pro")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .buttonStyle(SaneActionButtonStyle(prominent: true))
                    }
                    .padding()
                }
                .frame(height: widthClass == .compact ? 144 : 172)
                .onAppear {
                    guard manager.isConnected, !didLogChartGateView else { return }
                    didLogChartGateView = true
                    Task.detached {
                        await EventTracker.log("chart_locked_viewed", app: "sanesales")
                    }
                }
            }
        } else {
            liveChartSection(widthClass)
        }
    }

    var chartData: [DailySales] {
        let days: Int = switch selectedRange {
        case .today: 7
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: dashboardMetrics.dailyBreakdown.count
        }

        return Array(dashboardMetrics.dailyBreakdown.prefix(days).reversed())
    }

    var topProductsSection: some View {
        GlassSection("Top Products", icon: "star.fill", iconColor: .salesWarning) {
            if dashboardMetrics.productBreakdown.isEmpty {
                Text("No products yet")
                    .foregroundStyle(Color.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dashboardMetrics.productBreakdown.prefix(5).enumerated()), id: \.element.id) { index, product in
                        if index > 0 { GlassDivider() }

                        HStack(spacing: 12) {
                            productThumbnail(for: product.productName, rank: index)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.productName)
                                    .font(.saneSubheadline)
                                    .lineLimit(1)
                                Text(pluralize(product.orderCount, "sale"))
                                    .font(.saneCallout)
                                    .foregroundStyle(Color.textMuted)
                            }

                            Spacer()

                            Text(formatCents(product.revenue))
                                .font(.saneSubheadlineBold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: .salesGreen
        case 1: .blue
        case 2: .salesGold
        default: Color.white.opacity(0.18)
        }
    }

    @ViewBuilder
    func productThumbnail(for productName: String, rank: Int) -> some View {
        let matchedProduct = manager.products.first { $0.name == productName }

        if let thumbURL = matchedProduct?.thumbURL {
            AsyncImage(url: thumbURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                rankCircle(rank)
            }
            .frame(width: 34, height: 34)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            rankCircle(rank)
        }
    }

    func rankCircle(_ index: Int) -> some View {
        Text("\(index + 1)")
            .font(.saneFootnote)
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(rankColor(index))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func liveChartSection(_ widthClass: WidthClass) -> some View {
        GlassSection("Revenue Trend", icon: "chart.xyaxis.line", iconColor: .metricToday) {
            if dashboardMetrics.dailyBreakdown.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Sales data will appear here after your first order.")
                )
                .frame(height: 200)
            } else {
                ChartsView(dailySales: chartData, currency: manager.primaryCurrency)
                    .padding(.top, widthClass == .compact ? 4 : 8)
                    .frame(height: widthClass == .compact ? 144 : 208)
                    .clipped()
                    .padding(widthClass == .compact ? 8 : DashboardLayout.contentPadding)
            }
        }
    }
}
