# Christian Golfers

Standalone Android app built with Flutter. This project has its own Dart package
name (`christian_golfers`) and Android application ID
(`com.christiangolfers.capetown`). It does not share its Android identity or
project files with the previous app.

## Open in Android Studio

1. Choose **File → Open** in Android Studio.
2. Select this folder, `ChristianGolfersApp` (the folder containing
   `pubspec.yaml`). Do not open only its `android` subfolder.
3. Allow the Flutter and Dart plugins to load the project and let Gradle sync.
4. Select an Android emulator or connect a phone with USB debugging enabled.
5. Choose the **Christian Golfers Demo** run configuration and click **Run**
   for the local sample experience. It uses the in-memory demo backend and
   needs no Supabase credentials.

The Flutter SDK and Android SDK paths are in the machine-local,
git-ignored `android/local.properties` file. Update those paths if you open this
copy on another computer.

## Build a debug APK

From this folder, run:

```powershell
flutter pub get
flutter build apk --debug --dart-define=CHRISTIAN_GOLFERS_DEMO=true
```

The APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`.

## Live backend

The demo mode uses local in-memory data. To use Supabase, provide
`SUPABASE_URL` and `SUPABASE_ANON_KEY` as Dart defines and apply the SQL files in
`supabase/migrations/` to the intended Supabase project.

Apply the migrations in filename order. The final migration adds a secure
administrator allowlist and saves each completed round's gross score,
handicap-adjusted net score, and placing. Round completion calculates course
handicap from the player's Handicap Index, tee slope and course rating, then
allocates handicap strokes by each hole's stroke index.

### Provision administrators before release

Create each administrator as a Supabase Auth email/password user with a strong,
unique password. Then add that user's Auth UUID and sign-in email to
`public.admin_allowlist` using the Supabase SQL editor or a trusted server
environment. Do not commit credentials or place passwords in the Flutter app.
The Admin Portal rechecks membership using the protected `is_admin()` database
function, and database write policies use that same allowlist. Normal golfers
cannot grant themselves admin access by changing a profile field.

The attached League A and League B tables are imported starting standings. New
completed-round results are stored separately with net scores and a placing;
the screenshots do not specify the historical points formula, so the app does
not mix those totals with new score totals.

### Course imagery, tees and shot guidance

The course screen supports White, Yellow, Blue and Red tee boxes. Official
per-hole distances belong in `public.tee_box_hole_distances`; club-provided
hole images can be stored in `public.holes.image_url`. The available bundled
hole coordinates can show an explicitly labelled straight-line GPS estimate
when official tee distances are missing. Those estimates are not scorecard
yardages. The live score screen also has a lie and measured-distance shot helper;
its club and direction suggestions are general guidance, not measured hazard
or wind advice.
