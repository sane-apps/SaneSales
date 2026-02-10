# SaneSales - Claude Code Instructions

> **Project Docs:** [CLAUDE.md](CLAUDE.md) · [README](README.md) · [DEVELOPMENT](DEVELOPMENT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [SESSION_HANDOFF](SESSION_HANDOFF.md)

## What Is This

Universal indie sales tracker. iOS + macOS. Tracks revenue from LemonSqueezy, Gumroad, and Stripe (v1.0).

## Quick Start

```bash
xcodegen generate                    # Generate .xcodeproj
xcodebuild -scheme SaneSalesIOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme SaneSales -destination 'platform=macOS,arch=arm64' build
xcodebuild -scheme SaneSales test -destination 'platform=macOS,arch=arm64'
```

## Architecture

- **Core/Models/** — `Order`, `Product`, `Store`, `SalesMetrics` (all Codable, Sendable)
- **Core/Services/** — `SalesProvider` protocol, `LemonSqueezyProvider` actor, `KeychainService`, `CacheService`
- **Core/SalesManager.swift** — `@MainActor @Observable`, central state coordinator
- **iOS/Views/** — SwiftUI views shared by iOS and macOS
- **macOS/** — macOS-specific entry point
- **Widgets/** — WidgetKit (small, medium, rectangular)
- **Tests/** — Swift Testing (API parsing, metrics, cache, providers)

## Conventions

- Follow SaneClip patterns (same repo family)
- `SalesProvider` protocol for all platform adapters
- Actors for network services, `@Observable` for state
- UserDefaults cache for offline mode
- Keychain for API keys (service: `com.sanesales.app`)
- iOS 17+ / macOS 14+ minimum
- Swift 6 strict concurrency

## API Keys

**ALL 3 API KEYS ARE ALREADY IN THE MACOS KEYCHAIN. DO NOT ASK THE USER FOR THEM.**

Dev machine keychain (for testing/validation):
- `lemonsqueezy` / `api_key` — LemonSqueezy API key (CONFIRMED PRESENT)
- `gumroad` / `api_key` — Gumroad API key (CONFIRMED PRESENT)
- `stripe` / `api_key` — Stripe secret key (CONFIRMED PRESENT)

App keychain (runtime, under `com.sanesales.app`):
- `lemonsqueezy-api-key` — LemonSqueezy API key
- `gumroad-api-key` — Gumroad API key
- `stripe-api-key` — Stripe secret key

## Build Targets

| Target | Platform | Type |
|--------|----------|------|
| SaneSales | macOS 14+ | App |
| SaneSalesIOS | iOS 17+ | App |
| SaneSalesWidgets | macOS | Widget Extension |
| SaneSalesIOSWidgets | iOS | Widget Extension |
| SaneSalesTests | macOS | Unit Tests |
| SaneSalesIOSTests | iOS | Unit Tests |
