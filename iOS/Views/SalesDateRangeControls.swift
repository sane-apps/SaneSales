import SaneUI
import SwiftUI

struct OrdersEmptyStateCopy: Equatable {
    let title: String
    let message: String
    let details: [String]
    let secondaryActionTitle: String

    static func make(
        isConnected: Bool,
        isPro: Bool,
        cachedOrderCount: Int,
        rangeLabel: String
    ) -> OrdersEmptyStateCopy {
        guard isConnected else {
            return OrdersEmptyStateCopy(
                title: "No Orders Yet",
                message: "Connect a provider to turn this into your live order feed for customers, products, and today's sales.",
                details: [
                    "See the latest sales as they come in",
                    "Search by customer, product, or order ID",
                    "Unlock Pro to connect live data"
                ],
                secondaryActionTitle: "Open Provider Settings"
            )
        }

        guard cachedOrderCount > 0 else {
            return OrdersEmptyStateCopy(
                title: "No Synced Orders Yet",
                message: "Your providers are connected, but SaneSales has not synced any orders yet. Refresh now or check the connected provider settings.",
                details: [
                    "Refresh to fetch the latest sales",
                    "Manage provider settings if a key changed",
                    "New sales will appear here after the first sync"
                ],
                secondaryActionTitle: "Open Provider Settings"
            )
        }

        if isPro {
            return OrdersEmptyStateCopy(
                title: "No Orders in Range",
                message: "Your providers are connected and \(cachedOrderCount) cached \(cachedOrderCount == 1 ? "order is" : "orders are") available, but none match \(rangeLabel).",
                details: [
                    "Selected range: \(rangeLabel)",
                    "Cached orders: \(cachedOrderCount)",
                    "Switch ranges or refresh to confirm the latest data"
                ],
                secondaryActionTitle: "Show All Orders"
            )
        }

        return OrdersEmptyStateCopy(
            title: "No Orders Today",
            message: "Your providers are connected, but there are no orders today. Pro unlocks custom ranges and full order history.",
            details: [
                "Basic shows today's orders only",
                "Cached orders: \(cachedOrderCount)",
                "Upgrade to Pro for custom ranges and full history"
            ],
            secondaryActionTitle: "Open Provider Settings"
        )
    }
}

extension TimeRange {
    var accessibilityToken: String {
        switch self {
        case .today:
            return "today"
        case .sevenDays:
            return "sevenDays"
        case .thirtyDays:
            return "thirtyDays"
        case .allTime:
            return "allTime"
        case .custom:
            return "custom"
        }
    }
}

struct SalesDateRangePicker: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    let scope: String
    let selectedRange: TimeRange
    let isRangeLocked: (TimeRange) -> Bool
    let onSelect: (TimeRange) -> Void
    let prefersDenseLayout: Bool

    init(
        scope: String,
        selectedRange: TimeRange,
        isRangeLocked: @escaping (TimeRange) -> Bool,
        onSelect: @escaping (TimeRange) -> Void,
        prefersDenseLayout: Bool = false
    ) {
        self.scope = scope
        self.selectedRange = selectedRange
        self.isRangeLocked = isRangeLocked
        self.onSelect = onSelect
        self.prefersDenseLayout = prefersDenseLayout
    }

    private var usesCompactPills: Bool {
        if prefersDenseLayout {
            return true
        }
        #if os(iOS)
            return horizontalSizeClass == .compact
        #else
            return false
        #endif
    }

    private var usesContentSizedButtons: Bool {
        prefersDenseLayout
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    onSelect(range)
                } label: {
                    HStack(spacing: usesCompactPills ? 3 : 4) {
                        Text(range.rawValue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .allowsTightening(true)
                        if isRangeLocked(range) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: usesCompactPills ? 8 : 9, weight: .bold))
                        }
                    }
                    .font(.system(size: usesCompactPills ? 14 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedRange == range ? .white : Color.textMuted)
                    .padding(.horizontal, usesContentSizedButtons ? 10 : 0)
                    .frame(maxWidth: usesContentSizedButtons ? nil : .infinity)
                    .frame(minHeight: usesCompactPills ? 34 : 36)
                    .contentShape(Rectangle())
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        if selectedRange == range {
                            Capsule()
                                .fill(Color.salesGreen)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(scope).range.\(range.accessibilityToken)")
                .accessibilityValue(selectedRange == range ? "Selected" : (isRangeLocked(range) ? "Locked" : "Available"))
            }
        }
        .padding(usesCompactPills ? 2 : 3)
        .background(
            Capsule()
                .fill(Color.salesControlSurface)
        )
    }
}

struct SalesCustomDateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let startDate: Date
    let endDate: Date
    let maximumDate: Date
    let onApply: (Date, Date) -> Void

    @State private var draftStart: Date
    @State private var draftEnd: Date

    init(
        title: String = "Custom Range",
        startDate: Date,
        endDate: Date,
        maximumDate: Date = Date(),
        onApply: @escaping (Date, Date) -> Void
    ) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.maximumDate = maximumDate
        self.onApply = onApply
        _draftStart = State(initialValue: min(startDate, maximumDate))
        _draftEnd = State(initialValue: min(endDate, maximumDate))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        datePickerSection
                        rangeSummaryCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .accessibilityIdentifier("customRange.cancelButton")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            let interval = normalizedInterval
                            onApply(interval.start, interval.end)
                            dismiss()
                        }
                        .tint(.salesGreen)
                        .accessibilityIdentifier("customRange.applyButton")
                    }
                }
        }
    }

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dates")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                datePickerRow(
                    title: "Start",
                    icon: "calendar",
                    selection: startBinding,
                    accessibilityIdentifier: "customRange.startDatePicker"
                )
                GlassDivider()
                datePickerRow(
                    title: "End",
                    icon: "calendar.badge.checkmark",
                    selection: endBinding,
                    accessibilityIdentifier: "customRange.endDatePicker"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.salesControlSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.salesPanelStroke, lineWidth: 1)
                    )
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.salesPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    private func datePickerRow(
        title: String,
        icon: String,
        selection: Binding<Date>,
        accessibilityIdentifier: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.salesGreen)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 12)
            DatePicker(title, selection: selection, in: ...maximumDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(.salesGreen)
                .accessibilityLabel(title)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var rangeSummaryCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Color.salesGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected range")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(SaneSalesDateRangeStore.summaryLabel(for: .custom, customStart: draftStart, customEnd: draftEnd))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("\(SaneSalesDateRangeStore.dayCount(in: normalizedInterval)) days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.salesControlSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { draftStart },
            set: { newValue in
                draftStart = clampedDate(newValue)
                if draftStart > draftEnd {
                    draftEnd = draftStart
                }
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { draftEnd },
            set: { newValue in
                draftEnd = clampedDate(newValue)
                if draftEnd < draftStart {
                    draftStart = draftEnd
                }
            }
        )
    }

    private func clampedDate(_ date: Date) -> Date {
        min(date, maximumDate)
    }

    private var normalizedInterval: DateInterval {
        SaneSalesDateRangeStore.normalizedInterval(start: draftStart, end: draftEnd, maximumDate: maximumDate)
    }
}
