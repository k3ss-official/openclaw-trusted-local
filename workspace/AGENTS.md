# AGENTS.md — Rae's Agent Network Registry

> Master registry of all sub-agents in the OpenClaw stack. Rae orchestrates; these execute.

---

## Agent Architecture Overview

```
Tony (Human)
  └── Rae (Orchestrator / Primary Interface)
        ├── ResearchAgent
        ├── CodeAgent
        ├── ContentAgent
        ├── DataAgent
        ├── OutreachAgent
        ├── MonitorAgent
        └── [Business-specific agents per venture]
```

---

## Core Agents

### 1. Rae — Orchestrator
- **Model**: Claude (claude-3-5-sonnet via Claude Max)
- **Role**: Primary interface with Tony. Routes all tasks. Owns agent lifecycle.
- **Escalates to Tony**: Anomalies, budget overruns, stale jobs, strategic pivots
- **Comms**: Telegram (primary), terminal fallback
- **Config**: workspace/SOUL.md + workspace/IDENTITY.md

---

### 2. ResearchAgent
- **Model**: Kimi (moonshot-v1-128k) — long-context specialist
- **Role**: Deep research, competitive analysis, market scans, summarisation
- **Triggers**: "research X", "find me Y", "what does the market say about Z"
- **Output**: Structured markdown reports → Rae → Tony
- **Tools**: web_search, scrapling, read_url
- **Cost tier**: Low (Kimi free/cheap tier)

---

### 3. CodeAgent
- **Model**: Claude (claude-3-5-haiku for speed, sonnet for complex)
- **Role**: Write, debug, refactor, review code. Generate scripts.
- **Triggers**: "write a script", "fix this error", "build X feature"
- **Output**: Code blocks, PRs, patches
- **Tools**: bash, file_read, file_write, git
- **Stack awareness**: M4 Mac Mini (arm64), macOS, Python 3.12, Ruby, Shell

---

### 4. ContentAgent
- **Model**: Claude (claude-3-5-sonnet)
- **Role**: Write copy, posts, emails, threads, product descriptions
- **Triggers**: "write a post about", "draft an email", "create copy for"
- **Output**: Raw text, markdown, formatted for platform
- **Platforms**: X/Twitter, LinkedIn, Shopify, email
- **Style guide**: Punchy, no fluff, Tony's voice unless otherwise specified

---

### 5. DataAgent
- **Model**: Claude (haiku) + local processing
- **Role**: Parse CSVs, analyse metrics, generate reports, track KPIs
- **Triggers**: "analyse this data", "what are the trends", "summarise these numbers"
- **Output**: Tables, charts (mermaid), insight bullets
- **Tools**: python_exec, file_read, csv_parse

---

### 6. OutreachAgent
- **Model**: Claude (sonnet)
- **Role**: Draft and schedule outreach — cold emails, DMs, partnership proposals
- **Triggers**: "reach out to X", "draft a pitch for Y"
- **Output**: Message drafts → Tony approval → send
- **Rule**: NEVER sends without Tony confirmation. Always drafts first.
- **Tools**: gmail_draft (gws skill), telegram_notify

---

### 7. MonitorAgent
- **Model**: Lightweight (haiku or local)
- **Role**: Watch jobs, cron tasks, system health, API quotas
- **Triggers**: Scheduled (every 15min) or on-demand
- **Output**: Status pings to Tony via Telegram
- **Escalation**: Immediate alert if job fails, quota > 80%, anomaly detected
- **Tools**: bash, system_check, telegram_notify

---

## Business Venture Agents

> Each business spun up via OpenClaw gets its own agent config.
> See docs/BUILD_ARSENAL.md for the full Greg Isenberg SaaS playbook.

### Template: [BusinessName]Agent
- **Model**: [assign based on task complexity]
- **Role**: [specific to business function]
- **Revenue target**: [set per venture]
- **Reporting**: Weekly P&L summary → Rae → Tony via Telegram

---

## Agent Communication Protocol

```
Task flow:
Tony → Telegram → Rae → [routes to agent] → [executes] → [returns result] → Rae → Telegram → Tony

Escalation flow:
Agent → Rae (immediate) → Telegram alert → Tony
```

### Message format (agent → Rae):
```json
{
  "agent": "ResearchAgent",
  "task_id": "uuid",
  "status": "complete|running|failed",
  "result": "...",
  "confidence": 0.92,
  "cost_tokens": 4200,
  "escalate": false
}
```

---

## Model Assignment Logic

| Complexity | Speed needed | Model |
|---|---|---|
| High | No | claude-3-5-sonnet |
| High | Yes | claude-3-5-sonnet (streaming) |
| Medium | Yes | claude-3-5-haiku |
| Long context | No | kimi moonshot-v1-128k |
| Local/private | Any | ollama (llama3.2 / phi3) |

---

## Version History

| Version | Date | Change |
|---|---|---|
| 0.1 | 2025 | Initial agent registry — 7 core agents |
