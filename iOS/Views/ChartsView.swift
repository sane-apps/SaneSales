import Charts
import SwiftUI

struct ChartsView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dailySales: [DailySales]
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
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.primary.opacity(0.15))
                    AxisValueLabel {
                        if let decimal = value.as(Decimal.self) {
                            Text("$\(NSDecimalNumber(decimal: decimal).intValue)")
                                .font(.callout)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }

            // Selection overlay
            if let day = selectedDay {
                selectedDayOverlay(day)
            }
        }
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
        if dailySales.count <= 7 { return 1 }
        if dailySales.count <= 14 { return 2 }
        return 5
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: Decimal(cents) / 100 as NSDecimalNumber) ?? "$\(cents / 100)"
    }
}
