# OpenClaw Trusted-Local Auto-Maintainer

Patched OpenClaw build for trusted local personal assistant use on k3ss M4 Mac.

## What This Is

OpenClaw ships with hardcoded sandbox restrictions. This repo contains the auto-maintainer that:
1. Detects new upstream versions
2. Applies your trusted-local cleaning (removes sandbox/exec restrictions)
3. Self-heals when upstream changes
4. Builds and swaps the binary
5. Verifies your security intent is preserved

## Quick Start

```bash
cd /Volumes/openclaw/openclaw-trusted-local

# Check for updates
./oc-self-heal.sh --check

# Preview what would happen  
./oc-self-heal.sh --dry-run

# Run full update
./oc-self-heal.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `./oc-self-heal.sh` | Full update (stop → pull → clean → build → swap → restart) |
| `./oc-self-heal.sh --check` | Only check GitHub for new version |
| `./oc-self-heal.sh --dry-run` | Preview without applying |
| `./oc-self-heal.sh --force` | Force rebuild even if up-to-date |

## Files

```
openclaw-trusted-local/
├── oc-self-heal.sh              # Main entry point (NEW)
├── oc-update.sh                # Legacy updater
├── lib/                        # NEW: Self-healing engine
│   ├── detect-version.sh       # Version detection
│   ├── apply-cleaning.sh       # Self-healing transformer
│   ├── check-safety.sh        # Safety verification
│   └── build.sh               # Build & swap
├── patches/
│   └── cleaning-rules.json     # NEW: Declarative rules
└── openclaw-trusted-local.patch # Legacy static patch
```

## Security Intent

Enforces on your trusted local environment:
- **Exec**: Full access (no sandboxing)
- **Ask**: Off (no prompting)
- **Path**: Relaxed (no boundary restrictions)
- **Default Host**: Gateway

## What It NEVER Touches

- `/Volumes/openclaw/.openclaw/` - state directory
- `/Volumes/openclaw/.openclaw/openclaw.json` - config
- `/Volumes/openclaw/.openclaw/workspace/` - Rae's brain files

## If Self-Heal Fails

The system will STOP and report. Check output:
```bash
./lib/apply-cleaning.sh  # Run with verbose
```

Manual fix: Update `patches/cleaning-rules.json` patterns, then retry.

## Binary Location

`/opt/homebrew/lib/node_modules/openclaw/dist/openclaw.mjs`

## Support

- Logs: `/tmp/oc-cleaning.log`
- Gateway logs: `/tmp/openclaw/openclaw-*.log`
