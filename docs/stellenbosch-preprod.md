# Stellenbosch pre-production readiness — 22 November 2026

The event date is assumed to be 22 November 2026. Confirm the date, tee colours, competition format and current club scorecard with the league organiser.

## Course data

The live project contains 18 hole records for `stellenbosch-golf-club`, one generic unrated tee set and no per-hole tee distances or course photo. Do not treat its placeholder rating and slope as official. The bundled/live card lists hole 18 as par 4; the following tournament card lists it as par 3. The eCaddy club guide and tournament card also differ on stroke indexes for holes 2, 3 and 10. Layouts and temporary tournament tees may differ, so obtain the current card and check all 18 holes, tee colours, lengths, indexes and applicable course/slope ratings before handicap scoring.

- Tournament scorecard: https://tdb.albatrosgolf.co.za/frame/index.php?lang=en&srid_817=tournaments/courses/90270000007913
- eCaddy guide: https://www.ecaddy.co.za/mobile/stellenbosch/guide.php
- Course imagery and contours need verified sources and usage rights.

## Test isolation

The existing production Supabase project cannot create a development branch on its current plan. Use a separate test project or provision supported branching. A separate project has its own Auth users and OAuth setup. Apply migrations, load reviewed course data, configure the allowlisted test owner and provision test accounts. Never copy production member data without an agreed approach.

After configuring the test project, run `build_preprod_apk.ps1 -SupabaseUrl <test-project-url> -SupabasePublishableKey <test-publishable-key>`. The script rejects the known production URL and secret keys. Configure OAuth redirect URIs and Google sign-in for the test project, including the Android debug identity and signing certificate, before enabling Google login. The debug package is `com.christiangolfers.capetown.debug` and its round data belongs to the configured project.

## Acceptance gates

- Confirm actual scorecard data and prepare the course in the isolated database.
- Test at least two signed-in devices across a complete round, including fourball membership, all 18 holes, penalties, net scoring, completion, standings and admin visibility.
- Test poor connectivity, resumption and conflicts on the course. Offline score sync is not currently implemented; unsaved entries must not be represented as stored.
- Validate real-device Google and email sign-in, location permission, privacy and battery behavior. A phone was not connected when checked on 2 November.
- Have the organiser supply the official competition points schedule before using annual points standings.

On 2 November the existing 53 Flutter tests passed. These do not substitute for multiplayer device testing or verify real course data.

## Organiser decision and club scorecard

The organiser elected to use the existing live Supabase project for member testing. Test rounds and accounts are therefore live data. On 2 November, the supplied 2024 club scorecard confirmed the existing 18 pars and stroke indexes, including hole 18 as par 4. Eight rated tee categories and 18 distances each were loaded into the existing project by migration 20261102093838. The sums match the scorecard totals. The previous unrated tee remains for historical rounds. Verify with the club that the 2024 card remains current and confirm event format and competition points.
