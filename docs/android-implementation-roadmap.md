# Christian Golfers Cape Town — Android Flutter implementation roadmap

**Status:** planning baseline, 30 October 2026. This roadmap is based on a source review, not a fresh device or production database audit. Existing features may depend on configuration and data. No feature below is a promise of national data coverage or official handicap authority.

**Version 2 work started:** the package version is set to 2.0.0+2. The live scorecard warns the host about unsaved edits before changing holes or finishing, and explains penalty scoring. This is not offline auto-save or round recovery: edits can still be lost on app exit, process death, or when another device advances the shared hole. The feature inventory and phases below remain outstanding as described. Verify the Play Console's latest version code before uploading; the release build number must be higher.

The profile now uses the stored handicap and completed-round statistics instead of sample values, and its round history link opens the existing history screen with a back button. This does not implement a handicap history or official handicap integration.

## Product outcome and guardrails

Make a round easy to start, easy to score with one hand, and reliable when mobile reception disappears. Preserve the existing dark CGCT branding, welcome and authentication flows, Fellowship, daily scripture, profiles, course browsing, rounds, existing historical standings, administration and account controls. Avoid breaking stored rounds, links, login sessions or existing competition results. Introduce migrations additively and ship behind feature flags where behavior changes.

**Status key:** Existing = code is present; Partial = useful pieces exist but the selected outcome is incomplete; Planned = no implementation established by this review. Existing does not mean verified in production. Treat repository migrations and assets as evidence of intended behavior, not proof that a live deployment is current.

## Feature inventory and priorities

| Priority | Selection | Current status and evidence | Required outcome |
|---|---|---|---|
| P0 | Course and tee selection | Partial: course and tee models, repository, and round selection exist. Course/tee data is incomplete. | Search, select course and actual tee; display data source and unrated state. |
| P0 | GPS green and hazard distances | Partial: hole tee/green coordinates and estimated tee-to-green distance exist; no established live device-to-green/hazard feature. | Foreground GPS to front/centre/back and mapped hazards, with accuracy and missing-data states. |
| P0 | Offline course maps and scorecards | Partial: bundled course/hole data exists; live score saves use Supabase, no durable offline queue established. | Download authorized course package, score offline, sync safely and show status. |
| P0 | 9/18-hole round setup | Partial: nine-hole data and front/back card displays exist; live navigation currently bounds holes 1–18. | Explicit front/back/custom nine or 18, correct totals and completion. |
| P0 | Digital scorecard and net scoring | Existing/partial: hole entry, card, gross/net calculations exist; official tee ratings often missing. | Reliable multi-player card with verified inputs and clearly labelled provisional net scoring. |
| P0 | Penalty and putt recording | Existing: live score entry and storage include putts, penalties and sand shots. | Preserve, validate and clarify whether penalties are included in gross strokes. |
| P0 | Auto-save and round recovery | Partial: explicit score save and remote persistence exist; durable local autosave/recovery not established. | Save drafts locally on change, restore after process death and reconcile with server. |
| P1 | League A/B/Social standings | Partial: league screens, historical data and admin standings exist. | Server-backed, season-scoped standings with provenance, live and final views. |
| P1 | Round verification and handicap records | Partial: handicap calculations and completed results exist; verified marker workflow and official integration are not established. | Attestation, review, corrections and immutable handicap snapshots; label estimates. |
| P1 | Accessible, battery-efficient interface | Partial: themed UI and navigation exist; accessibility and battery performance not yet proven. | Large touch targets, scalable text, contrast, accessible semantics, restrained foreground GPS. |
| P1 | Competition points and best-seven season rules | Partial: `SeasonCompetitionCalculator` contains a proposed points schedule, ties and best-seven final calculation; admin uses live calculation. Official club rules and end-to-end finalization are unconfirmed. | Owner-approved, versioned rules; auditable server calculations and final standings. |
| P1 | Live multi-player scoreboards | Partial: score and player streams and round leaderboard exist. | Reliable shared scoreboard, reconnect and permission checks, including offline states. |
| P2 | Club-distance history | Planned: no established per-club shot history. | Optional manual shot records and robust personal distance summaries. |
| P2 | Fairway, GIR and putting statistics | Partial: fields are recorded; complete longitudinal analytics not established. | Per-round and trend metrics with correct denominators and missing data handling. |
| P1 | League administration and audited score corrections | Partial: allowlisted admin dashboard, round data and invitations exist; audited correction workflow not established. | Role-scoped correction with reason, before/after, actor, timestamp and recalculation. |
| P2 | Weather, pace-of-play and rules assistance | Partial: general lie-based advice exists; live weather, pace and rules assistant not established. | Optional sourced weather, privacy-aware pace and referenced rules guidance. |
| P2 | Android notifications and community messaging | Partial: local test and lobby round-start notifications, Fellowship/friends exist; remote push and messaging not established. | Opt-in push, preferences and controlled messaging with reporting/moderation. |
| P3 | Strokes gained and performance benchmarks | Planned: requires shot-level data and licensed reference benchmarks. | Show only with sufficient quality, coverage and valid reference data. |
| P3 | Personalised course and hole insights | Partial: generic lie guidance exists. | Use verified course geometry and sufficient personal history; show confidence. |
| P3 | Android Wear OS integration | Partial: phone notifications may be mirrored; no companion app established. | Optional watch interface and phone synchronization after device validation. |
| P3 | Automatic shot detection | Planned. | Opt-in sensor prototype, golfer confirmation and accuracy/battery gates. |
| P3 | Green contour mapping | Planned. | Only display licensed, surveyed and current contours with explicit coverage. |
| P3 | Official handicap integration, if authorised | Planned: local WHS-style estimates do not establish official status. | Authorized provider integration, consent, eligibility and verified submission/reconciliation. |

## Delivery sequence

### Phase 0 — Baseline and data trust

1. Inventory current app behavior on a physical Android device, deployed migrations, RLS policies and notification settings; reproduce round creation, navigation and score saving. Record version and environment.
2. Reconcile course identities against authoritative club sources. Local snapshot contains 361 catalog entries and 828 hole records across 52 courses, including 36 with 18 records; completeness and accuracy are not established. Official tee distances, ratings, imagery and hazards must be acquired and verified. Preserve source, license, units, date, verification status and attribution; do not invent hole imagery or mark GPS estimates as scorecard distances.
3. Agree on league eligibility, season dates, points schedule, ties, best-seven calculation timing and 9-hole treatment. Preserve imported historical totals separately from newly calculated standings.
4. Define pilot courses, supported Android devices, privacy choices, target GPS battery and accuracy thresholds with golfers and league owners.

**Exit:** baseline and trusted pilot data documented; owners sign off rules; current app flows remain usable.

### Phase 1 — Dependable on-course round (P0)

- Extend round setup with selected course, tee, 9/18 and specific holes; freeze course, tee, hole order, handicap index, ratings and rule version as a round snapshot. Validate incomplete/unrated data and use a clearly labelled provisional calculation when permitted.
- Add a local persistent database and outbox for rounds, scores and downloaded course packages. Save changes locally immediately, queue idempotent writes with stable mutation IDs, and show saved locally / syncing / synced / needs attention. Recover drafts on restart. Define edit ownership and version-based conflict detection; retain both conflicting edits for explicit resolution rather than silently overwriting. Handle retries, duplicate delivery, sign-out, account deletion and storage migration.
- Keep the existing Supabase repository interface while introducing local repositories and synchronization; move completion to an idempotent, transactional server operation after queued scores are synchronized. Preserve existing round and score records.
- Request foreground location in context; compute device-to-green and hazard distances only from verified coordinates, displaying metres, GPS accuracy, freshness and unavailable states. Add power-conscious update intervals and stop location updates when leaving the round. Download map tiles only where the map provider license explicitly permits offline use; provide a scorecard-only offline fallback.
- Refine the live hole screen: large score controls, hole navigation, visible save state, back navigation, clear gross/net labels, optional details, readable sunlight contrast and screen-reader labels. Keep existing visual identity.

**Exit:** a pilot golfer can start a 9- or 18-hole round, enter and recover scores after a restart without connectivity, reconnect without duplicates, and understand when GPS or data is unavailable. Existing online rounds and sign-in continue to work.

### Phase 2 — Trusted leagues and multiplayer (P1)

- Add marker/participant verification states: draft, submitted, disputed, verified and corrected. Store who verified, when, handicap and tee snapshots; do not call an estimated index official. A rejected or amended round returns to review.
- Move approved points, ties, season boundaries and best-seven rules into versioned server-side calculation. Publish round awards and both current and final tables; explain which rounds count. Keep proposed existing schedule disabled as an official rule until approved. A correction triggers deterministic recalculation and keeps an audit trail.
- Build protected admin workflows using existing allowlist/RLS approach. Require a correction reason and record old/new values, actor, timestamp and related version in an append-only audit record. Limit privileges to authorized owners/captains and verify access server-side.
- Harden live scoreboard subscriptions: reconnect, refresh, ordering, stale indicators and membership access; support locally pending scores without presenting them as confirmed for other players.

**Exit:** authorized staff can inspect a round, review a correction, and reproduce its points and standings; non-members cannot read or change protected data. Confirm tie, zero-score, incomplete and 9-hole cases with the club.

### Phase 3 — Golfer insights and communication (P2)

- Offer optional club selection and manual shot start/end capture. Derive median and spread after enough observations, excluding obvious outliers with golfer review; avoid prescribing clubs when data is insufficient.
- Summarize putts, fairways and GIR over verified rounds; define denominators, exclude unknowns, distinguish 9/18 and allow corrections. Provide simple round and trend views.
- Add a weather source with location consent, freshness, attribution and unavailable/offline state. Estimate pace from opt-in timestamps without tracking others invisibly. Link rules help to authoritative, current material and identify advice as guidance.
- Add server-triggered Android push with device token lifecycle, opt-in categories, quiet hours and deep links. For messaging, define membership visibility, retention, blocking/reporting and moderation before rollout. Keep existing local notification behavior working.

**Exit:** statistics agree with recorded cards, missing data is not treated as zero, notifications open the intended screen, and community controls are exercised with pilot users.

### Phase 4 — Advanced capabilities (P3)

- Wear OS: first validate phone notification mirroring; then prototype a small companion for green distances, current hole and score entry, with explicit pairing, offline recovery and conflict handling.
- Automatic shot detection: research sensors and permissions, validate on varied devices and swings, require confirmation/editing, and measure false detections and battery use before release.
- Strokes gained: collect sufficiently detailed, verified shot data and obtain benchmark rights; define method and sample thresholds before showing comparisons.
- Personal insights: derive from verified course and personal history; show confidence, source and an opt-out. Do not infer actual obstacles or hole layout from generic imagery.
- Green contours: assess cost, coverage, rights, freshness and competition restrictions; show only surveyed/authorized data and an unavailable state otherwise.
- Official handicap: pursue written authorization from the relevant governing body/provider, contractual/API access, golfer consent and correct rules for submission, correction and reconciliation. Until then label all computed values estimates.

**Exit:** each advanced feature meets an agreed pilot accuracy, privacy, license and battery threshold before wider release.

## Architecture and rollout

Retain Flutter, Riverpod, GoRouter and existing feature repositories. Add a local storage layer with versioned migrations and an outbox; use Supabase Auth, RLS and guarded transactional RPCs as the source of shared truth. Keep secrets and external provider credentials server-side. Store immutable round snapshots, score revisions, verification events, competition rule versions, award calculations and admin audit events. Add course geometry, hazards, imagery and source/license metadata with explicit verification and effective dates. Separate user location and shot history from public standings, with clear consent and deletion behavior. Keep offline data scoped to the signed-in account.

Use incremental migrations, feature flags, backfills and rollback plans. Preserve existing scores and historical league tables; validate new calculations against approved examples before activating. Measure crash-free rounds, round-start success, local save/recovery and sync conflict rate; collect location and battery metrics only with appropriate consent.

## Verification and release gates

- Automated domain tests: handicap allocation including plus handicaps and 9 holes, score/penalty validation, incomplete rounds, ties, best-seven and versioned rules; compare to owner-approved examples.
- Integration tests: RLS for member, marker, admin and outsider; idempotent completion and correction; migration of existing records; concurrent edits and server recalculation.
- Device scenarios: airplane mode before/during a round, process kill and restart, network loss during save, reconnect conflicts, denied location/notification permissions, GPS drift, low battery, large font, screen reader and back navigation. Validate on real paired watches when Wear is introduced.
- Course data checks: source provenance, permission, coordinate ranges, hole ordering, tee units, official ratings, photo rights and missing-data fallback. Validate each pilot course with the club.
- Pilot with golfers and captain, then closed testing; monitor issues and support a rollback. Reconfirm Play requirements and provider terms at release time.

## Decisions and dependencies

### Additional requested on-course features

The following remain planned unless otherwise stated: touch targets and layups; manual pin placement; shot distance logging; plays-like distances; per-player tees; match play, Stableford, skins, Nassau and Wolf; digital signatures; bag management and dispersion; weather and wind radar; course food orders; pace alerts; emergency/ranger contact; tournament leaderboards; and location sharing. FIR, GIR, putts, penalties and a shared round leaderboard have partial existing support as described above. These items require suitable course geometry, ratings, weather, verified rules or course/provider agreements as applicable. Wagering requires a separate legal and product review. Apple Watch requires a separately provisioned iOS build; no Apple Watch app exists today. Do not present generated contours, pin locations, distances or emergency connectivity as verified.

The supplied `south_africa_ultimate_complete_golf_courses_directory.csv` contains 356 rows with names, towns, provinces, hole counts, status and course type, but no tee ratings or per-hole distances. An initial normalized name comparison matches 109 rows to existing names and leaves 247 for review; aliases may represent the same facility. Reconcile those candidates before adding records to avoid duplicate courses and retain closed listings as inactive only after verification.

League owner must approve scoring rules, verification roles, correction policy and historical transition. Course owners/data providers must supply or license verified scorecards, tee ratings, hazards, photos and maps. Official handicap integration requires provider authorization. Offline maps, weather, push, benchmarking and imagery require suitable provider terms, credentials, budgets and operational ownership. Gemini can help locate and extract candidate information, but its results need source verification; the recent grounded request hit quota and established no nationwide coverage. No schedule is promised until pilot data availability, team capacity and these dependencies are agreed.
