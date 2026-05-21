# Session Handoff — SaneSales

Active handoff only. The long launch/release chronology was compacted on
2026-05-21 because it exceeded the 300-line active-context cap. Durable history
lives in git, `CHANGELOG.md`, `ARCHITECTURE.md`, `.outreach.yml`, release
receipts, Serena memory, and the knowledge graph.

## Current State

- Current direct/Sparkle/Homebrew release: `1.3.8` build `1308`.
- macOS and iOS App Store `1.3.8` build `1308` were submitted and were
  `WAITING_FOR_REVIEW` after the May 20 corrective rebuild.
- Public iOS App Store `1.3.7` should be treated as untrusted for the
  Pro/provider fix until Apple approves and users install `1.3.8`.
- Launch-week Pro offer copy was live through May 21, 2026; recheck and remove
  expired offer language before any new launch/posting action.

## Active Blockers

- Live hosted-file drift:
  - Lemon Squeezy still serves `SaneSales-1.3.7.zip`.
  - Canonical appcast/release is `SaneSales-1.3.8.zip`.
  - Validation product refs: `product_id=822714`,
    `product_slug=sanesales`, `variant_id=1296644`.
  - Replace the hosted file through the supported hosted-file action workflow,
    then rerun `hosted_file_actions --json` and global validation.
- Global validation may still show stale QA/customer proof until a fresh Mini
  customer UI sweep is run for the current source state.
- Do not post to Product Hunt, Indie Hackers, HN, directories, or social
  surfaces unless `launch_readiness` is green and the exact copy is approved.

## Release Evidence

- Direct release `1.3.8`:
  - `https://dist.sanesales.com/updates/SaneSales-1.3.8.zip` returned HTTP 200.
  - Live appcast pointed at `sparkle:version="1308"`.
  - Homebrew cask was updated to `1.3.8`.
- Corrective iOS artifact proof:
  - Fresh IPA contained `CFBundleShortVersionString=1.3.8`,
    `CFBundleVersion=1308`, bundle ID `com.sanesales.app`, and
    product ID `com.sanesales.app.pro.unlock.v2`.
- App Store submission IDs after corrective rebuild:
  - macOS submission `dd432476-1b0a-4b7f-9132-645cb02eb0b7`.
  - iOS submission `0654e97e-f573-4538-b1ee-3ad3dff2d583`.

## Known Process Lessons

- The May 20 incident was stale artifact reuse: local exported iOS artifact was
  `1.3.6/1306` even though handoff text claimed `1.3.7/1307`.
- Future App Store/direct releases must verify embedded artifact version/build,
  not just source metadata or handoff prose.
- Strict customer UI visual proof must use action-mapped screenshots. Round-robin
  or contaminated screenshots are invalid evidence.

## Next

1. Replace the stale Lemon Squeezy hosted file for `1.3.8`.
2. Run fresh Mini customer UI proof if any release/App Store action continues.
3. Rerun `ruby ~/SaneApps/infra/SaneProcess/scripts/validation_report.rb`.
4. Update this handoff only with active state and new proof receipts.
