# Build Your Body — technical brief (read this first)

A fitness PWA for **14–21 year olds**: training plans, meal plans + auto shopping
list, recipes, readiness/wearables, progress. Product/roadmap lives in
**BUSINESS.md** — this file is the *technical* orientation for any new chat.

## Starter prompts — paste one to open a parallel window
Each window owns ONE file/area so they never collide. Run **only one `app.js` window
at a time** (all features live there). Commit + push when done; next window pulls first.
- **Design/animation** → `styles.css`:
  > Read PROJECT.md and BUSINESS.md. You own `styles.css` only (design, layout, colour, animation). Don't change app.js logic. Task: …
- **Features/logic** → `app.js`:
  > Read PROJECT.md and BUSINESS.md. You own `app.js` only (features, logic, data/sync). Verify in the preview with no console errors before pushing. Task: …
- **Backend/integrations** → `backend/`:
  > Read PROJECT.md and BUSINESS.md. You own `backend/` only (Cloudflare Worker, wearables OAuth, SQL, sign-in). Task: …
- **Planning/QA** → docs:
  > Read PROJECT.md and BUSINESS.md. You own docs + QA (BUSINESS.md, PROJECT.md) — plan/test/review only, no app code. Task: …

*(When you need two feature windows at once: open a fresh chat tasked only with
"split app.js into core.js/training.js/meals.js/readiness.js/recipes.js, classic
scripts in load order, verify every screen." Then each feature becomes its own lane.)*

## Stack & philosophy
- **Vanilla static PWA. No build step, no framework, no bundler.** This is deliberate —
  it's why it "always works." Do **not** add React/Vite/etc.
- Plain `<script>` (classic, shared global scope) — inline `onclick="fn()"` handlers
  call global functions. Keep that pattern (don't convert to ES modules).
- Deploy = `git push` → **GitHub Pages** auto-builds (repo `Reetwell/summer26`,
  served at https://reetwell.github.io/summer26/). ~1 min to go live.
  Poll a build: `gh api repos/Reetwell/summer26/pages/builds/latest --jq '{status,commit:.commit}'`.

## File map
- `index.html` — page structure only (markup + the early splash `<script>` + the
  Chart.js CDN tag). Loads `styles.css` and `app.js`.
- `styles.css` — **all CSS** (design/animation work goes here).
- `app.js` — **all app logic** (features/data/sync go here).
- `icon.svg` + `icon-*.png` / `favicon.ico` — app icons ("BB" monogram). PNGs are
  generated from `icon.svg` via `qlmanage`/`sips` (see git history).
- `site.webmanifest` — PWA manifest.
- `backend/` — Cloudflare Worker code: `worker.js` (reminders + recipe extract),
  `wearables.js` (OAuth scaffold, not yet mounted), `*.sql` (Supabase tables).
- `BUSINESS.md` — product plan, pricing, roadmap, setup to-dos (run these SQL/keys).
- `BuildYourBody/` — **native iOS + macOS SwiftUI app** (Xcode 26 project; owned by
  the native-app chat — web chats don't touch it). Status: all 5 tab UIs + 7-step
  onboarding + auth screens done on sample data. Supabase-swift wired but
  `Core/Supabase/Secrets.swift` still has placeholder URL/key. Build headlessly:
  `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` then
  `xcodebuild -project BuildYourBody.xcodeproj -scheme BuildYourBody -destination
  'platform=iOS Simulator,name=iPhone 17 Pro' build` (or `platform=macOS`).
  See DESIGN-PLAN.md for the roadmap. `ios/` = old scaffold source, superseded.

## Data & sync (the reliability backbone)
- State lives in **localStorage** under `sbp-*` / `bb-*` keys.
- Writes go through a monkey-patched `localStorage.setItem`; any key in **`SYNC_KEYS`**
  (in app.js) auto-syncs to **Supabase** `app_data` (generic jsonb key/value — no
  schema change to add a key). Sign-in via Supabase auth (`initAuth`/`onAuth`).
- Key stores: `sbp-mealplan` (meal plan v-model), `sbp-trainingplan` (training, v3
  `phases` mode — `tpInit` migrates old `split` plans), `sbp-readiness`,
  `sbp-tp-progress`, `sbp-mealshop`, `sbp-today`, `sbp-weight`, `sbp-recipes`.
- **Data migrations:** when a model changes, migrate on load (see `migrateSplit`,
  `tpInit`) so existing users don't break. Always do this.

## Catalogs (Supabase, with bundled fallback in app.js)
- `recipe_library` (meals onboarding) ← `backend/recipe-library.sql` + `RECIPE_LIBRARY`.
- `exercise_library` (training) ← `backend/exercise-library.sql` + `EXERCISE_LIBRARY`.
- Pattern: try Supabase, fall back to the bundled JS copy so it works offline / while
  the project is paused. Keep both in sync when editing.

## Conventions
- Brand green `--green-500`/`--green-900` (#0F6E56). Fonts: DM Sans (body), DM Serif
  Display (headings). Tokens in `:root` in styles.css.
- Icons: **Font Awesome free** — use `fa-solid` (the `fa-regular`/Pro variants render
  as tofu boxes; that bug bit us once).
- Breakpoints: ≤1023px = mobile/tablet (bottom nav), ≥1024px = desktop (240px sidebar).
- Toasts: `showToast(msg, type)`. Escape user text with `esc()`.
- Each section is `<div class="section" id="sec-X">`; `showSection('X')` activates it.

## Verify before pushing (no test suite — do this manually)
1. Run the dev server via the preview tool (config in `.claude/launch.json`, port 8753)
   or `python3 -m http.server`.
2. Load the app, check the **console has no errors**, click through the changed screens.
3. Screenshot the change. Then commit + push.
- Dev shortcut: the sign-in gate has a "Skip sign-in (dev)" link; localStorage flags
  `sbp-dev-skip`, `sbp-onboarded` bypass it. **Remove the dev skip before launch.**

## Multi-chat workflow
- Chats don't share live memory — **git/files are the source of truth.** Always start a
  chat with "read PROJECT.md + BUSINESS.md."
- Safe parallel split: **design chat → `styles.css`**, **logic chat → `app.js`**,
  **structure → `index.html`**, **backend chat → `backend/`**. Avoid two chats editing
  the same file at once; commit + push between, pull latest first.

## Open setup tasks (owner: Brian — see BUSINESS.md §10)
- Run `backend/recipe-library.sql` + `backend/exercise-library.sql` in Supabase.
- Restore the paused Supabase project; add `ANTHROPIC_API_KEY` to the Worker (Recipes).
- Enable Google/Apple sign-in. Wearables: register Oura/Whoop/Fitbit dev apps + secrets,
  mount `backend/wearables.js`, set `WEARABLES_ENABLED = true`.
- Move the WorkoutX key (currently in app.js) behind the Worker before paid tier.
