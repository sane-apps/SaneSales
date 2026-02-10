# SaneSales

Track your sales from LemonSqueezy, Gumroad, and Stripe — in one place.

## Features

- **Dashboard** — Today, this month, and all-time revenue at a glance
- **Orders** — Searchable, sortable order history with full details
- **Charts** — Revenue trends over time with Swift Charts
- **Products** — Per-product revenue breakdown with pie chart
- **Widgets** — Home screen and lock screen sales widgets
- **Offline** — Cached data shown instantly, refreshes in background
- **Multi-platform** — iOS, iPad, and macOS from a single codebase

## Supported Platforms

| Platform | Status |
|----------|--------|
| LemonSqueezy | v1.0 |
| Gumroad | v1.0 |
| Stripe | v1.0 |

## Requirements

- iOS 17.0+ / macOS 14.0+ (Apple Silicon only)
- Xcode 16+
- XcodeGen (`brew install xcodegen`)

## Setup

```bash
git clone https://github.com/sane-apps/SaneSales.git
cd SaneSales
xcodegen generate
open SaneSales.xcodeproj
```

## Privacy

Your API key is stored in the device Keychain. SaneSales communicates directly with platform APIs — no intermediary server, no data collection.

## License

Copyright 2026 SaneApps. All rights reserved.
