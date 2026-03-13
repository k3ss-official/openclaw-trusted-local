#!/usr/bin/env bash
# lib/build.sh - Build and swap OpenClaw binary
# Can be sourced OR run directly
set -euo pipefail

# Only set SCRIPT_DIR if not already set (may be sourced from parent)
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
REPO_DIR="${REPO_DIR:-/Volumes/openclaw/openclaw-source}"
DEST_DIR="/opt/homebrew/lib/node_modules/openclaw/dist"

log() {
    echo "[BUILD] $*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

main() {
    local dry_run="${DRY_RUN:-false}"
    
    echo "========================================="
    echo "OpenClaw Build & Swap"
    echo "========================================="
    log "Source: $REPO_DIR"
    log "Destination: $DEST_DIR"
    log "Dry-run: $dry_run"
    echo ""
    
    if [ ! -d "$REPO_DIR" ]; then
        fail "Repository not found: $REPO_DIR"
    fi
    
    if [ ! -d "$DEST_DIR" ]; then
        fail "Destination not found: $DEST_DIR"
    fi
    
    cd "$REPO_DIR"
    
    # Get version
    local version
    version=$(grep '"version"' package.json | awk -F'"' '{print $4}')
    log "Building version: $version"
    
    if [ "$dry_run" = "true" ]; then
        log "DRY RUN - Would run:"
        log "  pnpm install"
        log "  pnpm build"
        log "  cp -R dist/* $DEST_DIR/"
        exit 0
    fi
    
    # Install dependencies
    log "Installing dependencies..."
    if ! pnpm install >/dev/null 2>&1; then
        fail "pnpm install failed"
    fi
    log "  ✅ Dependencies installed"
    
    # Build
    log "Building OpenClaw..."
    if ! pnpm build >/dev/null 2>&1; then
        fail "pnpm build failed"
    fi
    log "  ✅ Build complete"
    
    # Swap binaries
    log "Swapping binaries..."
    if ! cp -R dist/* "$DEST_DIR/"; then
        fail "Failed to copy binaries"
    fi
    log "  ✅ Binaries swapped to $DEST_DIR"
    
    echo ""
    log "✅ Build complete: OpenClaw $version"
    echo "   Run 'openclaw gateway restart' to use new version"
}

# Only run main if executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
