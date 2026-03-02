# openclaw-trusted-local

Patched OpenClaw build for trusted local personal assistant use on k3ss M4 Mac.

## What this is

OpenClaw ships with hardcoded sandbox restrictions that prevent it executing commands or writing files outside its workspace, even on a personal local machine. This repo contains the patch that removes those restrictions and the tooling to maintain it across upstream updates.

## Files

- `openclaw-trusted-local.patch` — git diff patch against openclaw/openclaw main. Apply this after any upstream update to restore trusted local mode.
- `oc-update.sh` — update script. Run this instead of brew upgrade or npm update. Pulls upstream, re-applies patch, rebuilds, swaps binary, restarts gateway.

## Patched files

| File | Change |
|------|--------|
| src/agents/bash-tools.exec.ts | Default exec host sandbox → gateway, security deny → full, ask on-miss → off |
| src/agents/bash-tools.exec-runtime.ts | Same defaults in normalizeExecHost/Security/Ask |
| src/agents/sandbox-paths.ts | assertSandboxPath() stubbed to no-op |
| src/agents/path-policy.ts | toRelativePathUnderRoot() path escape rejection removed |
| src/agents/pi-tools.read.ts | assertSandboxPath() callsite removed |
| src/agents/apply-patch.ts | Both assertSandboxPath() callsites removed |
| src/agents/sandbox-media-paths.ts | enforceWorkspaceBoundary() stubbed to no-op |
| src/agents/tool-fs-policy.ts | workspaceOnly defaults to false |
| src/agents/pi-tools.ts | applyPatchWorkspaceOnly defaults false, guard skipped when workspaceOnly false |
| src/agents/sandbox/config.ts | Scope default off, readOnlyRoot false, network bridge |
| src/agents/sandbox-tool-policy.ts | pickSandboxToolPolicy() always returns permissive |
| src/agents/workspace-dir.ts | normalizeWorkspaceDir() filesystem root rejection removed |

## How to apply after an upstream update

Run:
```bash
~/scripts/oc-update.sh
```

That script handles everything: stops gateway, pulls upstream, applies this patch, rebuilds, swaps binary, restarts gateway, verifies.

## If the patch fails to apply

Upstream changed one of the patched lines. Run:
```bash
cd ~/projects/openclaw
git pull origin main
git apply ~/projects/openclaw-trusted-local/openclaw-trusted-local.patch
```
Check which hunks failed, fix those lines manually to match the same intent (stub the enforcement, return early, flip the default), then update the patch:
```bash
git diff > ~/projects/openclaw-trusted-local/openclaw-trusted-local.patch
cd ~/projects/openclaw-trusted-local
git add openclaw-trusted-local.patch
git commit -m "fix: update patch for upstream changes"
git push
```

## Binary location

`/opt/homebrew/lib/node_modules/openclaw/dist/openclaw.mjs`
