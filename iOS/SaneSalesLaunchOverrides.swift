import Foundation

enum SaneSalesLaunchOverrides {
    private static let customRangeStartFlags = [
        "--custom-range-start",
        "--screenshot-custom-range-start"
    ]
    private static let customRangeEndFlags = [
        "--custom-range-end",
        "--screenshot-custom-range-end"
    ]

    static func applyPersistentUIState(
        arguments: [String] = CommandLine.arguments,
        userDefaults: UserDefaults = .standard,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        if let start = parsedDateArgument(in: arguments, flagNames: customRangeStartFlags, calendar: calendar),
           let end = parsedDateArgument(in: arguments, flagNames: customRangeEndFlags, calendar: calendar) {
            let normalized = SaneSalesDateRangeStore.normalizedInterval(
                start: start,
                end: end,
                maximumDate: now,
                calendar: calendar
            )

            userDefaults.set(TimeRange.custom.rawValue, forKey: SaneSalesDateRangeStore.selectedRangeKey)
            userDefaults.set(normalized.start.timeIntervalSince1970, forKey: SaneSalesDateRangeStore.customStartKey)
            userDefaults.set(normalized.end.timeIntervalSince1970, forKey: SaneSalesDateRangeStore.customEndKey)
        }

        #if DEBUG
            applyTrialStateOverride(arguments: arguments, userDefaults: userDefaults, now: now)
        #endif
    }

    #if DEBUG
        private static func applyTrialStateOverride(
            arguments: [String],
            userDefaults: UserDefaults,
            now: Date
        ) {
            let daysAgo: Int?
            if arguments.contains("--trial-expired") || arguments.contains("--screenshot-trial-expired") {
                daysAgo = SaneSalesTrialPolicy.durationDays + 1
            } else {
                daysAgo = parsedIntegerArgument(
                    in: arguments,
                    flagNames: ["--trial-started-days-ago", "--screenshot-trial-started-days-ago"]
                )
            }

            guard let daysAgo else { return }
            let startedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let defaultsTargets = [userDefaults, SharedStore.userDefaults()]
            for defaults in defaultsTargets {
                defaults.set(startedAt.timeIntervalSince1970, forKey: SaneSalesTrialPolicy.trialStartedAtKey)
                defaults.set("uitest", forKey: SaneSalesTrialPolicy.trialStartedBuildKey)
            }
        }

        private static func parsedIntegerArgument(in arguments: [String], flagNames: [String]) -> Int? {
            for flagName in flagNames {
                if let rawValue = value(for: flagName, in: arguments),
                   let parsed = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return parsed
                }
            }
            return nil
        }
    #endif

    private static func parsedDateArgument(
        in arguments: [String],
        flagNames: [String],
        calendar: Calendar
    ) -> Date? {
        for flagName in flagNames {
            if let value = value(for: flagName, in: arguments),
               let parsed = parseDate(value, calendar: calendar) {
                return parsed
            }
        }

        return nil
    }

    private static func value(for flagName: String, in arguments: [String]) -> String? {
        if let inlineValue = arguments.first(where: { $0.hasPrefix("\(flagName)=") })?
            .split(separator: "=", maxSplits: 1).last {
            return String(inlineValue)
        }

        if let index = arguments.firstIndex(of: flagName),
           arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }

        return nil
    }

    private static func parseDate(_ value: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
