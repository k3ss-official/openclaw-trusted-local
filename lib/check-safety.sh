#!/usr/bin/env bash
# lib/check-safety.sh - Verify cleaning intent is preserved
# Can be sourced OR run directly
set -euo pipefail

# Only set SCRIPT_DIR if not already set (may be sourced from parent)
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
REPO_DIR="${REPO_DIR:-/Volumes/openclaw/openclaw-source}"

log() {
    echo "[CHECK] $*"
}

fail() {
    echo "[FAIL] $*" >&2
    exit 1
}

check_exec_security() {
    log "Checking exec security configuration..."
    
    local file="$REPO_DIR/src/agents/bash-tools.exec.ts"
    
    if grep -q 'security ?? "full"' "$file" || grep -q 'security.*full' "$file"; then
        log "  ✅ Security set to full"
        return 0
    else
        log "  ❌ Security NOT set to full - INTENT NOT PRESERVED"
        return 1
    fi
}

check_exec_ask() {
    log "Checking exec ask configuration..."
    
    local file="$REPO_DIR/src/agents/bash-tools.exec.ts"
    
    if grep -q 'ask ?? "off"' "$file" || grep -q 'ask.*off' "$file"; then
        log "  ✅ Ask set to off"
        return 0
    else
        log "  ❌ Ask NOT set to off - INTENT NOT PRESERVED"
        return 1
    fi
}

check_path_policy() {
    log "Checking path policy..."
    
    local file="$REPO_DIR/src/agents/path-policy.ts"
    
    # Check that throwPathEscapesBoundary is disabled
    if grep -q 'DISABLED.*throwPathEscapesBoundary' "$file" || ! grep -q 'throwPathEscapesBoundary({' "$file"; then
        log "  ✅ Path boundary checks disabled"
        return 0
    else
        log "  ❌ Path boundary checks still active - INTENT NOT PRESERVED"
        return 1
    fi
}

check_exec_defaults() {
    log "Checking exec-approvals defaults..."
    
    local file="$REPO_DIR/src/infra/exec-approvals.ts"
    
    local checks=0
    local passed=0
    
    if grep -q 'return "gateway"; // DEFAULT' "$file" || grep -q '"gateway"' "$file"; then
        log "  ✅ Host defaults to gateway"
        ((passed++))
    fi
    ((checks++))
    
    if grep -q 'return "full"; // DEFAULT' "$file" || grep -q 'security.*full' "$file"; then
        log "  ✅ Security defaults to full"
        ((passed++))
    fi
    ((checks++))
    
    if grep -q 'return "off"; // DEFAULT' "$file" || grep -q 'ask.*off' "$file"; then
        log "  ✅ Ask defaults to off"
        ((passed++))
    fi
    ((checks++))
    
    if [ "$passed" -eq "$checks" ]; then
        return 0
    else
        log "  ❌ Only $passed/$checks checks passed"
        return 1
    fi
}

main() {
    local strict="${STRICT:-false}"
    
    echo "========================================="
    echo "OpenClaw Safety Verification"
    echo "========================================="
    echo ""
    
    if [ ! -d "$REPO_DIR" ]; then
        fail "Repository not found: $REPO_DIR"
    fi
    
    local checks=0
    local passed=0
    
    check_exec_security && ((passed++)) || true
    ((checks++))
    
    check_exec_ask && ((passed++)) || true
    ((checks++))
    
    check_path_policy && ((passed++)) || true
    ((checks++))
    
    check_exec_defaults && ((passed++)) || true
    ((checks++))
    
    echo ""
    echo "Results: $passed/$checks checks passed"
    
    if [ "$passed" -eq "$checks" ]; then
        echo "✅ SAFETY CHECK PASSED - Intent preserved"
        exit 0
    else
        echo "❌ SAFETY CHECK FAILED - Intent may be compromised"
        if [ "$strict" = "true" ]; then
            fail "Safety verification failed - refusing to proceed"
        fi
        exit 1
    fi
}

# Only run main if executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
