# Build Your Body — Release Plan

_Last updated: 2026-07-14_

**Launch strategy:** ship with the **Training + Meals systems perfect** — the daily core,
free to run, fully in the user's control. Defer the fragile/costly stuff (Recipes,
wearables) to later updates. **Launch marketing hook = "the plan that actually adapts to
you"** (build your own, log what you really ate/lifted, everything recalculates). Recipes
become the **1.1 headline** — a second marketing beat, not launch-day risk.

**Assumptions (flip if wrong):** "release" = the **native App Store app** (~late Aug 2026),
with the web PWA already live as the free base. Rank/League + Readiness check-in stay in
v1.0. Wearables are post-launch.

---

## ✅ At release — v1.0 (must be rock-solid)

**Training**
- Build-your-own OR generate-then-edit multi-phase plans
- Today-forward home (today's session hero → up-next → week strip)
- Mark-as-done + streak + weekly progress
- Exercise detail: animated demo (WorkoutX) + anatomical muscle map
- In-session: reorder exercises, **per-set reps×weight logging** with "last time" history ✅
- Skip (streak-safe) + reschedule
- Logged sets feed Progress

**Meals & Shopping**
- Build-your-own OR generate-then-edit; full per-day CRUD (add/remove/rename/reorder)
- Log actual vs planned ("I had something else"), eaten/skipped ✅
- Live macro totals that recalc from what you actually ate
- Auto shopping list (categorised, tick-off, Copy / Send-to-Reminders)

**Foundation**
- Accounts + cross-device sync (Supabase)
- Email OTP verification + age gate
- Readiness daily check-in → score that tunes training
- Progress tracking (weight, sessions, streaks, monthly change)
- Rank / League system
- PWA install + push reminders

## 🔨 In progress (finish for v1.0)

- **Plan-control polish** — engine shipped (`e6224a2`). Re-verified in the preview
  2026-07-25 (FEATURES); the three open items were all **already done**:
  - in-session *swap* ≠ *reorder* ✅ — distinct handlers, both persist via `tpRefreshDetails`
    → `tpSave`. Reorder (`tpExMove`, ↑↓) keeps the same exercises and changes order; swap
    (`tpSwapRich`, ↻) replaces one exercise in place and leaves the others untouched.
  - reschedule day-picker ✅ — **not** a `prompt()` (there are zero `prompt()` calls in
    app.js). `tpOpenReschedule` is a real modal offering only free days; it moves both the
    schedule slot and the session's `day`, and persists.
  - per-set reps×weight logging + "last time" history ✅ — verified end-to-end, and a
    logged set correctly marks the day in `sbp-workouts` for Progress.
  - **Still open, DESIGN:** the day-picker buttons (`.resched-day`) have **no CSS** — they
    render as raw browser grey buttons inside an otherwise-styled modal.
  - **Needs a decision:** there is no dedicated "active-session page" markup in index.html
    (sections are today/plan/meals/shopping/progress/recipes/account). The in-session
    surfaces that exist — the phase-details live editor and the exercise set-logger — are
    fully wired. Building a new full-screen session runner for web would be a new web-only
    surface, which the native-first rule excludes until v1.1.
- **Native redesign pass** — 11 Swift files, currently **uncommitted** → commit + QA
- **Data-deletion flow** — code done, needs one real end-to-end test
- **Native QA/parity** — HealthKit read, done-tracking, reminders end-to-end
- **Sync verification** — `app_data=0`, confirm cross-device writes actually happen

## 🔮 Later updates (post-launch)

- **v1.1 — TikTok / IG / YouTube Recipes** (built, gated "coming soon"; the deferred hook)
- **Wearables** — Oura/Whoop/Fitbit (web) + Apple Watch/HealthKit (native)
- **Full food database** — Open Food Facts search + barcode (endpoint already coded, inert
  until the Worker redeploy)
- **AI meal/macro coaching** (premium candidate — real AI cost)
- Metric/imperial units · data export · daily reminder notifications
- Behind-the-scenes: error monitoring, Supabase backup, AADC-safe analytics
- **Rebrand / rename** — parked until everything else is done

---

**The bar for launch is "excellent and reliable," not "perfect."** Ship when Training +
Meals are smooth, onboarding is clean, sync provably works, and there are no console errors.
Don't let polish eat the date.
