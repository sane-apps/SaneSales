// swiftlint:disable file_length
import SwiftUI
import SaneUI

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case allTime = "All"
}

enum SaneSalesFreeTierPolicy {
    static let unlockedDashboardRanges: [TimeRange] = [.today, .sevenDays, .thirtyDays]
    static let recentOrderPreviewLimit = 20

    static func locksDashboardRange(_ range: TimeRange, isPro: Bool) -> Bool {
        !isPro && !unlockedDashboardRanges.contains(range)
    }

    static func preferredDashboardRange(
        currentRange: TimeRange,
        isPro: Bool,
        todayOrders: Int,
        thirtyDayOrders: Int
    ) -> TimeRange {
        if locksDashboardRange(currentRange, isPro: isPro) {
            return .sevenDays
        }

        if !isPro, currentRange == .today, todayOrders == 0, thirtyDayOrders > 0 {
            return .sevenDays
        }

        return currentRange
    }
}

struct DashboardComparisonItem: Identifiable {
    let label: String
    let value: String
    let isPositive: Bool

    var id: String { label }
}

struct DashboardView: View {
    @Environment(SalesManager.self) var manager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedTimeRange") var selectedRange: TimeRange = .today
    @AppStorage("pendingSettingsRoute") var pendingSettingsRoute = ""
    @State var selectedProviderFilter: SalesProviderType?
    @State var quickConnectProvider: SalesProviderType?
    @State var animateCards = false
    @State var didLogChartGateView = false
    @Namespace var pickerNamespace
    #if os(macOS)
        @State var proUpsellFeature: ProFeature?
        @Environment(LicenseService.self) var licenseService
    #endif

    enum DashboardLayout {
        #if os(macOS)
            static let sectionSpacing: CGFloat = 16
            static let cardSpacing: CGFloat = 10
            static let horizontalPadding: CGFloat = 16
            static let cardHeight: CGFloat = 152
            static let contentPadding: CGFloat = 10
        #else
            static let sectionSpacing: CGFloat = 14
            static let cardSpacing: CGFloat = 8
            static let horizontalPadding: CGFloat = 16
            static let cardHeight: CGFloat = 168
            static let contentPadding: CGFloat = 8
        #endif
    }

    enum WidthClass {
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

        var heroValueSize: CGFloat {
            switch self {
            case .compact: 20
            case .regular: 28
            case .wide: 32
            }
        }

        var cardHeight: CGFloat {
            switch self {
            case .compact: 96
            case .regular: 124
            case .wide: 128
            }
        }

        var metricColumns: [GridItem] {
            switch self {
            case .compact, .regular:
                [.init(.flexible()), .init(.flexible())]
            case .wide:
                [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())]
            }
        }

        func comparisonColumns(for itemCount: Int) -> [GridItem] {
            switch self {
            case .compact:
                if itemCount <= 2 {
                    return [.init(.flexible()), .init(.flexible())]
                }
                return [.init(.flexible()), .init(.flexible()), .init(.flexible())]
            case .regular, .wide:
                return [.init(.flexible()), .init(.flexible()), .init(.flexible())]
            }
        }

        var supportsSecondaryColumns: Bool { self == .wide }

        var overviewPadding: CGFloat {
            switch self {
            case .compact: 7
            case .regular, .wide: 14
            }
        }

        var brandIconSize: CGFloat {
            switch self {
            case .compact: 28
            case .regular: 38
            case .wide: 40
            }
        }

        var brandTitleSize: CGFloat {
            switch self {
            case .compact: 17
            case .regular: 21
            case .wide: 22
            }
        }

    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                GeometryReader { proxy in
                    let widthClass = WidthClass(width: proxy.size.width)

                    ScrollView {
                        VStack(spacing: DashboardLayout.sectionSpacing) {
                            if let error = manager.error {
                                errorBanner(error)
                            }

                            overviewSection(widthClass)

                            revenueCards(widthClass)

                            secondarySection(widthClass)
                        }
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                        .padding(.bottom, dashboardBottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                        .frame(minHeight: proxy.size.height, alignment: .top)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if manager.isLoading {
                        ProgressView()
                            .tint(.salesGreen)
                    } else {
                        Button {
                            Task { await manager.refresh() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text(refreshButtonLabel)
                            }
                            .font(.saneCallout)
                            .foregroundStyle(Color.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(AnyShapeStyle(.ultraThinMaterial))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!manager.isConnected)
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
                enforceFreeTierRange()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateCards = true
                }
            }
            .onChange(of: manager.isPro) { _, _ in
                enforceFreeTierRange()
            }
            .onChange(of: manager.orders.count) { _, _ in
                enforceFreeTierRange()
            }
            #if os(macOS)
            .sheet(item: $proUpsellFeature) { feature in
                ProUpsellView(feature: feature, licenseService: licenseService)
            }
            #endif
            .sheet(item: $quickConnectProvider) { provider in
                ProviderConnectionSheet(provider: provider)
            }
        }
    }
}

extension DashboardView {
    // MARK: - Overview

    private func overviewSection(_ widthClass: WidthClass) -> some View {
        VStack(spacing: widthClass == .compact ? 10 : 12) {
            if widthClass == .wide {
                HStack(alignment: .top, spacing: DashboardLayout.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 12) {
                        dashboardBrandHeader(widthClass)
                        heroRevenue(widthClass, alignment: .leading)
                        if shouldShowRecentSnapshotNote {
                            dashboardContextNote
                        }
                    }

                    comparisonGrid(widthClass)
                        .frame(maxWidth: 360)
                }

                HStack(alignment: .center, spacing: DashboardLayout.cardSpacing) {
                    timeRangePicker
                        .frame(maxWidth: 360, alignment: .leading)
                    connectedBadges(alignment: .trailing)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    dashboardBrandHeader(widthClass)
                    heroRevenue(widthClass, alignment: .leading)

                    if shouldShowRecentSnapshotNote {
                        dashboardContextNote
                    }

                    timeRangePicker
                    comparisonGrid(widthClass)
                    connectedBadges(alignment: .leading)
                }
            }
        }
        .padding(widthClass.overviewPadding)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.08 : 0.04))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.16 : 0.10), lineWidth: 1)
        )
    }

    private func dashboardBrandHeader(_ widthClass: WidthClass) -> some View {
        HStack(spacing: DashboardLayout.cardSpacing) {
            let isCompact = widthClass == .compact
            Image("CoinColor")
                .resizable()
                .scaledToFit()
                .frame(width: widthClass.brandIconSize, height: widthClass.brandIconSize)
                .clipShape(RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("SaneSales")
                    .font(.system(size: widthClass.brandTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Live sales at a glance")
                    .font(isCompact ? .system(size: 11, weight: .medium) : .saneCallout)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroRevenue(_ widthClass: WidthClass, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(rangeLabel)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)

            Text(formatCents(revenueForRange))
                .font(.saneCardValue(size: widthClass.heroValueSize))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(revenueForRange)))
                .animation(.spring(response: 0.4), value: revenueForRange)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(pluralize(ordersForRange, "order"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    handleRangeSelection(range)
                } label: {
                    HStack(spacing: 4) {
                        Text(range.rawValue)
                        if isLockedRange(range) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .font(.saneCallout)
                    .foregroundStyle(selectedRange == range ? .white : Color.textMuted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 30)
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
                .modifier(DashboardRangeAccessibilityModifier(range: range))
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(AnyShapeStyle(.ultraThinMaterial))
        )
    }

    var comparisonItems: [DashboardComparisonItem] {
        var items = [
            DashboardComparisonItem(label: "vs prev", value: comparisonText, isPositive: comparisonDelta >= 0)
        ]

        if let avgDaily = averageDailyRevenue {
            items.append(DashboardComparisonItem(label: "avg/day", value: formatCents(avgDaily), isPositive: true))
        }

        items.append(DashboardComparisonItem(label: "orders/day", value: String(format: "%.1f", averageDailyOrders), isPositive: true))
        return items
    }

    private func comparisonGrid(_ widthClass: WidthClass) -> some View {
        LazyVGrid(columns: widthClass.comparisonColumns(for: comparisonItems.count), spacing: DashboardLayout.cardSpacing) {
            ForEach(comparisonItems) { item in
                comparisonPill(label: item.label, value: item.value, isPositive: item.isPositive, widthClass: widthClass)
            }
        }
    }

    private func comparisonPill(label: String, value: String, isPositive: Bool, widthClass: WidthClass) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: widthClass == .compact ? 15 : 16, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(label == "vs prev"
                    ? (isPositive ? Color.salesSuccess : Color.salesError)
                    : .primary)
            Text(label)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: widthClass == .compact ? 40 : 50)
        .padding(.vertical, widthClass == .compact ? 4 : 8)
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

    private func connectedBadges(alignment: Alignment) -> some View {
        HStack(spacing: 6) {
            ForEach(SalesProviderType.allCases, id: \.self) { provider in
                let isConnected = isProviderConnected(provider)
                let isSelected = selectedProviderFilter == nil || selectedProviderFilter == provider

                providerBadgeButton(provider: provider, isConnected: isConnected, isSelected: isSelected)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    // MARK: - Revenue Cards

    @ViewBuilder
    private func revenueCards(_ widthClass: WidthClass) -> some View {
        if !manager.isPro {
            freeTierRevenueCards(widthClass)
        } else {
            proRevenueCards(widthClass)
        }
    }

    private func proRevenueCards(_ widthClass: WidthClass) -> some View {
        LazyVGrid(columns: widthClass.metricColumns, spacing: DashboardLayout.cardSpacing) {
            SalesCard(
                title: "Today",
                value: formatCents(dashboardMetrics.todayRevenue),
                subtitle: pluralize(dashboardMetrics.todayOrders, "order"),
                icon: "clock.fill",
                iconColor: .metricToday,
                trend: todayTrend
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.0), value: animateCards)

            SalesCard(
                title: "This Month",
                value: formatCents(dashboardMetrics.monthRevenue),
                subtitle: pluralize(dashboardMetrics.monthOrders, "order"),
                icon: "calendar",
                iconColor: .metricMonth
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateCards)

            SalesCard(
                title: "All Time",
                value: formatCents(dashboardMetrics.allTimeRevenue),
                subtitle: pluralize(dashboardMetrics.allTimeOrders, "order"),
                iconAssetName: "CoinTemplate",
                iconColor: .metricAllTime
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.10), value: animateCards)

            storeCard
                .frame(height: widthClass.cardHeight)
                .offset(y: animateCards ? 0 : 20)
                .opacity(animateCards ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animateCards)
        }
    }

    private func freeTierRevenueCards(_ widthClass: WidthClass) -> some View {
        LazyVGrid(columns: widthClass.metricColumns, spacing: DashboardLayout.cardSpacing) {
            SalesCard(
                title: "Today",
                value: formatCents(dashboardMetrics.todayRevenue),
                subtitle: pluralize(dashboardMetrics.todayOrders, "order"),
                icon: "clock.fill",
                iconColor: .metricToday,
                trend: todayTrend
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.0), value: animateCards)

            SalesCard(
                title: "7 Days",
                value: formatCents(revenueForDays(7)),
                subtitle: pluralize(ordersForDays(7), "order"),
                icon: "calendar",
                iconColor: .metricMonth
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateCards)

            SalesCard(
                title: "30 Days",
                value: formatCents(dashboardMetrics.thirtyDayRevenue),
                subtitle: pluralize(dashboardMetrics.thirtyDayOrders, "order"),
                icon: "calendar.badge.clock",
                iconColor: .metricRolling30
            )
            .frame(height: widthClass.cardHeight)
            .offset(y: animateCards ? 0 : 20)
            .opacity(animateCards ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.10), value: animateCards)

            lockedRevenueCard(
                title: "All Time",
                subtitle: "Unlock your full revenue history",
                iconAssetName: "CoinTemplate",
                iconColor: .metricAllTime,
                delay: 0.15,
                height: widthClass.cardHeight
            )
        }
    }

    var storeCard: some View {
        Group {
            SalesCard(
                title: "30-Day",
                value: formatCents(dashboardMetrics.thirtyDayRevenue),
                subtitle: pluralize(dashboardMetrics.thirtyDayOrders, "order"),
                icon: "calendar.badge.clock",
                iconColor: .metricRolling30
            )
        }
    }

    var todayTrend: Trend? {
        let daily = dashboardMetrics.dailyBreakdown
        guard daily.count >= 2 else { return nil }
        let today = daily.first(where: { Calendar.current.isDateInToday($0.date) })?.revenue ?? 0
        let yesterday = daily.first(where: { Calendar.current.isDateInYesterday($0.date) })?.revenue ?? 0
        guard yesterday > 0 else { return nil }
        let pct = Double(today - yesterday) / Double(yesterday) * 100
        return Trend(label: String(format: "%.0f%%", abs(pct)), isPositive: pct >= 0)
    }
}

extension DashboardView {
    // MARK: - Error Banner

    func errorBanner(_ error: SalesAPIError) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.salesWarning)
                Text(error.localizedDescription)
                    .font(.saneCallout)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 10) {
                Button("Retry") {
                    Task { await manager.refresh() }
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))

                if let provider = primaryConnectedProvider {
                    Button("Fix \(provider.displayName)") {
                        queueSettingsRoute(for: provider)
                    }
                    .buttonStyle(SaneActionButtonStyle())
                }
            }
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

extension DashboardView {
    // MARK: - Computed Data

    var dashboardOrders: [Order] {
        guard let selectedProviderFilter else { return manager.orders }
        return manager.orders.filter { $0.provider == selectedProviderFilter }
    }

    var dashboardMetrics: SalesMetrics {
        SalesMetrics.compute(from: dashboardOrders)
    }

    var revenueForRange: Int {
        switch selectedRange {
        case .today: dashboardMetrics.todayRevenue
        case .sevenDays: revenueForDays(7)
        case .thirtyDays: revenueForDays(30)
        case .allTime: dashboardMetrics.allTimeRevenue
        }
    }

    var ordersForRange: Int {
        switch selectedRange {
        case .today: dashboardMetrics.todayOrders
        case .sevenDays: ordersForDays(7)
        case .thirtyDays: ordersForDays(30)
        case .allTime: dashboardMetrics.allTimeOrders
        }
    }

    var rangeLabel: String {
        switch selectedRange {
        case .today: "Today's Revenue"
        case .sevenDays: "Last 7 Days"
        case .thirtyDays: "Last 30 Days"
        case .allTime: "All Time Revenue"
        }
    }

    var comparisonDelta: Int {
        let current = revenueForRange
        let previous = previousPeriodRevenue
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return Int(Double(current - previous) / Double(previous) * 100)
    }

    var comparisonText: String {
        let delta = comparisonDelta
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(delta)%"
    }

    var previousPeriodRevenue: Int {
        let daily = dashboardMetrics.dailyBreakdown
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

    var averageDailyRevenue: Int? {
        guard selectedRange != .today else { return nil }
        let days: Int = switch selectedRange {
        case .today: 1
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: max(1, dashboardMetrics.dailyBreakdown.count)
        }
        return revenueForRange / max(1, days)
    }

    var averageDailyOrders: Double {
        let days: Double = switch selectedRange {
        case .today: 1
        case .sevenDays: 7
        case .thirtyDays: 30
        case .allTime: max(1, Double(dashboardMetrics.dailyBreakdown.count))
        }
        return Double(ordersForRange) / days
    }

    func revenueForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return dashboardOrders
            .filter { $0.status == .paid && $0.createdAt >= cutoff }
            .reduce(0) { $0 + $1.total }
    }

    func ordersForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return dashboardOrders.filter { $0.status == .paid && $0.createdAt >= cutoff }.count
    }

    func revenueInRange(daysAgo: Int, daysUntil: Int) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        let end = cal.date(byAdding: .day, value: -daysUntil, to: Date())!
        return dashboardOrders
            .filter { $0.status == .paid && $0.createdAt >= start && $0.createdAt < end }
            .reduce(0) { $0 + $1.total }
    }

    func isProviderConnected(_ provider: SalesProviderType) -> Bool {
        switch provider {
        case .lemonSqueezy: manager.isLemonSqueezyConnected
        case .gumroad: manager.isGumroadConnected
        case .stripe: manager.isStripeConnected
        }
    }

    // MARK: - Helpers

    func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = manager.primaryCurrency
        if let formatted = formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) {
            return formatted
        }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }

    func pluralize(_ count: Int, _ word: String) -> String {
        "\(count) \(word)\(count == 1 ? "" : "s")"
    }

    func handleRangeSelection(_ range: TimeRange) {
        if SaneSalesFreeTierPolicy.locksDashboardRange(range, isPro: manager.isPro) {
            showLockedFeature(event: "trend_range_locked_tap")
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRange = range
        }
    }

    func enforceFreeTierRange() {
        selectedRange = SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: selectedRange,
            isPro: manager.isPro,
            todayOrders: dashboardMetrics.todayOrders,
            thirtyDayOrders: dashboardMetrics.thirtyDayOrders
        )
    }

    func isLockedRange(_ range: TimeRange) -> Bool {
        SaneSalesFreeTierPolicy.locksDashboardRange(range, isPro: manager.isPro)
    }

    @ViewBuilder
    var dashboardContextNote: some View {
        if shouldShowRecentSnapshotNote {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.teal)
                Text("No sales yet today. Your recent sales snapshot is still loaded below.")
                    .font(.saneCallout)
                    .foregroundStyle(.white.opacity(0.96))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AnyShapeStyle(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.teal.opacity(0.24), lineWidth: 1)
                    )
            )
        }
    }

    var shouldShowRecentSnapshotNote: Bool {
        !manager.isPro
            && selectedRange == .sevenDays
            && dashboardMetrics.todayOrders == 0
            && dashboardMetrics.thirtyDayOrders > 0
    }

    func showLockedFeature(event: String) {
        Task.detached {
            await EventTracker.log(event, app: "sanesales")
        }
        #if os(macOS)
            proUpsellFeature = .charts
        #else
            queueLicenseSettingsRoute()
        #endif
    }

    func lockedRevenueCard(
        title: String,
        subtitle: String,
        icon: String? = nil,
        iconAssetName: String? = nil,
        iconColor: Color,
        delay: Double,
        height: CGFloat
    ) -> some View {
        Button {
            showLockedFeature(event: "revenue_card_locked_tap")
        } label: {
            Group {
                if let icon {
                    SalesCard(
                        title: title,
                        value: "Unlock",
                        subtitle: subtitle,
                        icon: icon,
                        iconColor: iconColor
                    )
                } else if let iconAssetName {
                    SalesCard(
                        title: title,
                        value: "Unlock",
                        subtitle: subtitle,
                        iconAssetName: iconAssetName,
                        iconColor: iconColor
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.teal)
                    .padding(10)
            }
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: animateCards)
    }

    var primaryConnectedProvider: SalesProviderType? {
        manager.connectedProviders.first
    }

    func queueLicenseSettingsRoute() {
        pendingSettingsRoute = "license"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
        }
    }

    func queueSettingsRoute(for provider: SalesProviderType) {
        if manager.needsProForAdditionalProvider, !isProviderConnected(provider) {
            queueLicenseSettingsRoute()
            return
        }

        pendingSettingsRoute = "provider:\(provider.rawValue)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(name: .showSettingsProviderSetup, object: provider.rawValue)
            }
        }
    }

    @ViewBuilder
    func providerBadgeButton(
        provider: SalesProviderType,
        isConnected: Bool,
        isSelected: Bool
    ) -> some View {
        let button = Button {
            if isConnected {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    selectedProviderFilter = selectedProviderFilter == provider ? nil : provider
                }
            } else {
                if manager.needsProForAdditionalProvider {
                    queueSettingsRoute(for: provider)
                } else {
                    quickConnectProvider = provider
                }
            }
        } label: {
            providerBadgeLabel(provider: provider, isConnected: isConnected, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            isConnected
                ? "Filters dashboard by \(provider.displayName)"
                : (manager.needsProForAdditionalProvider
                    ? "Opens Pro unlock for additional providers"
                    : "Opens setup for \(provider.displayName)")
        )

        switch provider {
        case .lemonSqueezy:
            button.accessibilityIdentifier("dashboard.provider.lemonSqueezy")
        case .gumroad:
            button.accessibilityIdentifier("dashboard.provider.gumroad")
        case .stripe:
            button.accessibilityIdentifier("dashboard.provider.stripe")
        }
    }

    @ViewBuilder
    private func providerBadgeLabel(
        provider: SalesProviderType,
        isConnected: Bool,
        isSelected: Bool
    ) -> some View {
        if isConnected {
            ProviderBadge(
                provider: provider,
                fillsAvailableWidth: true,
                allowsWrappedTitle: false
            )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? provider.brandColor.opacity(0.7) : .clear,
                            lineWidth: isSelected ? 1.2 : 0
                        )
                )
        } else {
            HStack(spacing: 5) {
                Image(systemName: provider.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(provider.brandColor)
                    .accessibilityHidden(true)
                Text(provider.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.62)
                Image(systemName: manager.needsProForAdditionalProvider ? "lock.fill" : "plus.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        manager.needsProForAdditionalProvider
                            ? SaneSettingsIconSemantic.license.color
                            : Color.salesGreen
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 36)
            .background(
                Capsule()
                    .fill(provider.brandColor.opacity(colorScheme == .dark ? 0.14 : 0.10))
            )
            .overlay(
                Capsule()
                    .stroke(provider.brandColor.opacity(0.75), lineWidth: 1)
            )
        }
    }

    private var refreshButtonLabel: String {
        guard let lastUpdated = manager.lastUpdated else { return "Refresh" }

        let elapsed = max(0, Int(Date().timeIntervalSince(lastUpdated)))
        switch elapsed {
        case ..<5:
            return "Now"
        case ..<60:
            return "\(elapsed)s"
        case ..<3600:
            return "\(elapsed / 60)m"
        case ..<86_400:
            return "\(elapsed / 3600)h"
        default:
            return "\(elapsed / 86_400)d"
        }
    }

    private func dashboardBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        #if os(iOS)
            return max(DashboardLayout.sectionSpacing + 8, safeAreaBottom + 78)
        #else
            return DashboardLayout.sectionSpacing
        #endif
    }
}
