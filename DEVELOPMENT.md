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

16 tests across 3 suites:
- **APITests** (4) — JSON:API parsing, date handling, unknown enum values
- **MetricsTests** (7) — Aggregation, filtering, product breakdown, date ranges
- **CacheTests** (5) — Round-trip caching, timestamps, clear

## Project Generation

Uses XcodeGen. After modifying `project.yml`:
```bash
xcodegen generate
```

## Adding a New Provider

1. Create `Core/Services/NewProvider.swift` — implement `SalesProvider` protocol as an actor
2. Add keychain account constant to `KeychainService.swift`
3. Add provider field and configuration to `SalesManager.swift`
4. Add connection UI to `SettingsView.swift`

## API Key for Testing

The LemonSqueezy key is in macOS Keychain (service: `lemonsqueezy`, account: `api_key`). The app stores its own copy under `com.sanesales.app` / `lemonsqueezy-api-key` when the user connects via Settings.

## Deployment Targets

- iOS 17.0 / macOS 14.0
- Swift 6 strict concurrency
- No third-party dependencies
