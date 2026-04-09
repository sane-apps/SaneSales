# Research Cache

Persistent research findings for this project. Limit: 200 lines.
Graduate verified findings to ARCHITECTURE.md or DEVELOPMENT.md.

<!-- Sections added by research agents. Format:
## Topic Name
**Updated:** YYYY-MM-DD | **Status:** verified/stale/partial | **TTL:** 7d/30d/90d
**Source:** tool or URL
- Finding 1
- Finding 2
-->

## App Store Rejections 2026-03-23
**Updated:** 2026-03-23 | **Status:** verified | **TTL:** 7d
**Source:** Mini Safari App Store Connect pages + local code + [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Live ASC status on the Mini shows `iOS 1.2.3` rejected and `macOS 1.2.3` rejected.
- Apple guideline `2.1(b)` says in-app purchases must be complete, visible to the reviewer, and functional.
- Current iOS review notes tell Apple to use `Settings > License`, but `iOS/Views/SettingsView.swift` only includes `licenseSection` inside `#if os(macOS)`, so the iOS app does not actually expose that path.
- Current iOS onboarding is provider/API-key first, so the free vs Pro model is not clear enough for review.
- Prior macOS review message said `Show SaneSales` did nothing, matching the current `WindowActionStorage` reopen path as a risk area that still needs direct Mini verification.
- Apple guideline `2.4.5(vii)` says Mac App Store apps must use the Mac App Store for updates and other update mechanisms are not allowed.
- Current App Store target in `project.yml` does not depend on Sparkle, but App Store compliance still needs binary verification so review does not see stale update residue.

## Verify / App Store Preflight Failure 2026-03-26
**Updated:** 2026-03-26 | **Status:** verified | **TTL:** 7d
**Source:** Apple docs `Testing`, Mini xcodebuild logs, web search, GitHub search, local code
- Apple docs for [`Testing`](https://developer.apple.com/documentation/testing) confirm Swift Testing is the supported framework for Xcode projects on Xcode 16+ and does not require XCTest-style test declarations.
- Web examples of Swift Testing command-line output show the normal pattern `Executed 0 tests` followed by `Testing Library Version ...`, so that line by itself is not proof of failure.
- GitHub search for a known Swift Testing + `Executed 0 tests` failure mode did not find a relevant upstream issue; no strong external evidence points to Xcode itself being broken here.
- Local Mini `xcodebuild test -only-testing:SaneSalesTests` exits `65`, but the real failing signal is not the `Executed 0 tests` line. The actual failing check is `AppStoreReviewPathTests.saneSalesIosReviewNotesMatchCode` in `Tests/APITests.swift`.
- The current failing expectation is `tap "Unlock Pro" on onboarding`, but `.saneprocess` now says `tap "Unlock Pro" on the setup screen`, so the test drift is in our local review-note guardrail, not in the app code or Swift Testing runtime.
- The SaneSales iOS review lane rejection still matches the real reviewer complaint: Apple could not locate `SaneSales Pro Unlock`, so the onboarding/settings upgrade path still needs direct reviewer-language verification after the guardrail test is corrected.

## App Store Metadata Research 2026-03-26
**Updated:** 2026-03-26 | **Status:** verified | **TTL:** 7d
**Source:** Apple App Store product-page guidance, App Review guidance, Mini code audit, competitor App Store listing review
- Apple product-page guidance favors a short value-led subtitle, a description that opens with one clear sentence, and promotional text that stays customer-facing rather than drifting into review-note language.
- For finance / analytics apps, the clearest positioning is direct and literal: `read-only`, `demo data`, and `optional one-time Pro unlock` are stronger than vague `track revenue anywhere` language.
- App Review clarity for SaneSales depends on three things being explicit in both review notes and listing copy:
  - the app is for merchants with existing LemonSqueezy, Gumroad, or Stripe accounts
  - those external accounts are optional and do not unlock paid app features
  - the only paid in-app unlock is `SaneSales Pro`, sold as a one-time StoreKit purchase
- Added explicit IAP metadata instead of relying on defaults:
  - `display_name: "SaneSales Pro Unlock"`
  - `description: "Unlock Pro analytics with one purchase."`
- Updated listing direction:
  - both macOS and iOS now lead with `Read-Only Sales Dashboard`
  - descriptions start with the dashboard value, then separate Free from Pro in a simple feature list

## macOS Settings / Window Routing Research 2026-04-09
**Updated:** 2026-04-09 | **Status:** verified | **TTL:** 30d
**Source:** Apple docs for [`Settings`](https://developer.apple.com/documentation/swiftui/settings) and [`openWindow`](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/openWindow), GitHub examples/research around SwiftUI settings access, local audit of `macOS/SaneSalesMacApp.swift`, `macOS/MenuBarManager.swift`, and `Tests/SettingsSourceTests.swift`
- Apple’s current SwiftUI model is to define a `Settings` scene for macOS and use environment-driven window actions like `openWindow` to front or create windows. That is the stable modern path, not old selector-based preferences hacks.
- External GitHub research around SwiftUI settings access confirms legacy `NSApp.sendAction(showSettingsWindow:)` is brittle or removed in newer SwiftUI/macOS flows, especially around menu-bar-driven apps.
- Local SaneSales code now routes both Dock and menu bar `Settings…` entry points through `SettingsTabNavigationStorage.requestShowSettingsTab()`, which first fronts the main window and then posts the settings-tab notification.
- Local SaneSales code keeps `WindowActionStorage.showMainWindow()` as the single reopen/front path for status item clicks, Dock menu actions, and settings routing, reducing split behavior between window sources.
- Local regression coverage in `Tests/SettingsSourceTests.swift` checks that Dock and menu bar settings actions both use the shared settings-tab navigation path, so release verification should focus on live UI confirmation rather than adding more source-only tests.
