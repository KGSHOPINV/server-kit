#!/bin/bash
# ============================================================
# alert-ai-explain.sh — AI explanation layer (optional)
# Called by alert scripts when ANTHROPIC_API_KEY is set.
# Sends a Claude-generated explanation alongside the raw alert.
#
# Usage: source notify.sh && source this file
#   ai_explain "context about what just happened"
#
# If no API key: exits silently. Never blocks the main alert.
# ============================================================

[ -f "$HOME/.server-alerts.conf" ] && source "$HOME/.server-alerts.conf"

ai_explain() {
  local context="$1"

  # No key = silent skip (AI is optional)
  [ -z "$ANTHROPIC_API_KEY" ] && return 0

  local HOST=$(hostname -s 2>/dev/null || echo "server")

  # Gather quick state snapshot
  local STATE=""
  command -v ip >/dev/null 2>&1 && \
    STATE+="Network: $(ip route get 1.1.1.1 2>/dev/null | awk '/src/{print $7}' | head -1)\n"
  [ -f /proc/loadavg ] && \
    STATE+="Load: $(cat /proc/loadavg | awk '{print $1,$2,$3}')\n"
  [ -f /proc/meminfo ] && \
    STATE+="RAM free: $(awk '/MemAvailable/{print $2}' /proc/meminfo)kB\n"
  command -v docker >/dev/null 2>&1 && \
    STATE+="Containers: $(docker ps -q 2>/dev/null | wc -l) running\n"

  local PROMPT="You are a server assistant for $HOST (Linux server).

Current state:
$(echo -e "$STATE")

Alert context:
$context

Give a 2-3 sentence plain-English explanation of what is likely happening and one specific next step. No markdown, no jargon. Be direct."

  # Call Claude API (model: haiku for speed/cost on alerts)
  local RESPONSE
  RESPONSE=$(curl -s --max-time 10 \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{
      \"model\": \"claude-haiku-4-5-20251001\",
      \"max_tokens\": 150,
      \"messages\": [{\"role\": \"user\", \"content\": $(printf '%s' "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}]
    }" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d['content'][0]['text'])" 2>/dev/null)

  [ -z "$RESPONSE" ] && return 0

  # Send as a follow-up notification (low priority — it's just context)
  notify \
    "🤖 AI note on $HOST" \
    "$RESPONSE" \
    "min" \
    "robot"
}
