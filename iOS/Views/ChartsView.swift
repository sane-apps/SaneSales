import Charts
import SwiftUI

struct ChartsView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dailySales: [DailySales]
    var currency: String = "USD"
    @State private var selectedDate: Date?

    private var selectedDay: DailySales? {
        guard let selectedDate else { return nil }
        return dailySales.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Chart(dailySales) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Revenue", day.revenueDecimal)
                )
                .foregroundStyle(
                    selectedDate == nil || Calendar.current.isDate(day.date, inSameDayAs: selectedDate ?? .distantPast)
                        ? LinearGradient(
                            colors: [Color.salesGreen, Color.salesGreen.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.salesGreen.opacity(0.25), Color.salesGreen.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .cornerRadius(4)
            }
            .chartXSelection(value: $selectedDate)
            .chartYScale(domain: 0...SaneSalesChartAxisPolicy.yAxisUpperBound(for: dailySales.map(\.revenueDecimal).max() ?? 0))
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.primary.opacity(0.15))
                    AxisValueLabel {
                        if let decimal = value.as(Decimal.self) {
                            Text(SaneSalesChartAxisPolicy.compactCurrencyLabel(for: decimal, currency: currency))
                                .font(.callout)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisDates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisLabel(for: date))
                                .font(.callout)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }

            // Selection overlay
            if let day = selectedDay {
                selectedDayOverlay(day)
            }
        }
        .accessibilityLabel("Revenue chart showing \(dailySales.count) days of sales data")
    }

    private func selectedDayOverlay(_ day: DailySales) -> some View {
        HStack(spacing: 8) {
            Text(day.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.callout.weight(.medium))
            Text(formatCents(day.revenue))
                .font(.callout.weight(.bold))
            Text("\(day.orderCount) orders")
                .font(.callout)
                .foregroundStyle(Color.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.12)
                    : Color.black.opacity(0.06))
        )
    }

    private var xAxisStride: Int {
        SaneSalesChartAxisPolicy.xAxisStride(for: dailySales.count)
    }

    private var xAxisDates: [Date] {
        guard !dailySales.isEmpty else { return [] }
        let step = max(1, xAxisStride)
        return stride(from: 0, to: dailySales.count, by: step).map { dailySales[$0].date }
    }

    private func xAxisLabel(for date: Date) -> String {
        if dailySales.count <= 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }
}

enum SaneSalesChartAxisPolicy {
    static func xAxisStride(for pointCount: Int) -> Int {
        switch pointCount {
        case ...7:
            return 1
        case 8...14:
            return 2
        case 15...31:
            return 7
        case 32...90:
            return 14
        default:
            return 30
        }
    }

    static func yAxisUpperBound(for maxRevenue: Decimal) -> Decimal {
        let rawValue = NSDecimalNumber(decimal: maxRevenue).doubleValue
        guard rawValue > 0 else { return 1 }

        let target = rawValue * 1.15
        let magnitude = pow(10, floor(log10(target)))
        let normalized = target / magnitude
        let niceStep: Double
        switch normalized {
        case ...1:
            niceStep = 1
        case ...2:
            niceStep = 2
        case ...5:
            niceStep = 5
        default:
            niceStep = 10
        }

        return Decimal(niceStep * magnitude)
    }

    static func compactCurrencyLabel(for value: Decimal, currency: String) -> String {
        let number = NSDecimalNumber(decimal: value).doubleValue
        let absolute = abs(number)
        let prefix = currency.uppercased() == "USD" ? "$" : "\(currency.uppercased()) "

        if absolute >= 1_000_000 {
            return "\(prefix)\(formatCompact(number / 1_000_000))M"
        }
        if absolute >= 1_000 {
            return "\(prefix)\(formatCompact(number / 1_000))K"
        }
        return "\(prefix)\(Int(number.rounded()))"
    }

    private static func formatCompact(_ value: Double) -> String {
        if value >= 10 || value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
