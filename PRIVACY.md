# Privacy Policy

> [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEVELOPMENT](DEVELOPMENT.md) · [PRIVACY](PRIVACY.md) · [SECURITY](SECURITY.md)

**Last updated: May 6, 2026**

SaneSales is built to keep your sales data off SaneApps servers and your provider keys in Apple-managed Keychain storage.

## The Short Version

- Your sales data stays on your device.
- Your API keys are stored in iCloud Keychain so your own Apple devices can reconnect automatically when Apple Keychain sync is enabled.
- There is no SaneApps server in the middle for your provider data.
- The app and website may send a few simple anonymous counts, such as whether the app opened in Basic or Pro, whether a locked feature was viewed, or whether a website download or purchase button was clicked.
- The public website may use cookie-free aggregate traffic stats and button-click counts.
- The SaneApps event counter does not use cookies, user IDs, advertising IDs, email addresses, sales data, API keys, page paths, or clicked URLs.
- SaneApps does not sell customer data to advertisers or data brokers.

## What Stays Local

- API keys stored in Apple Keychain, with iCloud Keychain sync available for your own Apple devices
- Cached sales data and settings stored on your device
- Searches, filters, dashboards, and exports

## Network Use

SaneSales uses network access only for:

- Direct API requests to LemonSqueezy, Gumroad, and Stripe after you configure them
- Sparkle update checks for direct-download macOS builds only
- A few simple anonymous app and website counts that do not include your API keys, orders, revenue data, name, email address, page path, clicked URL, advertising identifier, or cross-site tracking identifier

## Third-Party Services

- LemonSqueezy API, Gumroad API, and Stripe API: only if you connect them
- Apple iCloud Keychain: for syncing provider keys across your own Apple devices when enabled
- Sparkle: for direct-download macOS app updates only
- SaneApps distribution service: anonymous app and website button-click counts only
- Cloudflare Web Analytics on the public website only for cookie-free aggregate traffic stats, such as page views and referrers

## Source of Truth

The public website privacy page at [docs/privacy.html](docs/privacy.html) should match this file. If they drift, update this file first and then sync the website copy.
