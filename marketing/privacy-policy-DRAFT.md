---
status: DRAFT — needs solicitor review before publishing
gate: AADC hard gate (must be live before public launch)
publish-to: /privacy.html on GitHub Pages (link from web app + App Store listing)
owner: Brian + legal
---

# Privacy Policy — [APP NAME]  (DRAFT)

> ⚠️ **This is a starting draft, not legal advice.** A minors' health app must have
> a solicitor review this and confirm the `[placeholders]` before it goes live.
> Do **not** push this to GitHub Pages until reviewed.

*Last updated: [DATE]*

**Who we are.** [APP NAME] ("we", "us") is operated by [LEGAL ENTITY / SOLE TRADER
NAME], based in the United Kingdom. We are the data controller for your information.
Contact: [privacy@yourdomain].

**Who this app is for.** [APP NAME] is designed for people aged **13 and over**. We ask
you to confirm your age when you sign up. If you are under 13, do not use the app. If we
learn we have collected data from a child under 13, we will delete it.

**What we collect.**
- **Account:** your email address and password (passwords are stored hashed by our auth
  provider, Supabase — we never see them).
- **App data you create:** training plans, meal plans, shopping lists, saved recipes,
  bodyweight entries, readiness check-ins, and progress — stored so it syncs across your
  devices.
- **Health & wearable data (only if you connect a device):** if you connect Apple Health,
  Oura, Whoop or Fitbit, we read the specific metrics you approve (e.g. sleep, heart rate,
  recovery) to calculate your readiness score. You can disconnect at any time.
- **Technical:** basic logs needed to run the service (e.g. IP address for rate-limiting
  and security).

**What we do NOT do.** We do not sell your data. We do not use it for advertising or
profiling. We do not share it with third parties except the infrastructure providers
below, strictly to run the app.

**Who processes data for us.** Supabase (auth + database), Cloudflare (backend functions),
Resend (verification emails), Anthropic (recipe text extraction — only the link/caption
you submit, not your account data). Each acts under a data-processing agreement.

**Legal basis (UK GDPR).** We process your data to provide the service you signed up for
(contract), and — for health/wearable data, which is special-category data — only with
**your explicit consent**, given by connecting a device and withdrawable at any time.

**Your rights.** You can access, correct, export, or delete your data. **To delete
everything, use "Delete my account" in Settings, or email [privacy@yourdomain]** — we
action deletion requests within 30 days. You can also complain to the UK ICO (ico.org.uk).

**Data retention.** We keep your data while your account is active. When you delete your
account, we remove your personal data from live systems promptly and from backups within
[30] days.

**Children & the Age Appropriate Design Code.** We follow the ICO's Children's Code:
high-privacy defaults, data minimisation, no profiling, no nudge techniques, and no
unnecessary data collection.

**Changes.** We'll post changes here and update the date above.
