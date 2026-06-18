# SummerBody — App & Business Plan

> Living document. Last updated: 2026-06-15.
> This is the reference version — we also talk through it in chat. Edit freely as the plan evolves.

---

## 1. One-liner

**A fitness app built for how 14–21 year olds actually live: save the meals you
see on TikTok, train with a plan, track your body, and see your wearable data —
all in one place, mostly free.**

---

## 2. Who it's for

- **Core audience: 14–21.** Already glued to short-form video, already curious about
  gym/nutrition, but priced out of (and bored by) the serious adult apps
  (MyFitnessPal, Whoop, etc.).
- They don't want a spreadsheet. They want it to feel like the apps they already use.
- Price-sensitive (many have no income), so **free has to be genuinely good** — paid
  is only for the few things that genuinely cost us money to run.

---

## 3. The product today (already built)

- Training plan / workout tracking (phased program, per-day sessions)
- Daily nutrition targets (protein, creatine reminders via push)
- Bodyweight tracking + progress chart
- Meal plan + shopping list
- Cross-device sync + accounts (Supabase)
- Installable PWA (works on phone home screen, sends push reminders)
- **Recipes feature — built, currently behind a "Coming soon" teaser** while we
  finish the AI extraction backend.

---

## 4. The roadmap (what's coming)

| Phase | Feature | Status | Notes |
|------:|---------|--------|-------|
| Now | Recipes from TikTok/IG/YouTube | Code done, gated behind "Coming soon" | Needs Anthropic API key live on the worker |
| Next | Wearables: Apple Watch, Fitbit, Whoop, Oura | Planned (from TikTok idea) | **See §7 — Apple Watch forces a native app** |
| Next | AI meal/macro help ("what do I eat to hit my protein") | Idea | Clear premium candidate (real AI cost) |
| Later | App Store launch — **native SwiftUI build** | Deliberately deferred | Ties in with wearables — see §7. **Decision: when we go native, build the iOS app in SwiftUI** (not just a Capacitor/web wrapper) so it can use Apple's real materials, animations and system integrations — the web PWA stays the cross-platform base, SwiftUI is the premium iOS layer. |
| Later | **Liquid Glass throughout (native only)** | Planned for the SwiftUI build | In SwiftUI, lean into Apple's real **Liquid Glass** material (translucent/blurred, iOS 26 style) across the app — bottom tab bar first, then cards/sheets/nav where it fits. Web stays as-is for now. |
| Later | **Apple Intelligence features (iOS 27)** | Idea — revisit when iOS 27 ships | When Apple Intelligence APIs land in iOS 27, use on-device/Apple models for things like natural-language food & workout logging, smart recaps and recovery suggestions — privacy-friendly (on-device) and ideally cost-free vs. our paid AI calls. Scope once the iOS 27 SDK is public. |
| **Last** | **Rebrand — new product name** | Parked, do last | "SummerBody" was fine as a personal project but isn't a strong launch name for a 14–21 product. Rename only **after everything else is built & working** — no point rebranding a moving target. |
| TBD | _(your "couple more things" — to be added)_ | — | Drop them in and we'll slot them |

---

## 5. Money — the philosophy

**Brian's rule: charge as little as possible, only for things that are genuinely
game-changing AND genuinely cost us money. Everything else stays free.**

Translated into a model:

### Free tier (generous on purpose)
Everything that costs us ~nothing to run stays free, forever:
- Workouts, plans, bodyweight, progress charts
- Meal plan + shopping list
- Reminders / push
- Sync across devices
- Manually-typed recipes
- A **small monthly allowance** of the expensive stuff (e.g. a few AI recipe
  extractions per month) so everyone gets to taste it

### Paid tier — "SummerBody Plus" (thin margin, honest pricing)
Only the features with a **real per-use cost** sit here:
- Unlimited **AI recipe extraction** (each call costs us a fraction of a penny)
- **AI meal/macro coaching**
- **Wearable sync** (if it needs a server/API cost to run)

**Pricing principle (Brian's £2→£4 example):** price = our cost + a small margin.
Never gouge. The example was illustrative — in reality AI usage per user is
**pennies/month**, not £2/hour, so the practical way to apply "cost + small margin"
for a consumer app is a **low price that comfortably covers even a heavy user's
costs plus a little**.

**Pricing menu (Brian's preference: give people options):**

| Option | Price | Who it's for |
|--------|-------|--------------|
| **Monthly** | **£3–£4 / month** | Try it, cancel anytime |
| **Annual** | ~£24–£30 / year (≈2 months free) | Committed users who want to save |
| **Lifetime (one-time)** | **~£50–£89 once** (leaning ~£59) | Super-fans who want to pay once and never think about it again |

**The lifetime logic = price-lock.** Pay once and you're sealed in forever — even
when the monthly price rises later, lifetime holders never pay again. It's
deliberately premium because it's permanent. It also does two useful jobs:
1. **Anchoring** — a £59–£89 lifetime sitting next to "£3.99/month" makes the
   monthly look like a no-brainer. Most people buy the monthly *because* the
   lifetime exists.
2. **Upfront cash** — the few who do buy it hand us money now, not drip-fed.

**Honest caveat for the 14–21 audience:** £50–89 upfront is a big ask for someone
with no income — expect only a small % to take it (that's fine; that's not who it's
for). The lifetime's main job is anchoring + serving die-hard fans, not volume.
Cost-wise it's safe: AI per user is pennies/month, and rate limits + the spend
ceiling stop even a heavy lifetime user from running costs away.

The margin stays small by design; the goal is sustainability, not profit-maxing.
We can always raise the free allowance if costs allow — err toward generous.

### Guardrails to keep costs (and therefore prices) low
- Per-IP / per-user rate limits on AI endpoints (already built for recipes: 30/hr).
- Cheapest capable AI model (Claude Haiku) + tight token caps.
- A monthly **spend ceiling** on the backend so a viral spike can't bankrupt us —
  past the cap, AI features queue/pause rather than rack up a bill.

---

## 6. What it costs us to run

| Item | Cost | Notes |
|------|------|-------|
| GitHub Pages hosting | £0 | Static site, free |
| Cloudflare Worker (reminders + AI endpoint) | £0 | Free tier: 100k req/day |
| Supabase (auth + sync) | £0 free tier | ⚠️ Pauses after 7 days idle — see §9 |
| Anthropic API (recipe/AI) | ~£0.004 per extraction | Pay-as-you-go, scales with use |
| Apple Developer Program | **£79/yr** | Only when we go to the App Store |
| Domain (optional) | ~£10/yr | Nice-to-have |

**Personal/early use: pennies a month.** Real costs only start when (a) we go on the
App Store (£79/yr) and (b) AI usage scales — and the paid tier is designed to cover
exactly that.

---

## 7. Wearables (the TikTok idea) — and the catch

Pulling in **Apple Watch / Fitbit / Whoop / Oura** data (steps, heart rate, sleep,
recovery, calories burned) would make the app massively stickier — and unlock AI
insights like "your recovery's low, take it easy today."

**The technical reality, per device:**

| Device | How we'd connect | Difficulty |
|--------|------------------|-----------|
| **Apple Watch** | Apple **HealthKit** | ⚠️ **Requires a native iOS app** — a web app *cannot* read HealthKit |
| Fitbit | Fitbit Web API (OAuth) | Doable from web |
| Whoop | Whoop API (OAuth, dev access) | Doable from web |
| Oura | Oura API v2 (OAuth) | Doable from web |

**Key strategic insight:** Apple Watch is almost certainly the #1 device for our
audience, and it's the *one* that forces us off pure-web and into a **native app
wrapper** (Capacitor/PWABuilder). So **"Apple Watch support" and "App Store launch"
are effectively the same project** — they should be planned together, not separately.

Fitbit/Whoop/Oura could ship earlier as web integrations to prove demand before we
commit to the native build.

---

## 8. Go-to-market (rough)

- **The recipe feature *is* the marketing.** Teens saving recipes from TikTok →
  natural reason to share the app on TikTok. The content loop and the audience are
  the same place.
- Soft launch as the PWA (free), gather a core of real users + feedback.
- Use that traction to justify the App Store push (where wearables/native live).
- Word-of-mouth + creator collabs (fitness TikTokers in the 14–21 niche).

---

## 9. Risks & open questions

- **Supabase auto-pause** (7-day idle on free tier) → caused the recent sign-in
  glitch. Fix: keep it active / upgrade if we get real users. Data can be lost on a
  paused free project — verify history survived the last pause.
- **Audience is minors** → App Store age rating, privacy (COPPA/GDPR-K), and data
  handling need real care before public launch. Health + wearable data is sensitive.
- **Platform ToS** (TikTok/IG scraping) → we rely on public oEmbed + graceful
  degradation; don't build hard dependencies on fragile scraping.
- **AI cost runaway** → mitigated by rate limits, cheap model, and a spend ceiling.
- **Apple Watch = native app** → biggest scope jump; bundle with App Store plan.
- **Will teens pay anything?** → keep free tier strong; Plus must feel optional, not
  like a paywall on basics.

---

## 10. Immediate next actions

- [ ] Lock lifetime price in the £50–£89 range (leaning ~£59) + which features are Plus-only
- [ ] Add Anthropic API key to the worker → flip Recipes from "Coming soon" to live
- [ ] Restore the paused Supabase project (fixes sign-in + sync)
- [ ] **Seed the meal + exercise libraries in Supabase** — run `backend/recipe-library.sql`
  and `backend/exercise-library.sql` in the Supabase SQL editor (Dashboard → SQL →
  New query → paste → Run). These create public-read tables `recipe_library` and
  `exercise_library` that power the meal/training onboarding. Until run, the app uses
  the bundled fallback copies in `index.html`, so nothing breaks — the SQL just makes
  the catalogs editable server-side without an app update. Safe to re-run (they upsert).
- [ ] **Enable Sign in with Google + Sign in with Apple** (buttons + app code already
  built; they just need turning on in the Supabase dashboard — see below)
- [ ] Pick the first wearable to integrate (suggest Fitbit/Oura/Whoop via web first)
- [ ] Add Brian's remaining "couple more things" to §4

### Enabling Google / Apple sign-in (config only — no app code needed)

The "Continue with Google/Apple" buttons and the in-app OAuth code are already
done. They error until each provider is switched on in Supabase. Do **Google
first** (free, ~10 min); **defer Apple** until the App Store / native push since
it needs the paid Apple Developer Program and is fiddly on web.

**Both providers first need:**
- Supabase project **awake** (free tier sleeps after 7 days idle — that alone
  breaks sign-in).
- Supabase → **Authentication → URL Configuration**: set **Site URL** to
  `https://reetwell.github.io/summer26/` and add the same URL under **Redirect URLs**.

**Google (easy, free):**
1. Google Cloud Console → create an **OAuth client (Web application)**.
2. Authorized redirect URI = the Supabase callback:
   `https://owqyrgufwvqgbrpdpskx.supabase.co/auth/v1/callback`
3. Copy **Client ID + Secret** → Supabase → **Authentication → Providers → Google**
   → toggle on, paste both, save.

**Apple (needs paid Apple Developer Program, ~£79/yr — defer):**
1. Apple Developer: create a **Services ID** with "Sign in with Apple" enabled +
   a **Sign in with Apple key**; set the return URL to the Supabase callback above.
2. Supabase → Providers → Apple: paste **Services ID, Team ID, Key ID** + the key,
   then enable.
