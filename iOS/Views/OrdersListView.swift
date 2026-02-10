import SwiftUI

struct OrdersListView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var providerFilter: SalesProviderType?

    private var displayedOrders: [Order] {
        manager.filteredOrders(search: searchText, provider: providerFilter)
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
                        List(displayedOrders) { order in
                            NavigationLink(value: order.id) {
                                OrderRow(order: order)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark
                                        ? Color.white.opacity(0.06)
                                        : Color.white)
                                    .padding(.vertical, 1)
                            )
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
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(Color.salesGreen)
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

            // Customer + Product
            VStack(alignment: .leading, spacing: 4) {
                Text(order.customerName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(order.productName)
                        .font(.callout)
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(order.isRefunded ? Color.salesWarning : Color.primary)
                Text(order.createdAt, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case .paid: .salesSuccess
        case .refunded: .salesWarning
        case .pending: .yellow
        case .failed: .salesError
        case .unknown: .gray
        }
    }
}

// MARK: - Provider Dot (compact indicator)

struct ProviderDot: View {
    let provider: SalesProviderType

    var body: some View {
        Circle()
            .fill(provider.brandColor)
            .frame(width: 7, height: 7)
    }
}
