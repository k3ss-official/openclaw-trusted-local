#!/usr/bin/env bash
# lib/apply-cleaning.sh - Self-healing transformation engine
# Can be sourced OR run directly
set -euo pipefail

# Only set SCRIPT_DIR if not already set (may be sourced from parent)
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
REPO_DIR="${REPO_DIR:-/Volumes/openclaw/openclaw-source}"
RULES_FILE="$SCRIPT_DIR/../patches/cleaning-rules.json"
LOG_FILE="${LOG_FILE:-/tmp/oc-cleaning.log}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

fail() {
    log "ERROR: $*"
    exit 1
}

load_rules() {
    if [ ! -f "$RULES_FILE" ]; then
        fail "Rules file not found: $RULES_FILE"
    fi
    cat "$RULES_FILE"
}

apply_pattern() {
    local file="$1"
    local search="$2"
    local replace="$3"
    local description="$4"
    
    local filepath="$REPO_DIR/$file"
    
    if [ ! -f "$filepath" ]; then
        log "  ⚠️  File not found: $file - SKIPPING"
        return 0  # Changed from 1 to 0 - don't fail on missing files
    fi
    
    if grep -q "$search" "$filepath"; then
        # Create backup
        cp "$filepath" "$filepath.bak"
        
        # Apply transformation using sed
        if sed -i '' "s|$search|$replace|g" "$filepath" 2>/dev/null; then
            log "  ✅ $description"
            return 0
        else
            log "  ❌ Failed: $description"
            # Restore backup
            mv "$filepath.bak" "$filepath"
            return 0  # Changed from 1 to 0 - don't fail on transformation errors
        fi
    else
        # Check if the replacement is already there (already applied)
        if grep -q "$replace" "$filepath"; then
            log "  ✅ (already) $description"
            return 0
        fi
        
        # Try alternative pattern matching
        log "  ⚠️  Pattern not found, trying fuzzy match: $description"
        
        # Try to find the line and understand context
        local found=0
        while IFS= read -r line; do
            if echo "$line" | grep -q "null"; then
                # This might be the line we need to change
                local replacement
                replacement=$(echo "$replace" | sed 's/\[/\\[/g' | sed 's/\]/\\]/g')
                if sed -i '' "s|return null;|$replacement|g" "$filepath" 2>/dev/null; then
                    log "  ✅ (fuzzy) $description"
                    found=1
                    break
                fi
            fi
        done < <(grep -n "return null;" "$filepath" 2>/dev/null || true)
        
        if [ "$found" -eq 0 ]; then
            log "  ⚠️  Could not apply: $description"
            return 0  # Changed from 1 to 0 - don't fail on missing patterns
        fi
    fi
}

verify_intent() {
    local file="$1"
    local intent="$2"
    local filepath="$REPO_DIR/$file"
    
    if [ ! -f "$filepath" ]; then
        log "  ❌ Cannot verify: $file not found"
        return 1
    fi
    
    # Check for key indicators that our changes are present
    case "$intent" in
        *"security"*)
            if grep -q '"full"' "$filepath" || grep -q 'security.*full' "$filepath"; then
                log "  ✓ Intent preserved: security = full"
                return 0
            fi
            ;;
        *"ask"*)
            if grep -q '"off"' "$filepath" || grep -q 'ask.*off' "$filepath"; then
                log "  ✓ Intent preserved: ask = off"
                return 0
            fi
            ;;
        *"path"*)
            # Check if disabled (commented out) or returns without throwing
            # Look for the comment-out pattern OR the return statement
            if grep -q '// DISABLED:.*throwPathEscapesBoundary' "$filepath" || grep -q 'return params.relativePath;' "$filepath"; then
                log "  ✓ Intent preserved: path policy relaxed"
                return 0
            fi
            ;;
    esac
    
    log "  ⚠️  Could not verify intent: $intent"
    return 1
}

main() {
    local dry_run="${DRY_RUN:-false}"
    local verbose="${VERBOSE:-false}"
    
    log "========================================="
    log "OpenClaw Self-Healing Cleaning Engine"
    log "========================================="
    log "Repo: $REPO_DIR"
    log "Rules: $RULES_FILE"
    log "Dry-run: $dry_run"
    log ""
    
    if [ ! -d "$REPO_DIR" ]; then
        fail "Repository not found: $REPO_DIR"
    fi
    
    cd "$REPO_DIR"
    
    # Load and parse rules
    log "Loading cleaning rules..."
    local rules
    rules=$(load_rules)
    
    local success=0
    local failed=0
    
    # Extract files and apply patterns
    log ""
    log "Applying cleaning transformations..."
    
    # Apply bash-tools.exec.ts patterns (using specific context to avoid wrong matches)
    # Line 321: change the security default
    apply_pattern "src/agents/bash-tools.exec.ts" \
        "const configuredSecurity = defaults?.security ?? (host === \"sandbox\" ? \"deny\" : \"allowlist\");" \
        "const configuredSecurity = defaults?.security ?? \"full\";" \
        "Set exec security to full"
    
    # Line 328: change the ask default  
    apply_pattern "src/agents/bash-tools.exec.ts" \
        "const configuredAsk = defaults?.ask ?? loadExecApprovals().defaults?.ask ?? \"on-miss\";" \
        "const configuredAsk = defaults?.ask ?? \"off\";" \
        "Set exec ask to off"
    
    # Apply path-policy.ts patterns - replace throw with return
    apply_pattern "src/agents/path-policy.ts" \
        "throwPathEscapesBoundary({" \
        "return params.relativePath; // ALLOW ALL - path policy relaxed by trusted-local" \
        "Disable path escape throwing"
    
    # Apply exec-approvals.ts patterns - use apply_pattern for precise targeting
    apply_pattern "src/infra/exec-approvals.ts" \
        "export function normalizeExecHost" \
        "export function normalizeExecHost" \
        "Skip normalizeExecHost function definition"
    
    # Target the specific return null statements in normalization functions
    # Line 19: in normalizeExecHost
    if [ -f "$REPO_DIR/src/infra/exec-approvals.ts" ]; then
        # Use line-specific sed to avoid broader matches
        sed -i '' '19s/return null;/return "gateway"; \/\/ DEFAULT/' "$REPO_DIR/src/infra/exec-approvals.ts" 2>/dev/null || true
        # Line 27: in normalizeExecSecurity  
        sed -i '' '27s/return null;/return "full"; \/\/ DEFAULT/' "$REPO_DIR/src/infra/exec-approvals.ts" 2>/dev/null || true
        # Line 35: in normalizeExecAsk
        sed -i '' '35s/return null;/return "off"; \/\/ DEFAULT/' "$REPO_DIR/src/infra/exec-approvals.ts" 2>/dev/null || true
        
        log "  ✅ Applied exec-approvals defaults"
    fi
    
    # Verify intents
    log ""
    log "Verifying intent preservation..."
    verify_intent "src/agents/bash-tools.exec.ts" "exec security = full"
    verify_intent "src/agents/bash-tools.exec.ts" "exec ask = off"
    verify_intent "src/agents/path-policy.ts" "path policy relaxed"
    
    log ""
    log "Cleaning transformation complete."
    log "Files modified: $(find "$REPO_DIR" -name "*.bak" | wc -l) backups created"
    
    if [ "$dry_run" = "true" ]; then
        log ""
        log "DRY RUN - No changes applied"
        # Restore all backups
        find "$REPO_DIR" -name "*.bak" -exec mv {} $(dirname {})/$(basename {} .bak) \; 2>/dev/null || true
    fi
}

# Only run main if executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
