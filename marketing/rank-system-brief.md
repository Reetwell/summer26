# BB — Rank System Marketing Brief

> **Working name only** — the app name isn't final ([aso.md](aso.md)). Don't burn a name into thumbnails/merch yet.
>
> **What this is:** the handoff for advertising built around the **rank & weekly league** feature (Bronze → Diamond). Tagline: **Stay Focused**. Screen-first / faceless engine, creators amplify — same model as the rest of this folder ([README.md](README.md), [strategy.md](strategy.md)).
>
> **The one non-negotiable:** you rank up for **showing up**, never for what you weigh. If a piece of copy or a cut implies weight/size/"before-after", it's off-brand and (for a minors audience) policy-risky. See §3.

---

## 1. The feature in one paragraph (paste to creators)

> BB gives you a **rank** — Bronze, Silver, Gold, Platinum, Diamond — and you climb it by **showing up**: sessions done, streak days, goals hit. Not by what you weigh, not by how much you lift. Every week you're put in a small league with other people training at the same pace as you (all anonymous — no friends leaderboards, no pressure), and everyone starts the week fresh. It turns "did I train?" into a game you actually want to win.

---

## 2. Why the rank system is a marketing asset

- **It's the retention hook made visible.** "Don't break your streak / don't drop a tier this week" is a reason to reopen the app — and a reason to post.
- **It's screen-first.** The badges and the **rank-up animation** are the money shot; no talent, no face required. Perfect for the faceless engine.
- **It's differentiated.** Every other fitness app ranks you by *body*. Ours ranks you by *effort*. That contrast **is** the ad.
- **It's fair-by-design.** Anonymous, similar-pace matchmaking + weekly reset = a beginner and a gym rat compete fairly. That's a story teens trust.

---

## 3. Brand guardrail — the non-shaming rule (read before writing anything)

Mirrors the folder-wide guardrail in [README.md](README.md) and [strategy.md](strategy.md) §4. This feature is *especially* exposed because "ranking" invites competitive/comparison framing — keep it about effort.

**DO**
- Frame ranking as **effort, consistency, showing up** ("rank up for turning up").
- Emphasise **anonymous** + **weekly fresh start** (safe, low-pressure, not permanent).
- Use the words *sessions, streaks, consistency, showing up, fair, everyone*.

**DON'T**
- ❌ No weight, body size, calories-as-punishment, "shred", "summer body", before/after.
- ❌ No "beat your friends" / public friend leaderboards (it's anonymous strangers at your pace — say that).
- ❌ No implication a **lower** tier is shameful. Bronze isn't "bad" — it's the start of a streak. Never mock a tier.
- ❌ No "grind til you drop" — recovery/readiness is part of the product; overtraining framing is off-brand.

---

## 4. The five tiers + visual identity

**What earns a tier (all effort-based):** completed sessions, streak days, weekly consistency, goals hit. *Never* body metrics or strength numbers.

| Tier | Numeral | Feel | Metal |
|---|---|---|---|
| **Bronze** | I | "You've started." | warm copper `#D69A5C → #8A5A2B` |
| **Silver** | II | "It's becoming a habit." | brushed steel `#DEE4EA → #98A2AD` |
| **Gold** | III | "You're consistent." | rich gold `#F5CB55 → #C9922A` |
| **Platinum** | IV | "You're dialled in." | teal-platinum `#9AE7D6 → #3FA894` |
| **Diamond** | V | "Top tier — you made it." | **amethyst** `#E7DBFF → #A98FD6` |

**The badge (visual signature — keep it consistent across all creatives):**
- A **hanging banner** (heraldic swallowtail pennant) — *not* the generic hexagon/gem every game uses. This is ownable.
- Hangs from a **clasp bar that gains detail as you climb** (plain → beveled → capped → engraved → gem-set finials at Diamond).
- A **Roman numeral I–V** in the brand serif (DM Serif Display), set in a recessed plaque.
- A small **green "effort gem"** at the point — the brand-green signature (`#00694c`, the same green as the app), repeated on every tier.
- **Platinum & Diamond earn a laurel wreath**; Diamond is amethyst with iridescent fire — clearly the flagship.
- Palette sits on the brand's warm cream `#F9F6F0` with green `#00694c` as the accent.

**Design source of truth:** [../mockups/rank-badges-v3-banner.html](../mockups/rank-badges-v3-banner.html) — open it for the exact badges at every size, the both-greens study, and the **rank-up animation** (see §6). Native implementation: `BuildYourBody/.../Features/Rank/RankSystem.swift`.

---

## 5. Messaging angles + taglines

All ladder up to the master tagline **Stay Focused**.

**Angles**
1. **"Ranked for showing up."** The core contrast vs every other fitness app. (Lead angle.)
2. **"Everyone starts Bronze."** Fresh start, no intimidation, the streak begins today.
3. **"Fresh league every week."** Low-pressure, always another shot — anti-burnout.
4. **"Fair for everyone."** Anonymous, matched to your pace — beginner or not.

**Tagline / caption options** (pick per cut — keep them effort-framed)
- "Rank up for turning up."
- "Bronze to Diamond — on effort, not weight."
- "Your only competition trains at your pace."
- "Miss a week? New league Monday."
- "Show up. Rank up. Stay Focused."

---

## 6. Ad / video concepts (screen-first, 7–15s, TikTok-native)

Format per [video-concepts.md](video-concepts.md): vertical, screen recording, kinetic captions, trending-audio-friendly. The **rank-up celebration is the hero shot.**

1. **"The rank-up"** *(hero concept)* — screen-record the badge **unfurling** on promotion (the animation in the mockup: banner hangs in, light sweep, gem sparks, tier-glow pulse). Caption: *"POV: you actually stayed consistent this week."* End card: badge + **Stay Focused**.
2. **"Bronze → Diamond in 8 seconds"** — quick climb montage of all five banners, numeral I→V, metals warming to amethyst. Caption: *"Ranked on effort, not weight."*
3. **"Everyone starts here"** — a single Bronze banner, calm. Caption: *"No before-after. No weigh-in. Just show up."* Reassurance angle for the intimidated-beginner viewer.
4. **"New week, new league"** — Sunday-night reset moment; the league empty-state ("Your first league starts soon"). Caption: *"Miss a week? Monday's a fresh start."*
5. **"Why is it green, not a six-pack?"** — pattern-interrupt explainer: contrast our effort-gem/rank vs typical fitness-app body imagery. Caption: *"We rank you for turning up."*

> **The single most shareable asset is the rank-up animation.** Prioritise capturing a clean screen-record of it (front the mockup's Promote button, or the native rank-up once wired). Loop it, caption it, done.

---

## 7. Assets & specs

- **Badges (all 5, every size, + rank-up animation + both-greens study):** [../mockups/rank-badges-v3-banner.html](../mockups/rank-badges-v3-banner.html)
- **Native (source of production render):** `BuildYourBody/BuildYourBody/Features/Rank/RankSystem.swift`
- **Brand:** cream `#F9F6F0` · green `#00694c` (accent + effort-gem) · ink `#1A1A18` · fonts DM Serif Display (headings/numerals) + DM Sans (body).
- **Visual one-pager (share this link with marketing):** `rank-system-onepager.html` in this folder (self-contained; open in any browser or publish).

*Need a specific export (transparent PNGs per tier, a looping MP4/GIF of the rank-up, a 9:16 end-card)? That's a quick ask back to the design lane — the SVGs are production-ready and export cleanly at any resolution.*

---

## 8. Not-yet / dependencies (don't over-promise)

- **The ranking logic isn't live yet.** XP → tier, weekly matchmaking, and the reset are **backend work not built** (see [strategy.md](strategy.md) product dependencies). The **badges and the visual system are done**; the data that drives them is not. → Don't run ads promising a live leaderboard until it's wired.
- **Fresh-install state today** is Bronze / "Your first league starts soon" (empty state) — fine to show, it's honest and on-brand (the "everyone starts here" angle).
- **Name not final** — working-name rule applies (§ README).
- **Same launch gates as the rest of the folder** apply before this drives real install volume: published privacy policy, data-deletion, age gate (UK AADC).
