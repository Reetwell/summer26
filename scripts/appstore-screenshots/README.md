# App Store screenshot pipeline

Design lane, 2026-08-23. Builds the app, seeds demo data, and captures every
required App Store screenshot size for iPhone + Mac. No app code changes — it
drives three existing DEBUG-only test hooks (see below).

## Why this exists

The app **name is not locked** (overdue since 18 Jul — see
`marketing/name-candidates-trademark-check.md`) and the icon/wordmark will
change when it lands. Any screenshot captured today is throwaway once that
happens. So: this pipeline is the deliverable, not the screenshots. Once the
name locks and the icon/display name are updated, run `capture-all.sh` and the
full set regenerates from scratch.

## Apple's size matrix (verified against App Store Connect's current spec)

BuildYourBody is iPhone-only for v1 (no iPad — see DESIGN-PLAN.md), so iPad
screenshots are out of scope until v2.

| Platform | Size | Required? | Notes |
|---|---|---|---|
| iPhone 6.9" | 1320×2868 px | **Required** | iPhone 17 Pro Max simulator — native resolution, no scaling |
| iPhone 6.5"/6.3"/6.1"/5.5" etc. | — | Not needed | App Store Connect auto-scales these down from the 6.9" set |
| Mac | 2880×1800 px (16:10) | **Required** | Captured at 1440×900 *points*; Retina backing scale (2x) gives the exact px size |

5 screenshots per platform (one per tab: Today, Meals, Training, Progress,
Account) — well within Apple's 1–10 per size.

## The three launch hooks this pipeline drives (all DEBUG-only, already in the codebase)

- `BB_DEMO=1` — `App/DemoData.swift`: seeds a realistic, internally-consistent
  aspirational dataset (5-day streak, 35 sessions, Gold rank, etc.) instead of
  the true zero-state a fresh account would show.
- `BB_TAB=<0-4>` — `App/MainTabView.swift` + `App/MacSidebarView.swift`:
  preselects a tab on launch so each capture is a fresh, deterministic process
  (no UI-automation tapping required).
- `BB_SKIP_AUTH=1` — `App/AppState.swift`: bypasses the sign-in gate so launch
  goes straight to the tab content.

None of these compile into a Release build (`isActive`/the env reads are
`#if DEBUG`-gated), so there's no release-path risk.

## Known gap — found while validating this pipeline

`DemoData` doesn't mock the **Account tab's profile display name** — it's
still whatever real name/session is on this dev Simulator (came back as the
actual developer's name in testing). Before a real capture goes anywhere near
App Store Connect, `DemoData` needs a mocked display name too, or `AccountView`
needs to read it from `DemoData` the same way it does rank/streak. Flagging
here rather than fixing — it's a `DemoData.swift` change, native lane's file.

## Usage

```
scripts/appstore-screenshots/capture-iphone.sh   # ~1 min, no setup needed
scripts/appstore-screenshots/capture-mac.sh       # needs a one-time permission grant, see below
scripts/appstore-screenshots/capture-all.sh       # both, sequentially
```

Output goes to `.appstore-screenshots/{iphone-6.9,mac}/*.png` at the repo
root — gitignored, since it's throwaway pre-name-lock output, not an asset to
commit.

### Mac one-time setup

The Mac script positions the app window with System Events (for a
deterministic capture region) and screenshots it with `screencapture`. The
first run will need **Accessibility** and **Screen Recording** permission
granted to whatever process runs it (System Settings → Privacy & Security) —
it fails with a clear message rather than hanging if not yet granted. Grant
once, then every future run just works.

## Full regeneration time (measured 2026-08-23)

- iPhone: ~46s (incremental build ~5s once DerivedData is warm, + boot/install/5×capture)
- Mac: not yet measured end-to-end — blocked on the one-time permission grant above.
  Expect roughly the same order of magnitude (incremental build + 5× launch/capture,
  no simulator boot needed since it runs natively).
- **Total once the name is locked: comfortably under 5 minutes**, most of it
  fixed simulator-boot/build overhead rather than anything that scales with
  how many times you regenerate.
