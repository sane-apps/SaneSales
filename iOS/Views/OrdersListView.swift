import SwiftUI
#if os(macOS)
    import SaneUI
#endif

struct OrdersListView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var providerFilter: SalesProviderType?
    #if os(macOS)
        @State private var didLogOrderHistoryGate = false
        @State private var proUpsellFeature: ProFeature?
        @Environment(LicenseService.self) private var licenseService
    #endif

    private var displayedOrders: [Order] {
        manager.filteredOrders(search: searchText, provider: providerFilter)
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

    #if os(macOS)
        private var todayOrders: [Order] {
            displayedOrders.filter(\.isToday)
        }

        private var lockedHistoryPreview: [Order] {
            Array(displayedOrders.filter { !$0.isToday }.prefix(3))
        }
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                ordersContent
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
        #if os(macOS)
            if !manager.isPro {
                freeTierOrdersContent
            } else {
                fullOrdersContent
            }
        #else
            fullOrdersContent
        #endif
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

    #if os(macOS)
        private var freeTierOrdersContent: some View {
            Group {
                if displayedOrders.isEmpty, !manager.isLoading {
                    if searchText.isEmpty {
                        ContentUnavailableView("No Orders", systemImage: "list.bullet.rectangle",
                                               description: Text("Today's orders will appear here after your first sale."))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    List {
                        if todayOrders.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "Today's Orders",
                                    systemImage: "clock.badge.checkmark",
                                    description: Text("Free shows today's orders. Unlock Pro to browse yesterday and older sales.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                            }
                        } else {
                            Section {
                                ForEach(todayOrders) { order in
                                    NavigationLink(value: order.id) {
                                        OrderRow(order: order)
                                    }
                                    .listRowBackground(orderRowBackground)
                                }
                            } header: {
                                Text("Today")
                                    .font(.saneSectionHeader)
                                    .foregroundStyle(Color.textMuted)
                                    .textCase(nil)
                            }
                        }

                        if !lockedHistoryPreview.isEmpty || !displayedOrders.isEmpty {
                            Section {
                                ForEach(lockedHistoryPreview) { order in
                                    Button {
                                        showOrderHistoryUpsell(event: "order_history_locked_tap")
                                    } label: {
                                        OrderRow(order: order)
                                            .blur(radius: 4)
                                            .overlay(alignment: .trailing) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.teal)
                                                    .padding(.trailing, 4)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(orderRowBackground)
                                }

                                Button {
                                    showOrderHistoryUpsell(event: "order_history_locked_tap")
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(.teal)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Unlock full order history")
                                                .font(.saneSubheadlineBold)
                                                .foregroundStyle(.primary)
                                            Text("Browse yesterday and older sales, plus search and filters.")
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
                                Text("Earlier • Pro")
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
    #endif

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

    #if os(macOS)
        private func showOrderHistoryUpsell(event: String) {
            Task.detached {
                await EventTracker.log(event, app: "sanesales")
            }
            proUpsellFeature = .orderHistory
        }
    #endif
}

// MARK: - Order Row

struct OrderRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SalesManager.self) private var manager
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: order.status.icon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            // Customer + Product
            VStack(alignment: .leading, spacing: 4) {
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
            VStack(alignment: .trailing, spacing: 4) {
                Text(order.displayTotal)
                    .font(.saneSubheadlineBold)
                    .foregroundStyle(order.isRefunded ? Color.salesWarning : Color.primary)
                Text(order.createdAt, style: .date)
                    .font(.saneFootnote)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.vertical, 8)
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
