import SaneUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

private enum SalesDateBoundary: String, CaseIterable, Identifiable {
    case start
    case end

    var id: String { rawValue }

    var title: String {
        switch self {
        case .start: return "Start"
        case .end: return "End"
        }
    }

    var helperCopy: String {
        switch self {
        case .start: return "Choose the day where the range should begin."
        case .end: return "Choose the day where the range should end."
        }
    }
}

private enum SalesRangeHighlightPosition {
    case none
    case single
    case start
    case middle
    case end
}

private struct SalesCalendarDay: Identifiable {
    let date: Date
    let isCurrentMonth: Bool
    let isEnabled: Bool

    var id: String {
        SalesCalendarFormatters.accessibilityIdentifier.string(from: date)
    }
}

private enum SalesCalendarFormatters {
    static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d"
        return formatter
    }()

    static let accessibilityIdentifier: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum SalesCalendarBuilder {
    static func days(
        for monthStart: Date,
        maximumDate: Date,
        calendar: Calendar = .current
    ) -> [SalesCalendarDay] {
        let normalizedMonth = calendar.startOfMonth(for: monthStart)
        let firstWeekday = calendar.component(.weekday, from: normalizedMonth)
        let leadingDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: normalizedMonth) ?? normalizedMonth
        let maximumVisibleDate = calendar.endOfDay(for: maximumDate)

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            return SalesCalendarDay(
                date: date,
                isCurrentMonth: calendar.isDate(date, equalTo: normalizedMonth, toGranularity: .month),
                isEnabled: date <= maximumVisibleDate
            )
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? startOfDay(for: date)
    }

    func orderedVeryShortWeekdaySymbols() -> [String] {
        let symbols = veryShortStandaloneWeekdaySymbols
        let splitIndex = max(0, min(symbols.count, firstWeekday - 1))
        return Array(symbols[splitIndex...] + symbols[..<splitIndex])
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
    @State private var activeBoundary: SalesDateBoundary = .end
    @State private var displayedMonth: Date

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
        _draftStart = State(initialValue: startDate)
        _draftEnd = State(initialValue: endDate)

        let calendar = Calendar.current
        let maxMonth = calendar.startOfMonth(for: maximumDate)
        let latestLeadingMonth = calendar.date(byAdding: .month, value: -1, to: maxMonth) ?? maxMonth
        let preferredLeadingMonth = calendar.startOfMonth(for: startDate)
        _displayedMonth = State(initialValue: min(preferredLeadingMonth, latestLeadingMonth))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !usesSingleMonthCalendar {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("Pick exact start and end dates, preview the full span, then apply it everywhere in the app.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                boundaryCard(.start)
                                boundaryCard(.end)
                            }

                            VStack(spacing: 12) {
                                boundaryCard(.start)
                                boundaryCard(.end)
                            }
                        }

                        rangeSummaryCard
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

                        calendarSection
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

    @ViewBuilder
    private var rangeSummaryCard: some View {
        if usesSingleMonthCalendar {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.salesGreen)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SaneSalesDateRangeStore.summaryLabel(for: .custom, customStart: draftStart, customEnd: draftEnd))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text("\(SaneSalesDateRangeStore.dayCount(in: normalizedInterval)) days")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textMuted)
                    }
                    Spacer(minLength: 0)
                }

                Text(activeBoundary.helperCopy)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.salesGreen)
                VStack(alignment: .leading, spacing: 4) {
                    Text(SaneSalesDateRangeStore.summaryLabel(for: .custom, customStart: draftStart, customEnd: draftEnd))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(SaneSalesDateRangeStore.dayCount(in: normalizedInterval)) days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                }
                Spacer()
                Text(activeBoundary.helperCopy)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 220, alignment: .trailing)
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("Calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    shiftDisplayedMonths(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(SaneActionButtonStyle())
                .accessibilityLabel("Previous Month")
                .accessibilityIdentifier("customRange.previousMonth")

                Button {
                    shiftDisplayedMonths(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(SaneActionButtonStyle())
                .disabled(!canMoveForward)
                .opacity(canMoveForward ? 1 : 0.45)
                .accessibilityLabel("Next Month")
                .accessibilityIdentifier("customRange.nextMonth")
            }

            ViewThatFits(in: .horizontal) {
                if !usesSingleMonthCalendar {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(visibleMonths, id: \.self) { month in
                            monthCard(for: month)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(visibleMonths, id: \.self) { month in
                        monthCard(for: month)
                    }
                }
            }
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

    private var normalizedInterval: DateInterval {
        SaneSalesDateRangeStore.normalizedInterval(start: draftStart, end: draftEnd, maximumDate: maximumDate)
    }

    private var visibleMonths: [Date] {
        if usesSingleMonthCalendar {
            return [displayedMonth]
        }

        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)
        if let nextMonth {
            return [displayedMonth, nextMonth]
        }
        return [displayedMonth]
    }

    private var latestLeadingMonth: Date {
        let calendar = Calendar.current
        let maximumMonth = calendar.startOfMonth(for: maximumDate)
        if usesSingleMonthCalendar {
            return maximumMonth
        }
        return calendar.date(byAdding: .month, value: -1, to: maximumMonth) ?? maximumMonth
    }

    private var usesSingleMonthCalendar: Bool {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
#else
        false
#endif
    }

    private var canMoveForward: Bool {
        displayedMonth < latestLeadingMonth
    }

    private func shiftDisplayedMonths(_ delta: Int) {
        let calendar = Calendar.current
        guard let shifted = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else {
            return
        }
        displayedMonth = clampedLeadingMonth(shifted)
    }

    private func clampedLeadingMonth(_ candidate: Date) -> Date {
        let normalizedCandidate = Calendar.current.startOfMonth(for: candidate)
        return min(normalizedCandidate, latestLeadingMonth)
    }

    private func monthCard(for month: Date) -> some View {
        let calendar = Calendar.current
        let days = SalesCalendarBuilder.days(for: month, maximumDate: maximumDate, calendar: calendar)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return VStack(alignment: .leading, spacing: 12) {
            Text(SalesCalendarFormatters.monthTitle.string(from: month))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("customRange.month.\(SalesCalendarFormatters.accessibilityIdentifier.string(from: month))")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(calendar.orderedVeryShortWeekdaySymbols().enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textMuted)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("customRange.weekday.\(index)")
                }

                ForEach(days) { day in
                    dayCell(day)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.salesPanelStroke, lineWidth: 1)
                )
        )
    }

    private func dayCell(_ day: SalesCalendarDay) -> some View {
        let highlight = highlightPosition(for: day.date)
        let isToday = Calendar.current.isDateInToday(day.date)
        let isEndpoint = highlight == .single || highlight == .start || highlight == .end
        let textColor: Color = {
            if isEndpoint { return .white }
            if day.isEnabled { return day.isCurrentMonth ? .white : Color.textMuted }
            return .white
        }()

        return Button {
            guard day.isEnabled else { return }
            update(activeBoundary, with: day.date)
        } label: {
            ZStack {
                SalesRangeDayHighlight(position: highlight)

                if isToday, highlight == .none {
                    Capsule()
                        .stroke(Color.salesGreen.opacity(0.45), lineWidth: 1)
                        .frame(width: 34, height: 30)
                }

                Text(SalesCalendarFormatters.dayNumber.string(from: day.date))
                    .font(.system(size: 14, weight: isEndpoint ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("customRange.day.\(SalesCalendarFormatters.accessibilityIdentifier.string(from: day.date))")
        .accessibilityValue(day.isEnabled ? "Available" : "Unavailable")
    }

    private func highlightPosition(for date: Date) -> SalesRangeHighlightPosition {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: draftStart)
        let end = calendar.startOfDay(for: draftEnd)
        let day = calendar.startOfDay(for: date)

        guard day >= start && day <= end else {
            return .none
        }

        if day == start && day == end {
            return .single
        }
        if day == start {
            return .start
        }
        if day == end {
            return .end
        }
        return .middle
    }

    private func boundaryCard(_ boundary: SalesDateBoundary) -> some View {
        let isActive = activeBoundary == boundary
        let value = boundary == .start ? draftStart : draftEnd

        return Button {
            activeBoundary = boundary
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(boundary.title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(isActive ? .white : Color.textMuted)
                Text(value.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(isActive ? "Tap a day below to update this boundary" : "Switch focus to edit this boundary")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isActive ? Color.salesGreen.opacity(0.22) : Color.salesPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isActive ? Color.salesGreen.opacity(0.65) : Color.salesPanelStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("customRange.endpoint.\(boundary.rawValue)")
        .accessibilityValue(isActive ? "Active" : "Inactive")
    }

    private func update(_ boundary: SalesDateBoundary, with newValue: Date) {
        switch boundary {
        case .start:
            draftStart = newValue
            if draftStart > draftEnd {
                draftEnd = newValue
            }
        case .end:
            draftEnd = newValue
            if draftEnd < draftStart {
                draftStart = newValue
            }
        }
    }
}

private struct SalesRangeDayHighlight: View {
    let position: SalesRangeHighlightPosition

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                switch position {
                case .none:
                    EmptyView()
                case .single:
                    endpointHighlight(width: width)
                case .start:
                    trailingSpan(width: width)
                    endpointHighlight(width: width)
                case .middle:
                    Rectangle()
                        .fill(Color.salesGreen.opacity(0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                case .end:
                    leadingSpan(width: width)
                    endpointHighlight(width: width)
                }
            }
            .frame(width: width, height: proxy.size.height)
        }
    }

    private func endpointHighlight(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.salesGreen)
            .frame(width: min(max(32, width - 4), 38), height: 30)
    }

    private func trailingSpan(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: width / 2)
            Rectangle()
                .fill(Color.salesGreen.opacity(0.18))
                .frame(height: 30)
        }
    }

    private func leadingSpan(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.salesGreen.opacity(0.18))
                .frame(height: 30)
            Spacer(minLength: width / 2)
        }
    }
}
