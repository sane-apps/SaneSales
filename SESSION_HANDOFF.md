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
1. **Website rebuilt** — `docs/index.html` (1717 lines) cloned from SaneBar template with SaneSales content. Neutral dark backgrounds (#08080c, #0f0f16, #16161f), green accent (#34B062), all SaneBar structural elements (nav, hero, features, comparison table, donate/crypto, sustainability, cross-sell). NOT published yet — kept local per user request.
2. **Privacy page updated** — `docs/privacy.html` CSS matched to neutral color scheme
3. **SaneUI compliance** — Extensive UI overhaul from earlier in session (colors, SF Symbols, `.foregroundStyle` fixes)
4. **macOS v1.0 DMG created** — `/tmp/SaneSales-1.0.dmg` (3.5 MB), Developer ID signed, notarized, stapled, Gatekeeper accepted
5. **iOS v1.0 archive created** — `/tmp/SaneSales-iOS.xcarchive` builds clean, development IPA exported (4.4 MB)
6. **project.yml signing fixed** — All targets use `CODE_SIGN_STYLE: Automatic` with `Apple Development` for archive builds. Developer ID signing applied at export time via ExportOptions.plist.
7. **All 20 tests passing** across 4 suites

### Code Signing Notes
- **macOS Release workflow**: Archive with development signing → Export with `developer-id` method → Notarize + staple
- **iOS Release workflow**: Archive with development signing → Export needs App Store Connect record first
- Available certs: `Developer ID Application: Stephan Joseph (M78L6FXD48)` + `Apple Development: droog@protonmail.com`
- No `Apple Distribution` certificate on this machine — needed for iOS App Store/TestFlight
- Bundle IDs registered in Developer Portal: `com.sanesales.app`, `com.sanesales.app.ios`, `com.sanesales.app.ios.widgets`
- App record does NOT exist in App Store Connect yet (only SaneClip exists) — creating via API returned 403, needs manual creation in ASC web portal

### Build Artifacts (in /tmp/)
- `SaneSales-1.0.dmg` — macOS DMG, signed + notarized, ready for distribution
- `SaneSales-macOS.xcarchive` — macOS archive
- `SaneSales-iOS.xcarchive` — iOS archive
- `SaneSales-iOS-export/SaneSales.ipa` — Development IPA (4.4 MB)

### Next Steps
- [ ] **Create SaneSales app in App Store Connect** — must be done manually in web portal (API doesn't allow CREATE)
- [ ] **iOS TestFlight upload** — re-export archive with `app-store-connect` method after ASC record exists
- [ ] **Upload macOS DMG to Cloudflare R2** — `dist.sanesales.com` via `npx wrangler r2 object put --remote`
- [ ] **Publish website** — Deploy `docs/` to Cloudflare Pages (`npx wrangler pages deploy ./docs --project-name=sanesales-site`)
- [ ] **Connect sanesales.com domain** to Cloudflare Pages
- [ ] **App Store listing** — screenshots, description, pricing ($6.99 one-time)
- [ ] **Live validation** with Gumroad + Stripe API keys
- [ ] **Git commit** — website + signing changes not yet committed
