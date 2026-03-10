#!/usr/bin/env bash
# oc-update.sh - OpenClaw trusted-local update script
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="/Volumes/openclaw/openclaw-source"
PATCH_FILE="$SCRIPT_DIR/openclaw-trusted-local.patch"
DEST_DIR="/opt/homebrew/lib/node_modules/openclaw/dist"
LOG_FILE="/tmp/oc-update-conflicts.log"

# Define colors and formatting
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"

# Global PID var for the spinner
SPINNER_PID=""

# ==========================================
# Spinner Utility Functions
# ==========================================
start_spinner() {
    local msg="$1"
    printf "  ⏳ %s... " "$msg"
    # Run spinner in background
    (
        local spin='-\|/'
        local i=0
        while :; do
            i=$(( (i+1) % 4 ))
            printf "\b%c" "${spin:$i:1}"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    local res="$1"
    local msg="$2"
    if [ -n "$SPINNER_PID" ]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
    fi
    # Clear line and spinner (carriage return, clear to end of line)
    printf "\r\033[K"
    if [ "$res" = "success" ]; then
        printf "  ✅ %s\n" "$msg"
    elif [ "$res" = "fail" ]; then
        printf "  ❌ %s\n" "$msg"
    else
        printf "  ⚠️ %s\n" "$msg"
    fi
}

fail() {
    stop_spinner "fail" "$1"
    exit 1
}

echo -e "${BOLD}Starting OpenClaw Trusted-Local Update...${RESET}\n"

# ==========================================
# 1. Stop OpenClaw Gateway
# ==========================================
start_spinner "Stopping OpenClaw gateway"
set +e
openclaw stop >/dev/null 2>&1
STOP_EXIT=$?
set -e

if [ $STOP_EXIT -eq 0 ]; then
    sleep 1
    stop_spinner "success" "Stopped OpenClaw gateway"
else
    # Non-zero exit implies it wasn't running
    stop_spinner "success" "OpenClaw gateway was not running"
fi

# ==========================================
# 2. Pull upstream openclaw source
# ==========================================
if [ ! -d "$REPO_DIR" ]; then
    start_spinner "Cloning OpenClaw source (first run)"
    if git clone https://github.com/openclaw/openclaw "$REPO_DIR" >/dev/null 2>&1; then
        stop_spinner "success" "Cloned OpenClaw source"
    else
        fail "Failed to clone repository"
    fi
fi

cd "$REPO_DIR"

start_spinner "Pulling upstream source"
# Get current version gracefully
CURRENT_VERSION=$(awk -F '"' '/"version":/ {print $4; exit}' package.json 2>/dev/null || echo "unknown")

# Stash local changes to avoid merge conflicts on pull
git stash >/dev/null 2>&1 || true

# Pull upstream main
if git pull origin main >/dev/null 2>&1; then
    NEW_VERSION=$(awk -F '"' '/"version":/ {print $4; exit}' package.json 2>/dev/null || echo "unknown")
    if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
        stop_spinner "success" "Upstream is already up to date (v${CURRENT_VERSION})"
    else
        stop_spinner "success" "Pulled upstream (v${CURRENT_VERSION} -> v${NEW_VERSION})"
    fi
else
    fail "Failed to pull from upstream repository"
fi

# ==========================================
# 3. Apply trusted-local patch
# ==========================================
start_spinner "Applying trusted-local patch"

# Dry run the patch to catch conflicts safely before touching files
set +e
PATCH_OUT=$(patch --dry-run -p1 < "$PATCH_FILE" 2>&1)
PATCH_EXIT_CODE=$?
set -e

if [ $PATCH_EXIT_CODE -ne 0 ]; then
    stop_spinner "fail" "Patch failed with conflicts"
    
    # Save the conflict log
    echo "$PATCH_OUT" > "$LOG_FILE"
    
    # Extract just the files that failed
    CONFLICTS=$(echo "$PATCH_OUT" | grep "saving rejects to file" | sed -E 's/.*saving rejects to file (.*)\.rej.*/\1/' || true)
    
    printf "     ${RED}Conflicting file(s):${RESET}\n"
    if [ -n "$CONFLICTS" ]; then
        for file in $CONFLICTS; do
            printf "       - %s\n" "$file"
        done
    else
        printf "       - (Could not parse conflicting files; please check log)\n"
    fi
    printf "\n     ${YELLOW}Conflict log saved to %s${RESET}\n" "$LOG_FILE"
    printf "     ${YELLOW}Update aborted. Gateway will remain on existing version.${RESET}\n"
    exit 1
fi

# Dry run was clean. Apply it for real.
TOTAL_HUNKS=$(grep -c "^@@ " "$PATCH_FILE" 2>/dev/null || echo "0")
patch -p1 < "$PATCH_FILE" >/dev/null 2>&1
stop_spinner "success" "Applied patch successfully ($TOTAL_HUNKS/$TOTAL_HUNKS hunks)"

# ==========================================
# 4. Build OpenClaw
# ==========================================
start_spinner "Building OpenClaw (this may take a minute)"
# Run pnpm install and build
if pnpm install >/dev/null 2>&1 && pnpm build >/dev/null 2>&1; then
    stop_spinner "success" "Built OpenClaw successfully"
else
    fail "Build failed. Check syntax and dependencies."
fi

# ==========================================
# 5. Swap Binaries
# ==========================================
start_spinner "Swapping binaries to $DEST_DIR"
if [ ! -d "$DEST_DIR" ]; then
    fail "Destination directory $DEST_DIR not found"
fi

# We use shell globbing to copy files.
set +e
cp -R "dist/"* "$DEST_DIR/" >/dev/null 2>&1
CP_RES=$?
cp -R "dist/bundled" "$DEST_DIR/" >/dev/null 2>&1
cp -R "dist/plugin-sdk" "$DEST_DIR/" >/dev/null 2>&1
set -e

if [ $CP_RES -eq 0 ]; then
    stop_spinner "success" "Binaries swapped successfully"
else
    fail "Failed to copy binaries to $DEST_DIR"
fi

# ==========================================
# 6. Restart Gateway
# ==========================================
start_spinner "Restarting OpenClaw gateway"
openclaw start >/dev/null 2>&1 &
# Wait for the process to spin up
sleep 2 
stop_spinner "success" "Gateway startup commanded"

# ==========================================
# 7. Health Check
# ==========================================
start_spinner "Waiting for gateway health OK"
HEALTH_OK=false
for i in {1..15}; do
    set +e
    openclaw health >/dev/null 2>&1
    HEALTH_STATUS=$?
    set -e
    if [ $HEALTH_STATUS -eq 0 ]; then
        HEALTH_OK=true
        break
    fi
    sleep 1
done

if [ "$HEALTH_OK" = true ]; then
    stop_spinner "success" "Gateway health checks passed"
else
    stop_spinner "fail" "Gateway failed to become healthy after 15s"
    exit 1
fi

# ==========================================
# 8. Final Summary Line
# ==========================================
printf "\n🎯 ${BOLD}Running: openclaw %s (trusted-local)${RESET}\n" "$NEW_VERSION"
