# SaneSales Architecture

> [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEVELOPMENT](DEVELOPMENT.md) · [PRIVACY](PRIVACY.md) · [SECURITY](SECURITY.md)

## Overview

```
┌──────────────────────────────────────────────┐
│  iOS / macOS App                             │
│  ┌────────────────────────────────────────┐  │
│  │  SwiftUI Views (shared iOS/macOS)      │  │
│  │  Dashboard · Orders · Charts · Products│  │
│  └──────────────┬─────────────────────────┘  │
│                 │                             │
│  ┌──────────────▼─────────────────────────┐  │
│  │  SalesManager (@MainActor @Observable) │  │
│  │  Central state + multi-provider coord  │  │
│  └──────┬──────────────┬──────────────────┘  │
│         │              │                     │
│  ┌──────▼──────┐ ┌─────▼──────┐              │
│  │ CacheService│ │ Providers  │              │
│  │ (offline)   │ │ (actors)   │              │
│  └─────────────┘ └────────────┘              │
│                       │                      │
│  ┌────────────────────▼───────────────────┐  │
│  │  SalesProvider Protocol                │  │
│  │  fetchOrders · fetchProducts · store   │  │
│  └────────────────────────────────────────┘  │
│         │              │            │        │
│  ┌──────▼──┐    ┌──────▼──┐  ┌─────▼────┐   │
│  │LemonSqzy│    │Gumroad  │  │Stripe    │   │
│  │(v1.0)   │    │(v1.0)   │  │(v1.0)    │   │
│  └─────────┘    └─────────┘  └──────────┘   │
└──────────────────────────────────────────────┘
```

## Key Decisions

### ADR-001: Provider Protocol Pattern
Each sales platform is an actor implementing `SalesProvider`. UI code never touches platform APIs directly — only `SalesManager` coordinates providers. Adding Gumroad/Stripe means implementing one actor, zero UI changes.

### ADR-002: Client-Side Aggregation
LemonSqueezy has no daily revenue breakdown endpoint. We fetch all orders and compute `SalesMetrics` client-side (today/MTD/all-time/daily/product). This is fast — 160 orders processes in <1ms.

### ADR-003: Offline-First with UserDefaults
`CacheService` (actor) stores last-fetched orders/products/store in UserDefaults. On launch, cached data shows immediately. Network refresh happens in background. "Last updated" badge shows data staleness.

### ADR-004: No Backend
API keys stored in device Keychain. Direct HTTPS to platform APIs. No proxy server, no account system, no data collection. Privacy by architecture.

### ADR-005: Shared Views
iOS and macOS share all SwiftUI views (`iOS/Views/`, `iOS/Components/`). Only entry points differ (`SaneSalesApp.swift` vs `SaneSalesMacApp.swift`). ~95% code shared.

## Data Flow

```
User taps refresh
  → SalesManager.refresh()
    → async let: fetchAllOrders + fetchProducts + fetchStore (parallel)
      → LemonSqueezyProvider.fetchOrders(page:) (paginated, sequential)
        → URLSession → JSON:API → Order mapping
    → SalesMetrics.compute(from: orders) — client-side aggregation
    → CacheService.cacheOrders() — persist for offline
  → @Observable triggers SwiftUI view updates
```

## LemonSqueezy API

- Base: `https://api.lemonsqueezy.com/v1`
- Auth: `Bearer {api_key}` + JSON:API content type headers
- Pagination: `page[number]` + `page[size]`, check `meta.page.lastPage`
- Rate limit: 300 req/min
- Dates: ISO 8601 with fractional seconds (`.000000Z`)

### Endpoints Used
| Endpoint | Purpose |
|----------|---------|
| `GET /v1/stores` | Store name, total/30-day revenue |
| `GET /v1/orders` | All orders (paginated) |
| `GET /v1/products` | Product catalog |
