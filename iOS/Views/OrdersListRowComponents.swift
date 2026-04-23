import SaneUI
import SwiftUI

struct OrderRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SalesManager.self) private var manager
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: order.status.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 24)
                .accessibilityHidden(true)

            // Customer + Product
            VStack(alignment: .leading, spacing: 4) {
                Text(order.customerName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(order.productName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                    if manager.connectedProviders.count > 1 {
                        ProviderDot(provider: order.provider)
                    }
                }
            }

            Spacer()

            // Amount + Date
            VStack(alignment: .trailing, spacing: 4) {
                Text(order.displayTotal)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(order.isRefunded ? Color.salesWarning : Color.primary)
                Text(secondaryTimestamp)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
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

    private var secondaryTimestamp: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(order.createdAt) || calendar.isDateInYesterday(order.createdAt) {
            return order.createdAt.formatted(date: .omitted, time: .shortened)
        }

        if let daysAgo = calendar.dateComponents([.day], from: order.createdAt, to: Date()).day,
           daysAgo < 7 {
            return order.createdAt.formatted(.dateTime.weekday(.abbreviated))
        }

        return order.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

enum DateSection: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case earlier = "Earlier"

    static func from(_ date: Date) -> DateSection {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInYesterday(date) { return .yesterday }
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        if date >= weekAgo { return .thisWeek }
        if let monthStart = calendar.dateInterval(of: .month, for: Date())?.start,
           date >= monthStart {
            return .thisMonth
        }
        return .earlier
    }
}

struct ProviderDot: View {
    let provider: SalesProviderType

    var body: some View {
        Circle()
            .fill(provider.brandColor)
            .frame(width: 10, height: 10)
            .accessibilityLabel(provider.displayName)
    }
}
