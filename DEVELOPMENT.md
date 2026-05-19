# SaneSales Development Guide

> [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEVELOPMENT](DEVELOPMENT.md) · [PRIVACY](PRIVACY.md) · [SECURITY](SECURITY.md)

## Build

```bash
xcodegen generate
xcodebuild -scheme SaneSalesIOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme SaneSales -destination 'platform=macOS' build
```

## Test

```bash
xcodebuild -scheme SaneSales test -destination 'platform=macOS'
```

20 tests across 4 suites:
- **APITests** (4) — JSON:API parsing, date handling, unknown enum values
- **MetricsTests** (7) — Aggregation, filtering, product breakdown, date ranges
- **CacheTests** (5) — Round-trip caching, timestamps, clear
- **ProviderTests** (4) — Provider edge cases, refund handling, pagination

## Project Generation

Uses XcodeGen. After modifying `project.yml`:
```bash
xcodegen generate
```

**WARNING: XcodeGen overwrites entitlements.** Running `xcodegen generate` resets `Widgets/SaneSalesWidgets.entitlements` to an empty `<dict/>`. After regenerating, restore the entitlements:
```bash
git checkout Widgets/SaneSalesWidgets.entitlements
```

## Demo Mode

Launch with `--demo` to load realistic fake data (fictional "Pixel Studio" indie studio with 4 products across all 3 providers):

```bash
# macOS
xcodebuild -scheme SaneSales -destination 'platform=macOS,arch=arm64' build
./build/Build/Products/Debug/SaneSales.app/Contents/MacOS/SaneSales --demo

# iOS Simulator
xcrun simctl launch booted com.sanesales.app -- --demo
```

Or set UserDefaults programmatically:
```bash
defaults write com.sanesales.app demo_mode -bool true
```

Demo data is defined in `Core/DemoData.swift`. Used for App Store screenshots and previews.

## Marketing Video Capture

Use the global SaneProcess marketing video SOP in
`~/SaneApps/infra/SaneProcess/DEVELOPMENT.md` before creating or publishing a
SaneSales product video.

SaneSales-specific rules:

- Capture from the Mini when app runtime or simulator state is involved.
- Use Pro/test state for all marketing clips: pass `--force-pro-mode` through
  `EXTRA_APP_ARGS` for screenshot/video capture scripts.
- Use the official SaneSales logo asset for all video and website marketing
  lockups: `docs/images/branding.png`. Do not draw substitute `$` icons,
  generic symbols, or placeholder wordmarks in generated assets.
- For generated video logo lockups, use the larger official app icon source at
  `Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png` and key out
  the baked-in dark square so the logo blends into the Sane blue background with
  no hard rectangular edges.
- Keep launch-video slides on a consistent composition grid: SaneSales lockup at
  the same top-left position, headline/body/CTA stacked in a stable left column,
  and product proof/devices on the right. Do not make the viewer relearn where
  to look on every transition.
- Story order is a blocker, not polish. If the opener names privacy/data-mining
  or subscription pain, the next slide must answer it with SaneSales' privacy and
  pay-once position before moving into device walkthroughs.
- Text-heavy slides must not crossfade into other text-heavy slides. Use cuts or
  single-slide fade-in/fade-out so adjacent headings can never composite into an
  unreadable overlap during transition frames.
- Do not use rounded filled highlight pills for non-clickable video labels; they
  read like buttons. Use Sane teal/cyan text callouts with a simple accent rule,
  and avoid one-off yellow/blue highlight colors that do not match the SaneApps
  palette.
- Before rendering final sales copy, classify every line as `Problem`,
  `Benefit`, `Proof`, or `CTA`. If a line is only implementation detail,
  operations trivia, or defensive engineering copy, cut it. Examples that do
  not belong in buyer-facing video copy: license-check mechanics, provider-key
  storage mechanics, backend/server implementation labels, and internal product
  plumbing.
- Avoid contradictory shorthand like `private tracking`. Use benefit-first copy
  such as `Track sales privately.` and put each short statement on its own
  deliberate line instead of relying on automatic wrapping.
- Do not show locked, Basic, onboarding, permission-dialog, stale price, or
  popup frames in launch videos.
- Mac screenshots and Watch recent-sales screenshots are curated website/video
  inputs until their capture path has passed visual review. Automated capture
  can pick up macOS permission prompts or stale demo names, so do not blindly
  sync those frames into `docs/images`.
- Watch marketing captures must use the Pro-aware Watch path. `--force-pro-mode`
  must remove `Demo data`/locked language from Watch screenshots and clips.
- Revenue charts must show believable variation. A flat sales chart is a blocker
  unless the script explicitly labels the point as steady revenue.
- Every chart-bearing website/video source must be inspected at full resolution,
  not only through a contact sheet. The builder now fails `screenshot-mac-dashboard.png`,
  `screenshot-ipad-dashboard.png`, or `screenshot-iphone-dashboard.png` when the
  visible green bars are missing or too flat.
- The launch-week website video is embedded from:
  `docs/videos/sanesales-launch-week-pro-all-devices.mp4`
- The poster image is:
  `docs/images/sanesales-launch-video-poster.png`
- The repeatable launch-week video builder is:
  `python3 scripts/build_launch_video.py`
- The launch-week music source is repo-local:
  `Videos/pulse-ledger.mp3`. The builder loops, trims, normalizes, and fades it
  to the exact final video duration; do not depend on a Downloads-only audio
  file for a publishable rebuild.
- Working video artifacts live under `Videos/`; keep a source contact sheet and
  sampled final-video contact sheet with the MP4.
- Full-size review is mandatory for every rendered slide and representative
  transition-boundary frames. A contact sheet is only navigation; it is not visual
  approval for copy, spacing, or overlaps.

Minimum checks before publishing:

```bash
bash -n scripts/capture_appstore_screenshots.sh
bash -n scripts/capture_demo_videos.sh
python3 scripts/build_launch_video.py
ffprobe -v error -show_entries format=duration,size:stream=codec_type,codec_name,width,height,avg_frame_rate -of json Videos/<final>.mp4
for t in 1 8 15 22 29 36 43 50; do ffmpeg -y -ss "$t" -i Videos/launch-week-pro-all-devices.mp4 -frames:v 1 "/tmp/sanesales-video-full-$t.png"; done
```

For a fresh app UI capture, run `scripts/capture_appstore_screenshots.sh` on the
Mini before the builder. `bash -n` is only a syntax check; it does not prove the
captured frames are clean.

Also run an OCR/banned-term pass over final slides/frames for `Unlock Pro`,
`Basic`, `Demo data`, stale prices, permission prompts, other SaneApps product
names, and debug/internal text. Full-frame inspect the hero, chart, iPad, Watch,
privacy, and CTA slides; the contact sheet alone is not enough because it can
hide clipped text and overlap.

Distribution notes:

- The canonical website/social video is intentionally longer than App Store
  preview limits. Do not try to upload `launch-week-pro-all-devices.mp4` to App
  Store Connect as-is; create separate 15-30s device/display-specific app
  previews first.
- Product Hunt and G2 need a YouTube/Vimeo-style hosted video URL. The raw
  `sanesales.com/videos/...mp4` file is still the canonical website asset, but
  it is not enough for those directory video slots.
- For X posting, prefer `x-post.py --text-file /tmp/tweet.txt` for any launch
  copy containing prices. Shell double quotes can expand `$9.99` before the
  posting tool sees it; the tool now blocks `.99` without `$` as a guard.

## Website Brand QA

Before publishing website changes, compare the first viewport against the current
SaneApps product pages (`SaneBar`, `SaneClip`, `SaneClick`, `SaneHosts`) and the
brand docs in `~/SaneApps/meta/Brand/`.

SaneSales-specific checks:

- Hero headline follows the family pattern: `Bring Sanity to your Sales Tracking`.
- Above the fold stays simple: product logo/name, one concise tagline, privacy /
  no-subscription / transparent-code trust badges, and clear download/purchase
  CTAs.
- Do not put dense pricing tables, long privacy/server explanations, Homebrew
  commands, or SaneApps-family copy in the first viewport.
- Privacy proof should be strong but human: sales data, customers, orders,
  products, refunds, and provider keys are never sent to SaneApps.
- The page must include both direct Mac download and App Store iPhone/iPad paths
  when the App Store listing is live. Keep the `data-appstore-ios-link` marker so
  website deploy preflight can verify it.
- Hero animation must be legible at first paint. Do not hide primary copy with
  `opacity: 0` while delayed animations wait to start.
- Use the Mini Playwright runtime for final website smoke checks when possible.
  The expected Mini setup is `npm install -g playwright@1.60.0` plus
  `npx playwright install chromium`; run custom Node checks with
  `NODE_PATH=$(npm root -g)`.

## Adding a New Provider

1. Create `Core/Services/NewProvider.swift` — implement `SalesProvider` protocol as an actor
2. Add keychain account constant to `KeychainService.swift`
3. Add provider field and configuration to `SalesManager.swift`
4. Add connection UI to `SettingsView.swift`

## API Key for Testing

The LemonSqueezy key is in macOS Keychain (service: `lemonsqueezy`, account: `api_key`). The app stores its own copy under `com.sanesales.app` / `lemonsqueezy-api-key` when the user connects via Settings.

## Shared Infrastructure (SaneProcess)

The macOS target includes shared files from `SaneProcess/shared/`:

- **`MoveToApplications.swift`** — `SaneAppMover.moveToApplicationsFolderIfNeeded()` prompts direct-download users to move the app to /Applications on first launch. Called in `applicationDidFinishLaunching` wrapped in `#if !DEBUG && !APP_STORE`. Tries direct move first, falls back to AppleScript admin prompt.

These files are referenced via relative path in `project.yml` (`../../infra/SaneProcess/shared/`). Do NOT duplicate them — edit the shared source.

## Deployment Targets

- iOS 17.0 / macOS 14.0
- Swift 6 strict concurrency
- Sparkle for auto-updates (macOS only, stripped from App Store builds)
