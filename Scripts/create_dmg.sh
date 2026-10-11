#!/usr/bin/env bash
set -e

# ==========================================
# BatteryX DMG Disk Image Creator
# ==========================================

APP_NAME="BatteryX"
BUILD_DIR="./build"
DIST_DIR="./dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
STAGING_DIR="${BUILD_DIR}/dmg_staging"

# 1. Build app first if not built
if [ ! -d "${APP_BUNDLE}" ]; then
    ./Scripts/build_app.sh
fi

echo "💿 Preparing DMG staging directory..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${DIST_DIR}"

# 2. Copy App bundle and create /Applications symlink
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# 3. Create DMG using hdiutil
echo "🚀 Generating DMG image..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

rm -rf "${STAGING_DIR}"

echo "🎉 DMG successfully created at: ${DMG_PATH}"
