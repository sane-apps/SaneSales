import Foundation

enum SaneSalesTrialState: Equatable {
    case notStarted
    case active(startedAt: Date, expiresAt: Date, daysRemaining: Int)
    case expired(startedAt: Date, expiresAt: Date)

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    var isExpired: Bool {
        if case .expired = self { return true }
        return false
    }
}

enum SaneSalesTrialPolicy {
    static let durationDays = 7
    static let trialStartedAtKey = "sanesales.pro_trial.started_at"
    static let trialStartedBuildKey = "sanesales.pro_trial.started_build"

    static func ensureTrialStartedIfNeeded(
        defaults: UserDefaults = SharedStore.userDefaults(),
        now: Date = Date(),
        isPaidPro: Bool,
        hasConnectedProviders: Bool,
        demoModeEnabled: Bool,
        build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    ) -> SaneSalesTrialState {
        if isPaidPro || demoModeEnabled || !hasConnectedProviders {
            return state(defaults: defaults, now: now)
        }

        if defaults.object(forKey: trialStartedAtKey) == nil {
            defaults.set(now.timeIntervalSince1970, forKey: trialStartedAtKey)
            defaults.set(build, forKey: trialStartedBuildKey)
        }

        return state(defaults: defaults, now: now)
    }

    static func state(defaults: UserDefaults = SharedStore.userDefaults(), now: Date = Date()) -> SaneSalesTrialState {
        guard defaults.object(forKey: trialStartedAtKey) != nil else {
            return .notStarted
        }

        let startedAt = Date(timeIntervalSince1970: defaults.double(forKey: trialStartedAtKey))
        let expiresAt = Calendar.current.date(byAdding: .day, value: durationDays, to: startedAt)
            ?? startedAt.addingTimeInterval(TimeInterval(durationDays * 24 * 60 * 60))

        guard now < expiresAt else {
            return .expired(startedAt: startedAt, expiresAt: expiresAt)
        }

        let remainingSeconds = max(0, expiresAt.timeIntervalSince(now))
        let daysRemaining = max(1, Int(ceil(remainingSeconds / 86400)))
        return .active(startedAt: startedAt, expiresAt: expiresAt, daysRemaining: daysRemaining)
    }

    static func isTrialActive(defaults: UserDefaults = SharedStore.userDefaults(), now: Date = Date()) -> Bool {
        state(defaults: defaults, now: now).isActive
    }

    static func reset(defaults: UserDefaults = SharedStore.userDefaults()) {
        defaults.removeObject(forKey: trialStartedAtKey)
        defaults.removeObject(forKey: trialStartedBuildKey)
    }
}
