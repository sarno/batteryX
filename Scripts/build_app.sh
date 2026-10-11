#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Building BatteryX release binaries..."
swift build -c release --product BatteryX
swift build -c release --product batteryx-helper

APP_NAME="BatteryX.app"
DIST_DIR="$DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Packaging $APP_NAME into $DIST_DIR..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executables
cp ".build/release/BatteryX" "$MACOS_DIR/BatteryX"
cp ".build/release/batteryx-helper" "$MACOS_DIR/batteryx-helper"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy AppIcon.icns
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Set executable permissions
chmod +x "$MACOS_DIR/BatteryX"
chmod +x "$MACOS_DIR/batteryx-helper"

# Optional ad-hoc code signing for local execution
echo "==> Applying ad-hoc codesign..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build & packaging complete: $APP_BUNDLE"
