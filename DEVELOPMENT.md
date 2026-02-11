# SaneSales Development Guide

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

## Adding a New Provider

1. Create `Core/Services/NewProvider.swift` — implement `SalesProvider` protocol as an actor
2. Add keychain account constant to `KeychainService.swift`
3. Add provider field and configuration to `SalesManager.swift`
4. Add connection UI to `SettingsView.swift`

## API Key for Testing

The LemonSqueezy key is in macOS Keychain (service: `lemonsqueezy`, account: `api_key`). The app stores its own copy under `com.sanesales.app` / `lemonsqueezy-api-key` when the user connects via Settings.

## Shared Infrastructure (SaneProcess)

The macOS target includes shared files from `SaneProcess/shared/`:

- **`MoveToApplications.swift`** — `SaneAppMover.moveToApplicationsFolderIfNeeded()` prompts users to move the app to /Applications on first launch. Called in `applicationDidFinishLaunching` wrapped in `#if !DEBUG`. Tries direct move first, falls back to AppleScript admin prompt.

These files are referenced via relative path in `project.yml` (`../../infra/SaneProcess/shared/`). Do NOT duplicate them — edit the shared source.

## Deployment Targets

- iOS 17.0 / macOS 14.0
- Swift 6 strict concurrency
- Sparkle for auto-updates (macOS only, stripped from App Store builds)
