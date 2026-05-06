# Privacy Policy

> [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEVELOPMENT](DEVELOPMENT.md) · [PRIVACY](PRIVACY.md) · [SECURITY](SECURITY.md)

**Last updated: May 6, 2026**

SaneSales is built to keep your sales data off SaneApps servers and your provider keys in Apple-managed Keychain storage.

## The Short Version

- Your sales data stays on your device.
- Your API keys are stored in iCloud Keychain so your own Apple devices can reconnect automatically when Apple Keychain sync is enabled.
- There is no SaneApps server in the middle for your provider data.
- The app may send a few simple anonymous app counts, such as whether it opened in Basic or Pro or whether a locked feature was viewed.
- The public website uses simple aggregate traffic stats.

## What Stays Local

- API keys stored in Apple Keychain, with iCloud Keychain sync available for your own Apple devices
- Cached sales data and settings stored on your device
- Searches, filters, dashboards, and exports

## Network Use

SaneSales uses network access only for:

- Direct API requests to LemonSqueezy, Gumroad, and Stripe after you configure them
- Sparkle update checks for direct-download macOS builds only
- A few simple anonymous app counts that do not include your API keys, orders, or revenue data

## Third-Party Services

- LemonSqueezy API, Gumroad API, and Stripe API: only if you connect them
- Apple iCloud Keychain: for syncing provider keys across your own Apple devices when enabled
- Sparkle: for direct-download macOS app updates only
- Cloudflare Web Analytics on the public website only

## Source of Truth

The public website privacy page at [docs/privacy.html](docs/privacy.html) should match this file. If they drift, update this file first and then sync the website copy.
