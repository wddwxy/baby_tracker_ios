#!/usr/bin/env bash
# Build an unsigned physical-device app for local signing with Sideloadly.
set -euo pipefail

IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$IOS_DIR"
mkdir -p build
DERIVED_DATA="$IOS_DIR/build/DeviceDerivedData"
APP="$DERIVED_DATA/Build/Products/Release-iphoneos/LittleNest.app"
IPA="$IOS_DIR/build/LittleNest-unsigned.ipa"

xcodebuild \
  -project LittleNest.xcodeproj \
  -scheme LittleNest \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  build

python3 scripts/verify-build-artifacts.py --app-bundle "$APP"
STAGE="$(mktemp -d "$IOS_DIR/build/ipa-stage.XXXXXX")"
mkdir -p "$STAGE/Payload"
ditto "$APP" "$STAGE/Payload/LittleNest.app"
(
  cd "$STAGE"
  ditto -c -k --keepParent Payload "$IPA"
)
python3 scripts/check-ipa.py "$IPA"
shasum -a 256 "$IPA" > build/LittleNest-unsigned.ipa.sha256
echo "Unsigned device IPA: $IPA"
echo 'Requires local signing before installation. This is not an App Store/TestFlight package.'
