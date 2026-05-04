# Session Handoff — SaneSales

**Last updated:** 2026-05-04
**Current version:** `1.3.0` (build `1300`) direct live; macOS App Store ready; iOS App Store waiting for review

## Current State

## 2026-05-04: Dashboard Latest Sale Visibility Fix

- Research confirmed current sales trackers avoid empty default dashboards by exposing latest/recent transaction activity and freshness cues alongside range-based charts.
- Added a compact `Latest Sale` dashboard section showing the newest paid order, timestamp, provider, product, and net amount even when the selected dashboard range would otherwise be empty.
- Basic gating remains intact: Basic still defaults to Today and keeps 7D/30D/All/Custom and charts/order-history depth behind Pro; Pro shows the same latest sale plus unlocked range/chart views.
- Mini verification: `./scripts/SaneMaster.rb verify` passed 56 tests; `./scripts/SaneMaster.rb verify --ui` passed 84 tests in 237s; `test_mode --release` and Basic launch mode passed.
- Visual verification: Mini-generated iPhone and iPad dashboard screenshots for Basic and Pro were inspected; the new section is visible, not crowded, and does not overlap the chart/upgrade sections.

## 2026-04-24: Product Hunt Readiness / Website Source Sync

- Product Hunt website audit found live `sanesales.com` was correct, but the Mini repo source had drifted behind the live site and still contained the old hero copy, duplicate locked Apple Watch website screenshots, stale spreadsheet download link, and `0% Telemetry` footer copy.
- Repo source was synced to the live-approved launch state: approved "Stop checking three dashboards..." hero, Dashboard-first screenshot carousel, product Watch screenshots with cache-busting, `No Subscriptions / 0% Spying / 100% On-Device` footer, support/crypto copy retained, and `sanesales-vs-spreadsheets.html` download link updated to `SaneSales-1.3.0.zip`.
- `docs/support.html` now uses the tracked `images/branding.png` asset instead of untracked `images/icon.png`.
- Mini HTML audit after the fix found `HTML_AUDIT_FAILURES=0`; `./scripts/SaneMaster.rb check_docs` and `./scripts/SaneMaster.rb saneui_guard .` passed.
- Fresh Mini visual audit screenshots were captured with Playwright after a 4-second animation delay: `/tmp/sanesales-audit-shots/home-desktop-delay.png` and `/tmp/sanesales-audit-shots/home-mobile-delay.png`. Desktop passed cleanly; mobile is usable, with the comparison table still horizontally scrollable on narrow screens.
- Mini `./scripts/SaneMaster.rb verify --ui` passed 83 tests in 214 seconds on 2026-04-24 after the parallel-run false failure was documented in `.claude/research.md`.
- App Store Connect check on 2026-04-24: macOS 1.3.0 is `READY_FOR_SALE`; iOS 1.3.0 is still `WAITING_FOR_REVIEW`; public lookup still returned iOS/public version 1.2.6.
- Remaining launch caveat: Lemon Squeezy hosted file for SaneSales still shows `SaneSales-1.2.7.zip` while appcast/website/webhook/Homebrew are at 1.3.0; replace the hosted file in the Lemon Squeezy dashboard before heavy Product Hunt traffic if direct buyers may use the hosted file.

## 2026-04-23: SaneSales 1.3.0 Released

- Added Pro custom date ranges with editable start/end dates and a calendar range picker.
- Dashboard and Orders now share the selected custom range and enforce Basic gating correctly.
- App Store entitlement refresh now picks up redeemed offer codes/restored purchases more reliably through shared SaneUI license refresh work.
- Updated App Store metadata, README, changelog, website copy, and website screenshots for the custom-range release.
- Refreshed canonical App Store screenshot files from the Mini-verified Pro screenshots.
- Mini verification: `./scripts/SaneMaster.rb verify --ui` passed with 83 tests on 2026-04-23.
- Release command verification: `./scripts/SaneMaster.rb release --full --version 1.3.0 --deploy` passed its built-in Mini verification lane with 55 tests before packaging.
- Direct channel is live at `https://dist.sanesales.com/updates/SaneSales-1.3.0.zip`; appcast, website JSON-LD, Homebrew cask, GitHub release `v1.3.0`, download redirect, and email webhook all verified at 1.3.0.
- App Store Connect state: macOS 1.3.0 and iOS 1.3.0 are both `WAITING_FOR_REVIEW`; previous public App Store versions remain live until Apple approval.
- Final release commits: `7a1fec7` version bump, `fd84491` release metadata sync. Both Mini and Air repos were synced to `fd84491`.

- Pricing rollout approved on 2026-04-14: direct and App Store copy should present `Basic free + Pro $24.99 once`. Keep StoreKit product ID `com.sanesales.app.pro.unlock.v2`.
- Pricing language should stay consistent across README, `docs/index.html`, long-tail guide CTAs, and in-app unlock fallbacks. No apology pricing copy and no subscription wording for the product itself.
- Track rollout impact with direct checkout conversion, App Store unlock rate, activation-to-paid conversion, and whether long-tail guide CTAs still pull traffic after the price increase.
- Use `CHANGELOG.md` and `project.yml` for the current release picture; the notes below capture older launch work only.
- The old `WAITING_FOR_REVIEW` summary at the top of the historical notes is not current anymore.
- Keep new handoff updates above the archival sections below.

## Archived Notes

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
6. **Notarized DMG built** — `release.sh` ran successfully. DMG uploaded to shared R2 bucket `sanebar-downloads`.
7. **Appcast.xml created** — v1.0 entry with EdDSA signature for Sparkle updates.
8. **Website deployed** — `docs/` deployed to Cloudflare Pages at sanesales.com.
9. **LemonSqueezy product live** — Product ID 822714, published. Checkout UUID: `5f7903d4-d6c8-4da4-b3e3-4586ef86bb51`.
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
- [ ] Uncommitted website changes in `docs/index.html` (trust badges + testimonials carousel)
- [ ] `DOCS_AUDIT_FINDINGS.md` and `SEO_AUDIT_FINDINGS.md` — audit artifacts, gitignore or delete

## Session 6: v1.2 Release + Pipeline-Wide Infrastructure Audit

> Last updated: 2026-02-11

### Done
1. **v1.2 released** — Fixed misleading API key error messages, auto-trim whitespace on paste. Built, signed, notarized, ZIP'd, Sparkle-signed.
2. **v1.2 deployed** — ZIP uploaded to shared R2 bucket, sane-dist Worker updated to accept .zip, appcast.xml updated, website deployed.
3. **Pipeline-wide infrastructure audit** — Fixed systemic config drift across ALL SaneApps:
   - All 7 `.saneprocess` files → `r2_bucket: sanebar-downloads` (shared bucket)
   - `release.sh` default bucket fixed
   - `wrangler.toml` rewritten with all 8 routes (added sanesync, sanevideo)
   - Email webhook `PRODUCT_CONFIG` updated to current versions for all 5 apps
   - Missing DNS records created for `dist.sanehosts.com`, `dist.sanesync.com`, `dist.sanevideo.com`
   - Worker routes created for sanesync and sanevideo domains
4. **Orphan infrastructure deleted** — 3 orphan R2 buckets (saneclick-dist, sanehosts-dist, sanesales-downloads) emptied and deleted. Legacy `sanebar-dist` Worker deleted.
5. **E2E verification** — 33/33 checks pass across all 7 dist domains
6. **Customer impact assessed** — 4 SaneHosts customers had broken webhook download links, but LemonSqueezy provides its own download at purchase — minimal real impact. SaneBar/SaneClip customers got stale versions but Sparkle auto-updates.
7. **All repos committed and pushed** — SaneClick, SaneHosts, SaneSync, sane-email-automation all pushed. SaneVideo committed locally (blocked by faraday CVE in pre-push hook).

### Commits
- `97dc5f7` — fix: improve API key error messages with specific error types
- `4cec689` — Bump version to 1.2 for release
- `3abcd22` — Add v1.2 to appcast for Sparkle auto-updates

### Key Lesson
Per-app R2 buckets were never wired to the sane-dist Worker — only `sanebar-downloads` was. This caused broken download links for SaneHosts customers and stale versions in webhook emails for all other apps. Now standardized: ONE shared bucket, ONE Worker, all apps upload to `sanebar-downloads`.
