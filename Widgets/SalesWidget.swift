import SwiftUI
import WidgetKit

@main
struct SalesWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalesWidget()
    }
}

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
            #if os(iOS)
                var families: [WidgetFamily] = [.systemSmall, .systemMedium]
                families.append(contentsOf: [.accessoryInline, .accessoryCircular, .accessoryRectangular])
            #elseif os(watchOS)
                let families: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular]
            #else
                let families: [WidgetFamily] = [.systemSmall, .systemMedium]
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
    let currency: String

    var todayRevenueFormatted: String {
        formatCents(todayRevenue)
    }

    var monthRevenueFormatted: String {
        formatCents(monthRevenue)
    }

    var todayRevenueCompact: String {
        formatCompactCents(todayRevenue)
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }

    private func formatCompactCents(_ cents: Int) -> String {
        let amount = Double(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0

        guard amount >= 1000 else {
            return formatter.string(from: NSNumber(value: amount)) ?? formatCents(cents)
        }

        let symbol = formatter.currencySymbol ?? "$"
        let compactValue: String
        if amount >= 1_000_000 {
            compactValue = compactNumber(amount / 1_000_000, suffix: "M")
        } else {
            compactValue = compactNumber(amount / 1000, suffix: "K")
        }
        return "\(symbol)\(compactValue)"
    }

    private func compactNumber(_ value: Double, suffix: String) -> String {
        let text = String(format: "%.1f", value)
        let cleaned = text.hasSuffix(".0") ? String(text.dropLast(2)) : text
        return cleaned + suffix
    }

    static let placeholder = SalesWidgetEntry(
        date: Date(),
        todayRevenue: 2500,
        todayOrders: 5,
        monthRevenue: 15000,
        currency: "USD"
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
        #if os(iOS) || os(watchOS)
        case .accessoryInline:
            inlineAccessoryWidget
        case .accessoryCircular:
            circularAccessoryWidget
        case .accessoryRectangular:
            rectangularWidget
        #endif
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.92))
            Text(entry.todayRevenueFormatted)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(entry.todayOrders) orders")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.92))
                Text(entry.todayRevenueFormatted)
                    .font(.title.bold())
                Text("\(entry.todayOrders) orders")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.92))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("This Month")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.92))
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

    private var circularAccessoryWidget: some View {
        VStack(spacing: 2) {
            Text(entry.todayRevenueCompact)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(entry.todayOrders) orders")
                .font(.caption2)
                .lineLimit(1)
        }
    }

    private var inlineAccessoryWidget: some View {
        Text("Today \(entry.todayRevenueCompact) · \(entry.todayOrders)")
            .lineLimit(1)
    }
}
