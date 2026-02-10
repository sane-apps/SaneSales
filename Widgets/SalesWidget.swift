import SwiftUI
import WidgetKit

struct SalesWidget: Widget {
    let kind = "SaneSalesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalesWidgetProvider()) { entry in
            SalesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sales Today")
        .description("See today's revenue and order count.")
        .supportedFamilies({
            var families: [WidgetFamily] = [.systemSmall, .systemMedium]
            #if os(iOS)
                families.append(.accessoryRectangular)
            #endif
            return families
        }())
    }
}

struct SalesWidgetEntry: TimelineEntry {
    let date: Date
    let todayRevenue: Int // cents
    let todayOrders: Int
    let monthRevenue: Int

    var todayRevenueFormatted: String {
        formatCents(todayRevenue)
    }

    var monthRevenueFormatted: String {
        formatCents(monthRevenue)
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }

    static let placeholder = SalesWidgetEntry(
        date: Date(),
        todayRevenue: 2500,
        todayOrders: 5,
        monthRevenue: 15000
    )
}

struct SalesWidgetView: View {
    let entry: SalesWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            #if os(iOS)
                if family == .accessoryRectangular {
                    rectangularWidget
                } else {
                    smallWidget
                }
            #else
                smallWidget
            #endif
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.todayRevenueFormatted)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(entry.todayOrders) orders")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.todayRevenueFormatted)
                    .font(.title.bold())
                Text("\(entry.todayOrders) orders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("This Month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.monthRevenueFormatted)
                    .font(.title2.bold())
            }
        }
    }

    private var rectangularWidget: some View {
        VStack(alignment: .leading) {
            Text("Sales Today")
                .font(.caption2)
            Text(entry.todayRevenueFormatted)
                .font(.headline)
            Text("\(entry.todayOrders) orders")
                .font(.caption2)
        }
    }
}
