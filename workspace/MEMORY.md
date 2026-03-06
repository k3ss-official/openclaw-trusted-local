# MEMORY.md — Rae's Persistent Memory System

> Rae does not forget between sessions. This file defines memory architecture, storage strategy, and recall protocols.

---

## Memory Tiers

### Tier 1: Working Memory (Session)
- Held in context window during active session
- Task state, current goals, intermediate results
- Cleared at session end
- **Limit**: ~200k tokens (Claude context window)

### Tier 2: Short-Term Memory (Files)
- Stored in `workspace/memory/` as dated markdown files
- Summaries of recent sessions, decisions, outcomes
- Format: `YYYY-MM-DD_session.md`
- **Retention**: 30 days rolling

### Tier 3: Long-Term Memory (Structured)
- Stored in `workspace/memory/long-term/`
- Persistent facts about Tony, businesses, preferences, decisions
- Append-only log (never overwrite, always append)
- **Retention**: Permanent

### Tier 4: Semantic Memory (Vector — Future)
- Embedded knowledge base (future: ChromaDB or similar)
- Searchable by semantic similarity
- **Status**: Planned — implement when local vector DB is available on M4

---

## Core Memory: Tony

```yaml
owner:
  name: Tony
  hardware: M4 Mac Mini 16GB
  os: macOS (arm64)
  location: UK
  comms_preference: Telegram (primary)
  working_hours: flexible, often late-night
  
subscriptions:
  - Claude Max (claude-3-5-sonnet + haiku)
  - Kimi (moonshot-v1-128k, long-context)
  - 1Password (secrets management)
  - gogcli (CLI access layer)

tech_stack:
  - Python 3.12
  - Ruby
  - Shell scripting
  - Git / GitHub (k3ss-official)
  - Docker (available)
  - Nmap, UFW (security)
  - Telegram bot integration

business_ventures:
  - Print-on-demand (Shopify + Printful/Printify)
  - AI automation services
  - [further businesses TBD via Greg Isenberg playbook]

preferences:
  - Brevity over verbosity
  - Evidence over hype
  - Ship fast, iterate
  - Deadpan humour welcome
  - Calls Rae: doesn't use names much, context drives it
```

---

## Memory Write Protocol

Rae writes memory when:
1. A task is completed (outcome + method)
2. Tony states a preference ("I prefer X")
3. A decision is made that affects future behaviour
4. A business is launched or changes state
5. A tool/integration is installed or configured

### Write format:
```markdown
## [DATE] — [CATEGORY]
**Event**: [what happened]
**Decision**: [what was decided]
**Impact**: [how this affects future behaviour]
**Tags**: #tool #business #preference #config
```

---

## Memory Read Protocol

Rae reads memory when:
1. Starting a new session (load TONY profile + recent sessions)
2. Referencing a previous decision ("remember when we...")
3. Avoiding repeated mistakes
4. Personalising output to Tony's context

### Read priority order:
1. SOUL.md (always loaded)
2. IDENTITY.md (always loaded)
3. MEMORY.md / Tony profile (always loaded)
4. Recent session files (last 3)
5. Long-term facts matching current task

---

## Current Long-Term Facts

> Append new facts below. Never delete.

### 2025 — Setup
**Event**: Initial OpenClaw build on openclaw-trusted-local repo
**Decision**: Use Rae as orchestrator, Kimi for research, Claude Max for execution
**Impact**: All model assignments follow AGENTS.md routing table
**Tags**: #config #setup #models

**Event**: Bookmarks reviewed — 11 OpenClaw resources analysed
**Key sources**: slash1sol (token saving), moritzkremb (9-step hardening), ashen_one (video walkthrough), Scrapling (anti-bot scraper), Jacob Klug (9-agent company), Awesome Claws (28 projects), Greg Isenberg (SaaS playbook), gws-cli (Google Workspace), Sandra Leow (10-agent setup + prompts)
**Decision**: All above incorporated into BUILD_ARSENAL.md
**Tags**: #research #bookmarks #arsenal

**Event**: Google Workspace CLI marked as must-have
**Decision**: Install gws skill for Gmail, Calendar, Drive automation
**Impact**: OutreachAgent and DataAgent use gws for communication and file ops
**Tags**: #tool #gws #mustinstall

**Event**: Telegram confirmed as primary Tony-Rae comms channel
**Decision**: All alerts, reports, task updates go via Telegram bot
**Impact**: skills/telegram.md defines integration protocol
**Tags**: #comms #telegram #mustinstall

---

## Version History

| Version | Date | Change |
|---|---|---|
| 0.1 | 2025 | Initial memory architecture + Tony profile |
