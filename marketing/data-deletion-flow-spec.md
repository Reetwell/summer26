---
status: SPEC — ready to build
gate: AADC hard gate (must exist before public launch)
owners: FEATURES (app.js + native Account) + BACKEND (Worker)
est: ~1 day for email backstop (B) alone; ~2–4 days for in-app (A) across both chats
---

# Data-deletion-on-request — build spec

Build **both** paths. A is the real fix; B is the legal backstop and can ship first.

## Path A — In-app "Delete my account"

**FEATURES (`app.js` + native Account screen)**
1. Add a red **"Delete my account"** row in Settings.
2. Confirmation modal: "This permanently deletes your account and all your data. This
   can't be undone." Require the user to type `DELETE` (or re-enter their password).
3. On confirm, call the new backend endpoint with the user's Supabase JWT.
4. On success: clear all `sbp-*` / `bb-*` localStorage keys and sign out to the signed-out
   screen.

**BACKEND (Cloudflare Worker, uses `SUPABASE_SERVICE_ROLE_KEY`)**
New authenticated route `POST /account/delete`:
1. Verify the Supabase JWT → resolve `user_id` (reuse `requireUser` from wearables.js).
2. Delete all `app_data` rows for that `user_id`.
3. Delete any `wearable_tokens` rows for that `user_id`; where the provider API allows,
   revoke the OAuth token with the provider.
4. Call Supabase Admin `auth.admin.deleteUser(user_id)`.
5. Return `{ ok: true }`. Return clear errors on partial failure so the app can retry.

**Edge cases:** must work even if the user never synced anything (`app_data=0`); idempotent
if called twice; don't leave orphaned wearable tokens.

## Path B — Email request (manual backstop)

- Publish `[privacy@yourdomain]` in the privacy policy.
- On request: verify it's the account owner, run the same deletion steps as A, reply
  confirming within 30 days.
- Keep a simple request log (date, email, actioned Y/N) for compliance evidence.

## Done = 
- A signed-in user can delete their own account end-to-end and is signed out with no data
  left in Supabase, **and** an email request achieves the same within 30 days.
