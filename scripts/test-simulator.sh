#!/usr/bin/env bash
#
# Run the Little Nest unit and UI tests on the iOS Simulator.
#
# Requires macOS with Xcode 16 or newer.
#
#     scripts/test-simulator.sh
#     scripts/test-simulator.sh -only-testing:LittleNestTests
#     scripts/test-simulator.sh -only-testing:LittleNestUITests/DemoModeUITests
#
# Unit tests (plan test 01-04) never touch Home Assistant: they run without a session,
# without credentials and without network access.
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

xcodebuild \
  -project LittleNest.xcodeproj \
  -scheme LittleNest \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  "$@" \
  test
