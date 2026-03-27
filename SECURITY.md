# Security Policy

> [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEVELOPMENT](DEVELOPMENT.md) · [PRIVACY](PRIVACY.md) · [SECURITY](SECURITY.md)

## Supported Versions

Only the latest release branch is supported for security fixes.

## Security Model

SaneSales is a local-first sales dashboard that:

1. Stores API keys in the system Keychain
2. Talks directly to LemonSqueezy, Gumroad, and Stripe from your device
3. Stores cached sales data locally on your device
4. Uses limited network requests for provider APIs, updates, and a few simple anonymous app counts

## Reporting a Vulnerability

Do not open a public issue for a security problem.

- Email: [hi@saneapps.com](mailto:hi@saneapps.com)
- Include the affected version, reproduction steps, impact, and any logs or screenshots that help explain the issue

## Scope

Security reports are especially useful for:

- API key handling
- Data leakage or unintended upload
- Provider-auth or callback issues
- Export, cache, or local-storage exposure
- Update or signing problems

See [PRIVACY.md](PRIVACY.md) for the data-handling policy.
