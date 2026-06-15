# Designing SummerBody for 14–21 year-olds — research & design rules

> Living document. Last updated: 2026-06-15.
> Purpose: understand how our target audience *actually* thinks and behaves with
> apps, then turn that into concrete, testable design rules. The three layout
> concepts (see `/mockups`) are each built against these rules.
>
> _Note: live web-source citations are pending (research tooling was temporarily
> unavailable when this was written). The findings below synthesise well-established
> UX research — Nielsen Norman Group's teen/young-adult studies, Gen Z behavioural
> research, and the observable conventions of the apps this group uses daily. Treat
> specifics as strong hypotheses to validate with real users, not gospel._

---

## 1. Who we're actually designing for

"14–21" is **two sub-groups**, and the gap matters:

- **14–17 (school)** — no income, phone is their *primary* (often only) computer,
  heavy TikTok/Snap/Insta, very low tolerance for friction or anything that feels
  like "an adult app." Highly social, image-conscious, easily embarrassed by
  cringe. Often using a hand-me-down/older Android or a shared device.
- **18–21 (college/uni/first job)** — some disposable income, more goal-driven
  (real gym goals, body composition), more likely to *pay*, more likely to use a
  tablet/laptop too. Still mobile-first but will use desktop for "sit down and plan"
  moments.

**Design implication:** the *default* experience must nail the 14–17 mobile-native
bar (zero friction, feels like a social app), while *scaling up* gracefully for the
18–21 "planning" mindset on bigger screens.

---

## 2. How they think (the behavioural truths)

These are the findings that should drive every layout decision:

1. **They scan, they don't read.** Walls of text = instant bounce. They read in
   F-patterns and rely on icons, thumbnails, numbers and colour to navigate.
2. **Extremely low patience / high "swipe-away" reflex.** If the first screen
   doesn't make the value obvious in ~2 seconds, they're gone. They've been trained
   by infinite feeds to expect instant payoff.
3. **They are NOT "tech wizards."** Common myth. Research consistently shows teens
   have *lower* success rates than adults on unfamiliar/cluttered UIs — they're fast
   but impatient and give up quickly. They're fluent in *conventions* (TikTok-style
   gestures), not in problem-solving bad UIs.
4. **Authenticity > polish.** Over-designed, corporate, "markety" UI reads as fake.
   BeReal's whole rise was anti-polish. Real, a bit raw, human tone wins.
5. **They hate being condescended to.** No baby-talk, no over-explaining, no
   "Great job!!! 🎉🎉🎉" everywhere. Confident, peer-level tone.
6. **Identity & self-expression matter.** They want the app to feel like *theirs*
   (customisation, personalisation, "your" stats, avatars, themes).
7. **Motivation is fragile and social.** Streaks, visible progress, gentle loss
   aversion, and (optional) social proof drive return visits far more than features.
8. **Mental-health aware.** This generation is sensitive to pressure, shame, and
   "toxic" fitness framing. Avoid guilt mechanics, calorie-obsession, or
   body-shaming tones. Encourage, don't punish.
9. **Dark mode is an expectation, not a feature.** Many default their whole phone
   to dark. A light-only app can feel dated/harsh at night.
10. **Thumb-driven, one-handed.** Phones are big; they operate with a thumb on the
    go. Primary actions must live in the bottom third of the screen.

---

## 3. The apps they live in (and what we should steal)

We don't need to reinvent navigation — we need to feel *familiar* to apps they use
without copying so hard it's cringe. What to learn from each:

| App | The pattern that works | What to borrow |
|-----|------------------------|----------------|
| **TikTok** | Full-screen, immersive, gesture-first, content does the talking | Big visual focus, minimal chrome, vertical scroll, "for you" feel |
| **Instagram** | Bottom tab bar (5 icons), Stories ring, grid | Familiar bottom nav; story-style horizontal progress strips |
| **Snapchat** | Camera/action-first; swipe between worlds | A primary action that's instantly reachable |
| **BeReal** | Anti-polish, low-pressure, "be real" authenticity | Honest tone; no vanity-metric pressure |
| **Duolingo** | Streaks, bite-size, mascot, loss aversion, daily goal ring | Streaks + daily ring + tiny daily wins (THE retention model) |
| **Spotify** | Deep personalisation, "Wrapped," dark UI | "Your" framing, end-of-week recaps, dark-first |
| **Apple Health / Fitness** | Bento/tile dashboard, rings, glanceable | Modular tiles, activity rings, glance-don't-dig |
| **Strava** | Social fitness, kudos, segments | Optional social proof, shareable wins |
| **Gymshark / Nike Training Club** | Aspirational, clean, big imagery, guided | Premium-but-approachable visual rhythm, big media |

**The synthesis:** they expect a **bottom tab bar** (Instagram/TikTok norm), a
**glanceable "today" home** (Apple Health rings + Duolingo daily goal), **big visual
cards** (TikTok/Gymshark), **streaks & gentle gamification** (Duolingo), **"your"
personalisation** (Spotify), and a **dark mode**. Anything that looks like a desktop
admin dashboard, a hamburger menu, or a dense settings form will feel old.

---

## 4. Concrete design rules for SummerBody

Distilled, opinionated, and what the mockups follow:

### Navigation & structure
- **R1. Bottom tab bar on mobile, max 5 items.** It's the universal teen-app
  pattern. A 6th item (we had this with Recipes) is a smell — group or use a center
  action button instead.
- **R2. One thumb, bottom third.** Primary actions (log, add, start workout) live
  where the thumb rests. A prominent **center "+" / action button** is a strong move.
- **R3. Glanceable home, not a menu.** The home screen answers "what do I do *right
  now*?" in 2 seconds: today's ring/goal, next workout, quick-log. Not a directory.
- **R4. Progressive depth.** Surface the 20% they use daily; tuck the rest one tap
  deeper. Don't show everything at once.
- **R5. No hamburger menus.** Hidden nav = dead features for this group.

### Visual & content
- **R6. Big numbers, big imagery, few words.** Stats as hero numbers; recipes/food
  as photos; labels short. Replace paragraphs with icons + values.
- **R7. Keep the brand skin (DM Serif headers, DM Sans body, green accent), but go
  bolder in layout** — more whitespace OR more density depending on concept, larger
  tap targets (min 44px), rounded everything (we already have 16–24px radii).
- **R8. Dark mode is first-class.** Design tokens already support it; every concept
  should be dark-mode-ready (even if v1 ships light).
- **R9. Motion with meaning.** Subtle transitions, ring fills, count-ups, a tasteful
  haptic-feel. We already shipped the "Welcome" animation — that instinct is right.

### Psychology & tone
- **R10. Streak + daily goal = the retention engine.** A visible streak and a daily
  "close your ring" goal will out-perform any feature for return rate. Build it in.
- **R11. Encourage, never shame.** Missed a day? "Welcome back, let's go" — never a
  broken-streak guilt trip or red error energy around the body.
- **R12. Peer-level tone.** Short, confident, a little fun. No corporate, no
  condescension, no emoji-spam.
- **R13. Make it feel like *theirs*.** Name in the header, "your week," personal
  bests, and (later) light theming/avatar.
- **R14. Social is opt-in, never forced.** A way to share a win is great; a public
  feed that exposes their body/effort is risky for this age group. Private by
  default (matches our private recipe ratings decision).

### Cross-device
- **R15. Mobile is the product; tablet/desktop are "lean-back planning."** Don't
  just stretch the phone UI. On big screens, use the space for multi-column
  planning (week view, meal planning, progress deep-dives) — the "sit down and sort
  my week" mode for the 18–21s.

---

## 5. How this maps to the three concepts

Each concept keeps the **exact** colours/fonts and obeys the rules above, but takes a
**different structural bet**. They're in `/mockups` as clickable prototypes.

- **Concept A — "Today Feed" (TikTok/Duolingo DNA).** Home is a single vertical,
  card-stack feed of *what matters now*: daily goal ring + streak up top, then
  scrollable cards (next workout, macros, reminders, recipe of the day). Bottom tab
  bar + center action button. The most mobile-native / lowest-friction bet.

- **Concept B — "Bento Dashboard" (Apple Health/Spotify DNA).** Home is a modular
  bento grid of glanceable tiles (ring, weight trend, today's training, macros,
  streak). Tap a tile to expand. Scales beautifully: 1-column phone → 2-col tablet →
  multi-col desktop dashboard. The most "premium + scalable" bet.

- **Concept C — "Hub + Stories" (Instagram/Snap DNA).** A story-style horizontal
  progress strip at the very top (tap through your day's goals), a big central
  focal action ("Start today's session"), and swipeable horizontal sections. The
  most gesture-driven / app-like bet.

Across all three: streaks, daily ring, big numbers, thumb-reachable primary action,
dark-mode-ready, peer-level copy.

---

## 6. What to validate with real users (next)

- Do they "get" the home screen's main action in <3 seconds? (5-second test)
- Bottom tab bar vs center action button — which gets used?
- Does the streak/daily-ring actually pull them back? (retention cohort)
- Light vs dark default preference for this group.
- Which of A / B / C *feels* most "like an app I'd actually use" (preference test
  with 5–10 real 14–21s — even friends/siblings is a valid start).
