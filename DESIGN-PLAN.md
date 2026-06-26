# Build Your Body — Design Master Plan

> Living document. Update this when priorities shift, screens ship, or new decisions are made.
> This covers **both products**: the web PWA and the native SwiftUI iOS app.
> For technical/backend detail see PROJECT.md. For product/pricing see BUSINESS.md.

---

## The two-product strategy

| | Web App (PWA) | iOS App (SwiftUI) |
|---|---|---|
| **Where** | reetwell.github.io/summer26 | App Store |
| **Who** | Anyone — desktop, Android, browser | iPhone users, iOS 26+ |
| **Tech** | Vanilla HTML/CSS/JS, GitHub Pages | SwiftUI, Xcode 26 |
| **Backend** | Supabase (shared) | Supabase (same tables) |
| **Status** | Live, actively developed | Planned — not started |
| **Design language** | Custom brand tokens (green/cream) | Liquid Glass + brand tokens |

Both products share the same Supabase backend, brand identity, and core feature set. They are maintained as separate codebases. The web app is the public-facing / broad-access product; the iOS app is the premium native experience.

---

## Brand tokens (both products must use these)

```
Primary green:   #1D9E75  (--green-500)
Dark green:      #0F6E56  (--green-700)
Deepest green:   #085041  (--green-900)
Light green:     #E8F7F2  (--green-50)

Background:      #F9F6F0  (warm cream, light mode)
Background dark: #0E0E0E

Fonts:
  Headings — DM Serif Display (web) / .custom("DMSerifDisplay-Regular") (Swift)
  Body     — DM Sans (web)     / .custom("DMSans-Regular") (Swift)

Radius:  sm=8  md=14  lg=20  pill=999
```

---

## Product 1 — Web PWA

### Current state (as of June 2026)

| Screen | Status | Notes |
|---|---|---|
| Sign-in (`#sigate`) | ✅ Done | Split-screen desktop, word reel, @starting-style entrance |
| Dashboard (`#sec-today`) | ✅ Done | Macro rings, readiness score |
| Meal plan (`#sec-meals`) | ✅ Done | Expand animation, directional transitions |
| Training (`#sec-training`) | ✅ Done | Phase/week layout |
| Shopping list (`#sec-shopping`) | ✅ Done | Check-off animation, checkPop keyframe |
| Recipes (`#sec-recipes`) | ✅ Done | Recipe-soon modal, gradient header, soonItemIn animation |
| Account (`#sec-account`) | ✅ Done | Premium redesign, 2-col desktop grid, green hero |
| Readiness / Wearables | 🔲 Pending | Logic complete, design audit not done |
| Progress / Weight chart | 🔲 Pending | Animate-in on load (needs app.js, deferred) |
| Onboarding | 🔲 Pending | Not yet designed |

### CSS audit — remaining items (styles.css lane only)

- [ ] Readiness screen design pass
- [ ] Progress screen — chart entrance animation (coordinate with app.js chat)
- [ ] Onboarding flow design
- [ ] Dark mode pass — audit all new components against `prefers-color-scheme: dark`
- [ ] Tablet breakpoint (600–759px) audit on all new screens

### Web design rules to always follow

1. CSS lane only — never touch `app.js` or restructure `index.html`
2. Use `@starting-style` for modal/overlay entrances (Chrome 117+, Safari 17.5+, Firefox 129+)
3. Directional transitions — different `transition` on base vs active state
4. All interactive elements need `:active` feedback (scale or opacity)
5. Mobile-first — bottom nav, thumb-zone primary actions
6. No comments unless the why is non-obvious

---

## Product 2 — iOS SwiftUI App

### Target

- **Minimum deployment: iOS 26** (Liquid Glass, full SwiftUI concurrency)
- **Xcode 26** (stable release, available now)
- iPhone only for v1, iPad + Apple Watch in v2

### Architecture

```
BuildYourBody.xcodeproj
├── App/
│   ├── BuildYourBodyApp.swift      # @main, app entry
│   └── AppState.swift              # @Observable global state
├── Core/
│   ├── Supabase/                   # Supabase Swift client + auth
│   ├── Models/                     # MealPlan, TrainingPlan, WeightEntry etc.
│   └── Extensions/                 # Color+Brand, Font+Brand, View+Helpers
├── Features/
│   ├── Auth/                       # SignInView, CreateAccountView
│   ├── Dashboard/                  # TodayView, MacroRingView, ReadinessView
│   ├── Meals/                      # MealPlanView, MealCardView, MealEditView
│   ├── Training/                   # TrainingView, WorkoutLogView, PhaseView
│   ├── Shopping/                   # ShoppingListView, ShoppingItemRow
│   ├── Recipes/                    # RecipeLibraryView, RecipeDetailView
│   ├── Progress/                   # ProgressView, WeightChartView
│   └── Account/                    # AccountView, SettingsView
└── Design/
    ├── Tokens.swift                 # Color, spacing, radius as Swift constants
    └── Components/                  # BBButton, BBCard, BBTextField, etc.
```

### SwiftUI design language — Liquid Glass

iOS 26 ships a new material system. Use it deliberately:

- `.glassEffect()` — on overlapping cards, modal sheets, navigation elements
- `NavigationStack` with `.navigationTransition(.zoom)` — feel-of-the-OS transitions
- `TabView` with `.tabViewStyle(.sidebarAdaptable)` — adapts phone/iPad automatically
- `@Observable` macro — replaces ObservableObject/Published, cleaner state
- `SwiftData` — consider for local cache (or use Supabase client directly for all data)
- Avoid `UIKit` unless bridging something SwiftUI genuinely can't do

### Brand tokens in Swift

```swift
// Core/Extensions/Color+Brand.swift
extension Color {
    static let green500 = Color(hex: "#1D9E75")
    static let green700 = Color(hex: "#0F6E56")
    static let green900 = Color(hex: "#085041")
    static let green50  = Color(hex: "#E8F7F2")
    static let cream    = Color(hex: "#F9F6F0")
}

extension Font {
    static func serifDisplay(_ size: CGFloat) -> Font {
        .custom("DMSerifDisplay-Regular", size: size)
    }
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DMSans-Regular", size: size).weight(weight)
    }
}
```

### Screen inventory — iOS app

| Screen | Priority | Native advantage over web |
|---|---|---|
| Auth (sign-in / create account) | P0 | Face ID/Touch ID, Sign in with Apple |
| Dashboard — Today | P0 | Glanceable widget, HealthKit ring data |
| Meal plan | P0 | — |
| Training — log workout | P0 | HealthKit write, Apple Watch trigger |
| Shopping list | P1 | — |
| Recipes | P1 | — |
| Progress / Weight | P1 | HealthKit weight sync |
| Account / Settings | P1 | — |
| Apple Watch companion | P2 | Workout tracking on wrist |
| Home screen widgets | P2 | Macros today, streak, next workout |
| Live Activities | P3 | Workout timer on Lock Screen / Dynamic Island |

### Build order — what to do first

#### Phase 1 — Foundation (do this before any feature screens)

1. **Xcode project** — new SwiftUI app, iOS 26 target, add DM Serif Display + DM Sans fonts to the bundle
2. **Supabase Swift client** — add via Swift Package Manager (`github.com/supabase/supabase-swift`), configure with the same URL/anon key as the web app
3. **Brand tokens** — `Color+Brand.swift`, `Font+Brand.swift`, `Tokens.swift` (spacing/radius)
4. **Reusable components** — `BBButton` (green pill), `BBCard` (glass surface), `BBTextField`

#### Phase 2 — Auth (first screen to build)

Start here because it's the gate to everything and it's the screen most familiar from the web design work.

- `SignInView` — email/password + Sign in with Apple + Sign in with Google
- `CreateAccountView` — name, email, password, DOB
- Auth state flows through `AppState` into a `@Environment` key

Design reference: the web split-screen sign-in (left form, green brand panel). On mobile, collapse to the sheet-over-green-hero layout you already have.

#### Phase 3 — Dashboard

- `TodayView` — macro rings (calories, protein, carbs, fat), readiness score, today's training
- `MacroRingView` — custom `Canvas`-drawn rings (match the web's ring style)
- Read today's calorie data from `sbp-today` via Supabase

#### Phase 4 — Core loop (Meals + Training)

- `MealPlanView` — day tabs, meal cards, expand-to-edit
- `TrainingView` — phase/week grid, workout card
- `WorkoutLogView` — exercise sets, reps, weight — write to HealthKit on complete

#### Phase 5 — Widgets + Watch

- `TodayWidget` — small: streak + calories. medium: full macro summary
- `WatchApp` — start/end workout, quick log set, glanceable rings

---

## Shared decisions — both products

### Navigation model

| Context | Pattern |
|---|---|
| Mobile web | Bottom tab bar (5 items) |
| Desktop web | 240px left sidebar |
| iOS app | `TabView` with 5 tabs |
| iPad | `.sidebarAdaptable` (sidebar on iPad, tab bar on iPhone) |

### Core screens (same on both)
Today · Meals · Training · Shopping · Account

### Features that only make sense native (iOS only)
HealthKit sync · Apple Watch · Widgets · Live Activities · Siri Shortcuts · Face ID

### Features that only make sense web
Desktop planning view · SEO/discoverability · Android/cross-platform access

---

## Design principles — both products

These override everything. When in doubt, come back to these.

1. **Confidence, not noise.** No excessive animations, no celebration confetti everywhere. Clean, earned moments.
2. **Peer-level tone.** No baby-talk, no "Great job!!!" Copy sounds like a friend who knows fitness.
3. **Thumb-first.** Primary actions always in the bottom third. Never make someone reach to the top-left.
4. **Numbers do the talking.** Stats, rings, bars. Not walls of instructions.
5. **Dark mode is a given.** Every new component is designed for both. Test both before pushing.
6. **One action per screen.** Each view has one clear next step. Don't present a menu where a CTA should be.
7. **Authenticity over polish.** A slightly imperfect, honest feel is better than corporate sheen.

---

## Open questions

- [ ] Do we maintain separate Supabase projects for web vs iOS, or one shared? → **One shared** (decided)
- [ ] SwiftData local cache, or always fetch from Supabase? → TBD when building Phase 1
- [ ] What is the App Store pricing model? → See BUSINESS.md
- [ ] Apple Watch — v1 or v2? → v2 (after core app ships)
- [ ] TestFlight beta — who gets it first? → TBD

---

*Last updated: 2026-06-26*
