# Session Handoff — SaneSales

**Last updated:** 2026-05-20
**Current version:** 1.3.7 deployed for direct download/Sparkle/Homebrew as a critical security update; App Store 1.3.7 is intentionally withdrawn/blocked pending fresh strict visual proof; launch-week Pro offer is live at $9.99 through May 21, 2026

## Current State

## 2026-05-20 App Store Visual Proof Correction

- Human inspection caught that the earlier automated strict visual pass was invalid: generated customer UI proof images were mapped by list position and several SaneSales screenshots were contaminated by a SaneClip permission prompt. App Store was not resubmitted from that evidence.
- Fixed `scripts/customer_ui_action_sweep.rb` so each customer-facing action has an explicit screenshot fixture mapping instead of round-robin screenshot assignment. Added a regression test in `Tests/SettingsSourceTests.swift`.
- Added `scripts/render_widget_visual_proof.rb` to generate a Mini-rendered macOS WidgetKit contact sheet from the actual `SalesWidgetView` paid and locked states; widget proof no longer points at a Settings screenshot.
- Regenerated macOS App Store screenshots from the Mini GUI session on May 20, 2026. Fresh customer UI visual proof was inspected at `/tmp/sanesales-visual-proof/contact.png`; no SaneClip prompt, helper window, clipping, or obvious text overlap remained in the proof set.
- Mini gates after the correction:
  - `./scripts/SaneMaster.rb customer_ui_sweep --json` passed with 15 actions.
  - `./scripts/SaneMaster.rb customer_ui_contract --strict-visual --json` passed.
  - `./scripts/SaneMaster.rb appstore_preflight` passed with warnings only: privacy manifest project.yml mention, manual Watch icon contrast inspection, and dirty worktree before commit.
- App Store state remains intentionally withdrawn until the clean proof changes are committed/pushed and a fresh submission command is run. macOS `1.3.7` is still `DEVELOPER_REJECTED` before resubmission.

## 2026-05-20 Show HN Fallback Check

- Rechecked the live fallback condition at 11:00 EDT on Wednesday, May 20, 2026 instead of relying only on earlier notes. Product Hunt still shows the original May 6 launch post as live but unfeatured: post `1139905`, `featuredAt: null`, `scheduledAt: 2026-05-06T07:01:00Z`, `votesCount: 1`, and `commentsCount: 1`.
- The Product Hunt relaunch path still has no active replacement schedule recorded in [`.outreach.yml`](/Users/sj/SaneApps/apps/SaneSales/.outreach.yml), so there is no duplicate-launch conflict blocking the fallback lane.
- The exact prepared Show HN draft remains:
  `Show HN: SaneSales – native sales tracker for LemonSqueezy, Gumroad, and Stripe`
- No Show HN post was submitted from this slot. The remaining blockers were unchanged at send time: exact-copy approval was still missing, there was no signal that the user could stay present for several hours of comment replies, and the current launch gate had turned red again (`launch_readiness --json` was already tracked as `ok: false` because `release_preflight` failed with 2 issues and 2 warnings).
- Result: no HN URL exists and no 2-hour comment-monitoring window ran. Treat the Show HN draft as still approval-ready but unposted.

## 2026-05-20 Critical Direct Release + App Store Visual Gate Correction

- Direct release v1.3.7 is live:
  - R2 ZIP: `https://dist.sanesales.com/updates/SaneSales-1.3.7.zip` returns HTTP 200 with SHA256 `a53fb18dcb77790cb984789ab7cf3c522824b2a448a90209477300691e4e5db6`.
  - Live Sparkle appcast at `https://sanesales.com/appcast.xml` contains `1.3.7`, `sparkle:version="1307"`, `<sparkle:minimumAutoupdateVersion>1307</sparkle:minimumAutoupdateVersion>`, and `<sparkle:criticalUpdate sparkle:version="1307"/>`.
  - Website download links and JSON-LD now point to `SaneSales-1.3.7.zip`.
  - Homebrew cask `sane-apps/tap/sanesales` is updated to `1.3.7`; `brew audit --cask sane-apps/tap/sanesales` passed.
- App Store state:
  - macOS 1.3.7 was submitted during the interrupted release, then immediately withdrawn after the missing strict visual gate was identified. ASC now shows macOS `1.3.7` as `DEVELOPER_REJECTED`, not `WAITING_FOR_REVIEW`.
  - iOS 1.3.7 was stopped before version creation/submission; visible iOS builds still stop at `1306`.
- SaneProcess guard correction shipped:
  - `appstore_preflight` now runs `customer_ui_contract --strict-visual` as a hard blocker.
  - `appstore_submit.rb` now refuses upload/submission until strict visual proof passes.
  - Mini proof: `./scripts/SaneMaster.rb appstore_preflight` exits blocked with 7 strict visual customer UI issues for the current stale receipt.
  - Mini proof: direct `appstore_submit.rb --skip-upload ...` exits before upload/submission with the real strict visual contract failure.
- Repo state:
  - SaneSales pushed: `d5ab200 chore: sync 1.3.7 release metadata` on top of `4b182ae Bump version to 1.3.7`.
  - SaneProcess pushed: `a4c9369 Block App Store submit without strict visual proof` and `88604b6 Fix App Store submit guard wrapper invocation`.
  - Homebrew tap pushed: `2ea03b2 Update SaneSales cask to 1.3.7`.
- Next App Store step: rerun a full Mini customer UI sweep with fresh per-action screenshots, including onboarding provider Pro entry, dashboard refresh/Basic-Pro gates, provider Change Key Pro gate, and widget lock states. Do not resubmit App Store until strict `appstore_preflight` is green.

## 2026-05-20 Directory Schedule Recheck

- Re-ran the canonical Mini gate before touching any support-surface form: [`./scripts/SaneMaster.rb launch_readiness --json`](/Users/sj/SaneApps/apps/SaneSales/scripts/SaneMaster.rb) returned `ok: false` on 2026-05-20 because the latest `release_preflight` is now failed with 2 issues and 2 warnings. Rule 4 applies: no fresh irreversible launch-surface submission under a red gate.
- Launching Next remains the only completed low-friction submission. The existing free-path receipt at [`https://www.launchingnext.com/thanks/?i=134060`](https://www.launchingnext.com/thanks/?i=134060) still shows `Submitted`, `Fast-Track`, and `Status: In Queue (Estimated Wait: 4 Months)`. No paid fast-track upgrade was taken.
- MacUpdate is still blocked before any submission form. [`https://member.macupdate.com/content/submit`](https://member.macupdate.com/content/submit) still resolves to [`https://member.macupdate.com/member/login/%20content%20submit`](https://member.macupdate.com/member/login/%20content%20submit) with `Sign in` and `Create account`, so no safe progress is possible without an existing member session or explicit approval to create one. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/macupdate-login-2026-05-20.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/macupdate-login-2026-05-20.png).
- G2 still does not expose a usable claim/create path in this session. The public create-profile page at [`https://sell.g2.com/create-a-profile`](https://sell.g2.com/create-a-profile) still routes `Get Started` into [`https://my.g2.com/~/upgrade`](https://my.g2.com/~/upgrade), and the direct add-product path at [`https://www.g2.com/products/new`](https://www.g2.com/products/new) still lands in an access-restricted iframe that says `Access is temporarily restricted`. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/g2-antibot-2026-05-20.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/g2-antibot-2026-05-20.png).
- Optional SaaSHub is still not low-friction enough to justify diversion from the core launch schedule. The second-step form at [`https://www.saashub.com/services/new?url=https%3A%2F%2Fsanesales.com&commit=Continue`](https://www.saashub.com/services/new?url=https%3A%2F%2Fsanesales.com&commit=Continue) still requires categories, competitors, contact email, and a `Free` vs `$75 / One Off` submission choice before confirmation. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/saashub-step2-2026-05-20.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/saashub-step2-2026-05-20.png).
- The current direct-download asset for directory metadata is [`https://dist.sanesales.com/updates/SaneSales-1.3.6.zip`](https://dist.sanesales.com/updates/SaneSales-1.3.6.zip). The SaneSales directory tracker was corrected from stale `1.3.5` references to `1.3.6` during this run.
- No irreversible public action, no paid directory upgrade, and no account-creation step were taken in this run. Durable tracker updates were written back into [`.outreach.yml`](/Users/sj/SaneApps/apps/SaneSales/.outreach.yml).

## 2026-05-20 Demo-Mode Live Provider Bypass Incident

- User found a revenue-critical bypass: in demo mode, deleting an existing demo provider and adding a real provider API key could make live tracking work without purchase.
- Root cause confirmed independently by Codex and GPT audit agent: `SalesManager.isPro` treated `demoModeAccess` as effective Pro, and provider connection/refresh gates trusted `isPro`. Demo mode also did not start or consume the trial, so live refresh could run under demo-derived Pro access.
- Fix applied locally: `SalesManager` now separates `hasLiveProviderAccess` from demo UI access. Demo mode can still show sample data, but live provider connection, live refresh, cached live-data loading, key entry, export, widgets/watch live data, and Pro range/history surfaces require paid Pro or forced internal test mode. Successful real provider connection exits demo mode and clears sample data before saving the real key.
- Static UI contract fix applied: onboarding provider accessibility IDs are now explicit per provider, so `onboarding.provider.gumroad` and `onboarding.provider.stripe` remain visible to SaneMaster's reference validator.
- Regression coverage added in `Tests/APITests.swift`:
  - demo mode does not bypass Pro for live provider connections;
  - demo mode does not grant live refresh access;
  - demo fixtures still show sample data without granting live access;
  - demo provider deletion cannot reset the Pro gate;
  - deleting one demo provider cannot reconnect it as live without Pro.
- Worktree-safe source-reading fix added for the SaneUI welcome gate test so clean Mini worktrees resolve canonical `~/SaneApps/infra/SaneUI` when relative `infra/SaneUI` is not present.
- Follow-up audit fixes applied before publish: iOS onboarding no longer exposes provider API-key entry until Pro access exists; connected provider "Change Key" routes through the same Pro gate; cached live data does not load until live Pro access exists; dashboard/orders/products Pro range/history surfaces now key off `hasLiveProviderAccess`, not demo-derived `isPro`; App Store/outreach/review copy no longer describes live provider sync as a demo feature.
- Verification: clean Mini worktree `~/SaneApps/worktrees/SaneSales-gating-fix-20260520/SaneSales` ran `ruby ~/SaneApps/infra/SaneProcess/scripts/SaneMaster.rb verify --timeout 1200` and passed `87 tests` on 2026-05-20. `customer_ui_sweep --no-exit` passed. `appstore_preflight` passed with warnings only: manual Watch marketing icon contrast inspection and dirty worktree. Manual icon inspection found high-contrast cyan artwork on a dark blue background.
- Release implication: this is not protected for existing users until a new SaneSales version is shipped. Sparkle requires a version bump, so the fix must go out as `1.3.7` or later, not another `1.3.6` build.

## 2026-05-19 Directory Schedule Recheck

- Re-ran the canonical Mini gate before touching any directory surface: [`./scripts/SaneMaster.rb launch_readiness --app SaneSales --json`](/Users/sj/SaneApps/apps/SaneSales/scripts/SaneMaster.rb) returned `ok: true` on 2026-05-19 with warning-only `release_preflight` carryover, so the lane stayed eligible for safe review work.
- Launching Next remains the only completed low-friction submission. The existing free-path receipt at [`https://www.launchingnext.com/thanks/?i=134060`](https://www.launchingnext.com/thanks/?i=134060) still shows `Status: In Queue (Estimated Wait: 4 Months)` and the thank-you upsell page still offers Fast-Track for $99. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-07-708Z.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-07-708Z.png).
- MacUpdate is still blocked before any submission form. [`https://member.macupdate.com/content/submit`](https://member.macupdate.com/content/submit) still resolves to a sign-in/create-account page with no member session present. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-17-485Z.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-17-485Z.png).
- G2 still does not expose a usable claim/create path in this session. The public create-profile page still routes actual action into seller login/upgrade flows, and the direct add-product path [`https://www.g2.com/products/new`](https://www.g2.com/products/new) still lands in an anti-bot access-restricted iframe. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-26-770Z.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-26-770Z.png) and [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-38-272Z.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-38-272Z.png).
- Optional SaaSHub is still not low-friction enough to justify launch-time diversion. The second-step form remains reachable, but it still requires categories, competitors, contact email, and an explicit `Free` vs `$75 / One Off` submission choice before any confirmation step. Fresh evidence: [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-51-490Z.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/page-2026-05-19T14-02-51-490Z.png).
- No irreversible public action, no paid directory upgrade, and no account-creation step were taken in this run. Durable tracker updates were written back into [`.outreach.yml`](/Users/sj/SaneApps/apps/SaneSales/.outreach.yml).

## 2026-05-19 Indie Hackers Fallback Check

- Re-ran the canonical Mini gate before touching the fallback lane: [`./scripts/SaneMaster.rb launch_readiness --json`](/Users/sj/SaneApps/apps/SaneSales/scripts/SaneMaster.rb) stayed green on 2026-05-19 with only the known `release_preflight` warning carryover.
- Re-ran the global validation report as required for launch context. It remained broadly red across the wider SaneApps release pipeline, and SaneSales still shows stale customer UI receipt warnings in that global report.
- Product Hunt remains no-go for launch-week timing because no approval or rejection arrived by the Monday, May 18, 2026 noon EDT checkpoint. The fallback branch is still Indie Hackers first, then Show HN.
- Confirmed the prepared Indie Hackers draft is still the exact copy recorded in [`.outreach.yml`](/Users/sj/SaneApps/apps/SaneSales/.outreach.yml):
  `I built a private native sales tracker for LemonSqueezy, Gumroad, and Stripe`
- Checked the live site state and web search before posting. Web search still found no public SaneSales Indie Hackers post, and the in-app browser opened Indie Hackers in an anonymous visitor state with `Join` visible and no authenticated posting session available.
- Result: the May 19 Indie Hackers fallback did not execute. There is no post URL and no comment-monitoring run because there was no signed-in session available for safe posting. Do not mark the channel launched unless an authenticated Indie Hackers session exists and the exact copy is approved at send time.

## 2026-05-18 Noon Product Hunt Decision

- Noon EDT checkpoint completed. Product Hunt API still shows the May 6 SaneSales post as live but unfeatured: post `1139905`, `featuredAt: null`, `votesCount: 1`, `commentsCount: 1`, `dailyRank: 565`, `monthlyRank: 6382`.
- Standard work-email check found no Product Hunt moderation approval or rejection.
- Official Product Hunt Help Center lists `hello@producthunt.com` as the safe support path. Sent the one allowed follow-up through `check-inbox.sh compose`; delivery confirmed via Resend `3ddd62e3-5d38-448f-8735-105c275c6aa6`.
- Product Hunt is now no-go for launch-week timing. Do not create a duplicate Product Hunt launch unless Product Hunt explicitly approves later.
- Active fallback remains: Indie Hackers on Tuesday May 19, 2026 at 10:00 AM EDT, then Show HN on Wednesday May 20, 2026 at 11:00 AM EDT if exact final drafts are approved.
- Updated `.outreach.yml` to mark PH no-go for this launch-week slot and move the launch path to the existing Indie Hackers/HN fallback schedule.

## 2026-05-18 Directory Schedule Follow-up

- Re-ran the canonical Mini gate before touching any directory surface: [`./scripts/SaneMaster.rb launch_readiness --json`](/Users/sj/SaneApps/apps/SaneSales/scripts/SaneMaster.rb) stayed green on 2026-05-18 with warning-only cleanup (`release_preflight` still passed; 3 warnings remain).
- No new irreversible submission was taken because the only low-friction lane was already complete: Launching Next remains submitted with receipt [`https://www.launchingnext.com/thanks/?i=134060`](https://www.launchingnext.com/thanks/?i=134060) and there was nothing new to re-submit.
- MacUpdate still blocks immediately on account access. `https://member.macupdate.com/content/submit` redirects to [`https://member.macupdate.com/member/login/%20content%20submit`](https://member.macupdate.com/member/login/%20content%20submit) with Sign in/Create account, so no safe progress is possible without an existing member session or explicit approval to create one.
- G2 still does not expose usable access in this browser session. The public page at [`https://sell.g2.com/create-a-profile`](https://sell.g2.com/create-a-profile) remains visible, `Get Started` still hands off into [`https://my.g2.com/signup?login=true`](https://my.g2.com/signup?login=true), and the direct add-product path at [`https://www.g2.com/products/new`](https://www.g2.com/products/new) now falls into an anti-bot verification iframe. Claim/create is still blocked unless seller/profile access already exists.
- Optional SaaSHub is still not low-friction enough to justify distracting from the core launch schedule. The public flow accepts `https://sanesales.com`, but the second step requires categories, competitors, contact email, and a submission-type choice between `Free` and `$75 / One Off` before `Confirm`.
- Durable tracker updates were written back into [`.outreach.yml`](/Users/sj/SaneApps/apps/SaneSales/.outreach.yml) for the May 15 `Directories` slot plus the MacUpdate, G2, and SaaSHub entries.

## 2026-05-18 Launch Ops

- Re-ran the canonical Mini gate before touching any due launch work: `./scripts/SaneMaster.rb launch_readiness` stayed green for SaneSales with warning-level cleanup only.
- Executed the due 10:00 EDT `Product Hunt moderation check` without posting or scheduling anything irreversible. Product Hunt API still shows the old May 6 page as live but unfeatured: post `1139905`, `featuredAt: null`, `votesCount: 1`, `commentsCount: 1`, `dailyRank: 565`, `weeklyRank: 2464`, `monthlyRank: 6382`.
- Work inbox check via `~/SaneApps/infra/scripts/check-inbox.sh check` returned `0` actionable threads, so there is no new Product Hunt moderation email to act on today.
- Rechecked launch-week price references on 2026-05-18. Active user-facing surfaces found by `rg` include the explicit cutoff `May 21, 2026`; keep the $9.99/SANE60 copy until then, then remove/replace it everywhere in the `.outreach.yml` sunset checklist.
- No Product Hunt relaunch scheduling, no public reply, and no fallback Indie Hackers / Hacker News action was taken because external approval is still pending and all public copy remains exact-approval-gated.
- Public support-surface URLs remain unchanged: [Product Hunt product page](https://www.producthunt.com/products/sanesales), [website](https://sanesales.com), [Hosted YouTube demo](https://youtu.be/FmyGTWpBF4M), [direct download ZIP](https://dist.sanesales.com/updates/SaneSales-1.3.5.zip), and [direct checkout](https://go.saneapps.com/buy/sanesales).
- Next launch-ops date is 2026-05-19 for the Indie Hackers conditional, but only if Product Hunt is still pending/no-go and the exact draft is approved first.

## 2026-05-17: Directory Schedule Execution Recheck

- Re-opened the live May 15 support-surface directory targets after the fresh green Mini launch gate and advanced each one only to the latest safe pre-approval state.
- Launching Next remains the only clean approval-ready lane. The live form at `https://www.launchingnext.com/submit/` was re-filled from `.outreach.yml`, the newsletter box stayed off, and a fresh review screenshot was captured at [`/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/launchingnext-review-20260517.png`](/Users/sj/SaneApps/apps/SaneSales/outputs/playwright/launchingnext-review-20260517.png).
- Important correction before any submission: the first browser fill dropped the literal dollar signs from `$9.99` and `$24.99` because the shell expanded them. That was caught before submit, corrected in the live form, and the exact staged copy now matches the canonical pricing again.
- MacUpdate still redirects `https://member.macupdate.com/content/submit` into `https://member.macupdate.com/member/login/%20content%20submit` with Sign in/Create account, so no member-portal progress was possible.
- G2 still exposes the public create-profile marketing page at `https://sell.g2.com/create-a-profile`, but the real action still hands off into `my.g2.com` login/upgrade flows. No existing seller/profile session was available, so claim/create remains blocked.
- SaaSHub is slightly further than the prior run: `https://www.saashub.com/services/submit` now accepts `https://sanesales.com` and advances to the longer second-step form. That form still requires categories, competitors, contact email, and a free-vs-paid submission choice, so it is not low-friction enough to justify distracting from the core launch schedule.
- BetaList no longer looks merely approval-gated. `https://betalist.com/submissions/new` now redirects straight to `https://betalist.com/sign_in`, so it is blocked on account access before any submission work.
- Durable tracker updates were written back into `.outreach.yml` for the May 15 `Directories` slot plus the Launching Next, SaaSHub, and BetaList entries.

## 2026-05-17: Conversion Positioning + Launch Gate Repair

- Reframed the App Store metadata source in `.saneprocess` around the narrower buyer wedge: private native revenue tracking for indie sellers using Lemon Squeezy, Gumroad, and Stripe. Both macOS and iOS subtitles now use `Private Revenue Tracker`, and descriptions/keywords now lead with provider-specific buyer intent instead of generic `Read-Only Sales Dashboard`.
- Updated the website/README positioning to match the same wedge and added homepage CTA-specific aggregate events (`website_buy_hero_clicked`, `website_buy_pricing_clicked`, `website_download_hero_clicked`) while keeping the existing aggregate buy/download events.
- Split the iOS Settings unlock event into source-specific events: `appstore_purchase_started` for StoreKit and `direct_checkout_opened` for direct checkout, so `checkout_clicked` is no longer inflated by that surface.
- Fixed `scripts/customer_ui_action_sweep.rb` so visual evidence gets unique per-action proof artifacts instead of reusing the same screenshot path across release-required actions.
- Verification completed on the Mini:
  - `./scripts/SaneMaster.rb verify` passed 79 tests.
  - `./scripts/SaneMaster.rb appstore_preflight` passed with warnings only: manual Watch icon contrast inspection and dirty worktree.
  - `./scripts/SaneMaster.rb customer_ui_contract --no-exit` passed with 15 release-required actions covered.
  - `./scripts/SaneMaster.rb release_preflight` passed with warnings only: dirty worktree, 1 pending customer email, evening release timing.
  - `./scripts/SaneMaster.rb launch_readiness --json` returned `ok: true`.
- Product Hunt state is not changed by this code/docs fix. Relaunch is still waiting on Product Hunt moderation approval; the May 18 Product Hunt moderation check remains the next go/no-go point.

## 2026-05-16: Directory Schedule Recheck

- Re-ran the canonical Mini gate before touching public support surfaces: `ruby /Users/sj/SaneApps/infra/SaneProcess/scripts/SaneMaster.rb launch_readiness --app SaneSales --json`.
- Result at 10:02 AM EDT: `ok: false`. The gate is still red because the latest `release_preflight` is `failed` with 1 issue and 3 warnings, so no directory submission was allowed to move past blocker review.
- Live public surface recheck:
  - Launching Next still has the same ready-to-submit fields at `https://www.launchingnext.com/submit/`; the live form was re-filled, the newsletter checkbox was intentionally left off, and the tab is staged at `Submit Startup`. Exact copy in `.outreach.yml` remains valid, but `Submit Startup` is still an irreversible public action that needs exact approval once the gate is green.
  - MacUpdate still redirects `https://member.macupdate.com/content/submit` into `https://member.macupdate.com/member/login/%20content%20submit` with Sign in/Create account. No access session was available.
  - G2 still exposes the public create-profile marketing page at `https://sell.g2.com/create-a-profile` and routes actual action into `my.g2.com`. No seller/profile session was available, so claim/create could not proceed.
  - SaaSHub is no longer just “unknown friction.” Entering `https://sanesales.com` into `https://www.saashub.com/services/submit` left `Continue` disabled in the in-app browser, so it is not low-friction enough to justify more launch time.
- Durable tracker updates were written back into `.outreach.yml` for the May 15 `Directories` slot plus the Launching Next, MacUpdate, G2, and SaaSHub entries.

## 2026-05-15: App Store Offer Code Recovery

- Recovered the active SaneSales App Store one-time-use offer-code values through the App Store Connect API after local memory/file searches did not locate a prior saved SaneSales export.
- Secure local path: `/Users/sj/SaneApps/outputs/license-campaign/sanesales_ios_appstore_codes_20260515/`.
- Secure Mini path: `/Users/stephansmac/SaneApps/outputs/license-campaign/sanesales_ios_appstore_codes_20260515/`.
- Files: `appstore_offer_codes.csv` contains 500 code/redemption URL rows; `reserved_codes.csv` tracks codes already assigned so future outreach does not reuse them.
- ASC source: app `6759010976`, IAP `6761268205`, offer-code batch `096f3fef-bd74-46d9-a94b-37762003ea37` (`Noah Demo 2026-04-17`), one-time-use set `c119b93a-b57a-4fc5-a343-dbd9d01a529f`.
- User hit Apple's "already redeemed maximum number of these codes per Apple Account" message while the iPhone still appeared Basic. Interpretation: the Apple Account has already consumed an offer code, but the installed app did not surface the StoreKit entitlement.
- Shared SaneUI fix applied: `LicenseService` now processes `Transaction.unfinished`, preserves restored unfinished unlocks, and falls back to `Transaction.latest(for:)` in addition to `Transaction.currentEntitlements` after `AppStore.sync()`.
- Mini verification: `cd ~/SaneApps/infra/SaneUI && swift test --filter SaneLicenseServiceTests` passed; `cd ~/SaneApps/apps/SaneSales && ./scripts/SaneMaster.rb verify` passed 76 tests.
- Release implication: the current App Store build may still require Restore Purchases and may not include this hardened path until the next SaneSales App Store update ships.

## 2026-05-15: Support-Surface Directory Access Review

- Launching Next is the only clean public submission surface confirmed in this run. The live form fields were verified against `https://www.launchingnext.com/submit/`, and `.outreach.yml` now stores the exact ready-to-submit payload:
  startup name `SaneSales`, headline `Private native sales tracker for indie sellers`, the full privacy-first description, tags, `Bootstrapped startup`, `$0` marketing budget, submitter `Mr. Sane`, email `hi@saneapps.com`, and anti-spam answer `5`.
- Launching Next was intentionally not submitted. `Submit Startup` is an irreversible public action, so the lane is waiting on exact approval rather than form discovery.
- MacUpdate is blocked on member-portal access. The current submit URL is `https://member.macupdate.com/content/submit`, but it redirects into a sign-in/create-account flow when unauthenticated.
- G2 is blocked unless seller/profile access already exists. Public docs at `https://sell.g2.com/create-a-profile` still describe the create-then-claim workflow, but the real `my.g2.com` creation path requires login and the unauthenticated endpoint was protected in this environment.
- SaaSHub remains optional. The public first step at `https://www.saashub.com/services/submit` exposes a Website URL plus `Continue`, but the continuation path was not verified as account-free, so it was left unsent rather than burning time off the core launch schedule.

## 2026-05-15: Launch Readiness Cleanup

- Mini `./scripts/SaneMaster.rb launch_readiness --json` passes for support surfaces and targeted replies only. Product Hunt relaunch still requires moderation approval, and directory submissions still require exact approval before irreversible public posting.
- Live Product Hunt API still shows the original May 6, 2026 post as unfeatured: post `1139905`, `featuredAt: null`, `votesCount: 1`, `commentsCount: 1`, `dailyRank: 565`, `monthlyRank: 5657`.
- Launch-week price copy is currently intentional but date-bound. `.outreach.yml` now has a May 21, 2026 sunset checklist for README, website, guide pages, Product Hunt package copy, and outreach metadata.
- `macOS/SaneSalesSettingsCopy.swift` fallback price now uses the regular `$24.99` price so the app does not show stale `$9.99` copy if live pricing cannot load after the offer window.

## 2026-05-14: Full-Frame Video QA Correction

- User-provided QuickTime evidence at 5:34 PM showed the previous
  `launch-week-pro-all-devices.mp4` still had a broken text overlap on the
  iPhone slide. Root causes: contact-sheet review was treated as sufficient, the
  old transition path blended adjacent text-heavy slides, and body text positions
  were not always based on rendered title height.
- Story correction: the video now follows the intended sales order:
  1. problem: sales apps can mine private data and charge forever;
  2. solution: track sales privately, no subscription, no private sales data collected, pay once;
  3. product proof across dashboard, Mac, iPhone, iPad, and Apple Watch;
  4. launch-week CTA.
- Approved canonical artifact: the current video is final. Keep
  `Videos/launch-week-pro-all-devices.mp4` and
  `docs/videos/sanesales-launch-week-pro-all-devices.mp4` as the canonical
  SaneSales launch-week video. SHA-256:
  `164297c4cc171a641b03c2df1aca8831260294a88b97c4187b80b3f8915786f6`.
- Generator correction: `scripts/build_launch_video.py` uses per-slide fades plus
  `concat` instead of `xfade`, dynamic title/body spacing, and the CTA now uses
  short copy with no overlapping URL/body text.
- Current local rebuilt cache tag: `164297c4cc17`.
- Full-size frames inspected after rebuild:
  `/tmp/sanesales-final-review/full-1.png`, `full-8.png`, `full-15.png`,
  `full-22.png`, `full-29.png`, `full-36.png`, `full-43.png`, `full-50.png`.
  Midpoint and transition sheets inspected:
  `/tmp/sanesales-final-review/midpoints.png`,
  `/tmp/sanesales-final-review/boundaries-a.png`,
  `/tmp/sanesales-final-review/boundaries-b.png`.
- Local media metadata after rebuild: 1920x1080, 30fps, 55.977s, H.264 + AAC,
  mean volume `-19.0 dB`, max volume `-1.8 dB`.
- Critic follow-up applied after the first full-frame correction: opener now
  stays problem-led with `There is a cleaner way.`, the chart slide says
  `See what sold today.`, and the privacy line now says
  `No analytics cloud collecting your history`.
- Final line-break/copy correction: removed the contradictory phrase
  `Private tracking`. The privacy solution heading now renders as two deliberate
  lines: `Track sales privately.` and `No subscription.` The pay-once/no-monthly
  bill claims are also split into separate bullet lines.
- SOP correction recorded in project and shared docs: full-size every-slide
  inspection and transition-boundary inspection are mandatory; contact sheets are
  navigation only. Storyboard order must answer a privacy/subscription problem
  immediately with the privacy/pay-once solution.
- Final verification and publish: Mini `./scripts/SaneMaster.rb verify` passed
  76 tests after the final copy/layout rebuild. Website-only deploy to
  Cloudflare Pages completed, live homepage references cache tag
  `164297c4cc17`, and the live MP4 returned `200` with
  `content-type: video/mp4` / `content-length: 2616980`.

## 2026-05-14: Launch Video Attempt Failure Log

- Process failure: the first video pass was treated like a design task instead of a customer-facing release asset. It reused/combined screenshots without first proving each platform was in a Pro-safe state.
- Rejected frames/assets:
  - old Watch screenshots that showed `Demo data` or a locked Pro state;
  - Mac screenshots with permission dialogs or stale unlock/price bubbles;
  - slide layouts where headings were clipped or covered by device mockups;
  - dashboard/chart frames where the revenue bars were nearly identical across the selected range.
- Tooling gap found: `scripts/capture_appstore_screenshots.sh` had Mini-first and validation discipline, but `scripts/capture_demo_videos.sh` did not pass Pro/test args into clips before this session. It now supports `EXTRA_APP_ARGS`, including Watch, iPhone, iPad, and Mac clip launches.
- Second tooling gap found: the final launch video was originally generated by
  ad-hoc terminal code. That made it too easy to rebuild inconsistently. The
  repeatable builder is now `python3 scripts/build_launch_video.py`; it writes
  the MP4, poster, source contact sheet, sampled video contact sheet, audio bed,
  and website copy path in one command.
- Watch capture fix: `Watch/WatchDashboardView.swift` now honors `--force-pro-mode` / `SANEAPPS_FORCE_PRO_MODE=1` so Watch marketing captures can show a Pro-style dashboard/recent-sales view without `Demo data` or locked copy.
- Demo fixture fix: `Core/DemoData.swift` now creates visibly varied daily
  revenue for the April 4-18, 2026 marketing range, with a regression test in
  `Tests/MetricsTests.swift` so the selected chart range cannot silently flatten
  again.
- Generator QA failures caught and fixed in this pass:
  - first generator run failed because Pillow masking used the wrong API;
  - the first rebuilt hero clipped the headline;
  - the chart/iPad slides had text colliding with device frames at full size;
  - the background used ornamental circular glows/line-like texture that did
    not match SaneUI;
  - automated Mac screenshots reintroduced a permission dialog with `SaneClip`
    text into a SaneSales settings frame;
  - Watch recent-sales screenshots exposed unrelated SaneApps product names;
  - Mac screenshots exposed `Basic`/stale unlock pricing in tiny UI text.
- Current correction: the launch video now uses a gentle Sane-style blue
  gradient background, full-frame inspected screenshots, and curated Mac/Watch
  inputs where the automated capture path is not yet marketing-safe.
- Final chart correction: the clean Mac dashboard website asset still had flat
  revenue bars. It was corrected to show varied daily sales that match the
  visible `$3,240` / `$216 avg/day` summary, and `build_launch_video.py` now
  fails if chart-bearing source assets are missing bars or visually flat.
- Final critic correction: mobile headline spacing no longer reads `Sanityto`,
  iPad marketing frames are cropped to the useful dashboard/product regions,
  the sampled video contact sheet uses a 4x2 tile instead of leaving an empty
  black row, and awkward slide copy was changed to `Daily sales, clearly` /
  `Review sales from your Mac`.
- Branding correction: the video generator no longer draws a substitute `$`
  logo. It uses the official SaneSales `docs/images/branding.png` asset for
  generated video logo lockups, and the shared/project SOPs now block placeholder
  logos in marketing assets.
- Audio correction: the launch video now uses the repo-local
  `Videos/pulse-ledger.mp3` music source. `build_launch_video.py` loops, trims,
  normalizes, and fades that track to match the final MP4 duration instead of
  using a synthetic placeholder bed or a Downloads-only source.
- Logo/layout correction: the generated video lockup now uses the larger
  official app icon source at
  `Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png`, keys out
  the baked-in dark square so the mark blends into the Sane blue background, and
  keeps every slide on a stable left-column/right-proof layout so the eye path
  does not jump around between transitions.
- Highlight correction: non-clickable filled pills were removed from the video
  because they looked like buttons and the yellow/blue choices drifted from
  SaneApps colors. Highlights now use Sane teal/cyan callouts with an accent
  rule and no rounded filled background.
- Tooling correction: app-store screenshots now sync to website image names for
  safe iPhone/iPad/Watch dashboard sources, while Mac settings/screens and Watch
  recent-sales frames are intentionally held as curated inputs until reviewed.
- Accepted current artifacts:
  - canonical final MP4: `Videos/launch-week-pro-all-devices.mp4`
  - website copy: `docs/videos/sanesales-launch-week-pro-all-devices.mp4`
  - poster: `docs/images/sanesales-launch-video-poster.png`
  - source contact sheet: `Videos/launch-week-pro-contact-sheet.png`
  - sampled final-video contact sheet: `Videos/launch-week-pro-video-contact-sheet.jpg`
- Verification completed before the chart critique:
  - Mini `./scripts/SaneMaster.rb verify` passed 74 tests.
  - Mini Watch screenshot validator passed for the fresh Watch captures.
  - `ffprobe` confirmed the MP4 is 1920x1080, 30fps, 46.43s, H.264 + AAC.
  - OCR banned-term scan passed for slides.
  - Cloudflare Pages deploy succeeded and the live MP4 returned `200 video/mp4`.
- Latest verification after the final visual corrections:
  - Mini `./scripts/SaneMaster.rb verify` passed 76 tests on May 14, 2026 after the final chart/contact-sheet/mobile-spacing pass.
  - `python3 -m py_compile scripts/build_launch_video.py` passed.
  - `bash -n scripts/capture_appstore_screenshots.sh` and
    `bash -n scripts/capture_demo_videos.sh` passed locally and on the Mini.
  - `ffprobe` confirmed the final MP4 is 1920x1080, 30fps, 49.70s, H.264.
  - Chart QA measured non-flat bars in `screenshot-mac-dashboard.png`,
    `screenshot-ipad-dashboard.png`, and `screenshot-iphone-dashboard.png`.
  - Playwright screenshots verified desktop, mobile, and device-grid website
    renders with no permission dialogs, no popup blocks, readable spacing, and
    visible chart variation.
  - A GPT critic subagent reviewed the updated rendered screenshots/contact
    sheet and returned PASS with no remaining launch-blocking issues.
  - OCR banned-term scan passed across all 8 final slides for `Unlock Pro`,
    `Basic`, `Demo data`, stale prices, permission prompts, `SaneClip`,
    debug/internal text, and popup terms.
- Final publish verification:
  - Website-only deploy to Cloudflare Pages completed on May 14, 2026.
  - Live MP4 `https://sanesales.com/videos/sanesales-launch-week-pro-all-devices.mp4?v=164297c4cc17`
    returned `200` with `content-type: video/mp4` after the official-logo,
    Pulse Ledger audio, and final buyer-copy rebuild.
  - Live homepage HTML references the rebuilt poster/video cache tag
    `164297c4cc17` and includes the current privacy and launch-week copy.
  - Latest local rebuild uses the consistent layout grid, blended 1024px logo
    source, and non-clickable Sane teal/cyan callouts. Mini
    `./scripts/SaneMaster.rb verify` passed 76 tests after the generator/test
    updates, and a GPT critic pass returned PASS with no blocking visual issues.
  - Live Playwright screenshots in `outputs/playwright/` verify mobile headline
    spacing, the updated video poster, and the device grid with non-flat charts.
  - `./scripts/SaneMaster.rb check_docs` exits 0 cleanly after the
    SaneProcess README operator docs map was added.
  - Live homepage bad-copy scan passes for removed buyer-irrelevant lines:
    Homebrew install command, support/sponsor funnel, weak testimonial quotes,
    `No server in the middle`, provider-key storage mechanics, and license-check
    mechanics.
  - Mini Playwright runtime was confirmed/installed (`playwright@1.60.0` plus
    Chromium v1223), and a Mini headless render smoke passed against the synced
    `docs/` site. Evidence screenshot:
    `/tmp/sanesales-local-page-after-copy-cleanup.png` on the Mini.
- Marketing distribution pass on May 14, 2026:
  - Website redeployed through the standard Cloudflare Pages path after adding
    Open Graph video metadata and `VideoObject` JSON-LD for the canonical video.
  - Live homepage verifies `og:video`, `VideoObject`, and the MP4 cache tag
    `164297c4cc17`.
  - X search evidence is saved in `outputs/marketing/x-opportunities-20260514.json`
    and `outputs/marketing/x-opportunities-focused-20260514.json`; no high-fit
    reply target was worth forcing.
  - Standalone launch post is live at
    `https://x.com/i/web/status/2055078497328980172`.
  - A first post with shell-expanded `.99` was deleted immediately
    (`2055078406362943614`), and global `x-post.py` now supports `--text-file`
    plus blocks `.99` without `$` so the failure does not repeat.
  - Product Hunt/G2 remain blocked on a YouTube/Vimeo-style hosted video URL.
    App Store preview upload remains blocked on separate 15-30s
    device/display-specific preview cuts; the canonical 55.98s all-device
    marketing video is not App Store-ready.
  - Created a 30.000s all-content YouTube upload candidate at
    `Videos/sanesales-launch-week-pro-all-devices-30s.mp4` by reducing each of
    the eight approved sections to 3.75s. It was copied to the Mini desktop at
    `/Users/stephansmac/Desktop/SaneSales-launch-week-pro-all-devices-30s.mp4`;
    SHA-256 verified on both machines:
    `5ea0c9c1952506d66e03aa1a60f8e09106f5cdb139f727d9c3e064c7eb272662`.
  - YouTube hosted video is live at `https://youtu.be/FmyGTWpBF4M`; oEmbed
    verifies the title/channel. The website `VideoObject` was updated and
    redeployed so `embedUrl` points to the YouTube embed while the direct MP4
    remains `contentUrl`.
  - Posted the YouTube demo to X at
    `https://x.com/i/web/status/2055082714080969139`, using `x-post.py
    --text-file` to preserve `$9.99`.
  - Product Hunt launch package is staged at
    `outputs/marketing/product-hunt-sanesales-20260514/` with `thumbnail-240.png`,
    three 1270x760 gallery images, YouTube URL, and maker copy. Assets were
    visually checked; the thumbnail uses the keyed logo treatment to avoid hard
    icon edges.

## 2026-05-14: SaneSales 60% Off Direct Launch Offer Live

- Created LemonSqueezy discount `SANE60` for SaneSales direct checkout: effective direct price is $9.99 from the normal $24.99, expiring May 21, 2026 at end-of-day Eastern.
- Deployed `go.saneapps.com` checkout worker so `/buy/sanesales` redirects to the LemonSqueezy checkout with `checkout[discount_code]=SANE60`; verified live 302 includes the encoded discount parameter.
- Updated and deployed `sanesales.com` hero, pricing card, FAQ/guide CTAs, comparison copy, JSON-LD pricing, and README around the stronger positioning: private native sales tracking, no SaneApps sales-data server, one-time Pro, multi-provider views, order history, CSV export, widgets, Watch, and menu bar revenue.
- Corrected competitor claims: do not say Baremetrics or ChartMogul are Stripe-only. Current positioning should contrast SaneSales as native/private/one-time/direct-to-provider, while those tools are cloud SaaS analytics platforms with monthly pricing.
- Generated launch video assets in `Videos/`: `launch-week-60-off.mp4`, `launch-week-contact-sheet.png`, and `launch-week-slides/`. Final pass removes permission dialogs, stale $24.99 screenshot bubbles, and popup artifacts; includes dashboard, orders, products, export, privacy/no-subscription, and $9.99 direct CTA.
- Verification: `./scripts/SaneMaster.rb check_docs` exits 0 with only the pre-existing README/SaneProcess operator-docs warning; Cloudflare Pages deploy succeeded; live homepage text and guide CTA were verified by HTTP; live Playwright screenshot `/tmp/sanesales-home-live-cta.png` shows prominent SaneSales branding and the top $9.99 CTA; live checkout route redirects with `checkout%5Bdiscount_code%5D=SANE60`.
- Remaining: direct app/Sparkle recovery update has not been shipped; App Store IAP price was not changed; local SaneUI fallback price edit still needs commit/push/package resolution before a future app build will inherit it.

## 2026-05-12: Customer UI Action Release Gate

- Added `Tests/CustomerUIActions.yml`, `scripts/customer_ui_action_sweep.rb`, and `.sane/customer_ui_action_receipt.json`.
- `./scripts/SaneMaster.rb customer_ui_contract --no-exit` passes with 15 required actions covered; receipt generated `2026-05-12T03:46:32Z` on host `mini`.
- Mini `./scripts/SaneMaster.rb verify` passed 74 tests.

## 2026-05-09: Research Cache Compacted

- `.claude/research.md` was compacted back under the active-cache cap after validation found 204 lines.
- Stale March/April release and App Store findings were already promoted into this handoff, app metadata, tests, and source; the remaining active cache now keeps only current May 2026 operational findings.
- A corrupted shell environment dump under the old `OrdersListView split access control` topic was removed as invalid research content.

## 2026-05-09: Provider Setup Reliability Fix

- A validated provider connection should not be rolled back only because the first refresh after saving credentials hits a refresh/decoding/network error.
- `SalesSetupFlowPolicy` now treats a connected provider as enough to avoid reopening first-run setup even if the welcome flag is old and there is not yet cached sales data.
- `SalesManager` no longer deletes provider credentials after an initial refresh failure; the connection remains available for retry and normal offline/error handling.
- Regression tests assert the old `shouldTreatInitialRefreshFailureAsConnectionFailure` / `rollbackProviderConnection` path is gone.
- Latest recorded Mini verification for this pass: SaneSales verify passed with 74 tests.
- Live GitHub state at closeout: `#3 It keeps saying it’s not connected but it clearly is.` remains open and maps to this local provider setup reliability fix. Do not close or comment publicly without exact draft approval.

## 2026-05-06: SaneSales 1.3.3 Shipped

- Direct release shipped from the Mac Mini with `release.sh --full --version 1.3.3 --deploy`.
- Release artifacts verified: notarization accepted, `https://dist.sanesales.com/updates/SaneSales-1.3.3.zip` returns 200, appcast has v1.3.3, website JSON-LD/download links are v1.3.3, Homebrew cask is v1.3.3, and the signed-download email webhook serves `SaneSales-1.3.3.zip`.
- GitHub release `v1.3.3` was created and release metadata committed/pushed. Latest SaneSales commits: `9696694` release prep, `b74b11a` version bump, `5ef0104` release metadata.
- App Store Connect state verified after submission: macOS `1.3.3` is `WAITING_FOR_REVIEW` with submission `2e6a1a7a-0ab5-409e-815d-2b240a60bdb3`; iOS/watch `1.3.3` is `WAITING_FOR_REVIEW` with submission `14ca9e06-9cb7-4c8d-9c90-14e7e5617959`.
- Final post-release `release_preflight` passed with warnings only: static UserDefaults/migration warning, 3 pending customer emails, and evening-release timing. Appcast/Homebrew/webhook drift is resolved.
- Visual note: App Store screenshots were regenerated and inspected before submission. Live-site screenshot capture from SSH on the Mini is still not valid evidence because `screencapture` cannot access the Mini GUI display from SSH; live site was verified by HTTP/text checks after deploy.

## 2026-05-06: Release-Stabilization Pass Completed After Critic Findings

- Withdrew the broken macOS App Store 1.3.2 lane, then repaired App Store Connect state by retargeting the editable macOS lane from `1.3.2 (DEVELOPER_REJECTED)` to `1.3.3 (DEVELOPER_REJECTED)`.
- Fixed additional critic-found blockers after the first privacy/cache pass: legacy App Group raw order cache now migrates into app-local cache plus sanitized shared snapshot; malformed cache/snapshot payloads are discarded; provider removal now rewrites cache instead of resurrecting removed-provider data on next launch; total provider refresh failure preserves existing offline history instead of wiping it.
- Watch widgets now receive full sanitized aggregate fields for Today, 30D, Month, and All Time instead of showing bogus zeroes for non-today ranges.
- Expired/free access behavior is now intentionally stricter: loaded order/product/store data and shared widget/watch snapshots are cleared when Pro/trial access is lost. UI tests were updated to assert that expired trial does not retain older history or CSV export rows.
- Orders empty states now account for provider filters: if a selected provider has no matching orders while other provider data exists, the empty state offers `Show All Providers` instead of a no-op `Show All Orders`.
- Chart axis policy was hardened for high-volume sellers and long ranges: y-axis labels get headroom and compact `$3K`/`$2M` formatting, x-axis labels thin out for 30/90/180-day ranges, and chart labels render bright white.
- Privacy docs were corrected to describe iCloud Keychain provider-key sync and to clarify that Sparkle update checks apply only to direct-download macOS builds.
- Tests: `./scripts/SaneMaster.rb verify` passed 73 tests; `./scripts/SaneMaster.rb verify --ui --timeout 600` passed 107 tests in 243s on the Mini after fixing stale expired-trial UI expectations.
- Preflights: `./scripts/SaneMaster.rb appstore_preflight` now passes with warnings only: manual Watch marketing icon contrast inspection, provisional AppleEvents usage description reference, and uncommitted files. `./scripts/SaneMaster.rb release_preflight` passes with warnings only: uncommitted files, static UserDefaults/migration warning, expected appcast/Homebrew/webhook drift from live 1.3.2, and 6 pending emails.
- Visual verification: regenerated official App Store screenshots for iPhone/iPad/Watch and macOS. Mac screenshots required launching the capture script from Terminal inside the Mini GUI session because SSH `screencapture` lacks display access. Inspected screenshots show Watch product screens instead of Pro locks, Settings provider rows inline, Orders no-today fallback opening All with orders visible, and chart labels no longer cut off or garbled.
- Remaining before actual publish: commit the verified diff, submit 1.3.3 to App Store Connect, and handle direct-release expected drift during the release command. Pending support emails are a release-warning but not an app binary blocker.

## 2026-05-06: SaneSales Provider-Key Privacy + Stale Cache Fix Prepared

- User reported a serious SaneSales contradiction: iPhone showed SaneApps provider data/cached orders while Pro state appeared inconsistent, raising concern that private SaneApps sales might be broadcast to public users.
- Security audit found no public broadcast path, no embedded live provider secrets, no real SaneApps fixture payload, and aggregate-only SaneUI event telemetry. The screenshot issue was a UI/state contradiction: Settings correctly showed Pro, connected providers, and cached orders, while Orders showed first-run/no-provider empty-state copy.
- iCloud Keychain provider-key sync is intentional product behavior, not a bug. Provider keys remain synchronizable across the customer's own Apple devices.
- Stopped sharing full `Order` payloads through the App Group. App cache now stays app-local; widgets/watch read a sanitized `SharedSalesSnapshot` with aggregate revenue/order counts, provider rows, recent product/provider/amount/time only, and no customer emails, order IDs, receipts, or payment metadata.
- Fixed stale state on Pro/trial loss and provider removal: loaded sales data and shared widget/watch snapshots are cleared instead of leaving old private orders visible after access is lost.
- Fixed the iPhone Orders empty state so connected providers with cached orders but no orders in the selected range now says `No Orders in Range`, explains the selected range and cached order count, and offers `Show All Orders` instead of incorrectly saying to connect a provider.
- Fixed the Pro Orders default path: when the default Today range has zero visible orders but cached history exists, Orders now automatically opens All time instead of showing an empty/provider-settings card. Search and explicit custom ranges keep their no-result states.
- Fixed the iPhone Settings provider row: the long Lemon Squeezy row no longer stacks `Connected` above `Manage`; connected controls stay inline with a compact badge/button cluster.
- Added regression tests for iCloud Keychain provider sync, sanitized shared snapshots excluding private fields, Pro-loss cache clearing, connected-empty-range copy, and Pro Orders defaulting to all history when Today is empty.
- Updated in-app provider connection copy, README, website, support, privacy policy, and App Store metadata source to advertise iCloud Keychain provider sync accurately.
- Version bumped to `1.3.3 (1303)` and Xcode project regenerated from `project.yml`.
- Mini verification: `./scripts/SaneMaster.rb verify` passed 68 tests; watchOS target build passed; iOS Release-AppStore simulator build and macOS Release-AppStore build passed; release binary string scan found no test keys/live secrets (only expected Keychain account label strings).
- Visual verification: Mini simulator screenshot `/tmp/sanesales-audit-empty-range-orders-fixed.png` inspected cleanly; the affected Orders empty-state screen is not clipped/truncated and no longer shows the provider-setup contradiction. Follow-up Mini captures `/tmp/sanesales-orders-fallback.png` and `/tmp/sanesales-settings-provider-row.png` verify the Pro/no-Today fallback opens All time with orders visible and the Settings `Connected`/`Manage` row is inline.
- App Store preflight after the bump is blocked only by App Store Connect state: macOS `1.3.2` is still `WAITING_FOR_REVIEW`, while local is `1.3.3`. Next step is to withdraw/clear the macOS 1.3.2 review lane or wait for Apple to finish it, then rerun `./scripts/SaneMaster.rb appstore_preflight`.

## 2026-05-05: Custom Range Visual Regression Fixed, Not Yet Released

- Release-blocking iPhone custom range sheet regression was found after v1.3.1: the phone sheet reused the larger two-month calendar layout, day labels could wrap/split, disabled future days dimmed gray, and duplicate weekday symbols could disappear because `ForEach` used `id: \.self`.
- Fixed iPhone to use a single-month calendar while iPad keeps the two-month layout; day labels now stay single-line, unavailable day taps are guarded without SwiftUI disabled dimming, and weekday headers are enumerated by index.
- Watch dashboard text labels were normalized to white while keeping colored non-text accents.
- Added/expanded UI tests for Dashboard and Orders range buttons, custom sheet open/cancel/apply, previous/next month buttons, start/end boundary switching, calendar day taps, iPhone one-month layout, iPad two-month layout, and all seven weekday headers.
- Mini visual evidence copied to the controller: `/tmp/sanesales-custom-range-weekday-iphone.png`, `/tmp/sanesales-custom-range-weekday-ipad.png`, `/tmp/sanesales-watch-demo-white.png`, `/tmp/sanesales-watch-recent-white.png`.
- Final Mini verification: `./scripts/SaneMaster.rb verify --ui --timeout 420` passed 91 tests in 240s. Targeted iPhone/iPad layout and day-tap tests also passed; Watch simulator build and screenshots passed.
- Status: source is fixed and verified but uncommitted/unreleased. Next release needs a version bump above 1.3.1 before direct/App Store packaging.

## 2026-05-04: SaneSales 1.3.1 Released + Submitted

- Direct release completed successfully via `release.sh --full --version 1.3.1 --deploy` on the Mini.
- Notarization accepted, ZIP uploaded and verified at `https://dist.sanesales.com/updates/SaneSales-1.3.1.zip`, appcast propagated with one v1.3.1 entry, website deployed, Homebrew cask updated, and email webhook updated to `SaneSales-1.3.1.zip`.
- GitHub release `v1.3.1` was created with the ZIP asset.
- App Store Connect macOS v1.3.1 build 1301 submitted and is `WAITING_FOR_REVIEW`.
- App Store Connect iOS/watch v1.3.1 build 1301 submitted and is `WAITING_FOR_REVIEW`.
- Release commits pushed: `acd9a83` version bump, `1f6e25a` metadata/site links, `877c4cd` release metadata.

## 2026-05-04: Final Mini Screenshot Capture Hardening

- Confirmed the proven Mini GUI capture path is `~/SaneApps/infra/SaneProcess/scripts/mini/capture-mini-screenshot.sh` / `mini-gui-run.sh`; plain SSH `screencapture` is not valid evidence for Mini GUI screenshots.
- Hardened `scripts/capture_appstore_screenshots.sh` so simulator captures wait for populated UI state, macOS App Store screenshots use the validator's 1280x900 canvas, and `.capture_manifest` records `iphone,ipad,watch,mac`.
- Fixed Watch screenshot demo behavior so `--demo` can show demo data without a Pro unlock, and added a screenshot-only Recent Sales layout that avoids the Watch clock overlay and rounded-crop clipping.
- Added a release-safety test that guards the Mini screenshot capture delays, macOS canvas, Watch demo unlock, and Watch Recent Sales screenshot layout.
- Final Mini verification: `./scripts/SaneMaster.rb verify --ui --timeout 900` passed 85 tests in 161s after cleanup.
- Final Mini App Store screenshot validation passed for iPhone, iPad, Watch, and Mac. Contact sheets were visually inspected: Latest Sale is visible on iPhone/iPad/Mac, Basic/Pro gates are present without crowding, and Watch recent sales are readable with no clock overlap or row clipping.

## 2026-05-04: SaneSales 1.3.1 Release Prep

- Bumped all SaneSales targets from 1.3.0 (1300) to 1.3.1 (1301) so App Store Connect macOS and iOS lanes are clear for a new submission.
- Updated App Store whats_new metadata for macOS and iOS to describe the Latest Sale dashboard visibility fix instead of the previous custom-range release.
- Refreshed the canonical iPhone and iPad App Store dashboard screenshots from the Mini-verified Pro dashboard captures that show the new Latest Sale section. Screenshot PNGs are ignored by git but are used by App Store tooling from Screenshots/.
- Mini verification after release-prep edits: ./scripts/SaneMaster.rb verify --ui --timeout 900 passed 84 tests in 155s.
- Direct preflight after the bump passed with caution: expected pre-publish appcast/Homebrew/webhook version drift remains at live 1.3.0; pending-email warning still reports 2 pending; UserDefaults/migration warning is covered by existing migration/unit coverage plus a Mini release-style launch pass, but a full over-installed production upgrade visual capture was blocked by headless SSH display access.
- App Store preflight after the bump passed with warnings only: Watch marketing icon needs manual contrast inspection and AppleEvents usage description remains a provisional/compiled-out review item. Watch icon was manually inspected and is high contrast; Watch screenshots exist but the Recent Sales screenshot is visually cramped at the rounded crop edges.
- Mini release-style launch after the bump: ./scripts/SaneMaster.rb test_mode --release built Release, staged /Applications/SaneSales.app, launched a single fresh instance, and showed no crash reports/startup failure in logs.

## 2026-05-04: Dashboard Latest Sale Visibility Fix

- Research confirmed current sales trackers avoid empty default dashboards by exposing latest/recent transaction activity and freshness cues alongside range-based charts.
- Added a compact `Latest Sale` dashboard section showing the newest paid order, timestamp, provider, product, and net amount even when the selected dashboard range would otherwise be empty.
- Basic gating remains intact: Basic still defaults to Today and keeps 7D/30D/All/Custom and charts/order-history depth behind Pro; Pro shows the same latest sale plus unlocked range/chart views.
- Mini verification: `./scripts/SaneMaster.rb verify` passed 56 tests; `./scripts/SaneMaster.rb verify --ui` passed 84 tests in 237s; `test_mode --release` and Basic launch mode passed.
- Visual verification: Mini-generated iPhone and iPad dashboard screenshots for Basic and Pro were inspected; the new section is visible, not crowded, and does not overlap the chart/upgrade sections.

## 2026-04-24: Product Hunt Readiness / Website Source Sync

- Product Hunt website audit found live `sanesales.com` was correct, but the Mini repo source had drifted behind the live site and still contained the old hero copy, duplicate locked Apple Watch website screenshots, stale spreadsheet download link, and `0% Telemetry` footer copy.
- Repo source was synced to the live-approved launch state: approved "Stop checking three dashboards..." hero, Dashboard-first screenshot carousel, product Watch screenshots with cache-busting, `No Subscriptions / 0% Spying / 100% On-Device` footer, support/crypto copy retained, and `sanesales-vs-spreadsheets.html` download link updated to `SaneSales-1.3.0.zip`.
- `docs/support.html` now uses the tracked `images/branding.png` asset instead of untracked `images/icon.png`.
- Mini HTML audit after the fix found `HTML_AUDIT_FAILURES=0`; `./scripts/SaneMaster.rb check_docs` and `./scripts/SaneMaster.rb saneui_guard .` passed.
- Fresh Mini visual audit screenshots were captured with Playwright after a 4-second animation delay: `/tmp/sanesales-audit-shots/home-desktop-delay.png` and `/tmp/sanesales-audit-shots/home-mobile-delay.png`. Desktop passed cleanly; mobile is usable, with the comparison table still horizontally scrollable on narrow screens.
- Mini `./scripts/SaneMaster.rb verify --ui` passed 83 tests in 214 seconds on 2026-04-24 after the parallel-run false failure was documented in `.claude/research.md`.
- App Store Connect check on 2026-04-24: macOS 1.3.0 is `READY_FOR_SALE`; iOS 1.3.0 is still `WAITING_FOR_REVIEW`; public lookup still returned iOS/public version 1.2.6.
- Remaining launch caveat: Lemon Squeezy hosted file for SaneSales still shows `SaneSales-1.2.7.zip` while appcast/website/webhook/Homebrew are at 1.3.0; replace the hosted file in the Lemon Squeezy dashboard before heavy Product Hunt traffic if direct buyers may use the hosted file.

## 2026-04-23: SaneSales 1.3.0 Released

- Added Pro custom date ranges with editable start/end dates and a calendar range picker.
- Dashboard and Orders now share the selected custom range and enforce Basic gating correctly.
- App Store entitlement refresh now picks up redeemed offer codes/restored purchases more reliably through shared SaneUI license refresh work.
- Updated App Store metadata, README, changelog, website copy, and website screenshots for the custom-range release.
- Refreshed canonical App Store screenshot files from the Mini-verified Pro screenshots.
- Mini verification: `./scripts/SaneMaster.rb verify --ui` passed with 83 tests on 2026-04-23.
- Release command verification: `./scripts/SaneMaster.rb release --full --version 1.3.0 --deploy` passed its built-in Mini verification lane with 55 tests before packaging.
- Direct channel is live at `https://dist.sanesales.com/updates/SaneSales-1.3.0.zip`; appcast, website JSON-LD, Homebrew cask, GitHub release `v1.3.0`, download redirect, and email webhook all verified at 1.3.0.
- App Store Connect state: macOS 1.3.0 and iOS 1.3.0 are both `WAITING_FOR_REVIEW`; previous public App Store versions remain live until Apple approval.
- Final release commits: `7a1fec7` version bump, `fd84491` release metadata sync. Both Mini and Air repos were synced to `fd84491`.

- Pricing rollout approved on 2026-04-14: direct and App Store copy should present `Basic free + Pro $24.99 once`. Keep StoreKit product ID `com.sanesales.app.pro.unlock.v2`.
- Pricing language should stay consistent across README, `docs/index.html`, long-tail guide CTAs, and in-app unlock fallbacks. No apology pricing copy and no subscription wording for the product itself.
- Track rollout impact with direct checkout conversion, App Store unlock rate, activation-to-paid conversion, and whether long-tail guide CTAs still pull traffic after the price increase.
- Use `CHANGELOG.md` and `project.yml` for the current release picture; the notes below capture older launch work only.
- The old `WAITING_FOR_REVIEW` summary at the top of the historical notes is not current anymore.
- Keep new handoff updates above the archival sections below.

## Archived Notes

## Session 1: Full Project Scaffold

### Done
1. **Complete app built** — 22 Swift files, iOS 17 + macOS 14, both platforms build clean
2. **LemonSqueezy integration** — Full JSON:API adapter with pagination, date parsing, error handling
3. **All tests pass** — 20/20 (API parsing, metrics aggregation, cache round-trip, provider edge cases)
4. **API verified** — Tested against live SaneApps data (160 orders, $785 total revenue)
5. **5-doc standard** — CLAUDE.md, README.md, DEVELOPMENT.md, ARCHITECTURE.md, SESSION_HANDOFF.md

### Architecture
- `SalesProvider` protocol → actors per platform (LemonSqueezy, Gumroad, Stripe)
- `SalesManager` (@MainActor @Observable) → central state coordinator
- `CacheService` → UserDefaults offline cache
- `KeychainService` → API key storage
- Shared SwiftUI views between iOS and macOS

## Session 2: Gumroad + Stripe Day-One Readiness

### Done
1. **Refund-aware revenue** — added `refundedAmount` + `netTotal`, metrics now use net-of-refunds where available
2. **Gumroad pagination** — follows `next_page_url` when fetching all sales
3. **Apple Silicon only** — macOS targets restricted to `arm64`; iOS Simulator excludes `x86_64`
4. **Compatibility testing** — tests pass on macOS (arm64) and iOS Simulator (26.2 + 26.0.1)

## Session 3: Website + UI Overhaul + v1.0 Release Builds

### Done
1. **Website rebuilt** — `docs/index.html` cloned from SaneBar template with SaneSales content
2. **Privacy page updated** — `docs/privacy.html` CSS matched to neutral color scheme
3. **SaneUI compliance** — Extensive UI overhaul (colors, SF Symbols, `.foregroundStyle` fixes)
4. **macOS v1.0 DMG created** — Developer ID signed, notarized, stapled
5. **iOS v1.0 archive created** — builds clean
6. **project.yml signing fixed** — All targets use automatic signing
7. **All 20 tests passing** across 4 suites

## Session 4: Glass UI, App Store Upload, LemonSqueezy, Ship Prep

### Done
1. **Glass UI overhaul (light mode)** — Switched all glass from `.regularMaterial` to `.ultraThinMaterial` with `Color.brandBlueGlow` tint overlays. Files: `DashboardView.swift`, `SalesCard.swift`, `OrdersListView.swift`, `ContentView.swift`. User approved: "good enough".
2. **Chart $600 label cutoff fixed** — Added `.padding(.top, 8)` before `.clipped()`, increased frame height from 200 to 220.
3. **Full screenshot set captured** — 20 screenshots (iPhone 6.7" + Mac, light + dark, 5 screens each) in `Screenshots/`.
4. **Widget App Store fixes** — Created `Widgets/SaneSalesWidgets.entitlements` with app-sandbox + network.client. Added `@main WidgetBundle` entry point to `SalesWidget.swift`. Wired entitlements in `project.yml` for both macOS and iOS widget extensions.
5. **iOS + macOS uploaded to App Store Connect** — Both builds successfully uploaded via `xcrun altool`. Universal purchase under single bundle ID `com.sanesales.app`.
6. **Notarized DMG built** — `release.sh` ran successfully. DMG uploaded to shared R2 bucket `sanebar-downloads`.
7. **Appcast.xml created** — v1.0 entry with EdDSA signature for Sparkle updates.
8. **Website deployed** — `docs/` deployed to Cloudflare Pages at sanesales.com.
9. **LemonSqueezy product live** — Product ID 822714, published. Checkout UUID: `5f7903d4-d6c8-4da4-b3e3-4586ef86bb51`.
10. **Checkout Worker updated** — `go.saneapps.com/buy/sanesales` → LemonSqueezy checkout (verified 302 redirect). All 5 products confirmed working.
11. **saneapps.com updated** — SaneSales changed from "Coming Soon" to "Live" with link to sanesales.com. Deployed.
12. **Desktop wallpaper created** — `~/Desktop/Wallpapers/SaneSales.png` using feathered circular alpha mask on real app icon over navy gradient. User said "PERFECT!!!!". Method saved to Serena memory `wallpaper-generation-method`.
13. **SaneClick wallpaper created** — Same method, needs edge tweaking (icon edges brighter than gradient).
14. **Products config updated** — `infra/SaneProcess/config/products.yml` updated with checkout UUID, dist domain, appcast URL, type changed to `universal`.
15. **Git committed + pushed** — Two commits: `548accf` (v1.0 release prep) and `2b4cc55` (widget fixes).

### Commits This Session
- `548accf` — v1.0 release prep: website, glass UI overhaul, signing, demo data
- `2b4cc55` — fix: widget entry point and sandbox entitlements for App Store

### Known Issues
- **XcodeGen overwrites entitlements** — Running `xcodegen generate` resets `SaneSalesWidgets.entitlements` to empty `<dict/>`. Must restore content after regenerating.
- **SaneClick wallpaper** — Icon edge colors (rgba 26,39,68) don't blend as smoothly as SaneSales. Needs feather radius adjustment or gradient color-matching.

### Remaining To Ship

#### Blockers — ALL RESOLVED
- [x] **`dist.sanesales.com` working** — DNS + Cloudflare Worker + R2 bucket configured. DMG served correctly.
- [x] **App Store Connect metadata complete** — All metadata uploaded via ASC API (description, keywords, screenshots, pricing, privacy, review details).
- [x] **Submitted for App Store review** — Submission ID: `1373bfb1-83a5-4ae4-9cc0-17c6c463874d`. Status: **WAITING_FOR_REVIEW** (submitted 2026-02-10 23:15 UTC).

#### Non-Blockers
- [ ] **Uncommitted files** — `design-references/`, `docs/images/coin-symbol.png`, `docs/images/sanesales-background.html`, infra changes (sane-checkout.js, products.yml)
- [ ] **SaneClick wallpaper tweaking** — Edge blending not as clean as SaneSales
- [x] **Live validation** — LemonSqueezy verified against live data. Gumroad + Stripe keys confirmed present in Keychain.

### Infrastructure Changes (Outside This Repo)
- `infra/cloudflare-workers/sane-checkout.js` — Added `sanesales` entry
- `infra/SaneProcess/config/products.yml` — Updated SaneSales config
- `web/saneapps.com/index.html` — SaneSales changed to Live

## Session 5: App Store Submission + Documentation Audit

### Done
1. **App Store review submission** — Fixed all blockers (reviewer contact, app privacy, iPad screenshots), submitted for review
2. **iPad screenshots** — Booted iPad Pro 13" simulator, activated demo mode (`--demo`), captured 6 screenshots (3 light + 3 dark, 2048x2732)
3. **iPhone screenshot fix** — Re-uploaded stuck 04-products screenshot
4. **App Privacy** — Set "Data Not Collected" via ASC web portal (not available via API)
5. **Review detail** — Created with phone +1 212 555 0100, demoAccountRequired=false
6. **Demo mode on iPad** — Used `xcrun simctl launch -- --demo` to activate DemoData (fictional "Pixel Studio" store)
7. **14-perspective docs audit** — Full audit via free NVIDIA models (Mistral + DeepSeek), score 7.1/10
8. **Documentation updates** — SESSION_HANDOFF.md, README.md, DEVELOPMENT.md, docs/index.html all updated

### Key IDs
- Review Submission: `1373bfb1-83a5-4ae4-9cc0-17c6c463874d` (WAITING_FOR_REVIEW)
- iPad Screenshot Set: `71abe095-e9db-46fa-affd-fbd1a8447707`
- iPad Simulator UDID: `46EEDF7A-5C0E-419A-90CA-4652B8C735C8`

### Known Issues
- **XcodeGen overwrites entitlements** — Running `xcodegen generate` resets `SaneSalesWidgets.entitlements` to empty `<dict/>`. Must restore content after regenerating. (Also documented in DEVELOPMENT.md now.)

### Pending
- [ ] App Store review decision (WAITING_FOR_REVIEW)
- [ ] Uncommitted website changes in `docs/index.html` (trust badges + testimonials carousel)
- [ ] `DOCS_AUDIT_FINDINGS.md` and `SEO_AUDIT_FINDINGS.md` — audit artifacts, gitignore or delete

## Session 6: v1.2 Release + Pipeline-Wide Infrastructure Audit

> Last updated: 2026-02-11

### Done
1. **v1.2 released** — Fixed misleading API key error messages, auto-trim whitespace on paste. Built, signed, notarized, ZIP'd, Sparkle-signed.
2. **v1.2 deployed** — ZIP uploaded to shared R2 bucket, sane-dist Worker updated to accept .zip, appcast.xml updated, website deployed.
3. **Pipeline-wide infrastructure audit** — Fixed systemic config drift across ALL SaneApps:
   - All 7 `.saneprocess` files → `r2_bucket: sanebar-downloads` (shared bucket)
   - `release.sh` default bucket fixed
   - `wrangler.toml` rewritten with all 8 routes (added sanesync, sanevideo)
   - Email webhook `PRODUCT_CONFIG` updated to current versions for all 5 apps
   - Missing DNS records created for `dist.sanehosts.com`, `dist.sanesync.com`, `dist.sanevideo.com`
   - Worker routes created for sanesync and sanevideo domains
4. **Orphan infrastructure deleted** — 3 orphan R2 buckets (saneclick-dist, sanehosts-dist, sanesales-downloads) emptied and deleted. Legacy `sanebar-dist` Worker deleted.
5. **E2E verification** — 33/33 checks pass across all 7 dist domains
6. **Customer impact assessed** — 4 SaneHosts customers had broken webhook download links, but LemonSqueezy provides its own download at purchase — minimal real impact. SaneBar/SaneClip customers got stale versions but Sparkle auto-updates.
7. **All repos committed and pushed** — SaneClick, SaneHosts, SaneSync, sane-email-automation all pushed. SaneVideo committed locally (blocked by faraday CVE in pre-push hook).

### Commits
- `97dc5f7` — fix: improve API key error messages with specific error types
- `4cec689` — Bump version to 1.2 for release
- `3abcd22` — Add v1.2 to appcast for Sparkle auto-updates

### Key Lesson
Per-app R2 buckets were never wired to the sane-dist Worker — only `sanebar-downloads` was. This caused broken download links for SaneHosts customers and stale versions in webhook emails for all other apps. Now standardized: ONE shared bucket, ONE Worker, all apps upload to `sanebar-downloads`.

## Session 7: Launch Video + Website Brand Recovery

> Last updated: 2026-05-14

### Done
1. **SaneSales website hero restored to SaneApps brand** — Compared SaneBar, SaneClip, SaneClick, SaneHosts, and brand docs; changed SaneSales hero to `Bring Sanity to your Sales Tracking`, concise human copy, simple trust badges, and clear Download / Pro CTAs.
2. **Dense pricing moved below product proof** — Removed long pricing/server/Homebrew copy from the first viewport and added a dedicated pricing section lower on the page.
3. **Public website deployed** — `release.sh --website-only` deployed to Cloudflare Pages and verified `https://sanesales.com/` contains the corrected H1 and App Store marker.
4. **App Store download path restored** — Added the iPhone/iPad App Store CTA with `data-appstore-ios-link` so website deploy preflight can verify the live App Store listing.
5. **First-paint animation failure fixed** — Playwright screenshots showed the hero could render nearly unreadable while delayed animations started from `opacity: 0`; animation now stays legible at first paint.
6. **Launch video copy hardened** — Removed buyer-irrelevant implementation details from the SaneSales launch video. Current rule: every visible line must be a problem, benefit, proof point, or CTA; license-check mechanics, provider-key mechanics, and backend labels are cut.
7. **Website sales copy tightened** — Removed the Homebrew command from the pricing offer, removed the separate donation/support funnel from the main sales page, replaced technical privacy phrasing with buyer language, and removed weak testimonials that diluted purchase intent.

### Verification
- Local Browser DOM/title/console: passed for `http://127.0.0.1:8765/`.
- Local Playwright desktop + mobile screenshots: passed after animation fix.
- Live curl check: `https://sanesales.com/` contains `Bring <em>Sanity</em> to your Sales Tracking` and one `data-appstore-ios-link`.
- Live Playwright interaction: Products tab switches to product screenshot content; no site-code console errors. Headless environment blocks Cloudflare beacon, which is external analytics noise.
- Mini `./scripts/SaneMaster.rb verify`: passed, 76 tests in 15s after strengthening recent demo data so the rolling positive-momentum test remains true.
- `SaneMaster.rb check_docs`: exits 0 cleanly after updating the SaneProcess README operator docs map.

### Open Issues
- Large uncommitted launch-video / website / screenshot change set remains unstaged.

### 2026-05-14 Launch Marketing Follow-Up
- **Pricing consistency pass completed** — Website, guide CTAs, README, Product Hunt package, and `.outreach.yml` now state the same offer: direct Pro is `$9.99` with code `SANE60` through May 21, 2026; regular price is `$24.99`. Hero copy now explains that checkout may show regular `$24.99` first and SANE60 drops it to `$9.99`.
- **Website deployed and verified** — Cloudflare Pages deploy completed at `https://e491479d.sanesales-site.pages.dev`; live `https://sanesales.com/` contains the hero SANE60 caveat, pricing-section caveat, comparison full date, and valid JSON-LD. Checkout redirect verified to Lemon Squeezy with `checkout[discount_code]=SANE60`.
- **Product Hunt page refreshed** — Signed-in Mini Safari updated the public Product Hunt product page tagline, description, GitHub URL, pricing type, and thumbnail. Public page now shows `Private native sales tracker for indie sellers`, stronger privacy/no-subscription description, `Free Options`, and GitHub link.
- **Product Hunt launch state corrected** — Existing Product Hunt page is live, but it was an unfeatured/low-distribution launch. API evidence: `featuredAt: null`, `dailyRank: 565`, `votesCount: 1`, `commentsCount: 1`, scheduled/launched May 6, 2026.
- **Product Hunt relaunch review requested** — Signed-in Mini Safari `New launch` flow said `SaneSales recently launched on Product Hunt. Is this new launch a major update?`. Submitted an honest moderation request explaining the incomplete/unfeatured first launch and refreshed launch package. Product Hunt showed: `Thank you! We're reviewing your request and will be in contact with you shortly.`
- **Product Hunt maker comment updated** — Existing public maker comment now includes the YouTube demo, privacy/no-private-sales-data claim, and SANE60 launch-week offer.
- **Product Hunt limitation found** — Existing launch-post API data still reports the original launch tagline/media; Product Hunt product-page settings do not expose a video field, and the API schema has no mutation for editing existing launch post media. Relaunch requires Product Hunt moderation approval because SaneSales recently launched.
- **Hosted Product Hunt assets** — Refreshed Product Hunt images are now live under `https://sanesales.com/images/product-hunt-*.png` and copied to the Mini Desktop in `~/Desktop/SaneSales-Product-Hunt-Package/`.
- **Meaningful launch schedule added** — `.outreach.yml` now has a `launch_calendar` with exact gates and automation IDs. Active automations: `submit-sanesales-directories` (May 15 support surfaces), `check-product-hunt-relaunch-review` (daily through May 18), `sanesales-x-opportunity-scan` (May 16), `sanesales-indie-hackers-launch` (May 19 fallback / May 21 follow-on if PH approved), `sanesales-show-hn-fallback` (May 20 fallback), and `sanesales-offer-final-day-check` (May 21). Core rule: PH/IH/HN are meaningful conversation launches; MacUpdate/G2/LaunchingNext/SaaSHub are support surfaces, not launch substitutes.
- **Launch-readiness gate current** — On 2026-05-14, Mini `customer_ui_sweep --no-exit` passed and Mini `release_preflight` passed with 0 issues / 4 warnings. `./scripts/SaneMaster.rb launch_readiness --json` now returns `ok: true` for the current SaneSales direct/support-surface launch window. Product Hunt relaunch still remains channel-gated on moderation approval; directory receipts must be recorded after submission.

## 2026-05-15 Launch Ops

- 10:01 EDT recheck changed the lane from yesterday's go to today's no-go. Mini `./scripts/SaneMaster.rb launch_readiness` now fails because `outputs/release_preflight_status.json` flipped to `failed` with 1 issue: `Customer UI action contract: Receipt source fingerprint is stale; rerun customer UI QA after the latest code change`.
- Repair attempt failed before app QA started. Mini `./scripts/SaneMaster.rb customer_ui_sweep --json` returned `Mini visual precheck failed before customer UI sweep: 1 Peekaboo command(s) failed`; the new receipt is [`outputs/visual_smoke/visual_smoke_20260515-100332_66128/summary.md`](/Users/sj/SaneApps/apps/SaneSales/outputs/visual_smoke/visual_smoke_20260515-100332_66128/summary.md), where `menu-image` failed and `screen-image` still passed.
- Today’s 10:00 Eastern `Directories` slot was not executed. Per the launch gate rule, I did not open or submit MacUpdate, LaunchingNext, G2, SaaSHub, or BetaList forms once the current gate went red.
- Prepared-but-not-submitted support-surface targets remain:
  - [Product Hunt product page](https://www.producthunt.com/products/sanesales)
  - [Website](https://sanesales.com)
  - [Hosted YouTube demo](https://youtu.be/FmyGTWpBF4M)
  - [Direct download ZIP](https://dist.sanesales.com/updates/SaneSales-1.3.5.zip)
  - [Direct checkout](https://go.saneapps.com/buy/sanesales)
- `.outreach.yml` now marks LaunchingNext, MacUpdate, G2, and optional SaaSHub as `blocked_by_launch_gate` with the exact 2026-05-15 blocker, while BetaList remains intentionally unattempted because it is not part of today's core support-surface schedule.

## 2026-05-16 Launch Ops

- Mini `./scripts/SaneMaster.rb launch_readiness --json` stayed red again. The current blocker is still `outputs/release_preflight_status.json` failing with 1 issue: `Customer UI action contract: Receipt source fingerprint is stale; rerun customer UI QA after the latest code change`.
- No due launch-calendar work was executed. The overdue `Directories` lane stayed paused and the 10:00 Eastern `X opportunity scan` was skipped because the launch gate was not green.
- No public reply, no listing submission, and no Product Hunt scheduling action was taken. Public support-surface state is unchanged: [Product Hunt product page](https://www.producthunt.com/products/sanesales), [website](https://sanesales.com), [Hosted YouTube demo](https://youtu.be/FmyGTWpBF4M), [direct download ZIP](https://dist.sanesales.com/updates/SaneSales-1.3.5.zip), and [direct checkout](https://go.saneapps.com/buy/sanesales).
- Next launch-ops date is 2026-05-18 for the Product Hunt moderation check, but only if the stale customer UI receipt blocker is cleared first.

## 2026-05-17 Launch Ops

- Mini `./scripts/SaneMaster.rb launch_readiness --json` returned green again at 09:03 EDT. The current receipt is go for support-surface work only: `release_preflight` passed and still reports 3 warnings (dirty worktree, 1 pending customer email, evening release timing).
- Re-ran the overdue `Directories` lane with the green gate. Launching Next accepted the canonical free submission and returned receipt [`https://www.launchingnext.com/thanks/?i=134060`](https://www.launchingnext.com/thanks/?i=134060) with status `In Queue (Estimated Wait: 4 Months)`. No paid Fast-Track upgrade was taken.
- Exact submitted Launching Next copy matched `.outreach.yml`: headline `Private native sales tracker for indie sellers`; privacy-first description with direct Pro `$9.99` + code `SANE60` through May 21, 2026 and regular `$24.99`; tags `sales analytics, mac app, ios app, lemonsqueezy, gumroad, stripe, indie hackers, revenue tracking`; company type `Bootstrapped startup`; marketing budget `$0`; submitter `Mr. Sane`; email `hi@saneapps.com`; newsletter opt-in `false`; anti-spam answer `5`.
- Remaining directory blockers were re-verified live: MacUpdate still redirects to member login at [`https://member.macupdate.com/member/login/%20content%20submit`](https://member.macupdate.com/member/login/%20content%20submit); G2 create-profile is visible at [`https://sell.g2.com/create-a-profile`](https://sell.g2.com/create-a-profile) but no seller/profile session was present; optional SaaSHub now reaches second-step staging at [`https://www.saashub.com/services/new?url=https%3A%2F%2Fsanesales.com&commit=Continue`](https://www.saashub.com/services/new?url=https%3A%2F%2Fsanesales.com&commit=Continue) but was intentionally not carried further because it is no longer low-friction.
- Public support-surface URLs otherwise remain unchanged: [Product Hunt product page](https://www.producthunt.com/products/sanesales), [website](https://sanesales.com), [Hosted YouTube demo](https://youtu.be/FmyGTWpBF4M), [direct download ZIP](https://dist.sanesales.com/updates/SaneSales-1.3.5.zip), and [direct checkout](https://go.saneapps.com/buy/sanesales).
- Next launch-ops date stays 2026-05-18 for the Product Hunt moderation check.
