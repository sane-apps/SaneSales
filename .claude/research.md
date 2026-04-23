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

## Pricing Upgrade Surface Research 2026-04-14
**Updated:** 2026-04-14 | **Status:** verified | **TTL:** 30d
**Source:** Apple docs for [`Settings`](https://developer.apple.com/documentation/swiftui/settings), StoreKit pricing display patterns, GitHub search for current SwiftUI + StoreKit upgrade CTA examples, local audit of `iOS/Views/ContentView.swift`, `iOS/Views/SettingsView.swift`, `iOS/Views/OrdersListView.swift`, and shared `infra/SaneUI/Sources/SaneUI/License/*`
- The shared pricing source of truth for SaneSales is `LicenseService.displayPriceLabel`, which already resolves the live StoreKit/App Store price when available and falls back to the approved one-time sticker price otherwise.
- SaneSales macOS already routes setup, upsell, and license settings through shared `SaneUI` surfaces, so the remaining drift was iOS-only.
- The iOS setup and upgrade path previously had three local `$24.99` strings in onboarding, settings, and locked-history upsell rows. Those are now patched to use `licenseService.displayPriceLabel` so App Store and future price changes stay centralized.
- The post-patch code-only audit shows no remaining non-doc/test hardcoded upgrade prices in SaneSales outside the single approved fallback label in `macOS/SaneSalesSettingsCopy.swift`.
- SaneBar still owns a local licensing layer instead of shared `SaneUI`, so it requires its own computed `displayPriceLabel`; onboarding and local pro-upsell views must read that property rather than embedding `$14.99` in view code.

## Verify Recovery After Pricing Sweep 2026-04-14
**Updated:** 2026-04-14 | **Status:** verified | **TTL:** 7d
**Source:** local Mini verify/build logs, local code audit, Swift docs search, GitHub search
- The first post-pricing Mini `verify --quiet` failure was not a real product bug. It was a Swift type-inference issue in `macOS/SaneSalesSettingsCopy.swift` where `LicenseSettingsView<LicenseService>.Labels(...)` needed an explicit type annotation plus `.init(...)`.
- After changing that declaration to `static let licenseLabels: LicenseSettingsView<LicenseService>.Labels = .init(...)`, the compile blocker was removed.
- The Mini project also needed the local-package sync: `project.yml` and `SaneSales.xcodeproj/project.pbxproj` had to point at the monorepo `../../infra/SaneUI` path on the Mini, otherwise `displayPriceLabel` changes in shared SaneUI would not be visible during app builds.
- Current runtime-pricing source of truth remains `licenseService.displayPriceLabel` for iOS upgrade CTAs, with the macOS settings copy providing only the approved fallback label if live price resolution is unavailable.

## Custom Date Range AppStorage Mutation 2026-04-23
**Updated:** 2026-04-23 | **Status:** verified | **TTL:** 7d
**Source:** Apple docs [`AppStorage`](https://developer.apple.com/documentation/SwiftUI/AppStorage), Apple docs [`Settings`](https://developer.apple.com/documentation/swiftui/settings), web search on Apple docs, GitHub binding examples, local SaneApps code search
- Apple’s `AppStorage` API explicitly exposes a `wrappedValue` and a projected `Binding`, which is the supported write path for SwiftUI views. The Settings docs also show controls writing `AppStorage` values through bindings rather than through computed-property setter indirection.
- Local compile failures in `OrdersListView` happened when a `View` method assigned through computed `Date` properties whose setters wrote to `@AppStorage`-backed timestamps. Swift treated those computed setters as mutating `self` on an immutable view instance.
- Local SaneApps patterns in `SaneUI` and other apps consistently use `Binding(get:set:)` or direct writes to the wrapped storage property for SwiftUI state changes, not computed-property setters on the view struct.
- GitHub binding examples reinforce the same model: when a view needs transformed state, keep the stored source of truth writable and expose derived values through `Binding(get:set:)` or direct wrapped-value writes.
- Safe fix for SaneSales: keep custom range dates as read-only computed views over the timestamp storage, and in action methods write `customRangeStartTimestamp` / `customRangeEndTimestamp` directly.

## [OrdersListView split access control] | Updated: 2026-04-23 | Status: verified | TTL: 30d
- After moving helper types out of OrdersListView.swift, integer 10 readonly !=0
integer 10 readonly '#'=0
integer 10 readonly '$'=42169
array readonly '*'=(  )
readonly -=569X
0=zsh
integer 10 readonly '?'=0
array readonly @=(  )
integer 10 readonly ARGC=0
tied cdpath CDPATH=''
integer 10 COLUMNS=0
CPUTYPE=arm64
integer 10 EGID=20
integer 10 EUID=501
tied fignore FIGNORE=''
tied fpath FPATH=/usr/local/share/zsh/site-functions:/usr/share/zsh/site-functions:/usr/share/zsh/5.9/functions
integer 10 FUNCNEST=700
integer 10 GID=20
HISTCHARS='!^#'
integer 10 readonly HISTCMD=0
integer 10 HISTSIZE=30
HOME=/Users/stephansmac
HOST=Stephans-Mac-mini.local
IFS=$'
\C-@'
KEYBOARD_HACK=''
integer KEYTIMEOUT=40
LANG=C.UTF-8
LC_ALL=C.UTF-8
LC_CTYPE=C.UTF-8
integer 10 readonly LINENO=1
integer 10 LINES=0
integer LISTMAX=100
LOGNAME=stephansmac
MACHTYPE=x86_64
integer MAILCHECK=60
tied mailpath MAILPATH=''
tied manpath MANPATH=''
tied module_path MODULE_PATH=/usr/lib/zsh/5.9
NULLCMD=cat
OLDPWD=/Users/stephansmac
OPTARG=''
integer 10 OPTIND=1
OSTYPE=darwin25.0
tied path PATH=/opt/homebrew/bin:/usr/local/bin:/Users/stephansmac/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin
integer 10 readonly PPID=42168
PROMPT=''
PROMPT2=''
PROMPT3='?# '
PROMPT4='+
## [OrdersListView split access control] | Updated: 2026-04-23 | Status: verified | TTL: 30d
- After moving helper types out of OrdersListView.swift, `private` on DateSection became too narrow because the enum now lives in a separate file. Swift access control treats `private` as declaration-scoped, while file-wide sharing needs broader visibility. Fix by widening DateSection to file default/internal (or fileprivate if staying within one file). Source: local compiler error + Swift access control docs index at docs.swift.org/swift-book/LanguageGuide/AccessControl.html.

## 2026-04-23
- topic: SalesDateRangePicker dense-layout getter
- summary:  needs an explicit  on the iOS path. The getter currently evaluates  as a bare expression, which works poorly across conditional compilation and triggers  during  in full verify. Fix by returning the expression explicitly after the dense-layout early exit.

## iPhone Tab Bar Opaqueness 2026-04-23
**Updated:** 2026-04-23 | **Status:** verified | **TTL:** 7d
**Source:** Apple docs UITabBarAppearance, Apple docs on SwiftUI toolbar backgrounds, GitHub code search for UITabBarAppearance + scrollEdgeAppearance + SwiftUI TabView, local Mini audit of iOS/Views/ContentView.swift, iOS/SaneSalesApp.swift, and refreshed screenshots
- Apple’s UIKit tab bar appearance API is the control surface that actually defines tab bar background treatment. configureWithOpaqueBackground() is the documented path when the bar should stop reading as transparent glass over live content.
- SwiftUI toolbarBackground for .tabBar helps request a visible background, but by itself it did not remove visible content bleed in the refreshed SaneSales iPhone screenshots.
- Current GitHub SwiftUI + TabView patterns consistently apply UITabBar.appearance().standardAppearance and scrollEdgeAppearance from app startup when they need a stable opaque tab bar background.
- Local Mini findings: the per-screen bottom inset patch improved spacing, but the remaining screenshot problem is shared tab chrome, not individual screen layout. The correct fix path is app-level UITabBarAppearance plus the existing TabView modifiers in iOS/Views/ContentView.swift.
- Local Mini re-read confirmed the current source line in iOS/SaneSalesApp.swift is now CommandLine.arguments.contains("--uitest-reset"); the earlier compile failure was from a stale broken edit before the line-level rewrite.
