import SaneUI
import SwiftUI

struct OrdersListView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State private var searchText = ""
    @State private var providerFilter: SalesProviderType?
    @State private var didLogOrderHistoryGate = false
    #if os(macOS)
        @State private var proUpsellFeature: ProFeature?
        @Environment(LicenseService.self) private var licenseService
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

    private var displayedOrders: [Order] {
        manager.filteredOrders(search: searchText, provider: providerFilter)
    }

    private var orderSummaryTitle: String {
        if manager.isPro {
            return "\(displayedOrders.count) \(displayedOrders.count == 1 ? "order" : "orders")"
        }

        if displayedOrders.count > freeTierPreviewOrders.count {
            return "\(freeTierPreviewOrders.count) recent orders"
        }

        return "\(freeTierPreviewOrders.count) \(freeTierPreviewOrders.count == 1 ? "order" : "orders")"
    }

    private var orderSummarySubtitle: String {
        if !searchText.isEmpty {
            return "Search: \(searchText)"
        }

        let scope = providerFilter?.displayName
            ?? (manager.isPro ? "All providers" : (manager.connectedProviders.first?.displayName ?? "Recent activity"))

        guard !manager.isPro, displayedOrders.count > freeTierPreviewOrders.count else {
            return scope
        }

        return "\(scope) preview"
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

    private var freeTierPreviewOrders: [Order] {
        Array(displayedOrders.prefix(SaneSalesFreeTierPolicy.recentOrderPreviewLimit))
    }

    private var freeTierPreviewGroups: [(DateSection, [Order])] {
        let grouped = Dictionary(grouping: freeTierPreviewOrders) { order in
            DateSection.from(order.createdAt)
        }
        return DateSection.allCases.compactMap { section in
            guard let orders = grouped[section], !orders.isEmpty else { return nil }
            return (section, orders)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                GeometryReader { proxy in
                    let widthClass = WidthClass(width: proxy.size.width)

                    VStack(spacing: 12) {
                        ordersOverview(widthClass)
                        ordersContent
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle("Orders")
            .searchable(text: $searchText, prompt: "Search by name, email, product, or order ID")
            .refreshable {
                await manager.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    providerFilterMenu
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(for: String.self) { orderId in
                if let order = manager.orders.first(where: { $0.id == orderId }) {
                    OrderDetailView(order: order)
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
    private var ordersContent: some View {
        if !manager.isPro {
            freeTierOrdersContent
        } else {
            fullOrdersContent
        }
    }

    private var fullOrdersContent: some View {
        Group {
            if displayedOrders.isEmpty, !manager.isLoading {
                if searchText.isEmpty {
                    ContentUnavailableView("No Orders", systemImage: "list.bullet.rectangle",
                                           description: Text("Orders will appear here once you make your first sale."))
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
        return VStack(alignment: .leading, spacing: 10) {
            if widthClass == .compact {
                VStack(alignment: .leading, spacing: 8) {
                    orderSummary(widthClass: widthClass, subtitle: orderSummarySubtitle)
                    providerChipRow(widthClass)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    orderSummary(widthClass: widthClass, subtitle: orderSummarySubtitle)
                    Spacer()
                    providerChipRow(widthClass)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func orderSummary(widthClass: WidthClass, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(orderSummaryTitle)
                .font(.system(size: widthClass == .compact ? 21 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func providerChipRow(_ widthClass: WidthClass) -> some View {
        let providers = manager.connectedProviders
        let columns: [GridItem] = widthClass == .compact
            ? [.init(.flexible()), .init(.flexible())]
            : Array(repeating: GridItem(.flexible()), count: max(2, providers.count + 1))

        LazyVGrid(columns: columns, spacing: 8) {
            allProviderChip

            ForEach(providers, id: \.self) { provider in
                Button {
                    providerFilter = providerFilter == provider ? nil : provider
                } label: {
                    ProviderBadge(provider: provider, fillsAvailableWidth: true)
                        .overlay(
                            Capsule()
                                .stroke(
                                    providerFilter == provider ? provider.brandColor.opacity(0.9) : Color.clear,
                                    lineWidth: 1.2
                                )
                        )
                        .opacity(providerFilter == nil || providerFilter == provider ? 1.0 : 0.55)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var allProviderChip: some View {
        Button {
            providerFilter = nil
        } label: {
            Text("All")
                .font(.saneCallout)
                .foregroundStyle(providerFilter == nil ? .white : Color.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if providerFilter == nil {
                        Capsule()
                            .fill(Color.salesGreen.opacity(0.9))
                    } else {
                        Capsule()
                            .fill(AnyShapeStyle(.ultraThinMaterial))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var freeTierOrdersContent: some View {
        Group {
            if freeTierPreviewOrders.isEmpty, !manager.isLoading {
                if searchText.isEmpty {
                    ContentUnavailableView("No Orders", systemImage: "list.bullet.rectangle",
                                           description: Text("Recent orders will appear here after your first sale."))
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(freeTierPreviewGroups, id: \.0) { section, orders in
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

                    if displayedOrders.count > freeTierPreviewOrders.count {
                        Section {
                            Button {
                                showOrderHistoryUpsell(event: "order_history_locked_tap")
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Showing recent \(freeTierPreviewOrders.count) of \(displayedOrders.count) orders")
                                            .font(.saneSubheadlineBold)
                                            .foregroundStyle(.primary)
                                        Text("Unlock Pro for full history, deeper search, and older sales.")
                                            .font(.saneCallout)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                    Spacer()
                                    Text("$6.99")
                                        .font(.saneSubheadlineBold)
                                        .foregroundStyle(.teal)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(orderRowBackground)
                        } header: {
                            Text("More Orders • Pro")
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
            .fill(AnyShapeStyle(.ultraThinMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.08 : 0.04))
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

    private var providerFilterMenu: some View {
        Menu {
            Button {
                providerFilter = nil
            } label: {
                Label("All Providers", systemImage: providerFilter == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(manager.connectedProviders, id: \.self) { provider in
                Button {
                    providerFilter = provider
                } label: {
                    Label(provider.displayName, systemImage: providerFilter == provider ? "checkmark" : provider.icon)
                }
            }
        } label: {
            Image(systemName: providerFilter != nil
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
                .foregroundStyle(providerFilter != nil
                    ? providerFilter!.brandColor
                    : Color.salesGreen)
                .accessibilityLabel(providerFilter != nil
                    ? "Filter: \(providerFilter!.displayName)"
                    : "Filter providers")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            }
        #endif
    }
}

// MARK: - Order Row

struct OrderRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SalesManager.self) private var manager
    let order: Order

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Image(systemName: order.status.icon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            // Customer + Product
            VStack(alignment: .leading, spacing: 3) {
                Text(order.customerName)
                    .font(.saneSubheadlineBold)
                HStack(spacing: 6) {
                    Text(order.productName)
                        .font(.saneCallout)
                        .foregroundStyle(Color.textMuted)
                    if manager.connectedProviders.count > 1 {
                        ProviderDot(provider: order.provider)
                    }
                }
            }

            Spacer()

            // Amount + Date
            VStack(alignment: .trailing, spacing: 3) {
                Text(order.displayTotal)
                    .font(.saneSubheadlineBold)
                    .foregroundStyle(order.isRefunded ? Color.salesWarning : Color.primary)
                Text(order.createdAt, style: .date)
                    .font(.saneFootnote)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(order.customerName), \(order.productName), \(order.displayTotal), \(order.status.displayName)")
    }

    private var statusColor: Color {
        switch order.status {
        case .paid: .salesSuccess
        case .refunded: .salesWarning
        case .pending: .salesWarning
        case .failed: .salesError
        case .unknown: .textMuted
        }
    }
}

// MARK: - Date Section

private enum DateSection: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case earlier = "Earlier"

    static func from(_ date: Date) -> DateSection {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .today }
        if cal.isDateInYesterday(date) { return .yesterday }
        let weekAgo = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: Date()))!
        if date >= weekAgo { return .thisWeek }
        if let monthStart = cal.dateInterval(of: .month, for: Date())?.start, date >= monthStart {
            return .thisMonth
        }
        return .earlier
    }
}

// MARK: - Provider Dot (compact indicator)

struct ProviderDot: View {
    let provider: SalesProviderType

    var body: some View {
        Circle()
            .fill(provider.brandColor)
            .frame(width: 10, height: 10)
            .accessibilityLabel(provider.displayName)
    }
}
