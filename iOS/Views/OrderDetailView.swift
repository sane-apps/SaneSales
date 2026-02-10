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
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.brandDeepNavy, Color.black]
                    : [Color.saneBackground, Color.salesGreen.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationTitle("Order Details")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Amount Header

    private var amountHeader: some View {
        VStack(spacing: 8) {
            Text(order.displayTotal)
                .font(.system(size: 42, weight: .bold, design: .rounded))

            HStack(spacing: 8) {
                SalesBadge(order.status.displayName, color: statusColor, icon: order.status.icon)
                ProviderBadge(provider: order.provider)
            }

            if let id = order.identifier {
                Text(id)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Order Section

    private var orderSection: some View {
        GlassSection("Order", icon: "receipt", iconColor: .salesGreen) {
            VStack(spacing: 0) {
                GlassRow("Date", icon: "calendar", iconColor: .secondary) {
                    Text(order.createdAt.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                }
                GlassDivider()
                if let orderNum = order.orderNumber {
                    GlassRow("Order #", icon: "number", iconColor: .secondary) {
                        Text("\(orderNum)")
                            .font(.subheadline.monospaced())
                    }
                    GlassDivider()
                }
                GlassRow("Currency", iconAssetName: "CoinTemplate", iconColor: .secondary) {
                    Text(order.currency)
                        .font(.subheadline)
                }
                if let subtotal = order.subtotalFormatted ?? formatOptionalCents(order.subtotal) {
                    GlassDivider()
                    GlassRow("Subtotal", icon: "minus.circle", iconColor: .secondary) {
                        Text(subtotal)
                            .font(.subheadline)
                    }
                }
                if let discount = order.discountTotalFormatted ?? formatOptionalCents(order.discountTotal), order.discountTotal ?? 0 > 0 {
                    GlassDivider()
                    GlassRow("Discount", icon: "tag", iconColor: .orange) {
                        Text("-\(discount)")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let refundedAmount = formatOptionalCents(order.refundedAmount) {
                    GlassDivider()
                    GlassRow("Refunded Amount", icon: "arrow.uturn.backward.circle", iconColor: .orange) {
                        Text("-\(refundedAmount)")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let refundedAt = order.refundedAt {
                    GlassDivider()
                    GlassRow("Refunded", icon: "arrow.uturn.backward", iconColor: .orange) {
                        Text(refundedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
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
                GlassRow("Name", icon: "person", iconColor: .secondary) {
                    Text(order.customerName)
                        .font(.subheadline)
                }
                GlassDivider()
                GlassRow("Email", icon: "envelope", iconColor: .secondary) {
                    Text(order.customerEmail)
                        .font(.subheadline)
                        .foregroundStyle(Color.salesGreen)
                }
                if let country = order.ipCountry {
                    GlassDivider()
                    GlassRow("Country", icon: "globe", iconColor: .secondary) {
                        Text(country)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Product Section

    private var productSection: some View {
        GlassSection("Product", icon: "shippingbox.fill", iconColor: .salesGreen) {
            VStack(spacing: 0) {
                GlassRow("Product", icon: "shippingbox", iconColor: .secondary) {
                    Text(order.productName)
                        .font(.subheadline)
                }
                if let variant = order.variantName {
                    GlassDivider()
                    GlassRow("Variant", icon: "tag", iconColor: .secondary) {
                        Text(variant)
                            .font(.subheadline)
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
                            GlassRow("Tax Amount", icon: "percent", iconColor: .secondary) {
                                Text(taxFormatted)
                                    .font(.subheadline)
                            }
                        }
                        if let taxName = order.taxName {
                            GlassDivider()
                            GlassRow("Tax Type", icon: "doc.text", iconColor: .secondary) {
                                Text(taxName)
                                    .font(.subheadline)
                            }
                        }
                        if let taxRate = order.taxRate {
                            GlassDivider()
                            GlassRow("Rate", icon: "number", iconColor: .secondary) {
                                Text("\(taxRate)%")
                                    .font(.subheadline)
                            }
                        }
                        if let inclusive = order.taxInclusive {
                            GlassDivider()
                            GlassRow("Inclusive", icon: "arrow.up.arrow.down", iconColor: .secondary) {
                                Text(inclusive ? "Yes" : "No")
                                    .font(.subheadline)
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
                        .font(.subheadline.weight(.medium))
                }
                if let piID = order.stripePaymentIntentID {
                    GlassDivider()
                    GlassRow("Payment Intent", icon: "creditcard", iconColor: .secondary) {
                        Text(piID)
                            .font(.footnote.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                if let method = order.paymentMethod {
                    GlassDivider()
                    GlassRow("Payment Method", icon: "creditcard.fill", iconColor: .secondary) {
                        Text(method.capitalized)
                            .font(.subheadline)
                    }
                }
                if let saleID = order.gumroadSaleID {
                    GlassDivider()
                    GlassRow("Sale ID", icon: "number", iconColor: .secondary) {
                        Text(saleID)
                            .font(.footnote.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                GlassDivider()
                GlassRow("Internal ID", icon: "barcode", iconColor: .secondary) {
                    Text(order.id)
                        .font(.footnote.monospaced())
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
        case .pending: .yellow
        case .failed: .salesError
        case .unknown: .gray
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
