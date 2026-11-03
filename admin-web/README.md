# Christian Golfers Cape Town administration

Private web portal backed by the app's Supabase project. Build with `npm ci` and `npm run build`; serve `dist/`. `src/config.json` contains only the browser-safe publishable key. Never add a service-role key. Apply the web_admin_portal and web_admin_security migrations before using the live portal.

## Access and functionality

Sign in with Google or an existing email/password account on `admin_allowlist`. The website is additionally private to the Site owner until sharing is explicitly configured. Google authentication does not grant administrator access. The portal does not create or reset passwords.

Members: name, manually sourced Handicap Index, visiting status, league override and membership status; CSV export; existing email invitation Edge Function. Inactive membership is administrative only and does not revoke Auth access. Flutter league classification has been updated in source to respect the override; older installed APKs do not understand it.

Rounds: schedule registered fourballs; filter by play day in South African time; review fourballs, player totals and hole-by-hole gross scores; export the displayed scores as CSV. An asterisk indicates an unconfirmed hole and blanks indicate missing scores. Gross includes separately recorded penalties and is provisional for incomplete or unconfirmed cards. Net appears only for a completed, fully confirmed 18-hole card with a handicap index; it remains provisional because it uses the shared round tee rather than each player’s tee. Verify results before prize giving. The page shows database-synced scores and can be refreshed; it does not receive unsynced offline entries. Administrators can enter or correct scores while a round is active, with a required audit reason. Edits include the loaded score version; concurrent changes cause a rejection and require a refresh and review. Waiting and completed rounds cannot be changed through the portal. Operations: assigned tasks, due dates and completion states. Merchandise: products/variants, available stock, reserved orders, manually recorded payment/fulfilment and cancellation. Server transactions reserve and restore stock. No card payments, tax invoices, delivery integration or refunds are executed.

Analytics: membership counts, league distribution, round status and season-scoped gross performance. These are not official annual competition-point standings; the owner's official schedule is still required. Current assignments are not historical season snapshots. Courses are read-only here; corrections to completed rounds and recalculation, course ingestion, privacy/account workflows, delegated admin roles and official handicap integration remain pending.

## Security and audit

Administrative RPCs check the server allowlist. Merchandise/operations/audit tables have RLS and no direct client mutation grants. Portal writes require a reason and record before/after values and actor. Other app writes and scheduling are not covered by this portal audit log. Session tokens use sessionStorage. Database text is escaped before HTML rendering; CSV formula prefixes are neutralised. No live personal data is bundled in deployment artifacts; the optional layout preview is explicitly labelled sample data and cannot save.

Portal list limits: latest 1,000 orders and 200 audit entries; round and membership dashboard is presently a complete snapshot. Pagination and large-league load testing are required before scaling beyond this deployment. Stock edits and record edits are audited but have no optimistic stale-edit warning yet.

## Verification

Node tests cover HTML escaping, CSV injection, league overrides and South African season boundaries. Database transaction tests verify stock reservation, cancellation retries, audit entries and non-admin rejection and are rolled back. Browser preview validates navigation and sample-data display. Full authenticated owner acceptance is still required; no live invites, member changes or sales were made during testing.

## Google OAuth

Uses Supabase Google provider with PKCE, same-tab code exchange and callback URL cleanup. Return URL: https://christian-golfers-admin.vdiedericks6.chatgpt.site/ . Add this exact URL to Supabase Auth Redirect URLs without replacing mobile callbacks. Google Cloud continues to use https://cegmyadsnrvzlgpwoezu.supabase.co/auth/v1/callback . No Google secret is shipped to the browser. Private Sites access remains unchanged.

Eight Node tests pass. Google provider is enabled. Full Google sign-in requires owner testing.

## Shared administrator allowlist

Open Administrators as the league owner, select Add administrator, choose the verified member and enter a reason. To revoke, use Revoke access on that member. Grant and revoke affect the same Supabase allowlist checked by Android and the portal. Ordinary admins cannot delegate access. The owner is protected against removal. Invite unregistered members from Members first. Each grant/revocation is recorded in Audit. The website also requires viewer access through its private Sites sharing settings. Use individual viewer grants when sharing the site.
