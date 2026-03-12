#!/usr/bin/env bash
# oc-self-heal.sh - OpenClaw Trusted-Local Auto-Maintainer
# 
# Usage:
#   ./oc-self-heal.sh           # Normal update (pulls, cleans, builds, swaps)
#   ./oc-self-heal.sh --check   # Check for new version only
#   ./oc-self-heal.sh --dry-run # Preview what would happen
#   ./oc-self-heal.sh --force   # Force rebuild even if up to date

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-/Volumes/openclaw/openclaw-source}"
DEST_DIR="/opt/homebrew/lib/node_modules/openclaw/dist"
LOG_DIR="$SCRIPT_DIR/logs"
STATE_DIR="${STATE_DIR:-/Volumes/openclaw/.openclaw}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Options
DRY_RUN=false
FORCE=false
CHECK_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            export DRY_RUN
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--check] [--force]"
            exit 1
            ;;
    esac
done

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err() { echo -e "${RED}[ERROR]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }

# Load lib functions
source "$SCRIPT_DIR/lib/detect-version.sh"
source "$SCRIPT_DIR/lib/apply-cleaning.sh"
source "$SCRIPT_DIR/lib/check-safety.sh"
source "$SCRIPT_DIR/lib/build.sh"

fail() {
    err "$@"
    exit 1
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v curl >/dev/null 2>&1 || fail "curl required"
    command -v pnpm >/dev/null 2>&1 || fail "pnpm required"
    command -v git >/dev/null 2>&1 || fail "git required"
    
    success "Prerequisites OK"
}

clone_or_pull_source() {
    log "Preparing upstream source..."
    
    if [ ! -d "$REPO_DIR" ]; then
        log "Cloning upstream OpenClaw..."
        git clone https://github.com/openclaw/openclaw "$REPO_DIR" || fail "Failed to clone"
        success "Cloned OpenClaw source"
    else
        cd "$REPO_DIR"
        log "Pulling latest from upstream..."
        git fetch origin main || fail "Failed to fetch"
        
        local current_branch
        current_branch=$(git branch --show-current)
        git checkout main >/dev/null 2>&1 || true
        git pull origin main || warn "Pull may have conflicts"
        
        success "Pulled latest source"
    fi
    
    # Get version
    local version
    version=$(grep '"version"' "$REPO_DIR/package.json" | awk -F'"' '{print $4}')
    log "Upstream version: $version"
}

stop_gateway() {
    log "Stopping OpenClaw gateway..."
    
    # Try using openclaw command if available
    if command -v node >/dev/null 2>&1; then
        node /opt/homebrew/lib/node_modules/openclaw/openclaw.mjs gateway stop >/dev/null 2>&1 || true
    fi
    
    # Kill any remaining processes
    pkill -f "openclaw-gateway" 2>/dev/null || true
    
    sleep 2
    success "Gateway stopped"
}

start_gateway() {
    log "Starting OpenClaw gateway..."
    
    export OPENCLAW_STATE_DIR="$STATE_DIR"
    export OPENCLAW_CONFIG_PATH="$STATE_DIR/openclaw.json"
    
    node /opt/homebrew/lib/node_modules/openclaw/openclaw.mjs gateway run >/dev/null 2>&1 &
    
    sleep 4
    
    # Check health
    if node /opt/homebrew/lib/node_modules/openclaw/openclaw.mjs health >/dev/null 2>&1; then
        success "Gateway healthy"
    else
        warn "Gateway may not be fully healthy yet"
    fi
}

main() {
    echo ""
    echo "========================================="
    echo "  OpenClaw Trusted-Local Auto-Maintainer"
    echo "========================================="
    echo ""
    
    # Check mode
    if [ "$CHECK_ONLY" = true ]; then
        log "Checking for updates..."
        check_prerequisites
        clone_or_pull_source
        exit 0
    fi
    
    # Dry-run header
    if [ "$DRY_RUN" = true ]; then
        warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Step 1: Prerequisites
    check_prerequisites
    
    # Step 2: Get upstream source
    clone_or_pull_source
    
    # Step 3: Apply self-healing cleaning
    log ""
    log "Applying trusted-local cleaning..."
    REPO_DIR="$REPO_DIR" DRY_RUN="$DRY_RUN" "$SCRIPT_DIR/lib/apply-cleaning.sh"
    
    # Step 4: Safety check
    log ""
    log "Running safety verification..."
    REPO_DIR="$REPO_DIR" STRICT=true "$SCRIPT_DIR/lib/check-safety.sh" || {
        warn "Safety check reported issues"
        if [ "$DRY_RUN" = false ]; then
            err "Refusing to proceed with potentially compromised cleaning"
            err "Please review the output above and fix manually"
            exit 1
        fi
    }
    
    # Step 5: Build
    if [ "$DRY_RUN" = false ]; then
        log ""
        log "Building..."
        REPO_DIR="$REPO_DIR" DRY_RUN="$DRY_RUN" "$SCRIPT_DIR/lib/build.sh"
        
        # Step 6: Restart gateway
        log ""
        stop_gateway
        start_gateway
        
        echo ""
        echo "========================================="
        success "OpenClaw update complete!"
        echo "========================================="
    else
        echo ""
        echo "========================================="
        warn "DRY RUN COMPLETE - No changes made"
        echo "========================================="
    fi
    
    echo ""
    echo "State dir: $STATE_DIR"
    echo "Config:    $STATE_DIR/openclaw.json"
    echo "Workspace: $STATE_DIR/workspace (UNCHANGED)"
}

main
