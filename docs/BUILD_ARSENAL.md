# BUILD_ARSENAL.md — OpenClaw Resource Library

> Master reference document compiled from 11 research bookmarks.
> Everything we know that's worth knowing for building this stack.

**Hardware target**: M4 Mac Mini 16GB · **OS**: macOS arm64 · **Owner**: Tony (k3ss-official)

---

## Quick Reference: Must-Haves

| Priority | Tool/Concept | Source | Action |
|---|---|---|---|
| 🔴 CRITICAL | Telegram integration | Sandra Leow / Community | Install bot, see skills/telegram.md |
| 🔴 CRITICAL | Google Workspace CLI | GWS repo | `oc skills install google-workspace` |
| 🔴 CRITICAL | 1Password CLI | Existing sub | `brew install 1password-cli` |
| 🟠 HIGH | Scrapling | D4Vinci/GitHub | `pip install scrapling` |
| 🟠 HIGH | 9-Step Hardening | moritzkremb | Apply to SOUL.md - done |
| 🟠 HIGH | Token optimisation | slash1sol | Apply to all agent prompts |
| 🟡 MEDIUM | Jacob Klug 9-agent stack | X thread | Template for business agents |
| 🟡 MEDIUM | Greg Isenberg playbook | X thread | Business launch template |
| 🟡 MEDIUM | Sandra Leow 10-agent setup | Article | Agent prompt templates |
| ⚪ LOW | Awesome Claws projects | GitHub | Browse when adding features |

---

## Source 1: @slash1sol — Token Saving Tips

**Type**: X post · **Rating**: Must-apply

### Key Techniques
1. **Use XML tags** to structure prompts — reduces ambiguity, saves tokens on re-tries
   ```
   <task>...</task>
   <context>...</context>
   <output_format>...</output_format>
   ```
2. **Front-load instructions** — put the most important directive first
3. **Use `continue` patterns** — don't re-explain context on continuation calls
4. **Compress context** — summarise long chats before appending to system prompt
5. **Reuse prompts** — template reuse slashes per-task token cost dramatically
6. **Avoid filler phrases** — "Please", "Could you", "I need you to" all cost tokens for zero gain
7. **Chunk large tasks** — smaller atomic tasks are cheaper than one mega-prompt

### Applied To: All agent system prompts in this repo

---

## Source 2: @moritzkremb — 9-Step OpenClaw Hardening

**Type**: Article · **Rating**: Must-apply · **Applied to**: workspace/SOUL.md

### The 9 Steps
1. **Define the agent's role precisely** — name, function, what it controls
2. **Set hard limits** — what it can NEVER do (delete, send, pay)
3. **Define escalation triggers** — when to stop and ping the human
4. **Specify output format** — structured responses only (JSON, markdown)
5. **Set confidence thresholds** — below X% confidence = ask, don't assume
6. **Memory hygiene** — what persists, what gets cleared
7. **Tool access control** — each agent gets minimum necessary tools
8. **Audit trail** — all actions logged with timestamp, tool used, result
9. **Version your prompts** — treat system prompts like code (see Version History in each .md)

### Status: Applied throughout this repo's workspace/ files

---

## Source 3: @ashen_one — Video Walkthrough

**Type**: YouTube/X video · **Rating**: Good reference

### Key Timestamps & Concepts
- OpenClaw setup flow: install → configure → skills → agents
- Emphasises testing each agent in isolation before connecting to network
- Shows live Telegram bot setup for notifications
- Demonstrates skill install workflow: `oc skills list`, `oc skills install [name]`

### Takeaway: Test-before-connect methodology — spin up one agent, verify it works, then add next

---

## Source 4: Scrapling — Anti-Bot Python Scraper

**Type**: GitHub library · **Rating**: Must-install · **Source**: github.com/D4Vinci/Scrapling

### What It Is
- Python scraping library with anti-detection built in
- Mimics real browser behaviour — bypasses Cloudflare, bot detection
- Drop-in replacement for requests/BeautifulSoup on tough sites
- Playwright integration for JS-heavy sites

### Install
```bash
pip install scrapling
```

### Usage Pattern
```python
from scrapling import Fetcher
fetcher = Fetcher(auto_match=True)
page = fetcher.get('https://example.com')
print(page.find('h1').text)
```

### Use In Stack: ResearchAgent — when read_url fails on protected sites

---

## Source 5: Jacob Klug — 9-Agent Company Stack

**Type**: X thread · **Rating**: High value · **Use**: Template for business ventures

### The 9-Agent Company
Jacob runs a company with 9 specialist agents, each with a single job:

1. **CEO Agent** — strategy, prioritisation, quarterly goals (= Rae in our stack)
2. **Research Agent** — market research, competitive intel (= ResearchAgent)
3. **Writer Agent** — all written content, blogs, emails (= ContentAgent)
4. **Developer Agent** — code, debugging, shipping (= CodeAgent)
5. **Data Analyst** — metrics, reports, dashboards (= DataAgent)
6. **Sales Agent** — outreach, follow-ups, CRM (= OutreachAgent)
7. **Support Agent** — customer queries, FAQ responses
8. **Finance Agent** — invoice tracking, expense reports, P&L summaries
9. **Social Agent** — X/LinkedIn scheduling, engagement monitoring

### Key Principle: One agent = one job. Never multi-task a single agent.

### Applied To: AGENTS.md structure + Business venture agent template

---

## Source 6: Awesome Claws — Community Resource List

**Type**: GitHub curated list · **Rating**: Good reference · **Source**: github.com/dex-labs/awesome-claws

### Top Projects Worth Noting

| Project | What It Does | Priority |
|---|---|---|
| claw-memory | Persistent memory plugin | HIGH |
| claw-telegram | Telegram skill | CRITICAL |
| claw-research | Research agent template | HIGH |
| claw-code | Code execution environment | MEDIUM |
| claw-deploy | One-click agent deploy | MEDIUM |
| claw-monitor | System monitoring | MEDIUM |
| claw-web | Web browsing skill | HIGH |
| awesome-mcp-servers | MCP server list | HIGH |

### Takeaway: Check this list before building any new skill from scratch — likely already exists

---

## Source 7: Greg Isenberg — Repeatable SaaS Playbook

**Type**: X thread · **Rating**: Must-read for business ventures

### The Framework: Build → Validate → Scale

**Step 1: Niche Selection** (ResearchAgent job)
- Find a painful, specific problem in a community
- Target: small businesses, professionals, niche hobbyists
- Sweet spot: $50-500/month SaaS, 100-1000 customers = $5k-$500k ARR

**Step 2: Rapid Validation** (1 week)
- Build landing page (ContentAgent writes copy)
- 10 DMs to target users (OutreachAgent drafts)
- Aim for 3 paid pre-orders before building

**Step 3: MVP Build** (2-4 weeks)
- CodeAgent builds v1
- Single core feature only — no extras
- Ship to 3 pre-order customers

**Step 4: Feedback Loop** (ongoing)
- DataAgent tracks metrics
- ContentAgent handles support
- Weekly P&L report via Telegram

**Step 5: Scale**
- ContentAgent does content marketing
- OutreachAgent does partnerships
- MonitorAgent watches churn signals

### Revenue Targets (Tony's stack)
- Business 1: £1k/month by Month 3
- Business 2: £2k/month by Month 6
- Business 3: £5k/month by Month 12

---

## Source 8: Google Workspace CLI — Must-Have

**Type**: MCP skill · **Rating**: MUST INSTALL · **Source**: modelcontextprotocol/servers

### What It Enables
- **Gmail**: Read, draft, send, search, label emails via agent
- **Calendar**: Create events, check availability, book meetings
- **Drive**: Upload, download, search, share files
- **Docs**: Read/write Google Docs
- **Sheets**: Read/write Google Sheets for DataAgent

### Install
```bash
# Via OpenClaw skills
oc skills install google-workspace

# OR via MCP directly
npx @modelcontextprotocol/server-google-workspace
```

### Setup Requirements
1. Google Cloud Console — create project
2. Enable Gmail API, Calendar API, Drive API
3. OAuth 2.0 credentials — download credentials.json
4. Run auth flow once: `oc skills auth google-workspace`
5. Tokens stored via 1Password CLI

### Use In Stack
- OutreachAgent: Draft + send emails (requires Tony confirmation to send)
- DataAgent: Read/write Sheets for reporting
- Rae: Calendar awareness for scheduling tasks

---

## Source 9: Sandra Leow — 10-Agent Setup + Prompts

**Type**: Article · **Rating**: High value for prompt templates

### The 10-Agent Setup
Sandra's production stack (adapted for Tony's build):

1. **Orchestrator** — routes all tasks (= Rae)
2. **Researcher** — web + deep research
3. **Analyst** — data, metrics, financial
4. **Writer** — copy, content, emails
5. **Coder** — scripts, automation, debugging
6. **Reviewer** — QA, fact-check, proofread
7. **Planner** — project management, timelines
8. **Communicator** — outreach, CRM
9. **Monitor** — system health, job status
10. **Learner** — summarises sessions, updates memory

### Key Prompt Patterns

**The "Role + Context + Constraint" format:**
```
You are [ROLE] for [OWNER].
Your context: [CURRENT_TASK_CONTEXT]
Your constraints: [HARD_LIMITS]
Your output format: [FORMAT]
```

**The "Think-Reason-Act" pattern:**
```
1. THINK: Restate the task in your own words
2. REASON: Identify the 3 key steps to complete it
3. ACT: Execute step 1, then 2, then 3
4. VERIFY: Check output meets requirements
5. RESPOND: Return only the final output
```

**The "Confidence Gate" pattern:**
```
Before executing:
- If confidence > 80%: proceed
- If confidence 50-80%: note uncertainty, proceed with caveat
- If confidence < 50%: STOP, ask [OWNER] for clarification
```

### Applied To: SOUL.md operational guidelines

---

## Build Checklist

### Phase 1: Foundation (Do First)
- [x] SOUL.md — Rae's operational guidelines
- [x] IDENTITY.md — Rae's persona and cognitive style
- [x] AGENTS.md — Agent network registry
- [x] MEMORY.md — Memory architecture + Tony profile
- [x] config/models.yml — Model routing
- [x] config/tools.yml — Tool registry
- [x] docs/BUILD_ARSENAL.md — This file
- [ ] skills/telegram.md — Telegram setup

### Phase 2: Skills Install
- [ ] Telegram bot — create bot via @BotFather, get token, store in 1Password
- [ ] Google Workspace — OAuth setup, enable APIs
- [ ] Scrapling — `pip install scrapling`
- [ ] Ollama — `brew install ollama && ollama pull llama3.2:3b`

### Phase 3: First Agent Test
- [ ] Test Rae responds via Telegram
- [ ] Test ResearchAgent with simple research task
- [ ] Test ContentAgent with blog post draft
- [ ] Test MonitorAgent health check

### Phase 4: First Business
- [ ] Run Greg Isenberg playbook for Business 1
- [ ] Create business-specific agent config
- [ ] Set revenue target + tracking

---

## Version History

| Version | Date | Change |
|---|---|---|
| 0.1 | 2025 | Compiled from 9 bookmark sources + 2 research deep-dives |
