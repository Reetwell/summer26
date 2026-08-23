# SummerBody reminders — backend setup

This is a tiny **Cloudflare Worker** that sends your protein & creatine push
reminders, even when the app is closed. Free tier covers it easily.

You only do this once (~10 minutes). When you're done, send Claude the Worker
URL and it'll do the final wiring.

---

## What you need

- A free Cloudflare account → https://dash.cloudflare.com/sign-up
- The two values Claude generated for you:
  - **VAPID public key** (`applicationServerKey`)
  - **VAPID private key** (a small JSON object) — keep this one private

---

## Step 1 — Create a KV namespace (storage)

1. In the Cloudflare dashboard, go to **Storage & Databases → KV**.
2. Click **Create a namespace**. Name it `summerbody-reminders`. Create.

## Step 2 — Deploy the Worker  ⚠️ THE OLD COPY-PASTE METHOD NO LONGER WORKS

**Do not use the dashboard's "Edit code" box.** This used to say "paste the whole
of `worker.js` into the editor" — that stopped being possible once the backend
became four ES modules that import each other:

```
worker.js  →  wearables.js  →  account.js  →  food.js
```

The editor takes a single file and cannot resolve those imports. The Worker
currently running in production is still the old single-file version, which is
exactly why `/wearable/*`, `/account/*` and `/food/*` return 404 today.

Deploy with **wrangler** instead. `backend/wrangler.toml` already has the name,
KV binding, cron trigger and non-secret vars, so this is one command:

```bash
cd backend
npx wrangler login     # one-time, opens a browser
npx wrangler deploy
```

To check what would be uploaded without touching production:

```bash
npx wrangler deploy --dry-run
```

Steps 3 (KV binding) and 5 (cron trigger) below are now handled automatically by
`wrangler.toml` — no dashboard clicking needed.

## Step 3 — ~~Bind the KV namespace~~ (now automatic)

Declared in `wrangler.toml` as `REMINDERS` → namespace `summerbody-reminders`
(`681a24d4f838462aabfe9eca8ab4e07c`).

## Step 4 — Add the secrets

Non-secret vars (`VAPID_PUBLIC_KEY`, `VAPID_SUBJECT`, `SUPABASE_URL`) live in
`wrangler.toml`. **Secrets never go in that file** — set each one interactively so
the value goes straight from your terminal to Cloudflare:

```bash
npx wrangler secret put VAPID_PRIVATE_JWK           # push reminders
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY   # /account/delete + /wearable/*
npx wrangler secret put ANTHROPIC_API_KEY           # /recipe/extract (v1.1)
```

Secrets survive a deploy — you only set them once. A missing secret makes that
one feature inert; it does not take the Worker down. `/food/*` needs no secret.

⚠️ **Before the first wrangler deploy:** open **Settings → Variables** in the
dashboard and check the three plain-text vars match `wrangler.toml`. A deploy
makes the file the source of truth for vars, so a value that only exists in the
dashboard can be dropped. (Encrypted secrets are unaffected.)

## Step 5 — ~~Add the cron trigger~~ (now automatic)

Declared in `wrangler.toml` as `crons = ["*/5 * * * *"]`.

## Step 6 — Send Claude the URL

Your Worker URL looks like:

```
https://summerbody-reminders.<your-subdomain>.workers.dev
```

Open it in a browser — you should see `{"ok":true,"service":"summerbody-reminders"}`.
Send that URL to Claude, and it will plug it into the app and redeploy. Done.

---

## Recipe extraction (optional add-on)

The same Worker also powers the **"Add recipe from TikTok/Instagram/YouTube"**
feature via a `POST /recipe/extract` endpoint. It reads the post's public
caption/metadata and uses Claude to draft a structured recipe you then edit.

To enable it, add one more secret in **Settings → Variables and Secrets**:

| Type                 | Name                | Value                              |
|----------------------|---------------------|------------------------------------|
| **Secret** (encrypt) | `ANTHROPIC_API_KEY` | your Anthropic API key (`sk-ant-…`) |

Deploy after adding it. If the key is missing the endpoint still works — it just
returns a blank editable draft instead of an AI-filled one.

**Abuse / cost protection (already in `worker.js`):**
- The endpoint only accepts browser requests from `https://reetwell.github.io`
  (and localhost for dev) via a strict CORS origin allowlist.
- Per-IP rate limit of **30 extractions/hour** (stored in the same `REMINDERS`
  KV under `rl:` keys), returning HTTP 429 when exceeded.
- Uses Claude **Haiku** with `max_tokens: 1024` and a 6000-char input cap, so
  each call costs a fraction of a cent.

These limit accidental/abusive spend, but the endpoint is still public (no user
auth), so keep an eye on Anthropic usage if the app goes widely public.

---

## Data-deletion end-to-end test (AADC launch gate)

`POST /account/delete` is written and mounted but has **never been run against the
live stack**. It needs `SUPABASE_SERVICE_ROLE_KEY` set (above) and the Worker
deployed, because it hard-deletes the auth user via the Admin API.

### ⚠️ Two things to get right before you run it

**1. Never run this against your own account.** `me@reecerothwell.me` is currently
the *only* row in `auth.users`. The endpoint does exactly what it says — the
delete cascades and is irreversible. Use a throwaway account.

**2. You probably can't create that throwaway yet.** Sign-up needs an emailed OTP,
and the sender is still `onboarding@resend.dev`, which only delivers to your own
address. So a fresh test address will never receive its code.

**→ Verify the Resend domain first.** It's the ~1-day DNS item, and it gates this
test. Start it now and it runs in the background while you deploy.
(Possible shortcut worth trying: a plus-address like
`brian.rothwell+deltest@clickbill.co.uk` may pass Resend's own-recipient check and
still land in your inbox. If it does, you can test without waiting for DNS.)

### The test

1. Sign up as the throwaway account, verify the OTP, sign in.
2. Log something real (a session, a weight) so it has `app_data` rows to delete —
   deleting an empty account proves very little.
3. Grab that session's access token and call the endpoint:

```bash
curl -i -X POST https://summerbody.me-e29.workers.dev/account/delete \
  -H "Authorization: Bearer <the-test-account-access-token>"
```

Expect `200 {"ok":true}`. A `500 {"failed":[...]}` names the step that failed.

4. Confirm it's gone — tell me and I'll run the read-only check:

```sql
select
  (select count(*) from auth.users      where email = '<test-address>') as user_row,
  (select count(*) from public.profiles where email = '<test-address>') as profile_row,
  (select count(*) from public.app_data
     where user_id = '<the-test-uuid>')                                 as data_rows;
```

All three must be `0`. Capture that result — it's the evidence the deletion gate
was actually exercised, not just coded.

**Worth testing too:** call it a second time with the same (now-dead) token. It
should fail cleanly, not 500 — the endpoint is meant to be idempotent and
retry-safe.

I can't drive this one end to end: creating accounts and permanently deleting
data are both actions I don't take on your behalf. You run it, I'll verify.

---

## How it works

- The app subscribes your phone to Web Push and sends the subscription +
  your chosen times to `/subscribe`.
- Every 5 minutes the cron checks whether a reminder time just passed and, if so,
  sends a push. The service worker shows the notification — even with the app closed.
- Times are stored in UTC; the app converts your local time automatically and
  re-syncs whenever you open it, so it stays correct.

## Notes / limits

- **iPhone:** the app must be **added to the Home Screen** and opened from there
  (iOS only allows web push for installed PWAs, iOS 16.4+).
- Free tier: 100k Worker requests/day and plenty of cron runs — far more than enough.
- No secrets live in `worker.js`, so it's safe to keep in the public repo. The
  private key only exists as an encrypted Cloudflare secret.
