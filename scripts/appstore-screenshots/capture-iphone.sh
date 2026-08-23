#!/bin/bash
# Captures one screenshot per tab (Today/Meals/Training/Progress/Account) on the
# iPhone 17 Pro Max simulator — Apple's 6.9" required size, native 1320x2868, no
# resizing needed. Uses the existing DEBUG-only BB_DEMO/BB_TAB/BB_SKIP_AUTH launch
# hooks (App/DemoData.swift, App/MainTabView.swift, App/AppState.swift) — no app
# code changes required.
#
# Usage: scripts/appstore-screenshots/capture-iphone.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SIM_NAME="iPhone 17 Pro Max"
BID="uk.co.buildyourbody.app.BuildYourBody"
OUT="$(pwd)/.appstore-screenshots/iphone-6.9"
mkdir -p "$OUT"

echo "==> Building (Debug, $SIM_NAME)..."
xcodebuild -project BuildYourBody/BuildYourBody.xcodeproj -scheme BuildYourBody \
  -configuration Debug -destination "platform=iOS Simulator,name=$SIM_NAME" \
  build < /dev/null 2>&1 | tail -5

APP="$(xcodebuild -project BuildYourBody/BuildYourBody.xcodeproj -scheme BuildYourBody \
  -configuration Debug -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -showBuildSettings < /dev/null 2>/dev/null | awk -F'= ' '/ BUILT_PRODUCTS_DIR /{print $2; exit}')/BuildYourBody.app"

UDID="$(xcrun simctl list devices available < /dev/null | awk -v n="$SIM_NAME" -F'[()]' '$0 ~ n {print $2; exit}')"
if [ -z "$UDID" ]; then echo "!! Simulator '$SIM_NAME' not found"; exit 1; fi

echo "==> Booting $SIM_NAME ($UDID)..."
xcrun simctl boot "$UDID" < /dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b < /dev/null
xcrun simctl ui "$UDID" appearance light < /dev/null 2>&1 || true

echo "==> Installing..."
xcrun simctl install "$UDID" "$APP" < /dev/null

# index -> tab name (bash 0-indexed; run with a bash shebang, not sourced under zsh)
tab_names=(today meals training progress account)

for i in "${!tab_names[@]}"; do
  name="${tab_names[$i]}"
  echo "==> Capturing tab $i ($name)..."
  xcrun simctl terminate "$UDID" "$BID" < /dev/null 2>&1 || true
  sleep 0.5
  # simctl forwards SIMCTL_CHILD_* vars (stripped of the prefix) into the
  # launched process's environment — trailing args to `launch` become argv,
  # NOT env vars, so they must be exported here, not passed positionally.
  export SIMCTL_CHILD_BB_DEMO=1
  export SIMCTL_CHILD_BB_TAB="$i"
  export SIMCTL_CHILD_BB_SKIP_AUTH=1
  xcrun simctl launch --terminate-running-process "$UDID" "$BID" \
    < /dev/null > /dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" < /dev/null
done
xcrun simctl terminate "$UDID" "$BID" < /dev/null 2>&1 || true

echo "==> Verifying distinct frames..."
if [ "$(shasum "$OUT"/*.png | awk '{print $1}' | sort -u | wc -l)" -ne "${#tab_names[@]}" ]; then
  echo "!! WARNING: two or more screenshots are byte-identical — a tab didn't render before capture."
  echo "   Re-run, or raise the 'sleep 3' settle delay above."
  shasum "$OUT"/*.png
  exit 1
fi

echo "==> Done: $OUT"
ls -la "$OUT"
