# Google Play release readiness

**Package:** `com.christiangolfers.capetown`

**Checklist prepared:** 29 October 2026

## Implemented in the app/repository

- Standalone Flutter app identity; repository is separate from Divot.
- Email/password sign-in is available; Google account is optional.
- Supabase RLS and admin allowlist separate ordinary golfers from league owners/captains.
- Admin member onboarding is performed by the protected `admin-invite-member` Edge Function.
- Admin dashboard can review member, round, score and standings data.
- In-app account deletion from Profile and external account deletion request page are implemented. The public page is served at the URL below, and the admin dashboard includes a verified-request workflow.
- Privacy policy is served at the public URL below and linked in the app.
- Request pages accept privacy questions and deletion requests without asking the visitor to install/sign in to the app.
- A clear confirmation explains that deleting an account also deletes hosted rounds and all associated score records.
- Golf/course imagery, logo, scorecard UI and OpenStreetMap attribution are included in the app.
- Android application ID and Supabase project URL are stable.

## Public links to enter in Play Console

- Privacy policy: <https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=privacy>
- Account deletion: <https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=delete>
- Privacy contact: <https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=contact>

Before submitting, open these links outside an authenticated session and verify they render on mobile. Submit one non-destructive privacy test request, confirm that it appears in the allowlisted admin inbox, close it, and confirm request details are redacted. Do not submit an actual deletion test against a real golfer account.

## Required owner actions before submission

1. **Build/version/signing:** a new Play upload keystore and signed AAB are now prepared locally. Securely back up the keystore and local ignored `android/key.properties`; register the public upload certificate in Play Console, enable Play App Signing, and increment the version/build number for each subsequent release. If an upload key was already registered for this package, use it or reset it in Play Console before uploading this bundle.
2. **Current device/API verification:** install the release candidate on supported Android versions and verify sign-in/sign-out/session restore, invite, round creation/join, score entry, round completion, standings, account deletion, links, back navigation, offline/error recovery, and accessibility/font scaling.
3. **API and native compatibility:** confirm target SDK is at least API 36 for this release cycle. Verify 64-bit and 16 KB page-size compatibility of all shipped native dependencies before the applicable Play deadline.
4. **Play Console identity:** confirm package registration, developer account verification, app name, category, support contact, countries, content rating and target audience. App is intended for adult golfers; verify all audience answers against the real product.
5. **Store listing:** supply original app icon, feature graphic, phone/tablet screenshots, concise/full descriptions, contact email/website, and translations where offered. Ensure all artwork and course imagery may legally be distributed.
6. **Data safety:** complete the Data safety form from the actual release build and current SDK/dependency inventory. Declare email/account identifiers, profile and user-generated content/round/score data, sharing with other round participants and league administrators, Supabase processing, and Google processing when Google sign-in is used. Confirm whether data is encrypted in transit and whether deletion is available (both are implemented). Verify collection/sharing answers with Play's current definitions; this document is not a substitute for the Play Console form.
   - The app uses local notifications for round alerts and asks Android 13+ users for notification permission. Local notifications are scheduled/displayed by the OS; no FCM remote push or push-token collection is currently configured. Recheck the release dependency inventory and privacy disclosures if remote push is added.
7. **Privacy and deletion:** put the public policy URL in the listing and the external deletion URL in the Play Console deletion field. Check that policy names the app/operator, data categories, uses, sharing, retention/deletion, and contact path and stays consistent with every SDK and production feature.
8. **Production auth:** configure production SMTP and send real invite, confirmation and password recovery emails; set Supabase leaked-password protection; verify Google OAuth only if it is enabled for the submitted build.
9. **Production data:** review the admin allowlist; ensure `vdiedericks6@gmail.com` has a secure Supabase Auth account and admin row. Replace or verify seeded course/tee data and explain that historical league screenshot totals are not newly calculated points.
10. **Testing/review access:** use an internal track first; provide Play reviewers a functioning test account and steps if any screen requires authentication. Keep the test account active throughout review and do not provide an admin credential unless the review specifically requires it and the owner accepts the risk.
11. **Release monitoring:** establish crash/ANR monitoring, user support and privacy-request review. The privacy inbox currently has no email notification, so assign an owner to review it regularly.

## Build commands

From this directory (`ChristianGolfersApp`):

```powershell
flutter pub get
flutter analyze
flutter build appbundle --release
```

For a local device preview:

```powershell
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Debug installs use the debug signing key and do not prove Play release signing. The release upload key is `android/app/christiangolfers-upload.jks`; its password and alias are stored in ignored `android/key.properties`. The public certificate to register with Play Console is `docs/android-upload-certificate.pem`. Never commit the keystore or `key.properties`.

## Outstanding environment gates

- The release upload keystore and signed app bundle are present locally. The release owner must securely back up the keystore and `android/key.properties`, register the certificate, and configure Play App Signing in Play Console.
- Supabase Auth leaked-password protection is currently reported disabled by the project's security advisor. Enable it before production accounts are onboarded.
- Production SMTP/invitation/password reset delivery and live privacy URL accessibility need owner-side verification.
- Play Console listing, Data safety, content rating, developer verification, app access instructions, and signing are Console work and cannot be completed from the source repository alone.
- Account deletion cascades hosted rounds and their participant score records. Review this data-retention behavior with league owners and update product policy if the league requires archival retention.

## Official references

- [Google Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Google Play user data and privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- [Prepare and roll out a release](https://support.google.com/googleplay/android-developer/answer/9859348?hl=en)
- [Android 16 KB page-size compatibility](https://developer.android.com/guide/practices/page-sizes)
