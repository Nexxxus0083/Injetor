#!/bin/bash
set -euo pipefail
# build.sh - build IPA tailored for TrollStore (attempts unsigned app packaging)
# Usage: ./build.sh [clean|build|package|all]
PROJECT_NAME="MemoryInjector"
SCHEME_NAME="MemoryInjector"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-./DerivedData}"
OUT_DIR="${OUT_DIR:-./build_artifacts}"
APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.app"
IPA_PATH="$OUT_DIR/${PROJECT_NAME}_trollstore_$(date +%Y%m%d%H%M%S).ipa"

mkdir -p "$OUT_DIR"
echo "[INFO] Cleaning previous build..."
xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" || true

echo "[INFO] Building app (signing disabled)..."
# Attempt to build without code signing. This may fail on some Xcode versions/configs.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -sdk iphoneos BUILD_DIR="$DERIVED_DATA/Build" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO ENABLE_BITCODE=NO | xcpretty || true

if [ ! -d "$APP_PATH" ]; then
  echo "[WARN] .app not found at $APP_PATH. Listing derived data build products:"
  find "$DERIVED_DATA" -maxdepth 4 -type d -name "*.app" -print || true
  echo "[ERROR] Build failed or produced no .app. You may need a signing identity or adjust project settings."
  exit 1
fi

echo "[INFO] Packaging .app into .ipa (TrollStore-compatible)..."
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/Payload"
cp -R "$APP_PATH" "$TMPDIR/Payload/"
# remove code signature to simulate unsigned app (optional)
if [ -d "$TMPDIR/Payload/${PROJECT_NAME}.app/_CodeSignature" ]; then
  rm -rf "$TMPDIR/Payload/${PROJECT_NAME}.app/_CodeSignature" || true
fi
( cd "$TMPDIR" && zip -r "$IPA_PATH" Payload ) >/dev/null 2>&1 || true
rm -rf "$TMPDIR"
echo "[OK] IPA ready: $IPA_PATH"
echo "[INFO] You can download the IPA and install it using TrollStore on a compatible device."
