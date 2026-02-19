import SwiftUI

struct OrdersListView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var providerFilter: SalesProviderType?

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

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
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
                                        .listRowBackground(
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
                                        )
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
        }
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
        case .unknown: .gray
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
