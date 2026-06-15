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

## Step 2 — Create the Worker

1. Go to **Compute (Workers) → Workers & Pages → Create → Start with Hello World → Create Worker**.
2. Give it a name like `summerbody-reminders`. Deploy.
3. Click **Edit code**. Delete everything in the editor and paste the entire
   contents of `worker.js` (in this folder). Click **Deploy**.

## Step 3 — Bind the KV namespace

1. In the Worker, go to **Settings → Bindings → Add → KV namespace**.
2. **Variable name:** `REMINDERS`  •  **KV namespace:** `summerbody-reminders`.
3. Save / Deploy.

## Step 4 — Add the variables

Go to **Settings → Variables and Secrets** and add:

| Type             | Name                | Value                                              |
|------------------|---------------------|----------------------------------------------------|
| Text (plaintext) | `VAPID_PUBLIC_KEY`  | your VAPID **public** key                           |
| Text (plaintext) | `VAPID_SUBJECT`     | `mailto:brian.rothwell@clickbill.co.uk`             |
| **Secret** (encrypt) | `VAPID_PRIVATE_JWK` | your VAPID **private** key JSON (the whole `{...}`) |

Deploy after adding them.

## Step 5 — Add the cron trigger (the scheduler)

1. Go to **Settings → Triggers (Cron Triggers) → Add Cron Trigger**.
2. Enter:  `*/5 * * * *`  (runs every 5 minutes).
3. Save.

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
