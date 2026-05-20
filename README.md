<div align="center">

# SaneSales

### Bring Sanity to Your Sales Tracking

**Private revenue tracking for indie sellers using Lemon Squeezy, Gumroad, and Stripe**

[![GitHub stars](https://img.shields.io/github/stars/sane-apps/SaneSales?style=flat-square)](https://github.com/sane-apps/SaneSales/stargazers)
[![License: PolyForm Shield](https://img.shields.io/badge/License-PolyForm%20Shield-blue.svg?style=flat-square)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14.0+-blue?style=flat-square)](https://sanesales.com)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue?style=flat-square)](https://sanesales.com)
[![Price](https://img.shields.io/badge/Launch_Offer-60%25_off-green?style=flat-square)](https://sanesales.com)
[![Privacy: No SaneApps Cloud](https://img.shields.io/badge/Privacy-No%20SaneApps%20Cloud-success?style=flat-square)](PRIVACY.md)
[![Listed on macOS apps list](https://img.shields.io/badge/Listed%20on-macOS--apps--list%20(40k%E2%98%85)-black?style=flat-square)](https://github.com/serhii-londar/open-source-mac-os-apps)

> **Launch week:** SaneSales Pro is **$9.99** with code **SANE60** through **May 21, 2026**. Normally **$24.99**. One-time purchase. No subscription.

</div>

---

## The Problem

You sell on more than one storefront. Every morning you check three dashboards, copy numbers into a spreadsheet, and try to answer: *"What sold today, and how are we actually doing?"*

- Lemon Squeezy has your licenses
- Gumroad has your digital products
- Stripe has your subscriptions
- Your spreadsheet is already out of date

## The Solution

SaneSales pulls your sales data from all three platforms into one private native app for Mac, iPhone, iPad, and Apple Watch. Demo data is available immediately; Pro unlocks live provider connections. Revenue, orders, products, charts, widgets, menu bar totals, and export stay on your device.

| | |
|---|---|
| **Revenue Dashboard** | Today, 7-day, 30-day, custom-range, and all-time revenue at a glance with trend indicators |
| **Interactive Charts** | Daily revenue charts with Swift Charts across quick presets and custom date ranges |
| **Product Breakdown** | Donut chart showing revenue by product. Tap segments to explore |
| **Refund-Aware Revenue** | Net totals that deduct refunds automatically — no more overstated numbers |
| **Order Tracking** | Search by customer, product, or amount. Filter by provider, status, or date |
| **CSV Export** | Export your full order history for accounting or email marketing |
| **Widgets + Watch Glance** | Glance at today's revenue from Home Screen, Lock Screen, or Apple Watch Smart Stack |
| **macOS Menu Bar** | See today's revenue in the menu bar. Right-click for quick actions |
| **iCloud Keychain Sync** | Provider keys sync through your Apple ID. SaneApps never receives your sales data, customers, products, orders, revenue, or API keys |

---

## Current Release

**Current direct-download release: 1.3.5**

- Keeps connected providers connected when a first refresh has no sales data yet
- Prevents setup from reappearing after valid credentials have been saved
- Preserves the 1.3.3 dashboard, chart scaling, no-orders, and Apple Watch snapshot refinements

---

## Supported Providers

| Provider | Revenue | Orders | Products | Refunds | Pagination |
|----------|:-------:|:------:|:--------:|:-------:|:----------:|
| **Lemon Squeezy** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Gumroad** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Stripe** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Why Not Just Use Baremetrics or ChartMogul?

They're cloud SaaS dashboards built for teams that want billing analytics in a browser. That means:

- **Your revenue data lives on their servers** — every sale, every customer, every refund, stored and processed by a third party
- **They are priced like SaaS tools** — monthly analytics bills add up fast when you only need to read your own sales numbers
- **No native app** — another browser tab to check when you want a quick read
- **No offline access** — no internet, no data

SaneSales is the opposite:

| Feature | SaneSales | Baremetrics | ChartMogul | Spreadsheets |
|---------|:---------:|:-----------:|:----------:|:------------:|
| **Multi-provider** | ✅ LemonSqueezy + Gumroad + Stripe | Cloud integrations | Cloud integrations | Manual |
| **LemonSqueezy support** | ✅ | ❌ | ❌ | Manual |
| **Gumroad support** | ✅ | ❌ | ❌ | Manual |
| **Refund-aware revenue** | ✅ Net after refunds | ✅ | ✅ | Manual |
| **Native iOS + macOS** | ✅ | Web only | Web only | ❌ |
| **Home screen widgets** | ✅ | ❌ | ❌ | ❌ |
| **Menu bar revenue** | ✅ | ❌ | ❌ | ❌ |
| **Your data stays on YOUR device** | ✅ | ❌ Their cloud | ❌ Their cloud | Local |
| **No subscription** | **$9.99 with SANE60 through May 21, 2026. Regular $24.99.** | $75+/mo | Free tier, then $59+/mo | Free |
| **100% Transparent Code** | PolyForm Shield | ❌ | ❌ | N/A |

> **Private, native, and one-time priced.** SaneSales keeps your sales data on your devices and gives you dashboard views, order history, exports, widgets, and menu bar revenue without a monthly SaaS bill. **[Get SaneSales ->](https://sanesales.com)**

---

## Download

**One-time purchase. No subscription. Works on iPhone, iPad, and Mac.**

**[Download from sanesales.com](https://sanesales.com)** — free demo, with live data unlocked by Pro. Direct SaneSales Pro is **$9.99** with code **SANE60** through **May 21, 2026**; regular price is **$24.99**.

Also available on the iOS and Mac App Store.

> Pay once. Keep the full Pro dashboard. No subscription.

Or [build from source](#development) — it's PolyForm Shield licensed, always will be.

**Requirements:** iOS 17+ / macOS 14+ &middot; Apple Silicon (arm64) only

---

## How It Works

1. **Connect** — Paste your API key from LemonSqueezy, Gumroad, or Stripe
2. **Sync** — SaneSales fetches your orders, products, and revenue directly from the provider APIs
3. **Track** — See everything in one dashboard with charts, shared date ranges, search, and export

API keys are stored in iCloud Keychain so your own Apple devices can reconnect automatically. Sales data is cached locally for offline access. Nothing is ever transmitted to SaneApps servers.

---

## Privacy

**No private data collected. SaneSales never sends your sales data, orders, customers, products, or API keys to SaneApps servers.**

- No accounts, no sign-up, no email required
- A few simple anonymous app counts may be sent, such as Basic vs Pro launches or locked-feature views
- API keys stored in iCloud Keychain for your own Apple devices
- Direct communication with provider APIs — no intermediary server
- Sales data cached on-device only
- 100% transparent code — [verify yourself](https://github.com/sane-apps/SaneSales)

Full policy: [sanesales.com/privacy](https://sanesales.com/privacy.html)

---

## Development

```bash
# Clone the repo
git clone https://github.com/sane-apps/SaneSales.git
cd SaneSales

# Canonical SaneApps verification
./scripts/SaneMaster.rb verify
```

Use the shared wrapper for normal build/test verification so local checks match the release pipeline. See [DEVELOPMENT.md](DEVELOPMENT.md) for focused macOS, iOS, watchOS, and App Store debugging commands.

### Requirements

- macOS 14.0+ (Sonoma) / iOS 17.0+
- Xcode 16+
- Apple Silicon (arm64) only
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Architecture

```
Core/
  Models/          Order, Product, Store, SalesMetrics (Codable, Sendable)
  Services/        SalesProvider protocol, LemonSqueezy/Gumroad/Stripe actors
  SalesManager     @MainActor @Observable — central state coordinator

iOS/
  Views/           Shared SwiftUI views (iOS + macOS)
  Components/      SalesCard, GlassSection, badges, chart components

macOS/
  SaneSalesMacApp  macOS entry point, menu bar, activation policy
  MenuBarManager   Status item with revenue display + right-click menu

Widgets/           WidgetKit extensions (small, medium, accessory watch/lock-screen)
Tests/             Swift Testing (API parsing, metrics, cache, providers)
```

### Key Patterns

- `SalesProvider` protocol for all platform adapters
- Actors for network services, `@Observable` for state
- UserDefaults cache for offline mode
- Keychain for API keys (service: `com.sanesales.app`)
- Swift 6 strict concurrency

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed setup, demo mode, and conventions.

---

## Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Product overview and doc map |
| [ARCHITECTURE.md](ARCHITECTURE.md) | App structure and provider model |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Build, test, and workflow SOP |
| [PRIVACY.md](PRIVACY.md) | Canonical privacy policy for the app |
| [SECURITY.md](SECURITY.md) | Security policy and reporting |
| [`docs/`](docs/) | Public website, privacy page, and guide pages |

---

## Support

- **Email:** [hi@saneapps.com](mailto:hi@saneapps.com)
- **Bugs:** [Report a Bug](https://github.com/sane-apps/SaneSales/issues/new?template=bug_report.md)
- **Discussions:** [GitHub Discussions](https://github.com/sane-apps/SaneSales/discussions)

---

## License

[PolyForm Shield 1.0.0](https://polyformproject.org/licenses/shield/1.0.0) — free for any use except building a competing product. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with love in the USA by [Mr. Sane](https://github.com/MrSaneApps)**

**Not fear, but power, love, sound mind** — 2 Timothy 1:7

**[SaneBar](https://sanebar.com)** &middot; **[SaneClip](https://saneclip.com)** &middot; **[SaneHosts](https://sanehosts.com)** &middot; **[SaneSales](https://sanesales.com)** &middot; **[All Apps](https://saneapps.com)**

</div>

## Third-Party Notices

Third-party open-source attributions are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

<!-- SANEAPPS_AI_CONTRIB_START -->
### Become a Contributor (Even if You Don't Code)

Are you tired of waiting on the dev to get around to fixing your problem?  
Do you have a great idea that could help everyone in the community, but think you can't do anything about it because you're not a coder?

Good news: you actually can.

Copy and paste this into Claude or Codex, then describe your bug or idea:

```text
I want to contribute to this repo, but I'm not a coder.

Repository:
https://github.com/sane-apps/SaneSales

Bug or idea:
[Describe your bug or idea here in plain English]

Please do this for me:
1) Understand and reproduce the issue (or understand the feature request).
2) Make the smallest safe fix.
3) Open a pull request to https://github.com/sane-apps/SaneSales
4) Give me the pull request link.
5) Open a GitHub issue in https://github.com/sane-apps/SaneSales/issues/new?template=bug_report.md that includes:
   - the pull request link
   - a short summary of what changed and why
6) Also give me the exact issue link.

Important:
- Keep it focused on this one issue/idea.
- Do not make unrelated changes.
```

If needed, you can also just email the pull request link to hi@saneapps.com.

I review and test every pull request before merge.

If your PR is merged, I will publicly give you credit, and you'll have the satisfaction of knowing you helped ship a fix for everyone.
<!-- SANEAPPS_AI_CONTRIB_END -->
