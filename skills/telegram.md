# skills/telegram.md — Telegram Integration

> Rae's primary communication channel with Tony.
> All alerts, reports, task completions, and commands flow through Telegram.

**Priority**: CRITICAL — set this up first before anything else

---

## Overview

Telegram serves as the human-AI interface for the entire OpenClaw stack:
- Tony sends commands → Rae receives and routes
- Rae sends updates → Tony gets notified in real-time
- MonitorAgent sends health alerts → Tony's phone buzzes
- Task completions, errors, budget alerts — all via Telegram

---

## Step 1: Create the Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Follow prompts:
   - Bot name: `Rae` (or `RaeAI` / `k3ss-rae`)
   - Bot username: must end in `bot` e.g. `k3ss_rae_bot`
4. BotFather gives you a **token** — looks like: `7123456789:AAFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
5. **Save this token to 1Password immediately**:
   ```bash
   op item create \
     --category="API Credential" \
     --title="Telegram Bot Token" \
     --vault="OpenClaw" \
     credential="YOUR_TOKEN_HERE"
   ```

---

## Step 2: Get Your Chat ID

You need your personal Telegram chat ID so Rae only talks to Tony:

1. Start a conversation with your new bot (search for it, press Start)
2. Send it any message (e.g. `/start`)
3. Open this URL in your browser (replace TOKEN):
   ```
   https://api.telegram.org/botTOKEN/getUpdates
   ```
4. Find `"chat":{"id":XXXXXXXX}` in the response
5. That number is your **chat_id** — save to 1Password:
   ```bash
   op item create \
     --category="API Credential" \
     --title="Telegram Chat ID" \
     --vault="OpenClaw" \
     credential="YOUR_CHAT_ID_HERE"
   ```

---

## Step 3: Test the Connection

```bash
# Quick test - send a message via curl
BOT_TOKEN=$(op read "op://OpenClaw/Telegram Bot Token/credential")
CHAT_ID=$(op read "op://OpenClaw/Telegram Chat ID/credential")

curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": '"${CHAT_ID}"', "text": "Rae is online. Ready."}'  
```

If you get a message on your phone — it's working.

---

## Step 4: OpenClaw Integration

```bash
# Store credentials in OpenClaw environment
export TELEGRAM_BOT_TOKEN=$(op read "op://OpenClaw/Telegram Bot Token/credential")
export TELEGRAM_CHAT_ID=$(op read "op://OpenClaw/Telegram Chat ID/credential")

# Add to your shell profile for persistence
echo 'export TELEGRAM_BOT_TOKEN=$(op read "op://OpenClaw/Telegram Bot Token/credential")' >> ~/.zshrc
echo 'export TELEGRAM_CHAT_ID=$(op read "op://OpenClaw/Telegram Chat ID/credential")' >> ~/.zshrc
```

---

## Python Integration

```python
# telegram_client.py - Rae's Telegram interface
import os
import requests

class TelegramClient:
    def __init__(self):
        self.token = os.environ['TELEGRAM_BOT_TOKEN']
        self.chat_id = os.environ['TELEGRAM_CHAT_ID']
        self.base_url = f'https://api.telegram.org/bot{self.token}'
    
    def send(self, message: str, parse_mode: str = 'Markdown') -> bool:
        """Send message to Tony."""
        response = requests.post(
            f'{self.base_url}/sendMessage',
            json={
                'chat_id': self.chat_id,
                'text': message,
                'parse_mode': parse_mode
            }
        )
        return response.ok
    
    def alert(self, title: str, message: str, level: str = 'INFO') -> bool:
        """Send formatted alert."""
        emoji_map = {'INFO': 'ℹ️', 'SUCCESS': '✅', 'WARNING': '⚠️', 'ERROR': '🔴'}
        emoji = emoji_map.get(level, 'ℹ️')
        formatted = f"{emoji} *{title}*\n{message}"
        return self.send(formatted)
    
    def task_complete(self, task: str, result: str, agent: str) -> bool:
        """Notify task completion."""
        msg = f"✅ *Task Complete*\n*Agent*: {agent}\n*Task*: {task}\n*Result*: {result}"
        return self.send(msg)
    
    def escalate(self, issue: str, agent: str, severity: str = 'HIGH') -> bool:
        """Escalate issue to Tony immediately."""
        msg = f"🔴 *ESCALATION REQUIRED*\n*Severity*: {severity}\n*Agent*: {agent}\n*Issue*: {issue}\n\nAction required from Tony."
        return self.send(msg)
    
    def get_updates(self, offset: int = None) -> list:
        """Poll for incoming messages from Tony."""
        params = {'timeout': 30}
        if offset:
            params['offset'] = offset
        response = requests.get(f'{self.base_url}/getUpdates', params=params)
        if response.ok:
            return response.json().get('result', [])
        return []


# Usage example:
# client = TelegramClient()
# client.send("Rae is online. Ready for commands.")
# client.alert("Budget Warning", "Kimi token usage at 78% of daily limit", "WARNING")
# client.escalate("API key rotation required", "MonitorAgent")
```

---

## Message Format Standards

### Rae → Tony (outbound)
```
[EMOJI] *TITLE*
Agent: [agent_name]
Task: [task_description]
Result: [outcome]
Time: [timestamp]
```

### Notification Types
| Type | Emoji | When |
|---|---|---|
| Task complete | ✅ | Agent finishes job |
| Escalation | 🔴 | Needs Tony input |
| Warning | ⚠️ | Non-critical issue |
| Budget alert | 💰 | Token/cost threshold hit |
| System health | 🖥️ | MonitorAgent check-in |
| Job started | ⏳ | Long task beginning |
| Rae online | 🤖 | System startup |

### Tony → Rae (inbound commands)
Rae listens for these command patterns:
```
/status          - System health report
/agents          - List running agents
/stop [agent]    - Stop specific agent
/task [desc]     - New task for Rae to route
/research [topic] - ResearchAgent quick trigger
/budget          - Show token/cost usage
/help            - Command list
```

---

## Security

- Bot token stored in 1Password ONLY — never in .env files, config files, or git
- Chat ID validation: Rae only responds to messages from Tony's chat_id
- Reject all messages from unknown chat IDs
- Rate limit: max 30 messages/second per Telegram API limits

```python
# Security check in message handler
def handle_message(update):
    chat_id = update['message']['chat']['id']
    authorized_id = int(os.environ['TELEGRAM_CHAT_ID'])
    
    if chat_id != authorized_id:
        # Unknown sender - ignore silently
        return
    
    # Process command...
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| No message received | Check BOT_TOKEN is correct via `/getMe` endpoint |
| 400 Bad Request | Check CHAT_ID format (should be integer) |
| 403 Forbidden | Bot blocked by user — restart conversation in Telegram |
| getUpdates empty | You must message the bot first to initiate |
| Token expired | Create new bot via BotFather, update 1Password |

---

## Status

- [ ] Bot created via BotFather
- [ ] Token saved to 1Password
- [ ] Chat ID obtained and saved
- [ ] Test message sent successfully
- [ ] Environment variables set in ~/.zshrc
- [ ] telegram_client.py placed in project root
- [ ] Rae configured to use TelegramClient
- [ ] MonitorAgent wired up for health alerts

---

## Version History

| Version | Date | Change |
|---|---|---|
| 0.1 | 2025 | Initial Telegram skill setup guide |
