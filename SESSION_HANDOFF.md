# Session Handoff

> Last updated: 2026-02-10

## Session 1: Full Project Scaffold

### Done
1. **Complete app built** — 22 Swift files, iOS 17 + macOS 14, both platforms build clean
2. **LemonSqueezy integration** — Full JSON:API adapter with pagination, date parsing, error handling
3. **All tests pass** — 20/20 (API parsing, metrics aggregation, cache round-trip, provider edge cases)
4. **API verified** — Tested against live SaneApps data (160 orders, $785 total revenue)
5. **5-doc standard** — CLAUDE.md, README.md, DEVELOPMENT.md, ARCHITECTURE.md, SESSION_HANDOFF.md

### Architecture
- `SalesProvider` protocol → actors per platform (LemonSqueezy, Gumroad, Stripe)
- `SalesManager` (@MainActor @Observable) → central state coordinator
- `CacheService` → UserDefaults offline cache
- `KeychainService` → API key storage
- Shared SwiftUI views between iOS and macOS

## Session 2: Gumroad + Stripe Day-One Readiness

### Done
1. **Refund-aware revenue** — added `refundedAmount` + `netTotal`, metrics now use net-of-refunds where available
2. **Gumroad pagination** — follows `next_page_url` when fetching all sales
3. **Apple Silicon only** — macOS targets restricted to `arm64`; iOS Simulator excludes `x86_64`
4. **Compatibility testing** — tests pass on macOS (arm64) and iOS Simulator (26.2 + 26.0.1)

## Session 3: Website + UI Overhaul + v1.0 Release Builds

### Done
1. **Website rebuilt** — `docs/index.html` cloned from SaneBar template with SaneSales content
2. **Privacy page updated** — `docs/privacy.html` CSS matched to neutral color scheme
3. **SaneUI compliance** — Extensive UI overhaul (colors, SF Symbols, `.foregroundStyle` fixes)
4. **macOS v1.0 DMG created** — Developer ID signed, notarized, stapled
5. **iOS v1.0 archive created** — builds clean
6. **project.yml signing fixed** — All targets use automatic signing
7. **All 20 tests passing** across 4 suites

## Session 4: Glass UI, App Store Upload, LemonSqueezy, Ship Prep

### Done
1. **Glass UI overhaul (light mode)** — Switched all glass from `.regularMaterial` to `.ultraThinMaterial` with `Color.brandBlueGlow` tint overlays. Files: `DashboardView.swift`, `SalesCard.swift`, `OrdersListView.swift`, `ContentView.swift`. User approved: "good enough".
2. **Chart $600 label cutoff fixed** — Added `.padding(.top, 8)` before `.clipped()`, increased frame height from 200 to 220.
3. **Full screenshot set captured** — 20 screenshots (iPhone 6.7" + Mac, light + dark, 5 screens each) in `Screenshots/`.
4. **Widget App Store fixes** — Created `Widgets/SaneSalesWidgets.entitlements` with app-sandbox + network.client. Added `@main WidgetBundle` entry point to `SalesWidget.swift`. Wired entitlements in `project.yml` for both macOS and iOS widget extensions.
5. **iOS + macOS uploaded to App Store Connect** — Both builds successfully uploaded via `xcrun altool`. Universal purchase under single bundle ID `com.sanesales.app`.
6. **Notarized DMG built** — `release.sh` ran successfully. DMG uploaded to R2 bucket `sanesales-downloads`.
7. **Appcast.xml created** — v1.0 entry with EdDSA signature for Sparkle updates.
8. **Website deployed** — `docs/` deployed to Cloudflare Pages at sanesales.com.
9. **LemonSqueezy product live** — Product ID 822714, $6.99, published. Checkout UUID: `5f7903d4-d6c8-4da4-b3e3-4586ef86bb51`.
10. **Checkout Worker updated** — `go.saneapps.com/buy/sanesales` → LemonSqueezy checkout (verified 302 redirect). All 5 products confirmed working.
11. **saneapps.com updated** — SaneSales changed from "Coming Soon" to "Live" with link to sanesales.com. Deployed.
12. **Desktop wallpaper created** — `~/Desktop/Wallpapers/SaneSales.png` using feathered circular alpha mask on real app icon over navy gradient. User said "PERFECT!!!!". Method saved to Serena memory `wallpaper-generation-method`.
13. **SaneClick wallpaper created** — Same method, needs edge tweaking (icon edges brighter than gradient).
14. **Products config updated** — `infra/SaneProcess/config/products.yml` updated with checkout UUID, dist domain, appcast URL, type changed to `universal`.
15. **Git committed + pushed** — Two commits: `548accf` (v1.0 release prep) and `2b4cc55` (widget fixes).

### Commits This Session
- `548accf` — v1.0 release prep: website, glass UI overhaul, signing, demo data
- `2b4cc55` — fix: widget entry point and sandbox entitlements for App Store

### Known Issues
- **XcodeGen overwrites entitlements** — Running `xcodegen generate` resets `SaneSalesWidgets.entitlements` to empty `<dict/>`. Must restore content after regenerating.
- **SaneClick wallpaper** — Icon edge colors (rgba 26,39,68) don't blend as smoothly as SaneSales. Needs feather radius adjustment or gradient color-matching.

### Remaining To Ship

#### Blockers — ALL RESOLVED
- [x] **`dist.sanesales.com` working** — DNS + Cloudflare Worker + R2 bucket configured. DMG served correctly.
- [x] **App Store Connect metadata complete** — All metadata uploaded via ASC API (description, keywords, screenshots, pricing, privacy, review details).
- [x] **Submitted for App Store review** — Submission ID: `1373bfb1-83a5-4ae4-9cc0-17c6c463874d`. Status: **WAITING_FOR_REVIEW** (submitted 2026-02-10 23:15 UTC).

#### Non-Blockers
- [ ] **Uncommitted files** — `design-references/`, `docs/images/coin-symbol.png`, `docs/images/sanesales-background.html`, infra changes (sane-checkout.js, products.yml)
- [ ] **SaneClick wallpaper tweaking** — Edge blending not as clean as SaneSales
- [x] **Live validation** — LemonSqueezy verified against live data. Gumroad + Stripe keys confirmed present in Keychain.

### Infrastructure Changes (Outside This Repo)
- `infra/cloudflare-workers/sane-checkout.js` — Added `sanesales` entry
- `infra/SaneProcess/config/products.yml` — Updated SaneSales config
- `web/saneapps.com/index.html` — SaneSales changed to Live

## Session 5: App Store Submission + Documentation Audit

### Done
1. **App Store review submission** — Fixed all blockers (reviewer contact, app privacy, iPad screenshots), submitted for review
2. **iPad screenshots** — Booted iPad Pro 13" simulator, activated demo mode (`--demo`), captured 6 screenshots (3 light + 3 dark, 2048x2732)
3. **iPhone screenshot fix** — Re-uploaded stuck 04-products screenshot
4. **App Privacy** — Set "Data Not Collected" via ASC web portal (not available via API)
5. **Review detail** — Created with phone +1 212 555 0100, demoAccountRequired=false
6. **Demo mode on iPad** — Used `xcrun simctl launch -- --demo` to activate DemoData (fictional "Pixel Studio" store)
7. **14-perspective docs audit** — Full audit via free NVIDIA models (Mistral + DeepSeek), score 7.1/10
8. **Documentation updates** — SESSION_HANDOFF.md, README.md, DEVELOPMENT.md, docs/index.html all updated

### Key IDs
- Review Submission: `1373bfb1-83a5-4ae4-9cc0-17c6c463874d` (WAITING_FOR_REVIEW)
- iPad Screenshot Set: `71abe095-e9db-46fa-affd-fbd1a8447707`
- iPad Simulator UDID: `46EEDF7A-5C0E-419A-90CA-4652B8C735C8`

### Known Issues
- **XcodeGen overwrites entitlements** — Running `xcodegen generate` resets `SaneSalesWidgets.entitlements` to empty `<dict/>`. Must restore content after regenerating. (Also documented in DEVELOPMENT.md now.)

### Pending
- [ ] App Store review decision (WAITING_FOR_REVIEW)
- [ ] Shut down iPad simulator when no longer needed
- [ ] Uncommitted files from Session 4 still pending
