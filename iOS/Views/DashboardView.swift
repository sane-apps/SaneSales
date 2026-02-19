import SwiftUI

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case allTime = "All"
}

struct DashboardView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("selectedTimeRange") private var selectedRange: TimeRange = .today
    @State private var animateCards = false
    @Namespace private var pickerNamespace

    private enum DashboardLayout {
        static let sectionSpacing: CGFloat = 21
        static let cardSpacing: CGFloat = 13
        static let horizontalPadding: CGFloat = 21
        static let cardMinHeight: CGFloat = 168
        static let contentPadding: CGFloat = 13
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DashboardLayout.sectionSpacing) {
                        if let error = manager.error {
                            errorBanner(error)
                        }

                        // Brand header
                        dashboardBrandHeader

                        // Hero revenue
                        heroRevenue

                        // Time range picker
                        timeRangePicker

                        // Comparison row
                        comparisonRow

                        // Provider badges
                        connectedBadges

                        // Revenue cards grid
                        revenueCards

                        // Chart
                        chartSection

                        // Top products
                        topProductsSection
                    }
                    .padding(.horizontal, DashboardLayout.horizontalPadding)
                    .padding(.bottom, DashboardLayout.sectionSpacing)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if manager.isLoading {
                        ProgressView()
                            .tint(.salesGreen)
                    } else if let date = manager.lastUpdated {
                        Text(date, style: .relative)
                            .font(.saneCallout)
                            .foregroundStyle(Color.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(AnyShapeStyle(.ultraThinMaterial))
                            )
                    }
                }
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .refreshable {
                await manager.refresh()
            }
            .task {
                if manager.orders.isEmpty, manager.isConnected {
                    await manager.refresh()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateCards = true
                }
            }
        }
    }
}

private extension DashboardView {
    // MARK: - Hero Revenue

    private var dashboardBrandHeader: some View {
        HStack(spacing: DashboardLayout.cardSpacing) {
            Image("CoinColor")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SaneSales")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text("Revenue Dashboard")
                    .font(.saneCallout)
                    .foregroundStyle(Color.textMuted)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var heroRevenue: some View {
        VStack(spacing: 6) {
            Text(rangeLabel)
                .font(.saneSubheadline)
                .foregroundStyle(Color.textMuted)

            Text(formatCents(revenueForRange))
                .font(.saneCardValue(size: 48))
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(revenueForRange)))
                .animation(.spring(response: 0.4), value: revenueForRange)

            Text(pluralize(ordersForRange, "order"))
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.saneSubheadline)
                        .foregroundStyle(selectedRange == range ? .white : Color.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40)
                        .contentShape(Rectangle())
                        .background {
                            if selectedRange == range {
                                Capsule()
                                    .fill(Color.salesGreen)
                                    .matchedGeometryEffect(id: "picker", in: pickerNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(AnyShapeStyle(.ultraThinMaterial))
        )
    }

    // MARK: - Comparison Row

    private var comparisonRow: some View {
        HStack(spacing: DashboardLayout.cardSpacing) {
            comparisonPill(
                label: "vs prev",
                value: comparisonText,
                isPositive: comparisonDelta >= 0
            )

            if let avgDaily = averageDailyRevenue {
                comparisonPill(
                    label: "avg/day",
                    value: formatCents(avgDaily),
                    isPositive: true
                )
            }

            comparisonPill(
                label: "orders/day",
                value: String(format: "%.1f", averageDailyOrders),
                isPositive: true
            )
        }
    }

    private func comparisonPill(label: String, value: String, isPositive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.saneSubheadline)
                .fontWeight(.bold)
                .foregroundStyle(label == "vs prev"
                    ? (isPositive ? Color.salesSuccess : Color.salesError)
                    : .primary)
            Text(label)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.08 : 0.04))
                )
        )
    }

    // MARK: - Connected Badges

    private var connectedBadges: some View {
        Group {
            if manager.connectedProviders.count > 1 {
                HStack(spacing: 8) {
                    ForEach(manager.connectedProviders, id: \.self) { provider in
                        ProviderBadge(provider: provider)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Revenue Cards

    private var revenueCards: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: DashboardLayout.cardSpacing) {
            SalesCard(
                title: "Today",
                value: formatCents(manager.metrics.todayRevenue),
                subtitle: pluralize(manager.metrics.todayOrders, "order"),
                icon: "clock.fill",
                iconColor: .metricToday,
                trend: todayTrend
            )
            .frame(minHeight: DashboardLayout.cardMinHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.0), value: animateCards)

            SalesCard(
                title: "This Month",
                value: formatCents(manager.metrics.monthRevenue),
                subtitle: pluralize(manager.metrics.monthOrders, "order"),
                icon: "calendar",
                iconColor: .metricMonth
            )
            .frame(minHeight: DashboardLayout.cardMinHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateCards)

            SalesCard(
                title: "All Time",
                value: formatCents(manager.metrics.allTimeRevenue),
                subtitle: pluralize(manager.metrics.allTimeOrders, "order"),
                iconAssetName: "CoinTemplate",
                iconColor: .metricAllTime
            )
            .frame(minHeight: DashboardLayout.cardMinHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.10), value: animateCards)

            storeCard
                .frame(minHeight: DashboardLayout.cardMinHeight)
                .offset(y: animateCards ? 0 : 20)
                .opacity(animateCards ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animateCards)
        }
    }

    private var storeCard: some View {
        Group {
            let providerCount = manager.connectedProviders.count
            let subtitle = providerCount == 0 ? "Not connected" : "\(providerCount) connected providers"
            SalesCard(
                title: "30-Day",
                value: formatCents(manager.metrics.thirtyDayRevenue),
                subtitle: subtitle,
                icon: "calendar.badge.clock",
                iconColor: .metricRolling30
            )
        }
    }

    private var todayTrend: Trend? {
        let daily = manager.metrics.dailyBreakdown
        guard daily.count >= 2 else { return nil }
        let today = daily.first(where: { Calendar.current.isDateInToday($0.date) })?.revenue ?? 0
        let yesterday = daily.first(where: { Calendar.current.isDateInYesterday($0.date) })?.revenue ?? 0
        guard yesterday > 0 else { return nil }
        let pct = Double(today - yesterday) / Double(yesterday) * 100
        return Trend(label: String(format: "%.0f%%", abs(pct)), isPositive: pct >= 0)
    }
}

private extension DashboardView {
    // MARK: - Chart

    private var chartSection: some View {
        GlassSection("Revenue Trend", icon: "chart.xyaxis.line", iconColor: .metricToday) {
            if manager.metrics.dailyBreakdown.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.line.uptrend.xyaxis",
                                       description: Text("Sales data will appear here after your first order."))
                    .frame(height: 200)
            } else {
                ChartsView(dailySales: chartData, currency: manager.primaryCurrency)
                    .padding(.top, 8)
                    .frame(height: 220)
                    .clipped()
                    .padding(DashboardLayout.contentPadding)
            }
        }
    }

    private var chartData: [DailySales] {
        let days: Int = switch selectedRange {
        case .today: 7
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: manager.metrics.dailyBreakdown.count
        }
        return Array(manager.metrics.dailyBreakdown.prefix(days).reversed())
    }

    // MARK: - Top Products

    private var topProductsSection: some View {
        GlassSection("Top Products", icon: "star.fill", iconColor: .salesWarning) {
            if manager.metrics.productBreakdown.isEmpty {
                Text("No products yet")
                    .foregroundStyle(Color.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(manager.metrics.productBreakdown.prefix(5).enumerated()), id: \.element.id) { index, product in
                        if index > 0 { GlassDivider() }
                        HStack(spacing: 12) {
                            // Product thumbnail or rank fallback
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

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: .salesGreen
        case 1: .blue
        case 2: .salesGold
        default: .secondary
        }
    }

    @ViewBuilder
    private func productThumbnail(for productName: String, rank: Int) -> some View {
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

    private func rankCircle(_ index: Int) -> some View {
        Text("\(index + 1)")
            .font(.saneFootnote)
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(rankColor(index))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Error Banner

    private func errorBanner(_ error: SalesAPIError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.salesWarning)
            Text(error.localizedDescription)
                .font(.saneCallout)
            Spacer()
            Button("Retry") {
                Task { await manager.refresh() }
            }
            .buttonStyle(.bordered)
            .tint(.salesGreen)
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.salesWarning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.salesWarning.opacity(0.2), lineWidth: 0.5)
        )
    }
}

private extension DashboardView {
    // MARK: - Computed Data

    private var revenueForRange: Int {
        switch selectedRange {
        case .today: manager.metrics.todayRevenue
        case .sevenDays: revenueForDays(7)
        case .thirtyDays: revenueForDays(30)
        case .allTime: manager.metrics.allTimeRevenue
        }
    }

    private var ordersForRange: Int {
        switch selectedRange {
        case .today: manager.metrics.todayOrders
        case .sevenDays: ordersForDays(7)
        case .thirtyDays: ordersForDays(30)
        case .allTime: manager.metrics.allTimeOrders
        }
    }

    private var rangeLabel: String {
        switch selectedRange {
        case .today: "Today's Revenue"
        case .sevenDays: "Last 7 Days"
        case .thirtyDays: "Last 30 Days"
        case .allTime: "All Time Revenue"
        }
    }

    private var comparisonDelta: Int {
        let current = revenueForRange
        let previous = previousPeriodRevenue
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return Int(Double(current - previous) / Double(previous) * 100)
    }

    private var comparisonText: String {
        let delta = comparisonDelta
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(delta)%"
    }

    private var previousPeriodRevenue: Int {
        let daily = manager.metrics.dailyBreakdown
        let cal = Calendar.current
        switch selectedRange {
        case .today:
            return daily.first(where: { cal.isDateInYesterday($0.date) })?.revenue ?? 0
        case .sevenDays:
            return revenueInRange(daysAgo: 14, daysUntil: 7)
        case .thirtyDays:
            return revenueInRange(daysAgo: 60, daysUntil: 30)
        case .allTime:
            return 0
        }
    }

    private var averageDailyRevenue: Int? {
        guard selectedRange != .today else { return nil }
        let days: Int = switch selectedRange {
        case .today: 1
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: max(1, manager.metrics.dailyBreakdown.count)
        }
        return revenueForRange / max(1, days)
    }

    private var averageDailyOrders: Double {
        let days: Double = switch selectedRange {
        case .today: 1
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: max(1, Double(manager.metrics.dailyBreakdown.count))
        }
        return Double(ordersForRange) / days
    }

    private func revenueForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return manager.orders
            .filter { $0.status == .paid && $0.createdAt >= cutoff }
            .reduce(0) { $0 + $1.total }
    }

    private func ordersForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return manager.orders.filter { $0.status == .paid && $0.createdAt >= cutoff }.count
    }

    private func revenueInRange(daysAgo: Int, daysUntil: Int) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        let end = cal.date(byAdding: .day, value: -daysUntil, to: Date())!
        return manager.orders
            .filter { $0.status == .paid && $0.createdAt >= start && $0.createdAt < end }
            .reduce(0) { $0 + $1.total }
    }

    // MARK: - Helpers

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = manager.primaryCurrency
        if let formatted = formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) {
            return formatted
        }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }

    private func pluralize(_ count: Int, _ word: String) -> String {
        "\(count) \(word)\(count == 1 ? "" : "s")"
    }
}
