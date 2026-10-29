# Play Console setup answers — Christian Golfers Cape Town

Prepared 29 October 2026 from the Flutter source, Android manifest, dependencies, Supabase migrations, and existing release checklist. This is a preparation sheet; answers marked **owner confirmation** must be verified by the app owner before they are submitted. Play Console declarations must match the actual release build and current SDK behavior.

## App identity

- **App name:** Christian Golfers Cape Town
- **Package:** `com.christiangolfers.capetown`
- **Suggested category:** Sports
- **Suggested tags:** Golf; Sports (select only tags offered by Play Console and matching the listing)
- **Distribution:** Google Play (countries/regions require owner choice)

## App content checklist

| Play Console item | Proposed answer | Status / notes |
| --- | --- | --- |
| Privacy policy | `https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=privacy` | Enter this URL after verifying it loads publicly, without login, on mobile. |
| Sign-in details | Email and password. Google sign-in is optional and depends on Supabase OAuth configuration. | **Owner action:** provide a dedicated, active reviewer test account and its password privately in Play Console. Do not use an administrator account. Add steps: launch → Get Started → email sign-in → use the test credentials. Confirm confirmation email/MFA is not needed for review. |
| Ads | No ads | Source/dependency check found no ad SDK or ad integration. Recheck the final release bundle if dependencies change. |
| Content rating | Complete the IARC questionnaire based on the shipped app. | The app is a golf community/scorecard tool with Bible verse/day content and user accounts. Do not guess questionnaire answers; accurately declare user-generated/social content and any moderation/reporting behavior. |
| Target audience | Adults are the intended audience per release notes. | **Owner confirmation required:** select age groups only after confirming the app is not designed for children and the app/store artwork/content do not target children. Google requires accurate age-group declarations. |
| Data safety | Declare account identifiers, profile information, and golfer-generated round/score data as collected/processed. See proposed inventory below. | **Owner confirmation required:** confirm whether user profile photos are uploaded or only external OAuth URLs; confirm any course search/friend lookup request logs, retention, backup deletion, and Google OAuth configuration for the release. Include third-party SDK behavior. |
| Government apps | No | The app is a private golf community product; no government-service feature was found. |
| Financial features | No | No payment, lending, banking, investment, crypto, or billing SDK/feature was found. |
| Health | No | Golf scoring/handicap is sports data, not a health service. No health SDK/permission was found. |
| Category and contact details | Sports; support email/website/phone | **Owner action:** choose the public support email and provide any requested phone/website. The policy URLs are not substitutes for user-support contact details. |
| Store listing | Draft copy and assets below | **Owner action:** choose countries/languages and upload/confirm required icon, feature graphic, phone screenshots and any tablet screenshots. Confirm rights to all course photographs/logos. |

## Data safety working inventory

Observed in code and database structure:

- **Personal info:** email address (authentication/profile); display name; optional profile photo URL. Authentication account identifiers are stored by Supabase Auth.
- **App activity / user-generated content:** golf course and tee selection, round participation, handicap index/course handicap, per-hole strokes, putts, penalties, fairway/GIR stats, standings, and friendship requests. Some profile/round/score data is visible to other round participants and league administrators by product design.
- **Notifications:** local notifications for round alerts. Android notification permission is declared. No Firebase Messaging/FCM or push-token feature was found; local alerts are not equivalent to remote push.
- **Location:** Android manifest does not request device location. Course coordinates are stored in course records; verify there is no release-specific location permission before declaring.
- **Payment / financial:** none found.
- **Health:** none found.
- **Ads / advertising ID:** no ad SDK or advertising identifier permission found.
- **Processing/storage:** Supabase Auth, Postgres and Edge Functions at the project's Supabase URL. HTTPS is used for backend requests. OAuth may additionally involve Google when enabled.
- **Deletion:** in-app account deletion plus public external deletion request page at `https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=delete`. Deleting the account cascades hosted rounds and related participant scores; ensure the privacy policy matches this behavior.

The final Data safety form asks about each data type, collection, purpose, sharing, optionality, encryption in transit, deletion requests, and independent security review. This repository inspection cannot determine all server logs, backup retention, Google provider settings, or operational use; the owner must validate these against Supabase/project configuration and the final AAB.

## Store listing draft

### Short description (draft)

Play golf together, track rounds and scorecards, and follow Christian Golfers Cape Town league standings.

### Full description (draft)

Christian Golfers Cape Town brings the club’s golf community together. Find South African courses, create or join a round, keep a hole-by-hole scorecard, and follow league standings with your fellow golfers.

Features include:

- Create and join golf rounds with other members.
- Record scores and round statistics hole by hole.
- Review completed rounds and league leaderboards.
- Browse course and tee information.
- Connect with fellow golfers and receive local round notifications.
- Read a daily word and Bible verse.

An account is required for member features. Sign in with email and password; Google sign-in may be available where enabled.

### Store listing assets/contact still required

- High-resolution app icon (Play listing asset, separate from the launcher icon if requirements differ).
- Feature graphic.
- Phone screenshots showing current production UI (not mockups).
- Tablet screenshots if offered/required for chosen form factors.
- Public support email and any requested website/phone.
- Store languages and country availability.
- Verify licenses/permission for course photographs and third-party course logos.

## Console/release blockers to resolve

1. Owner-confirm the target audience and public support contact details.
2. Create a least-privilege reviewer account and add private sign-in instructions in Play Console. Never provide admin credentials for routine review.
3. Verify policy and account-deletion pages are publicly reachable and accurately identify the app/developer.
4. Reconcile the Data safety form against the final AAB, Supabase Auth/OAuth settings, server-side logs/retention and privacy policy.
5. Complete IARC content-rating questions using actual user-generated content and moderation behavior.
6. Prepare production store assets and written description; verify image rights.
7. Verify release target SDK and native compatibility from the exact AAB. Android Gradle config inherits Flutter's SDK defaults, so the effective target must be confirmed from the built artifact/Play Console before release.
8. Finish internal/closed testing requirements shown by the Play Console account before applying for production access.

## Official references

- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- [Data safety form](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [User data and privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Content rating requirements](https://support.google.com/googleplay/android-developer/answer/9859655?hl=en)
- [App dashboard setup](https://support.google.com/googleplay/android-developer/answer/9859454?hl=en)
- [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
