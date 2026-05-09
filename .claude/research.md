# Research Cache

Persistent research findings for this project. Active target: roughly 200 lines.
Graduate verified findings to ARCHITECTURE.md, DEVELOPMENT.md, SESSION_HANDOFF.md,
Serena, memory graph, or issues before adding more research.

## Historical Research Compacted 2026-05-09
**Updated:** 2026-05-09 | **Status:** verified | **TTL:** 30d
**Source:** SESSION_HANDOFF.md, DEVELOPMENT.md, ARCHITECTURE.md, prior research cache
- Expired March and April App Store/review/pricing/layout findings were already promoted into `SESSION_HANDOFF.md`, app metadata, tests, release notes, and current source.
- The prior active cache included a pasted shell environment dump under the `OrdersListView split access control` topic; that was not useful research and was removed during compaction.
- Durable release history and operational state live in `SESSION_HANDOFF.md`; add only fresh unresolved research here.

## SaneSales setup refresh failure policy
**Updated:** 2026-05-09 | **Status:** verified | **TTL:** 30d
**Source:** local Mini verify failure in `Tests/APITests.swift` and local read of `Core/SalesManager.swift`
- Customer-facing bug family: SaneSales could say a provider was not connected even though credentials existed.
- Decision: keep the recovered behavior because it directly covers the customer report. A refresh error should block setup completion only when there is an actual error and no usable orders/products.
- If cached/loaded usable content exists, the app should not present the connection as failed.

## SaneSales source-reading tests
**Updated:** 2026-05-06 | **Status:** verified | **TTL:** 30d
**Source:** local Mini `./scripts/SaneMaster.rb verify` failure, existing `Tests/SettingsSourceTests.swift` source-reading tests, local repo path inspection
- Xcode's test process working directory is not guaranteed to be the SaneSales repo root.
- Tests that read source files must derive the project root from `#filePath`, then read files through `projectRoot.appendingPathComponent(...)`.
- This keeps verify independent of the test runner working directory.

## SaneSales trial defaults domain
**Updated:** 2026-05-05 | **Status:** verified | **TTL:** 30d
**Source:** local Mini re-read of `Core/SaneSalesTrialPolicy.swift` and `Core/Services/SharedStore.swift`
- Production trial state defaults to `SharedStore.userDefaults()`, which resolves to the app-group suite `group.com.sanesales.app` when available.
- Seeding `UserDefaults.standard` in tests does not affect `SalesManager.refresh()` trial re-evaluation.
- Regression tests that need existing/expired trial state must write `SaneSalesTrialPolicy.trialStartedAtKey` into `SharedStore.userDefaults()` or pass an explicit suite into `SaneSalesTrialPolicy` helpers.

## SaneSales trial expiry and 12-hour refresh
**Updated:** 2026-05-05 | **Status:** verified | **TTL:** 30d
**Source:** Apple `ScenePhase` / `Task.sleep` docs, local Mini audit
- `SalesManager.refresh()` is the enforcement boundary because manual refresh, foreground stale refresh, and periodic refresh all flow through it.
- Trial expiry must be re-evaluated before provider fetch, not only at app launch or license-change handlers.
- Keep paid/forced/demo inputs in `SalesManager`, re-run `SaneSalesTrialPolicy.ensureTrialStartedIfNeeded` before every refresh, block live fetch after expiry, and preserve the 12-hour app-level refresh loops plus active-scene stale refresh.

## SaneUI EventTracker dependency path
**Updated:** 2026-05-01 | **Status:** verified | **TTL:** 30d
**Source:** Mini `xcodebuild -showBuildSettings`
- SaneSales resolves SaneUI from `https://github.com/sane-apps/SaneUI.git @ main (df151bb)` in Xcode package resolution, not from the local `~/SaneApps/infra/SaneUI` checkout during `./scripts/SaneMaster.rb verify`.
- App call sites must use the already-published `EventTracker.log("event", app:)` API until the SaneUI package update is committed, pushed, and resolved by each app.
- One-per-install behavior should be implemented with local UserDefaults markers in app code for this release.
