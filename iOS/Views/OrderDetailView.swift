import SwiftUI

struct OrderDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let order: Order

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero amount
                amountHeader
                // Sections
                orderSection
                customerSection
                productSection
                taxSection
                providerSection
            }
            .padding()
        }
        .background(SaneBackground().ignoresSafeArea())
        .navigationTitle("Order Details")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Amount Header

    private var amountHeader: some View {
        VStack(spacing: 8) {
            Text(order.displayTotal)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            HStack(spacing: 8) {
                SalesBadge(order.status.displayName, color: statusColor, icon: order.status.icon)
                ProviderBadge(provider: order.provider)
            }

            if let id = order.identifier {
                Text(id)
                    .font(.saneCallout.monospaced())
                    .foregroundStyle(Color.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Order Section

    private var orderSection: some View {
        GlassSection("Order", icon: "receipt", iconColor: .salesGreen) {
            VStack(spacing: 0) {
                GlassRow("Date", icon: "calendar", iconColor: .textMuted) {
                    Text(order.createdAt.formatted(date: .long, time: .shortened))
                        .font(.saneSubheadline)
                }
                GlassDivider()
                if let orderNum = order.orderNumber {
                    GlassRow("Order #", icon: "number", iconColor: .textMuted) {
                        Text("\(orderNum)")
                            .font(.saneSubheadline.monospaced())
                    }
                    GlassDivider()
                }
                GlassRow("Currency", iconAssetName: "CoinTemplate", iconColor: .textMuted) {
                    Text(order.currency)
                        .font(.saneSubheadline)
                }
                if let subtotal = order.subtotalFormatted ?? formatOptionalCents(order.subtotal) {
                    GlassDivider()
                    GlassRow("Subtotal", icon: "minus.circle", iconColor: .textMuted) {
                        Text(subtotal)
                            .font(.saneSubheadline)
                    }
                }
                if let discount = order.discountTotalFormatted ?? formatOptionalCents(order.discountTotal), order.discountTotal ?? 0 > 0 {
                    GlassDivider()
                    GlassRow("Discount", icon: "tag", iconColor: .orange) {
                        Text("-\(discount)")
                            .font(.saneSubheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let refundedAmount = formatOptionalCents(order.refundedAmount) {
                    GlassDivider()
                    GlassRow("Refunded Amount", icon: "arrow.uturn.backward.circle", iconColor: .orange) {
                        Text("-\(refundedAmount)")
                            .font(.saneSubheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let refundedAt = order.refundedAt {
                    GlassDivider()
                    GlassRow("Refunded", icon: "arrow.uturn.backward", iconColor: .orange) {
                        Text(refundedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.saneSubheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let receiptURL = order.receiptURL {
                    GlassDivider()
                    Link(destination: receiptURL) {
                        GlassRow("Receipt", icon: "doc.text", iconColor: .salesGreen) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.salesGreen)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Customer Section

    private var customerSection: some View {
        GlassSection("Customer", icon: "person.fill", iconColor: .salesGreen) {
            VStack(spacing: 0) {
                GlassRow("Name", icon: "person", iconColor: .textMuted) {
                    Text(order.customerName)
                        .font(.saneSubheadline)
                }
                GlassDivider()
                GlassRow("Email", icon: "envelope", iconColor: .textMuted) {
                    Text(order.customerEmail)
                        .font(.saneSubheadline)
                        .foregroundStyle(Color.salesGreen)
                }
                if let country = order.ipCountry {
                    GlassDivider()
                    GlassRow("Country", icon: "globe", iconColor: .textMuted) {
                        Text(country)
                            .font(.saneSubheadline)
                    }
                }
            }
        }
    }

    // MARK: - Product Section

    private var productSection: some View {
        GlassSection("Product", icon: "shippingbox.fill", iconColor: .salesGreen) {
            VStack(spacing: 0) {
                GlassRow("Product", icon: "shippingbox", iconColor: .textMuted) {
                    Text(order.productName)
                        .font(.saneSubheadline)
                }
                if let variant = order.variantName {
                    GlassDivider()
                    GlassRow("Variant", icon: "tag", iconColor: .textMuted) {
                        Text(variant)
                            .font(.saneSubheadline)
                    }
                }
            }
        }
    }

    // MARK: - Tax Section

    private var taxSection: some View {
        Group {
            if order.tax != nil || order.taxName != nil {
                GlassSection("Tax", icon: "building.columns", iconColor: .salesGreen) {
                    VStack(spacing: 0) {
                        if let taxFormatted = order.taxFormatted ?? formatOptionalCents(order.tax) {
                            GlassRow("Tax Amount", icon: "percent", iconColor: .textMuted) {
                                Text(taxFormatted)
                                    .font(.saneSubheadline)
                            }
                        }
                        if let taxName = order.taxName {
                            GlassDivider()
                            GlassRow("Tax Type", icon: "doc.text", iconColor: .textMuted) {
                                Text(taxName)
                                    .font(.saneSubheadline)
                            }
                        }
                        if let taxRate = order.taxRate {
                            GlassDivider()
                            GlassRow("Rate", icon: "number", iconColor: .textMuted) {
                                Text("\(taxRate)%")
                                    .font(.saneSubheadline)
                            }
                        }
                        if let inclusive = order.taxInclusive {
                            GlassDivider()
                            GlassRow("Inclusive", icon: "arrow.up.arrow.down", iconColor: .textMuted) {
                                Text(inclusive ? "Yes" : "No")
                                    .font(.saneSubheadline)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Provider Section

    private var providerSection: some View {
        GlassSection("Provider", icon: "link.circle", iconColor: order.provider.brandColor) {
            VStack(spacing: 0) {
                GlassRow("Platform", icon: order.provider.icon, iconColor: order.provider.brandColor) {
                    Text(order.provider.displayName)
                        .font(.saneSubheadline)
                }
                if let piID = order.stripePaymentIntentID {
                    GlassDivider()
                    GlassRow("Payment Intent", icon: "creditcard", iconColor: .textMuted) {
                        Text(piID)
                            .font(.saneCallout.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                if let method = order.paymentMethod {
                    GlassDivider()
                    GlassRow("Payment Method", icon: "creditcard.fill", iconColor: .textMuted) {
                        Text(method.capitalized)
                            .font(.saneSubheadline)
                    }
                }
                if let saleID = order.gumroadSaleID {
                    GlassDivider()
                    GlassRow("Sale ID", icon: "number", iconColor: .textMuted) {
                        Text(saleID)
                            .font(.saneCallout.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                GlassDivider()
                GlassRow("Internal ID", icon: "barcode", iconColor: .textMuted) {
                    Text(order.id)
                        .font(.saneCallout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch order.status {
        case .paid: .salesSuccess
        case .refunded: .salesWarning
        case .pending: .salesWarning
        case .failed: .salesError
        case .unknown: .textMuted
        }
    }

    private func formatOptionalCents(_ cents: Int?) -> String? {
        guard let cents, cents > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = order.currency
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber)
    }
}
