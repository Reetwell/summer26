# Cross-lane request: realistic App Store release date

**From:** MARKETING lane. **Why:** the coming-soon campaign (60s ad + TikTok teasers) needs a launch date to count down to. Announcing a date we then miss burns the audience we build — so we need a *realistic, buffered* date, not an optimistic one.

**Paste the prompt below into the NATIVE chat (primary) and the BACKEND chat.** Ask each to answer in a short STATUS-BLOCK style: **target date + confidence (low/med/high) + the items still blocking it + who owns each.**

---

## Prompt to paste

> Marketing needs a realistic **App Store release date** for the native iOS app to build a "Coming Soon" countdown campaign around. Please give me: **(a) a target launch date, (b) your confidence in it, and (c) the remaining blockers with owners.**
>
> Work back from these known launch-gate items (from the project note) — tell me which are done, in progress, or not started, and how long each realistically takes:
>
> **Compliance (AADC — hard gate, must be live before public launch):**
> - Published **privacy policy**
> - **Data-deletion-on-request** flow
> - Age gate on sign-up *(done — age-declaration checkbox)*
>
> **Backend / launch blockers:**
> - **Resend sender domain** verified (currently `onboarding@resend.dev` only delivers to Brian — no new user can get a signup code until a real domain is verified)
> - Remove the TEMP **"skip sign-in (dev)" bypass**
> - **Loosen password rules** (strict symbols/uppercase will cost 14–21 sign-ups)
> - **Verify cross-device sync** actually writes (`app_data=0` — possible silent bug)
> - **Supabase paid tier?** (free tier auto-pauses after 7 days idle — risky with real users)
>
> **Native / App Store specifics:**
> - Native feature parity done? (Recipes, wearables/HealthKit, exercise detail/muscle map, swap, done-tracking, reminders still flagged as gaps)
> - **App name finalised** (still "Build Your Body", ex-"SummerBody" — marketing needs this locked + trademark/collision-checked before any store listing or printed asset)
> - Native brand tokens migrated to the #00694c ramp
> - **App Store Connect** set up: dev account, screenshots, metadata, privacy nutrition label
> - **Apple review time** — budget ~1–3 days, sometimes longer for a health/fitness app aimed at minors
>
> Give me the **earliest date you'd stake your name on**, plus a **safe date** with buffer. Marketing will announce the safe date.

---

## What marketing does once a date comes back

1. Announce the **safe/buffered** date (month-level unless confidence is high — see below).
2. Drop the date into the coming-soon ad end-card + VO ("Coming [DATE] — follow so you don't miss it").
3. Recommend **month-only** publicly (e.g. "Coming September 2026") until App Store review is passed — then tighten to an exact day and/or flip to App Store pre-order.

## Open dependency (for the project note)

Release date is **TBD, blocked on the compliance gate + native App Store readiness**. Marketing coming-soon assets are prepped with a `[LAUNCH DATE]` placeholder, ready to fill the moment the date is confirmed.
