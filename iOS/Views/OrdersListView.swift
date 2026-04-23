import SaneUI
import SwiftUI

struct OrdersListView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(LicenseService.self) private var licenseService
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(SaneSalesDateRangeStore.selectedRangeKey) private var selectedRange: TimeRange = .today
    @AppStorage(SaneSalesDateRangeStore.customStartKey) private var customRangeStartTimestamp = SaneSalesDateRangeStore.defaultCustomStartTimestamp
    @AppStorage(SaneSalesDateRangeStore.customEndKey) private var customRangeEndTimestamp = SaneSalesDateRangeStore.defaultCustomEndTimestamp
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State private var searchText = ""
    @State private var providerFilter: SalesProviderType?
    @State private var didLogOrderHistoryGate = false
    @State private var showingCustomRangeSheet = false
    #if os(macOS)
        @State private var proUpsellFeature: ProFeature?
    #endif

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

    private var customRangeStartDate: Date {
        Date(timeIntervalSince1970: customRangeStartTimestamp)
    }

    private var customRangeEndDate: Date {
        Date(timeIntervalSince1970: customRangeEndTimestamp)
    }

    private var selectedDateInterval: DateInterval? {
        SaneSalesDateRangeStore.interval(
            for: selectedRange,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    private var rangeSummaryLabel: String {
        manager.isPro
            ? SaneSalesDateRangeStore.summaryLabel(
                for: selectedRange,
                customStart: customRangeStartDate,
                customEnd: customRangeEndDate
            )
            : "Today"
    }

    private var displayedOrders: [Order] {
        manager.filteredOrders(search: searchText, provider: providerFilter, in: selectedDateInterval)
    }

    private var scopedOrders: [Order] {
        manager.planScopedOrders(filteredBy: providerFilter, in: selectedDateInterval)
    }

    private var allOrdersForScope: [Order] {
        if manager.isPro {
            return manager.allOrders(filteredBy: providerFilter, in: selectedDateInterval)
        }
        return manager.allOrders(filteredBy: providerFilter)
    }

    private var hasOrders: Bool {
        !scopedOrders.isEmpty
    }

    private var hasLockedHistory: Bool {
        !manager.isPro && allOrdersForScope.count > scopedOrders.count
    }

    private var lockedHistoryCount: Int {
        max(0, allOrdersForScope.count - scopedOrders.count)
    }

    private var canFilterProviders: Bool {
        manager.connectedProviders.count > 1
    }

    private var shouldShowOrdersOverview: Bool {
        manager.isLoading || hasOrders || hasLockedHistory
    }

    private var shouldShowSearch: Bool {
        hasOrders || !searchText.isEmpty
    }

    private var orderSummaryTitle: String {
        let count = searchText.isEmpty ? scopedOrders.count : displayedOrders.count

        if manager.isPro {
            return "\(count) \(count == 1 ? "order" : "orders")"
        }

        return "\(count) \(count == 1 ? "order today" : "orders today")"
    }

    private var orderSummarySubtitle: String {
        let scope = providerFilter?.displayName
            ?? (manager.connectedProviders.count > 1 ? "All providers" : (manager.connectedProviders.first?.displayName ?? "Today"))

        guard manager.isPro else {
            if scope == "All providers" || scope == "Today" {
                return "Today"
            }
            return "\(scope) · Today"
        }

        if scope == "All providers" {
            return rangeSummaryLabel
        }

        return "\(scope) · \(rangeSummaryLabel)"
    }

    private var groupedOrders: [(DateSection, [Order])] {
        let grouped = Dictionary(grouping: displayedOrders) { order in
            DateSection.from(order.createdAt)
        }
        return DateSection.allCases.compactMap { section in
            guard let orders = grouped[section], !orders.isEmpty else { return nil }
            return (section, orders)
        }
    }

    var body: some View {
        NavigationStack {
            let content = ZStack {
                SaneBackground().ignoresSafeArea()
                GeometryReader { proxy in
                    let widthClass = WidthClass(width: proxy.size.width)

                    VStack(spacing: 12) {
                        if shouldShowOrdersOverview {
                            ordersOverview(widthClass)
                        }
                        ordersContent(widthClass)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }

            Group {
                if shouldShowSearch {
                    content.searchable(text: $searchText, prompt: manager.isPro ? "Search customers, products, or order IDs" : "Search today's customers or products")
                } else {
                    content
                }
            }
            #if os(iOS)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: SaneSalesIOSChrome.floatingTabBarClearance)
            }
            #endif
            .navigationTitle("Orders")
            .refreshable {
                await manager.refresh()
            }
            .onAppear {
                enforceFreeTierRange()
            }
            .onChange(of: manager.isPro) { _, _ in
                enforceFreeTierRange()
            }
            .onChange(of: manager.orders.count) { _, _ in
                enforceFreeTierRange()
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(for: String.self) { orderId in
                if let order = manager.orders.first(where: { $0.id == orderId }) {
                    OrderDetailView(order: order)
                }
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
        }
    }

    // MARK: - Orders Content (shared)

    @ViewBuilder
    private func ordersContent(_ widthClass: WidthClass) -> some View {
        if !manager.isPro {
            freeTierOrdersContent(widthClass)
        } else {
            fullOrdersContent(widthClass)
        }
    }

    private func fullOrdersContent(_ widthClass: WidthClass) -> some View {
        Group {
            if displayedOrders.isEmpty, !manager.isLoading {
                if searchText.isEmpty {
                    emptyOrdersState(widthClass: widthClass)
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(groupedOrders, id: \.0) { section, orders in
                        Section {
                            ForEach(orders) { order in
                                NavigationLink(value: order.id) {
                                    OrderRow(order: order)
                                }
                                .listRowBackground(orderRowBackground)
                            }
                        } header: {
                            Text(section.rawValue)
                                .font(.saneSectionHeader)
                                .foregroundStyle(Color.textMuted)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func ordersOverview(_ widthClass: WidthClass) -> some View {
        VStack(alignment: .leading, spacing: widthClass == .compact ? 8 : 10) {
            #if os(macOS)
            if widthClass != .compact {
                denseMacOrdersOverview
            } else {
                standardOrdersOverviewHeader(widthClass)

                if hasLockedHistory {
                    lockedHistoryCallout(widthClass)
                }
            }
            #else
            standardOrdersOverviewHeader(widthClass)

            if hasLockedHistory {
                lockedHistoryCallout(widthClass)
            }
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.salesPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func standardOrdersOverviewHeader(_ widthClass: WidthClass) -> some View {
        VStack(alignment: .leading, spacing: widthClass == .compact ? 8 : 10) {
            if widthClass == .compact {
                orderSummary(widthClass: widthClass, subtitle: orderSummarySubtitle)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    orderSummary(widthClass: widthClass, subtitle: orderSummarySubtitle)
                    Spacer()
                }
            }

            ordersFilterControls(widthClass)
        }
    }

    private var denseMacOrdersOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    orderSummary(widthClass: .regular, subtitle: orderSummarySubtitle)

                    if hasLockedHistory {
                        Text("Basic shows today’s orders. Pro unlocks custom date ranges, older orders, deeper search, and CSV export.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                if !hasLockedHistory {
                    ordersFilterControls(.regular)
                        .frame(maxWidth: 420, alignment: .trailing)
                }
            }

            if hasLockedHistory {
                HStack(alignment: .center, spacing: 12) {
                    Spacer(minLength: 0)
                    ordersFilterControls(.regular)
                }

                Button {
                    showOrderHistoryUpsell(event: "orders_overview_unlock_tap")
                } label: {
                    Label("Unlock Full History — \(licenseService.displayPriceLabel)", systemImage: "arrow.up.right")
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("orders.unlockHistoryButton")
            }
        }
    }

    @ViewBuilder
    private func lockedHistoryCallout(_ widthClass: WidthClass) -> some View {
        if widthClass == .compact {
            VStack(alignment: .leading, spacing: 8) {
                Text("Basic shows today only. Pro unlocks custom date ranges, older orders, deeper search, and CSV export.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showOrderHistoryUpsell(event: "orders_overview_unlock_tap")
                } label: {
                    Label("Unlock Full History — \(licenseService.displayPriceLabel)", systemImage: "arrow.up.right")
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .accessibilityIdentifier("orders.unlockHistoryButton")
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                Text("Basic keeps today front and center. Pro unlocks custom date ranges, older orders, deeper search, and CSV export.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button {
                    showOrderHistoryUpsell(event: "orders_overview_unlock_tap")
                } label: {
                    Label("Unlock Full History — \(licenseService.displayPriceLabel)", systemImage: "arrow.up.right")
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .accessibilityIdentifier("orders.unlockHistoryButton")
            }
        }
    }

    private func orderSummary(widthClass: WidthClass, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(orderSummaryTitle)
                .font(.system(size: widthClass == .compact ? 20 : 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
                .lineLimit(widthClass == .compact ? 2 : 1)
        }
    }

    private var providerFilterControl: some View {
        Menu {
            Button("All Providers") {
                providerFilter = nil
            }

            ForEach(manager.connectedProviders, id: \.self) { provider in
                Button(provider.displayName) {
                    providerFilter = provider
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(.white.opacity(0.9))
                Text(providerFilter?.displayName ?? "All Providers")
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
        .accessibilityIdentifier("orders.providerMenu")
    }

    @ViewBuilder
    private func ordersFilterControls(_ widthClass: WidthClass) -> some View {
        if widthClass == .compact {
            VStack(alignment: .leading, spacing: 10) {
                if canFilterProviders {
                    providerFilterControl
                }
                timeRangePicker(for: widthClass)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                if canFilterProviders {
                    providerFilterControl
                        .frame(maxWidth: 220)
                } else if let provider = manager.connectedProviders.first {
                    ProviderBadge(provider: provider, fillsAvailableWidth: false)
                }
                timeRangePicker(for: widthClass)
            }
        }
    }

    private func timeRangePicker(for widthClass: WidthClass) -> some View {
        SalesDateRangePicker(
            scope: "orders",
            selectedRange: selectedRange,
            isRangeLocked: isLockedRange,
            onSelect: handleRangeSelection
        )
    }

    private func handleRangeSelection(_ range: TimeRange) {
        if isLockedRange(range) {
            showOrderHistoryUpsell(event: "order_history_locked_tap")
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

    private func applyCustomRange(start: Date, end: Date) {
        let normalized = SaneSalesDateRangeStore.normalizedInterval(start: start, end: end)
        customRangeStartTimestamp = normalized.start.timeIntervalSince1970
        customRangeEndTimestamp = normalized.end.timeIntervalSince1970
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRange = .custom
        }
    }

    private func normalizeStoredCustomRange() {
        let normalized = SaneSalesDateRangeStore.normalizedInterval(start: customRangeStartDate, end: customRangeEndDate)
        customRangeStartTimestamp = normalized.start.timeIntervalSince1970
        customRangeEndTimestamp = normalized.end.timeIntervalSince1970
    }

    private func enforceFreeTierRange() {
        normalizeStoredCustomRange()
        selectedRange = SaneSalesFreeTierPolicy.preferredDashboardRange(
            currentRange: selectedRange,
            isPro: manager.isPro,
            todayOrders: manager.metrics(filteredBy: providerFilter, scopedToPlan: true).todayOrders,
            thirtyDayOrders: manager.metrics(filteredBy: providerFilter, scopedToPlan: true).thirtyDayOrders
        )
    }

    private func isLockedRange(_ range: TimeRange) -> Bool {
        SaneSalesFreeTierPolicy.locksDashboardRange(range, isPro: manager.isPro)
    }

    private func freeTierOrdersContent(_ widthClass: WidthClass) -> some View {
        Group {
            if displayedOrders.isEmpty, !manager.isLoading {
                if searchText.isEmpty {
                    emptyOrdersState(widthClass: widthClass)
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(groupedOrders, id: \.0) { section, orders in
                        Section {
                            ForEach(orders) { order in
                                NavigationLink(value: order.id) {
                                    OrderRow(order: order)
                                }
                                .listRowBackground(orderRowBackground)
                            }
                        } header: {
                            Text(section.rawValue)
                                .font(.saneSectionHeader)
                                .foregroundStyle(Color.textMuted)
                                .textCase(nil)
                        }
                    }

                    if hasLockedHistory && widthClass != .compact {
                        Section {
                            Button {
                                showOrderHistoryUpsell(event: "order_history_locked_tap")
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Showing today’s \(displayedOrders.count) orders")
                                            .font(.saneSubheadlineBold)
                                            .foregroundStyle(.primary)
                                        Text("Unlock Pro for custom date ranges, \(lockedHistoryCount) older \(lockedHistoryCount == 1 ? "order" : "orders"), deeper search, and export.")
                                            .font(.saneCallout)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                    Spacer()
                                    Text(licenseService.displayPriceLabel)
                                        .font(.saneSubheadlineBold)
                                        .foregroundStyle(.teal)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(orderRowBackground)
                        } header: {
                            Text("Older Orders • Pro")
                                .font(.saneSectionHeader)
                                .foregroundStyle(Color.textMuted)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onAppear {
                    guard manager.isConnected, !didLogOrderHistoryGate else { return }
                    didLogOrderHistoryGate = true
                    Task.detached {
                        await EventTracker.log("order_history_gate_seen", app: "sanesales")
                    }
                }
            }
        }
    }

    private var orderRowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.salesPanel)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.salesPanelStroke, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.brandBlueGlow.opacity(0.12)
                    : Color.brandBlueGlow.opacity(0.06),
                radius: 6,
                x: 0,
                y: 2
            )
            .padding(.vertical, 2)
    }

    private func emptyOrdersState(widthClass: WidthClass) -> some View {
        VStack {
            Spacer(minLength: widthClass == .compact ? 28 : 40)

            VStack(spacing: 18) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.salesGreen)

                VStack(spacing: 8) {
                    Text("No Orders Yet")
                        .font(.system(size: widthClass == .compact ? 28 : 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Connect a provider to turn this into your live order feed for customers, products, and today's sales.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 540)
                }

                VStack(alignment: .leading, spacing: 8) {
                    emptyStateDetailRow("See the latest sales as they come in")
                    emptyStateDetailRow("Search by customer, product, or order ID")
                    emptyStateDetailRow("Use Basic for today’s feed or Pro for custom ranges and older history")
                }
                .frame(maxWidth: 520, alignment: .leading)

                if manager.connectedProviders.isEmpty {
                    Text("Choose the store you already use. SaneSales will sync today's orders after you connect it.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
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
                            .foregroundStyle(.white.opacity(0.78))
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

    private func showOrderHistoryUpsell(event: String) {
        Task.detached {
            await EventTracker.log(event, app: "sanesales")
        }
        #if os(macOS)
            proUpsellFeature = .orderHistory
        #else
            pendingSettingsRoute = "license"
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            }
        #endif
    }
}
