# SaneSales Agent Instructions

Follow `~/AGENTS.md` first (cross-LLM policy source of truth). This file carries SaneSales-specific facts.

Philosophy: `~/SaneApps/meta/Brand/NORTH_STAR.md`

## What Is This

Universal indie sales tracker. iOS + macOS. Tracks revenue from LemonSqueezy, Gumroad, and Stripe. Free MIT app: setup stays, every feature stays unlocked, Buy is Donate.

## Source Of Truth

- Product behavior and setup: `README.md`
- Development workflow: `DEVELOPMENT.md`
- Architecture: `ARCHITECTURE.md`
- Current session context: `SESSION_HANDOFF.md`

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

## Build & Test (Mini-first)

- Canonical route: run `ruby scripts/SaneMaster.rb verify` on the Mac Mini (build + tests). `xcodegen generate` regenerates the `.xcodeproj` from `project.yml`.
- Local Xcode builds on the Air are an explicitly-approved fallback only.

| Target | Platform | Type |
|--------|----------|------|
| SaneSales | macOS 14+ | App |
| SaneSalesIOS | iOS 17+ | App |
| SaneSalesWidgets | macOS | Widget Extension |
| SaneSalesIOSWidgets | iOS | Widget Extension |
| SaneSalesTests | macOS | Unit Tests |
| SaneSalesIOSTests | iOS | Unit Tests |

## API Keys

Do not ask the user for provider API keys — they are already provisioned.

App keychain (runtime, under service `com.sanesales.app`):
- `lemonsqueezy-api-key` — LemonSqueezy API key
- `gumroad-api-key` — Gumroad API key
- `stripe-api-key` — Stripe secret key

Dev-secret lookup (testing/validation) uses the shared resolver order: env var → `~/.config/nv/env` → keychain (see `~/AGENTS.md` preferred-secret-path rule).
