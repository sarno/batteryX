#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER_BIN="$DIR/.build/release/batteryx-helper"

if [ ! -f "$HELPER_BIN" ]; then
    echo "==> Building helper first..."
    swift build -c release --product batteryx-helper
fi

INSTALL_DEST="/usr/local/bin/batteryx-helper"

echo "==> Installing batteryx-helper to $INSTALL_DEST (requires sudo)..."
sudo cp "$HELPER_BIN" "$INSTALL_DEST"
sudo chown root:wheel "$INSTALL_DEST"
sudo chmod 4755 "$INSTALL_DEST"

echo "✅ batteryx-helper installed successfully with SUID root permission!"
echo "You can now run 'batteryx-helper get-limit' and 'batteryx-helper set-limit 80' without password."
