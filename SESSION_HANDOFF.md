# Session Handoff — SaneSales

Active handoff only. The long launch/release chronology was compacted on
2026-05-21 because it exceeded the 300-line active-context cap. Durable history
lives in git, `CHANGELOG.md`, `ARCHITECTURE.md`, `.outreach.yml`, release
receipts, Serena memory, and the knowledge graph.

## Current State

- Current direct/Sparkle/Homebrew release: `1.3.8` build `1308`.
- 2026-05-25 22:10 EDT expired offer and weak upgrade-flow copy fixed:
  - Removed stale launch-window `SANE60`, `$9.99`, and trial/launch-offer copy
    from the website/docs surfaces touched in this pass, including structured
    pricing metadata.
  - Homepage pricing now leads with Demo vs Pro at `$24.99` once and ties Pro
    to live sales/provider value instead of a temporary discount.
  - Added regression coverage so the homepage keeps provider-specific buyer
    intent and does not reintroduce stale offer labels or the expired coupon.
  - Verification: Mini `./scripts/SaneMaster.rb verify --timeout 1200` passed
    `87` tests after the shared SaneProcess verifier fix for benign
    App Intents `autoShortcut` diagnostics.
- 2026-05-25 09:33 EDT cross-product launch ops reran canonical Mini
  `launch_readiness`; it exited `1`, so no launch-week follow-up, directory,
  or public reply action was executed. The gate is still red because the
  `2026-05-21` offer window ended and launch/package copy still needs human
  review before any new launch work. Mini `release_preflight` still
  passed with `3` warnings, so release safety is not the blocker. The shared
  validation report still flags stale SaneSales customer UI proof. Existing
  Launching Next receipt remains
  `https://www.launchingnext.com/thanks/?i=134060`. Next checkpoint:
  `2026-05-30`.
- 2026-05-21 10:00 EDT directory recheck:
  - Mini `launch_readiness --json` returned `ok: true` with passed
    `release_preflight` and 1 warning, so the old red gate is no longer the
    blocker for directory work.
  - Launching Next still has the live receipt
    `https://www.launchingnext.com/thanks/?i=134060` and still shows
    `Submitted` / `Fast-Track` / `In Queue (Estimated Wait: 4 Months)`.
  - MacUpdate still redirects the submit URL into member login, so a member
    session or an explicitly approved account-creation step is required before
    any submission can continue.
  - G2 still resolves the create-profile CTA into unauthenticated `my.g2.com`
    signup/login, so no seller access exists in this session to claim or create
    a profile.
  - Optional SaaSHub was intentionally left unsubmitted again because the flow
    still expands into a higher-friction second step with categories,
    competitors, contact email, and `Free` vs `$75 / One Off` submission
    choice.
- 2026-05-21 Mini proof refresh:
  - `./scripts/SaneMaster.rb test_mode --release --no-logs` built, staged, and
    launched the Release app on the Mini.
  - `./scripts/SaneMaster.rb customer_ui_sweep --json` passed and refreshed `15`
    customer action families; receipt generated `2026-05-21T10:29:41Z`.
  - `customer_ui_contract --json --no-exit` is green with no issues/warnings.
- macOS and iOS App Store `1.3.8` build `1308` were submitted and were
  `WAITING_FOR_REVIEW` after the May 20 corrective rebuild.
- Public iOS App Store `1.3.7` should be treated as untrusted for the
  Pro/provider fix until Apple approves and users install `1.3.8`.
- 2026-05-21 user report after App Store `1.3.8` update:
  - Apple lookup now reports public SaneSales `1.3.8` released
    `2026-05-21T17:23:08Z`.
  - User screenshots show Pro and all three providers connected, but live cache
    collapsed to `0` cached orders, `0` products, Dashboard `$0.00`, and
    `0 orders`.
  - Expected from the corrective build is retained live provider access and
    cached/live sales data; prior expected screenshot state showed `657` cached
    orders, `4` products, Today `$510.00`, `10 orders`, latest sale `ColorKit`
    via Stripe, and a populated revenue chart.
- 2026-05-21 Basic/Pro customer UI audit and patch:
  - Six-agent audit found the core issue family: App Store purchase-state timing
    and unpaid-access reset paths could make Pro/connected/provider screens look
    real while cache/data was empty or demo-sourced.
  - Patched refresh/access handling so missing Pro/live access no longer clears
    provider credentials, in-memory orders/products/stores, or persistent cache.
  - App launch now waits for App Store purchase-state refresh before automatic
    live refresh when no live provider access has been confirmed.
  - Settings now distinguishes `Pro Active`, `Pro Syncing`, `Demo`, and live
    `Connected`; App Store `Restore Purchases` is no longer the primary active
    Pro action.
  - Dashboard and Products now show explicit missing-data recovery states for
    connected Pro accounts instead of plausible `$0` or setup-empty copy.
  - Custom range picker was simplified from the custom two-month calendar to
    native Start/End date pickers with a selected-range summary.
  - Mini `./scripts/SaneMaster.rb verify --timeout 1200` built and all 87 unit
    tests passed, but SaneMaster still returned non-zero because its failure
    marker scan treats macOS App Intents `com.apple.linkd.autoShortcut` runtime
    diagnostics as test failures.
- Launch-week Pro offer copy was live through May 21, 2026; website/docs copy
  has been revised to the regular one-time price, while launch packages still
  require human review before reuse.

## Active Blockers

- Validation caveat: unit tests pass, but canonical `verify` currently exits
  non-zero due `com.apple.linkd.autoShortcut` App Intents diagnostics being
  classified as explicit failure markers by SaneMaster.
- Directory progress is now blocked by third-party access only:
  MacUpdate member portal access, G2 seller/profile access, and explicit user
  approval before any paid or irreversible SaaSHub branch.
- Active iOS `1.3.8` regression report: local patch now preserves credentials
  and cached data across missing purchase/live-access states, but this needs a
  new App Store/direct build before customers will see it.
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

1. Prepare and verify the next SaneSales release containing the Pro/cache
   preservation and UI-state clarity fixes.
2. Decide whether to patch SaneMaster failure-marker handling for known
   `com.apple.linkd.autoShortcut` App Intents diagnostics.
3. Monitor App Store review/state for `1.3.8` and supersede it if needed.
4. Resume MacUpdate only if an authenticated member session or approved
   account-creation step is available.
5. Resume G2 only if seller/profile access exists; otherwise keep it blocked.
6. Ignore optional SaaSHub unless there is explicit approval to spend time on
   the higher-friction form.
