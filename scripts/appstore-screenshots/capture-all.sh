#!/bin/bash
# Full regen: iPhone + Mac App Store screenshots, all 5 tabs each.
# Run this once the app name is locked (rebuild the app icon / display name
# first) — see scripts/appstore-screenshots/README.md.
set -euo pipefail
cd "$(dirname "$0")"
START=$(date +%s)
./capture-iphone.sh
./capture-mac.sh
END=$(date +%s)
echo "==> Total regen time: $((END - START))s"
