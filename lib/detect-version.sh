#!/usr/bin/env bash
# lib/detect-version.sh - Check GitHub for new OpenClaw versions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-/Volumes/openclaw/openclaw-source}"

get_current_version() {
    if [ -f "$REPO_DIR/package.json" ]; then
        grep '"version"' "$REPO_DIR/package.json" | awk -F'"' '{print $4}'
    else
        echo "unknown"
    fi
}

get_latest_github_version() {
    local latest
    latest=$(curl -sS "https://api.github.com/repos/openclaw/openclaw/releases/latest" | grep '"tag_name"' | awk -F'"' '{print $4}' | sed 's/^v//')
    echo "${latest:-unknown}"
}

check_for_update() {
    local current="$1"
    local latest="$2"
    
    if [ "$current" = "unknown" ] || [ "$latest" = "unknown" ]; then
        return 1
    fi
    
    # Compare versions
    if [ "$current" != "$latest" ]; then
        return 0  # Update available
    fi
    return 1  # No update
}

main() {
    local current latest
    
    current=$(get_current_version)
    latest=$(get_latest_github_version)
    
    echo "Current:  $current"
    echo "Latest:   $latest"
    
    if check_for_update "$current" "$latest"; then
        echo "UPDATE_AVAILABLE"
        exit 0
    else
        echo "UP_TO_DATE"
        exit 1
    fi
}

main "$@"
