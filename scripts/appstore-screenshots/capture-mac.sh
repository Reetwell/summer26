#!/bin/bash
# Captures one screenshot per tab on native macOS at 1440x900 points, which on a
# Retina display renders at 2880x1800px — one of Apple's four accepted Mac App
# Store sizes (16:10). Uses the same DEBUG-only BB_DEMO/BB_TAB/BB_SKIP_AUTH hooks
# as the iPhone capture; no app code changes required.
#
# One-time setup: grant "Claude Code" (or whatever runs this — Terminal/iTerm if
# run by hand) Accessibility AND Screen Recording permission in System Settings >
# Privacy & Security, then re-run. Confirmed 2026-08-23: fails cleanly with this
# same message rather than hanging, since no permission was granted yet.
#
# Usage: scripts/appstore-screenshots/capture-mac.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
OUT="$(pwd)/.appstore-screenshots/mac"
mkdir -p "$OUT"
W=1440
H=900

echo "==> Building (Debug, macOS)..."
xcodebuild -project BuildYourBody/BuildYourBody.xcodeproj -scheme BuildYourBody \
  -configuration Debug -destination "platform=macOS" \
  build < /dev/null 2>&1 | tail -5

APP="$(xcodebuild -project BuildYourBody/BuildYourBody.xcodeproj -scheme BuildYourBody \
  -configuration Debug -destination "platform=macOS" \
  -showBuildSettings < /dev/null 2>/dev/null | awk -F'= ' '/ BUILT_PRODUCTS_DIR /{print $2; exit}')/BuildYourBody.app"
BIN="$APP/Contents/MacOS/BuildYourBody"

tab_names=(today meals training progress account)

quit_app() {
  osascript -e 'tell application "System Events" to if exists process "BuildYourBody" then tell process "BuildYourBody" to quit' > /dev/null 2>&1 || true
  pkill -f "$BIN" > /dev/null 2>&1 || true
  sleep 0.5
}

for i in "${!tab_names[@]}"; do
  name="${tab_names[$i]}"
  echo "==> Capturing tab $i ($name)..."
  quit_app
  BB_DEMO=1 BB_TAB="$i" BB_SKIP_AUTH=1 "$BIN" & disown
  # Wait for the window to exist, then pin its position/size so the region
  # capture below is deterministic regardless of last-used window frame.
  for _ in $(seq 1 20); do
    osascript -e 'tell application "System Events" to (exists window 1 of process "BuildYourBody")' 2>/dev/null | grep -q true && break
    sleep 0.25
  done
  sleep 1.5
  if ! osascript -e "tell application \"System Events\" to tell process \"BuildYourBody\" to set {position, size} of window 1 to {{0, 0}, {$W, $H}}" > /dev/null 2>&1; then
    echo "!! Could not resize the window via System Events — grant Terminal Accessibility"
    echo "   permission in System Settings > Privacy & Security, then re-run."
    quit_app
    exit 1
  fi
  sleep 0.5
  if ! screencapture -x -R "0,0,$W,$H" "$OUT/$name.png" 2>/dev/null; then
    echo "!! screencapture failed — grant Terminal Screen Recording permission in"
    echo "   System Settings > Privacy & Security, then re-run."
    quit_app
    exit 1
  fi
done
quit_app

echo "==> Verifying distinct frames..."
if [ "$(shasum "$OUT"/*.png | awk '{print $1}' | sort -u | wc -l)" -ne "${#tab_names[@]}" ]; then
  echo "!! WARNING: two or more screenshots are byte-identical — a tab didn't render before capture."
  shasum "$OUT"/*.png
  exit 1
fi

echo "==> Done: $OUT ($W x $H pt -> should be $((W*2)) x $((H*2)) px on Retina)"
ls -la "$OUT"
