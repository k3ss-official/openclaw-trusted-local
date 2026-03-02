#!/usr/bin/env bash
set -euo pipefail
REPO=/Volumes/deep-1t/Users/k3ss/projects/openclaw
PATCH=/Volumes/deep-1t/Users/k3ss/projects/openclaw-trusted-local.patch
DEST_DIR=/opt/homebrew/lib/node_modules/openclaw/dist
echo "=== Stopping gateway ==="
pkill -f "openclaw start" || true
sleep 1
echo "=== Pulling upstream ==="
cd "$REPO"
git stash
git pull origin main
echo "=== Re-applying trusted local patch ==="
git apply "$PATCH"
echo "=== Building ==="
pnpm build
echo "=== Swapping binaries ==="
cp -r "$REPO/dist/"* "$DEST_DIR/"
cp -r "$REPO/dist/bundled" "$DEST_DIR/"
cp -r "$REPO/dist/plugin-sdk" "$DEST_DIR/"
echo "=== Restarting gateway ==="
openclaw start &
sleep 2
mkdir -p ~/Documents/oc-update-verify
echo "update ok" > ~/Documents/oc-update-verify/result.txt
cat ~/Documents/oc-update-verify/result.txt
echo "UPDATE_COMPLETE"
