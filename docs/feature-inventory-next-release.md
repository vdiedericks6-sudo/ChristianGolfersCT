# Christian Golfers Cape Town — feature inventory and next-release requirements

Status based on local source review on 30 October 2026. Implemented means code exists, not that it has been validated on the current device or deployed backend. Partial means important elements are missing. Planned means not established in the code reviewed. This document describes the intended next release; it does not assert that planned features are already built.

## Latest requested changes

- Settings-to-Fellowship navigation now switches to the existing tab instead of pushing a second shell page; a widget regression test covers the reported navigator assertion. Verify on the phone as well.
- Course search now offers round-ready and 9/18-hole filters alongside the existing province and text filters. A course with unknown hole count is excluded when a hole count is selected.
- New-round creation seats only the signed-in host in the checked migration and demo implementation; subsequent members can still join. Live database behavior should be verified against deployed migrations.
- The owner specified annual overall standings by competition points, preserving members and prior rounds. The official points schedule will be provided by the owner; annual standings have not yet been implemented and no records were reset or deleted.
- Admin member editing, handicap management, league assignment, game scheduling and fourball allocation require authorized server operations, access controls and audit history. Live round tracking across groups requires shared scheduling/round data and suitable member permissions.
- Moving Crew to a footer chat hub requires actual messaging, participant permissions, notification preferences and moderation; it is not yet implemented. Fellowship-wide annual standings require an approved points schedule and a secure member-wide aggregation.
- Dynamic GPS distances need verified green coordinates and foreground location permissions. Uphill/downhill approach cues and green contours require trustworthy licensed elevation data. Per-player virtual caddie, benchmarks, shot detection, Wear OS and authorized handicap integration retain the dependencies below; none is implemented merely by adding a label.

## Features in the app

| Feature | Status | Current behavior and remaining gap |
|---|---|---|
| Welcome, CGCT branding and themed navigation | Implemented | Flutter welcome, home and feature navigation; validate layouts on supported devices. |
| Accounts | Implemented/conditional | Email/password and persistent sessions; Google sign-in depends on provider configuration. |
| Profiles and round history | Partial | Profile and history use saved data; statistics and handicap history are not complete. |
| Daily word and Bible verse | Implemented | Local-date selection and refresh; confirm content and device behavior. |
| Course browsing | Partial | Bundled 361-entry catalog and live Supabase catalog; national coverage and data accuracy are not verified. |
| Course photos and hole artwork | Partial | Displays course/hole images if supplied and missing-data fallback. Verified licensed images are largely unavailable. |
| Tee selection | Partial | Existing tee records can be selected for a playable course. Most have only a neutral unrated club tee; missing colour rows are disabled. Actual tee data must be obtained and loaded. |
| Hole distances | Partial | Shows supplied per-tee distances or labelled tee-to-green GPS straight-line estimates. Current supplied directory does not include official hole distances. |
| Round creation and group | Partial | Create/join, four-player lobby, host navigation and shared scores exist. Explicit 9/18 setup and per-player tees are missing. |
| Scorecard and net | Partial | Gross/net calculations, shared scorecard, leaderboard and hole entry exist. Official ratings are generally missing and calculations require verification. |
| Putts, penalties, sand, fairway and GIR | Partial | Hole fields and controls exist; complete analytics, sand-save definition and validation are outstanding. Penalties are added to strokes entered. |
| Saving | Partial | Explicit remote score saving, with warning for unsaved host edits before changing hole/finishing. No durable offline auto-save or recovery; other navigation or another device can still cause unsaved edits to be lost. |
| League standings | Partial | Historical standings, League A/B/Social logic and admin view exist; validate live backend, league rules, season finalization and auditability. |
| Competition points and best seven | Partial | Proposed calculator and tests exist. Club approval, server-side authoritative rules, tie and season handling are required before treating results as official. |
| Multiplayer leaderboard | Partial | Round/player/score streams and leaderboard exist. Reconnection, conflict handling, offline synchronization and permissions require device/backend verification. |
| Handicap estimates | Partial | Local WHS-style calculations and profile data exist. Unrated tee placeholders make results provisional; no official handicap integration is established. |
| Admin dashboard | Partial | Member list now supports editing Handicap Index, provenance and visiting status through the verified existing admin-only RPC. Active round cards show shared current hole and each player's gross and hole count, refreshing every 45 seconds. Admin scheduling now allocates one to four registered members to a future round with a chosen host, course and tee. Arbitrary league assignment and audited corrections remain unimplemented. |
| Fellowship and Chat hub | Partial | Shared member-only chat is deployed with message-length validation, server-assigned author, author/admin deletion and polling. Chat replaces Courses in the footer; Courses remains accessible from Play Golf. Crew/friends management moves into Chat. Private channels, push, blocking/reporting, rate limiting and full message history remain unimplemented. |
| Notifications | Partial | Android local permission, test alert and lobby round-start alert exist; background remote push is not implemented. Watch mirroring depends on device settings. |
| Privacy and account deletion | Partial | In-app and public request mechanisms exist in source; confirm operational configuration and deletion behavior before release. |
| General shot advice | Partial | Lie-based hints exist; not personalized to verified hazards, weather or club data. |

## To implement for the next release

| Feature | Status | Missing pieces / dependencies |
|---|---|---|
| Foreground GPS front/centre/back | Planned | Device location permission, verified green coordinates, accuracy/freshness indicators, battery strategy, real-device validation. |
| Hazard distances and hole maps | Planned | Licensed and verified geometry and imagery, hazard locations, suitable map provider, attribution and coverage. |
| Map touch targets and layups | Planned | Interactive map and validated geometry; show both distances and signal accuracy. |
| Offline maps and scorecards | Planned | Licensed offline map downloads, local durable store, per-account queue, idempotent sync, conflict handling and recovery testing. |
| 9/18 hole setup | Planned | Hole selection and round snapshots, data and calculations for 9-hole rounds, database/RLS migration and completion validation. |
| Multi-player and multi-tee scoring | Planned | Per-player tee and handicap snapshots, database and UI updates, correct scoring and authorization. |
| Auto-save and round recovery | Planned | Durable local drafts, local-first score queue and conflict handling, process-death and offline testing. |
| Round attestation | Planned | Marker identity, submission/verification/dispute flow, signatures, audit history and permissions. |
| League score corrections | Planned | Authorized roles, immutable audit events, reason, before/after values and reliable standings recalculation. |
| Club-distance and shot tracking | Planned | Manual shot and club entry, consent, persistence, history and outlier handling. |
| Bag management and club dispersion | Planned | User-editable bag, adequate shot samples, map geometry and privacy-aware storage. |
| Virtual caddie | Partial | Basic lie advice exists; personal recommendations need shot history, verified distances, weather and confidence labels. |
| PlaysLike distance | Planned | Reliable elevation, temperature, wind and altitude inputs, methodology, source and update frequency. |
| Personal hole insights | Planned | Verified hole data and sufficient golfer history; confidence and missing-data states. |
| Putting, FIR and GIR statistics | Partial | Round history now aggregates recorded fairways on known par-4/5 holes and recorded GIR, showing numerator and denominator. Putts use completed 18-hole cards. Trends, verification and production data-quality checks remain. |
| Strokes gained / benchmarks | Planned | Complete shot-level records, licensed reference data, documented methodology and enough samples. |
| Game formats | Planned | Agreed format rules for stroke/medal, Stableford, match play, skins, Nassau and Wolf; adjudication and scoring tests. Wagering additionally requires legal/product review. |
| Green contours and putting guidance | Planned | Licensed surveyed contours, course and competition rules, maintenance and coverage; never fabricate maps. |
| Pin placement | Planned | Valid green geometry, editable daily pin and clear precision limitations. |
| Weather, wind and radar | Planned | Weather provider agreement, API and cost, consent, location, attribution and freshness. |
| Pace of play | Planned | Agreed pace targets, optional timestamps, privacy controls and notification rules. |
| Rules assistance | Planned | Reliable current sources, jurisdiction/competition context and citations. |
| Food and beverage | Planned | Participating course menus, ordering and fulfillment integration, payment choices and support processes. |
| Emergency/ranger call | Planned | Club-verified contacts and clear dialing behavior. Reliable emergency connectivity and response must not be assumed. |
| Live tournaments | Partial | Existing round leaderboard is not a tournament system; competitions, eligibility, aggregation and access controls are needed. |
| Live location sharing | Planned | Explicit consent, access controls, expiry, revoke, battery and privacy design. |
| Android push and community messages | Partial | Shared chat text works with 10-second foreground polling and latest 100 messages. Push provider, token management, blocking/reporting, retention and full moderation remain outstanding. |
| Wear OS | Planned | Watch app, pairing/sync and device testing. Existing phone alert mirroring is not a companion app. |
| Apple Watch | Planned | iOS provisioning, Apple developer setup, watch app and physical-device testing. |
| Automatic shot detection | Planned | Sensor research, confirmation UX, accuracy, permission and battery validation on supported devices. |
| Official handicap integration | Planned | Written provider authorization, API access, golfer consent, submission and correction rules. Existing estimates are not official. |

## Hurdles and actions

1. **Course directory:** the supplied CSV has 356 listings, including active, closed and minimal-data rows. The initial normalized-name comparison matched 109 existing names and left 247 candidates for review. Reconcile aliases and status before importing; do not overwrite verified records or invent tee ratings. Identify the directory's source, permission and freshness. The CSV contains no per-hole distances, tee ratings, imagery, hazard or green geometry.
2. **Tee boxes:** obtain the club's current scorecard, colours, per-hole par and stroke indexes, distances in metres, course rating, slope and any applicable player categories; verify against the club and load into the existing tee and distance tables. Do not treat the neutral unrated tee as an official rating. For multi-tee play add player-level tee selection and snapshots.
3. **Course maps and greens:** obtain licensed imagery, permitted offline tiles and current verified tee/green/hazard geometry. Green contours need separate licensed survey data. Mark coverage gaps and estimate uncertainty.
4. **League rules:** owner must approve points table, ties, season cutoff, best-seven timing, 9-hole eligibility, verification roles and correction procedures. Preserve historical imported standings separately.
5. **Remote services and privacy:** weather, push, messaging, ordering, live locations and official handicap each need provider selection, credentials, agreements, cost controls, security/RLS, consent and support ownership.
6. **Release quality:** validate round start/navigation, scoring, permissions, connectivity loss, recovery, sync conflicts, accessibility, battery use and paired watches on actual devices. Verify live database migrations, auth, RLS and configuration. Keep version 2 until the release AAB is prepared; increase the build code above the last Play Console upload at release time.
7. **Android build:** Flutter/Gradle requires access to the SDK caches and working Java local sockets. The debug APK built successfully with `jdk.net.unixdomain.tmpdir` pointed to the project's `.tmp-jdk-sockets` directory. `build_debug_apk.cmd` applies this setting for future debug builds. Debug builds default to `com.christiangolfers.capetown.debug` and can coexist with the released package; release builds retain `com.christiangolfers.capetown`. The debug build uses the live backend, so test scores affect real data. Google OAuth and other deep links use the existing callback scheme and must be tested with both apps installed. Device validation is still required.

Detailed sequencing and acceptance criteria: [Android implementation roadmap](android-implementation-roadmap.md).

## Scheduling increment — 30 October 2026

- League dashboard calendar action opens the scheduling screen: choose an existing round-ready course/tee, future local tee time and 1–4 registered members. First selected member is host. Repeat for additional fourballs.
- `admin_schedule_fourball` validates the allowlist server-side and creates the round and roster atomically. A request token prevents duplicates on retries. Creator and tee time are retained; existing members and round history are preserved.
- Play Golf now lists the member's waiting/active rounds, with refresh and links to lobby/live scoring. Scheduled tee times display in device local time; dashboard date filtering uses South African dates.
- Scope limits: one group per operation, one shared tee, no booking confirmation, bulk event editor, reassignment/cancellation workflow or push invitations. Normal self-created rounds still seat only the current golfer.
- Validation: 51 Flutter tests passed; database rollback tests covered successful scheduling, idempotency, duplicate members, invalid tee and non-admin rejection. Debug APK built. Full multi-account device acceptance remains required.
- Course research and remaining data gates: [GolfRSA / GolfAPI assessment](course-sources-2026-10-30.md). No unverified provider data imported.
- Security advisor flags the new RPC as executable by signed-in users with elevated database privileges. This is intentional for the guarded API: its first operation enforces the admin allowlist, and non-admin rejection was tested. See [SECURITY DEFINER guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable). Existing password-protection and restricted-table notices remain.

## Version 2 implementation check — 30 October 2026

Implemented in this increment: admin handicap editor with finite/range/provenance validation; active group current-hole and gross-score summaries; shared member chat with protected database table, latest 100 messages, 10-second foreground polling and author/admin deletion; footer Chat navigation and preserved friend management. New table RLS/grants were verified: anonymous SELECT is denied and authenticated clients cannot set another sender. Existing admin handicap RPC enforces admin authorization. No members or rounds were reset.

Verification: 49 Flutter tests passed, including invalid handicap/source checks and route regressions. Static analysis found informational lints but no compiler errors. A live multi-account chat/handicap editing exercise is still required; no real messages or handicap changes were sent as a test. The security advisor reports existing authenticated SECURITY DEFINER RPC warnings, restricted tables with no policies, and disabled leaked-password protection. Review the existing RPC checks and [password security setting](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) before release.

Still unimplemented: manual league assignments, member-name editing from admin, offline synchronization/recovery, official annual points aggregation, club/shot logging, dynamic GPS, advanced analytics, Wear OS and the provider-dependent features listed above. The official points schedule is pending from the owner. No claim is made that the whole roadmap is complete.


Device delivery: Version 2.0.0+2 debug APK installed successfully on connected Samsung SM-S926B and launched as com.christiangolfers.capetown.debug. Four scheduling tests passed after adding cap and timezone checks; the 51-test suite passed before those two additional assertions. Final follow-up corrected a test's UTC/local representation comparison; application time conversion was unchanged. Backend dashboard smoke check passed. User multi-account approval remains pending.
