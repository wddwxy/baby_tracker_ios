#!/usr/bin/env bash
#
# Build the Little Nest prototype for the iOS Simulator (plan test 01-01).
#
# Requires macOS with Xcode 16 or newer. Run from anywhere:
#
#     ios/scripts/build-simulator.sh
#     SIMULATOR_DEVICE="iPhone 16 Pro" ios/scripts/build-simulator.sh
#
set -euo pipefail

IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$IOS_DIR"

DEVICE="${SIMULATOR_DEVICE:-iPhone 16}"
DESTINATION="platform=iOS Simulator,name=$DEVICE"
if [[ -n "${SIMULATOR_UDID:-}" ]]; then
  DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID"
fi
DERIVED_DATA="${DERIVED_DATA_PATH:-$IOS_DIR/build/DerivedData}"

echo "Project : $IOS_DIR/LittleNest.xcodeproj"
echo "Device  : $DEVICE (iOS Simulator)"
echo "Derived : $DERIVED_DATA"

xcodebuild \
  -project LittleNest.xcodeproj \
  -scheme LittleNest \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo
echo "Built. To run it in the simulator:"
echo "  xcrun simctl boot \"$DEVICE\" 2>/dev/null || true"
echo "  xcrun simctl install booted \"$DERIVED_DATA/Build/Products/Debug-iphonesimulator/LittleNest.app\""
echo "  xcrun simctl launch booted com.wddwxy.littlenest"
