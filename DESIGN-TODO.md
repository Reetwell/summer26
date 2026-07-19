# DESIGN-TODO — Build Your Body (BB)

Design-lane audit, 2026-07-19. Surfaces: **native** (SwiftUI, primary product) ·
**web** (PWA, `styles.css` only) · **marketing/mockups**.
Brand tokens (locked): green **#00694c** · cream #F9F6F0 / bg #F7F6F3 · ink #1A1A18 ·
DM Serif Display + DM Sans. Guardrail: rank/progress by **effort**, body-neutral, non-shaming.

Effort key: **S** ≈ <1hr · **M** ≈ half-day · **L** ≈ multi-session.

---

## P0 — Brand foundations (native is currently off-brand)

### 1. Migrate native green #1D9E75 → #00694c  ·  native  ·  **M**  ·  not blocked
- **Files:** `Core/Extensions/Color+Brand.swift` (source of truth — `green500/700/900`
  still hold the OLD ramp `#1D9E75 / #0F6E56 / #085041`), + ~203 usage sites across
  `Features/*`, `Design/Components/*`.
- **Why:** Web already migrated (`styles.css --green-500: #00694c`); native has **203**
  old-green refs vs **4** new. The whole app renders a visibly different, brighter green
  than the brand + web + rank gem. This is the highest-impact consistency fix and the
  cheapest to land — fix the 3 token constants + audit the handful of hardcoded hexes.
- **Approach:** update `green500→#00694c`, `green700→#00543D`, `green900→#003F2E`
  (match web ramp), keep `green50` as the tint. Most call sites reference the tokens so
  they update for free; grep for any inline `#1D9E75`. Verify in simulator (light + dark).

### 2. Bundle DM Serif Display + DM Sans in native  ·  native  ·  **M**  ·  not blocked (needs Xcode file-add)
- **Files:** add `.ttf/.otf` under a new `Resources/Fonts/` group; `Info.plist`
  (`UIAppFonts`); `Core/Extensions/Font+Brand.swift` (swap `.system(design:.serif)`
  fallback for the real family names).
- **Why:** headings + big numerals (rank tier, Today rings, macros) fall back to system
  New York serif — the brand's whole numeric personality is missing. Rank numeral already
  uses `.serifDisplay` so it upgrades automatically once bundled.
- **Note:** fonts are OFL/free. Adding resource files to the `.xcodeproj` is the fiddly
  part (no xcodegen / no sudo per project-ios-app memory) — may need a careful pbxproj
  edit or a GUI add by Brian. Flag before starting.

---

## P1 — Native polish & system

### 3. Establish a native type + color token layer  ·  native  ·  **M**  ·  not blocked
- **Files:** `Design/Tokens.swift` (today only has `Radius` + `Spacing`),
  `Core/Extensions/Color+Brand.swift`, `Core/Extensions/Font+Brand.swift`.
- **Why:** no typographic scale exists (sizes are ad-hoc per view) and color is split
  between `green*` and semantic `bbBackground/bbSurface`. A small type scale
  (display/title/body/caption) + semantic color names would kill drift and make items 1–2
  land cleanly. Do alongside #1 and #2.

### 4. Per-screen visual pass — Today / Meals / Training / Account / Progress  ·  native  ·  **L**  ·  not blocked
- **Files:** `Features/Dashboard/TodayView.swift`, `Features/Meals/MealsView.swift`,
  `Features/Training/TrainingView.swift`, `Features/Account/AccountView.swift`,
  `Features/Progress/ProgressDashboardView.swift` (the 5 largest views).
- **Why:** these were built to feature-parity with sample data; now on fresh/zero state.
  Needs a consistency + empty-state + spacing-rhythm pass once tokens (1–3) are in. Best
  done screen-by-screen after the foundations, not before.

### 5. Rank badge — verify against new green + all 5 tiers  ·  native + mockups  ·  **S**  ·  not blocked
- **Files:** `Features/Rank/RankSystem.swift`, source of truth
  `mockups/rank-badges-v3-banner.html`.
- **Why:** gem already uses the #00694c ramp, but the surrounding card/CTA greens will
  shift when #1 lands — re-verify the effort-gem still reads against the new card green,
  and that native still matches the mockup. Quick regression check after #1.

---

## P2 — Web (already largely on-brand; needs verification, not migration)

### 6. Web consistency + dark-mode verification pass  ·  web  ·  **M**  ·  not blocked
- **Files:** `styles.css` only (never `app.js`/`index.html` — match existing markup hooks;
  see project-web-design-hooks memory).
- **Why:** web already has #00694c tokens + DM fonts loaded, so it's ahead of native. Open
  question is polish/regression: verify the recently-wired hooks (meal log bar, plan-choice
  modal, per-set log, reschedule) still look right, and check dark mode. Verify via preview
  browser by calling the real app.js functions (per memory) rather than scratch HTML.

---

## Blocked — UI exists, waiting on backend (do NOT design-build further yet)

### 7. Rank XP / Weekly League live data  ·  native  ·  blocked on backend
- `Features/Rank/LeagueView.swift`, `RankSystem.swift`. UI complete; live views run
  `RankState.fresh`. XP tracking + matchmaking + weekly reset are backend/app.js work not
  built (see project-backend-state). Nothing to design until data exists — the empty/"not
  started" states are already handled.

### 8. Sign in with Apple  ·  native  ·  blocked (Apple Dev Program + Supabase config)
- Visuals done; provider config needs paid Apple Developer account + Supabase dashboard.

---

## Out of design lane (noted, not owned here)

- **`marketing/`** is owned by the MARKETING lane per `marketing/README.md` (copy,
  strategy, ASO, video). Design's contribution is limited to **visual/badge source**
  (`mockups/`, rank one-pager visuals) — defer marketing copy/strategy edits to that lane
  to avoid clobbering.

---

## Suggested order
1 → 2 → 3 (foundations, unblock everything visual) · then 5 (quick regression) · then
4 (screen-by-screen) · 6 (web) can run in parallel/independently. 7–8 stay parked.
