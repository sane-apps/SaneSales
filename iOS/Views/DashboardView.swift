// swiftlint:disable file_length
import SwiftUI
import SaneUI

import Foundation

enum SaneSalesDateRangeStore {
    static let selectedRangeKey = "selectedTimeRange"
    static let customStartKey = "customDateRangeStart"
    static let customEndKey = "customDateRangeEnd"

    static var defaultCustomStartTimestamp: Double {
        defaultCustomInterval().start.timeIntervalSince1970
    }

    static var defaultCustomEndTimestamp: Double {
        defaultCustomInterval().end.timeIntervalSince1970
    }

    static func defaultCustomInterval(now: Date = Date(), calendar: Calendar = .current) -> DateInterval {
        let end = calendar.endOfDay(for: now)
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        return DateInterval(start: start, end: end)
    }

    static func normalizedInterval(
        start: Date,
        end: Date,
        maximumDate: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval {
        let lowerBound = min(start, end)
        let upperBound = min(max(start, end), maximumDate)
        let startOfRange = min(calendar.startOfDay(for: lowerBound), calendar.startOfDay(for: maximumDate))
        let endOfRange = max(startOfRange, calendar.endOfDay(for: upperBound))
        return DateInterval(start: startOfRange, end: endOfRange)
    }

    static func interval(
        for range: TimeRange,
        customStart: Date,
        customEnd: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval? {
        let end = calendar.endOfDay(for: now)
        let startOfToday = calendar.startOfDay(for: now)

        switch range {
        case .today:
            return DateInterval(start: startOfToday, end: end)
        case .sevenDays:
            let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
            return DateInterval(start: start, end: end)
        case .thirtyDays:
            let start = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
            return DateInterval(start: start, end: end)
        case .allTime:
            return nil
        case .custom:
            return normalizedInterval(start: customStart, end: customEnd, maximumDate: now, calendar: calendar)
        }
    }

    static func previousInterval(
        for range: TimeRange,
        customStart: Date,
        customEnd: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval? {
        guard let currentInterval = interval(
            for: range,
            customStart: customStart,
            customEnd: customEnd,
            now: now,
            calendar: calendar
        ) else {
            return nil
        }

        let days = dayCount(in: currentInterval, calendar: calendar)
        let previousEndDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: currentInterval.start))
            ?? currentInterval.start
        let previousStartDay = calendar.date(byAdding: .day, value: -(days - 1), to: previousEndDay)
            ?? previousEndDay
        return DateInterval(start: calendar.startOfDay(for: previousStartDay), end: calendar.endOfDay(for: previousEndDay))
    }

    static func title(for range: TimeRange) -> String {
        switch range {
        case .today:
            return "Today"
        case .sevenDays:
            return "7 Days"
        case .thirtyDays:
            return "30 Days"
        case .allTime:
            return "All Time"
        case .custom:
            return "Custom Range"
        }
    }

    static func summaryLabel(
        for range: TimeRange,
        customStart: Date,
        customEnd: Date,
        calendar: Calendar = .current
    ) -> String {
        switch range {
        case .today:
            return "Today"
        case .sevenDays:
            return "Last 7 days"
        case .thirtyDays:
            return "Last 30 days"
        case .allTime:
            return "All time"
        case .custom:
            let interval = normalizedInterval(start: customStart, end: customEnd, calendar: calendar)
            let formatter = DateIntervalFormatter()
            formatter.calendar = calendar
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: interval.start, to: interval.end)
        }
    }

    static func compactLabel(
        for range: TimeRange,
        customStart: Date,
        customEnd: Date,
        calendar: Calendar = .current
    ) -> String {
        switch range {
        case .today:
            return "Today"
        case .sevenDays:
            return "7D"
        case .thirtyDays:
            return "30D"
        case .allTime:
            return "All"
        case .custom:
            let interval = normalizedInterval(start: customStart, end: customEnd, calendar: calendar)
            let formatter = DateIntervalFormatter()
            formatter.calendar = calendar
            formatter.dateTemplate = "MMM d"
            return formatter.string(from: interval.start, to: interval.end)
        }
    }

    static func dayCount(in interval: DateInterval, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: interval.end)
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return max(1, (components.day ?? 0) + 1)
    }

    static func dailySeries(
        from orders: [Order],
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> [DailySales] {
        let normalized = normalizedInterval(start: interval.start, end: interval.end, maximumDate: interval.end, calendar: calendar)
        let paidOrders = orders.filter { order in
            order.status == .paid && order.createdAt >= normalized.start && order.createdAt <= normalized.end
        }
        let grouped = Dictionary(grouping: paidOrders) { order in
            calendar.startOfDay(for: order.createdAt)
        }

        let endDay = calendar.startOfDay(for: normalized.end)
        var currentDay = calendar.startOfDay(for: normalized.start)
        var series: [DailySales] = []

        while currentDay <= endDay {
            let dayOrders = grouped[currentDay] ?? []
            series.append(
                DailySales(
                    date: currentDay,
                    revenue: dayOrders.reduce(0) { $0 + $1.netTotal },
                    orderCount: dayOrders.count
                )
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }

        return series
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        let next = self.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return next.addingTimeInterval(-1)
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case allTime = "All"
    case custom = "Custom"
}

enum SaneSalesFreeTierPolicy {
    static let unlockedDashboardRanges: [TimeRange] = [.today]
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
        guard isPro else { return .today }
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
    @Environment(LicenseService.self) var licenseService
    @AppStorage(SaneSalesDateRangeStore.selectedRangeKey) var selectedRange: TimeRange = .today
    @AppStorage(SaneSalesDateRangeStore.customStartKey) private var customRangeStartTimestamp = SaneSalesDateRangeStore.defaultCustomStartTimestamp
    @AppStorage(SaneSalesDateRangeStore.customEndKey) private var customRangeEndTimestamp = SaneSalesDateRangeStore.defaultCustomEndTimestamp
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State var selectedProviderFilter: SalesProviderType?
    @State private var quickConnectProvider: SalesProviderType?
    @State private var animateCards = false
    @State var didLogChartGateView = false
    @State private var showingCustomRangeSheet = false
    @Namespace var pickerNamespace
    #if os(macOS)
        @State var proUpsellFeature: ProFeature?
    #endif

    enum DashboardLayout {
        #if os(macOS)
            static let sectionSpacing: CGFloat = 16
            static let cardSpacing: CGFloat = 10
            static let horizontalPadding: CGFloat = 16
            static let cardHeight: CGFloat = 152
            static let contentPadding: CGFloat = 10
        #else
            static let sectionSpacing: CGFloat = 18
            static let cardSpacing: CGFloat = 12
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

        var metricGridSpacing: CGFloat {
            switch self {
            case .compact: 16
            case .regular, .wide: DashboardLayout.cardSpacing
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

                            secondarySection(widthClass)
                        }
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                        .padding(.bottom, dashboardBottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                        .frame(minHeight: proxy.size.height, alignment: .top)
                    }
                }
            }
            .navigationTitle("Dashboard")
            #if os(iOS)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: SaneSalesIOSChrome.floatingTabBarClearance)
            }
            #endif
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
            .sheet(isPresented: $showingCustomRangeSheet) {
                SalesCustomDateRangeSheet(
                    startDate: customRangeStartDate,
                    endDate: customRangeEndDate,
                    maximumDate: Date()
                ) { start, end in
                    applyCustomRange(start: start, end: end)
                }
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
        VStack(alignment: .leading, spacing: widthClass == .compact ? 14 : 16) {
            dashboardBrandHeader(widthClass)
            controlsRow(widthClass)
            heroRevenue(widthClass, alignment: .leading)
            comparisonGrid(widthClass)
        }
        .padding(widthClass == .compact ? 14 : 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.salesPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.06 : 0.03))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.salesPanelStroke, lineWidth: 1)
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
                Text(manager.isPro ? "Choose a provider and range" : "Live daily sales")
                    .font(isCompact ? .system(size: 11, weight: .medium) : .saneCallout)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroRevenue(_ widthClass: WidthClass, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(manager.isPro ? rangeLabel : "Revenue")
                .font(.system(size: widthClass == .compact ? 13 : 14, weight: .semibold))
                .foregroundStyle(Color.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(formatCents(revenueForRange))
                .font(.saneCardValue(size: widthClass.heroValueSize))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(revenueForRange)))
                .animation(.spring(response: 0.4), value: revenueForRange)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 10) {
                Text(pluralize(ordersForRange, "order"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                if let provider = selectedProviderFilter {
                    Text(provider.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                } else if manager.connectedProviders.count > 1 {
                    Text("All providers")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                }
            }

            if shouldShowCustomRangeSummary {
                Text(customRangeSummary)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    @ViewBuilder
    private func controlsRow(_ widthClass: WidthClass) -> some View {
        if widthClass == .compact {
            VStack(alignment: .leading, spacing: 10) {
                providerMenu
                timeRangePicker
                if shouldShowCustomRangeSummary {
                    customRangeSummaryRow
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    providerMenu
                        .frame(maxWidth: 260, alignment: .leading)
                    timeRangePicker
                }

                if shouldShowCustomRangeSummary {
                    customRangeSummaryRow
                }
            }
        }
    }

    private var timeRangePicker: some View {
        SalesDateRangePicker(
            scope: "dashboard",
            selectedRange: selectedRange,
            isRangeLocked: isLockedRange,
            onSelect: handleRangeSelection
        )
    }

    private var customRangeSummaryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Color.salesGreen)
            Text(customRangeSummary)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Edit") {
                showingCustomRangeSheet = true
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.salesGreen)
            .buttonStyle(.plain)
            .accessibilityIdentifier("dashboard.customRange.editButton")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.salesControlSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    private var providerMenu: some View {
        Menu {
            if manager.connectedProviders.count > 1 {
                Button("All Providers") {
                    selectedProviderFilter = nil
                }
            }

            ForEach(manager.connectedProviders, id: \.self) { provider in
                Button(provider.displayName) {
                    selectedProviderFilter = provider
                }
            }

            let disconnected = SalesProviderType.allCases.filter { !isProviderConnected($0) }
            if !disconnected.isEmpty {
                if !manager.connectedProviders.isEmpty {
                    Divider()
                }
                ForEach(disconnected, id: \.self) { provider in
                    Button("Connect \(provider.displayName)") {
                        beginQuickConnect(provider)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(.white)
                Text(providerMenuTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.salesControlSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.salesPanelStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard.providerMenu")
    }

    private var providerMenuTitle: String {
        if let selectedProviderFilter {
            return selectedProviderFilter.displayName
        }
        if manager.connectedProviders.isEmpty {
            return "Choose Provider"
        }
        if manager.connectedProviders.count == 1, let provider = manager.connectedProviders.first {
            return provider.displayName
        }
        return "All Providers"
    }

    var comparisonItems: [DashboardComparisonItem] {
        var items: [DashboardComparisonItem] = [
            DashboardComparisonItem(label: "vs prev", value: comparisonText, isPositive: comparisonDelta >= 0)
        ]

        if selectedRange != .today, let avgDaily = averageDailyRevenue {
            items.append(DashboardComparisonItem(label: "avg/day", value: formatCents(avgDaily), isPositive: true))
        }

        items.append(
            DashboardComparisonItem(
                label: selectedRange == .today ? "orders" : "orders/day",
                value: selectedRange == .today ? "\(ordersForRange)" : String(format: "%.1f", averageDailyOrders),
                isPositive: true
            )
        )
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
        .frame(minHeight: widthClass == .compact ? 36 : 50)
        .padding(.vertical, widthClass == .compact ? 3 : 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.salesControlSurface)
                )
        )
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
        LazyVGrid(columns: widthClass.metricColumns, spacing: widthClass.metricGridSpacing) {
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
        LazyVGrid(columns: widthClass.metricColumns, spacing: widthClass.metricGridSpacing) {
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
        manager.planScopedOrders(filteredBy: selectedProviderFilter)
    }

    var dashboardMetrics: SalesMetrics {
        manager.metrics(filteredBy: selectedProviderFilter, scopedToPlan: true)
    }

    var customRangeStartDate: Date {
        Date(timeIntervalSince1970: customRangeStartTimestamp)
    }

    var customRangeEndDate: Date {
        Date(timeIntervalSince1970: customRangeEndTimestamp)
    }

    var selectedDateInterval: DateInterval? {
        SaneSalesDateRangeStore.interval(
            for: selectedRange,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    var previousDateInterval: DateInterval? {
        SaneSalesDateRangeStore.previousInterval(
            for: selectedRange,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    var selectedRangeOrders: [Order] {
        manager.planScopedOrders(filteredBy: selectedProviderFilter, in: selectedDateInterval)
    }

    var selectedRangeMetrics: SalesMetrics {
        manager.metrics(filteredBy: selectedProviderFilter, in: selectedDateInterval, scopedToPlan: true)
    }

    var chartSeries: [DailySales] {
        if let selectedDateInterval {
            return SaneSalesDateRangeStore.dailySeries(from: dashboardOrders, in: selectedDateInterval)
        }
        return Array(selectedRangeMetrics.dailyBreakdown.reversed())
    }

    var customRangeSummary: String {
        SaneSalesDateRangeStore.summaryLabel(
            for: .custom,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    var shouldShowCustomRangeSummary: Bool {
        manager.isPro && selectedRange == .custom
    }

    var revenueForRange: Int {
        selectedRangeMetrics.allTimeRevenue
    }

    var ordersForRange: Int {
        selectedRangeMetrics.allTimeOrders
    }

    var rangeLabel: String {
        SaneSalesDateRangeStore.title(for: selectedRange)
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
        guard let previousDateInterval else { return 0 }
        return manager.metrics(
            filteredBy: selectedProviderFilter,
            in: previousDateInterval,
            scopedToPlan: true
        ).allTimeRevenue
    }

    var averageDailyRevenue: Int? {
        guard selectedRange != .today else { return nil }
        let days = if let selectedDateInterval {
            SaneSalesDateRangeStore.dayCount(in: selectedDateInterval)
        } else {
            max(1, selectedRangeMetrics.dailyBreakdown.count)
        }
        return revenueForRange / max(1, days)
    }

    var averageDailyOrders: Double {
        let days: Double = if let selectedDateInterval {
            Double(SaneSalesDateRangeStore.dayCount(in: selectedDateInterval))
        } else {
            max(1, Double(selectedRangeMetrics.dailyBreakdown.count))
        }
        return Double(ordersForRange) / days
    }

    func revenueForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days + 1, to: Calendar.current.startOfDay(for: Date()))
            ?? Date()
        return dashboardOrders
            .filter { $0.status == .paid && $0.createdAt >= cutoff }
            .reduce(0) { $0 + $1.netTotal }
    }

    func ordersForDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days + 1, to: Calendar.current.startOfDay(for: Date()))
            ?? Date()
        return dashboardOrders.filter { $0.status == .paid && $0.createdAt >= cutoff }.count
    }

    func revenueInRange(daysAgo: Int, daysUntil: Int) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: Date()))!
        let end = cal.endOfDay(for: cal.date(byAdding: .day, value: -daysUntil, to: Date())!)
        return dashboardOrders
            .filter { $0.status == .paid && $0.createdAt >= start && $0.createdAt <= end }
            .reduce(0) { $0 + $1.netTotal }
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

        if range == .custom {
            showingCustomRangeSheet = true
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRange = range
        }
    }

    func applyCustomRange(start: Date, end: Date) {
        let normalized = SaneSalesDateRangeStore.normalizedInterval(start: start, end: end)
        customRangeStartTimestamp = normalized.start.timeIntervalSince1970
        customRangeEndTimestamp = normalized.end.timeIntervalSince1970
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRange = .custom
        }
    }

    func normalizeStoredCustomRange() {
        let normalized = SaneSalesDateRangeStore.normalizedInterval(start: customRangeStartDate, end: customRangeEndDate)
        customRangeStartTimestamp = normalized.start.timeIntervalSince1970
        customRangeEndTimestamp = normalized.end.timeIntervalSince1970
    }

    func enforceFreeTierRange() {
        normalizeStoredCustomRange()
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
    var basicPlanNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.salesGold)
            Text("Basic shows live daily sales. Pro unlocks 7D, 30D, custom date ranges, all-time history, charts, and CSV export.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.salesControlSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    var shouldShowRecentSnapshotNote: Bool {
        false
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
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
        }
    }

    func queueSettingsRoute(for provider: SalesProviderType) {
        pendingSettingsRoute = "provider:\(provider.rawValue)"
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
        }
    }

    func beginQuickConnect(_ provider: SalesProviderType) {
        if manager.requiresProForProviderConnection(provider) {
            Task.detached {
                await EventTracker.log("second_provider_attempt", app: "sanesales")
            }
            #if os(macOS)
                proUpsellFeature = .multipleProviders
            #else
                queueLicenseSettingsRoute()
            #endif
            return
        }

        quickConnectProvider = provider
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
            let breathingRoom = DashboardLayout.sectionSpacing + 20
            return max(breathingRoom, safeAreaBottom + 18)
        #else
            return DashboardLayout.sectionSpacing
        #endif
    }
}
