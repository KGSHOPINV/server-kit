#!/bin/bash
# ============================================================
# alert-ai-explain.sh — provider-agnostic AI explanation layer
#
# Priority:
#   1. Ollama (local, free, no key needed)
#   2. Anthropic (ANTHROPIC_API_KEY)
#   3. OpenAI or compatible (OPENAI_API_KEY + optional OPENAI_URL)
#   4. Silent skip — alerts always work without this
#
# Usage: source notify.sh && source alert-ai-explain.sh
#   ai_explain "what just happened on the server"
# ============================================================

[ -f "$HOME/.server-alerts.conf" ] && source "$HOME/.server-alerts.conf"

# Defaults
AI_PROVIDER="${AI_PROVIDER:-auto}"          # auto, ollama, anthropic, openai
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2}"    # small model — fast, good enough
OPENAI_URL="${OPENAI_URL:-https://api.openai.com/v1}"
OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-haiku-4-5-20251001}"

# ── Provider detectors ────────────────────────────────────────

_ollama_available() {
  curl -s --max-time 2 "$OLLAMA_URL/api/tags" >/dev/null 2>&1
}

_pick_provider() {
  [ "$AI_PROVIDER" != "auto" ] && echo "$AI_PROVIDER" && return

  if _ollama_available; then
    echo "ollama"
  elif [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "anthropic"
  elif [ -n "$OPENAI_API_KEY" ]; then
    echo "openai"
  else
    echo "none"
  fi
}

# ── Callers ───────────────────────────────────────────────────

_call_ollama() {
  local prompt="$1"
  curl -s --max-time 15 \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$OLLAMA_MODEL\",\"prompt\":$(printf '%s' "$prompt" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read()))'),\"stream\":false}" \
    "$OLLAMA_URL/api/generate" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))" 2>/dev/null
}

_call_anthropic() {
  local prompt="$1"
  curl -s --max-time 15 \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{\"model\":\"$ANTHROPIC_MODEL\",\"max_tokens\":150,\"messages\":[{\"role\":\"user\",\"content\":$(printf '%s' "$prompt" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read()))')}]}" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d['content'][0]['text'])" 2>/dev/null
}

_call_openai() {
  local prompt="$1"
  curl -s --max-time 15 \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$OPENAI_MODEL\",\"max_tokens\":150,\"messages\":[{\"role\":\"user\",\"content\":$(printf '%s' "$prompt" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read()))')}]}" \
    "$OPENAI_URL/chat/completions" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" 2>/dev/null
}

# ── Main function ─────────────────────────────────────────────

ai_explain() {
  local context="$1"
  local PROVIDER
  PROVIDER=$(_pick_provider)

  [ "$PROVIDER" = "none" ] && return 0

  local HOST
  HOST=$(hostname 2>/dev/null || echo "server")

  # Quick state snapshot (using /proc — works on any Linux)
  local STATE="Host: $HOST"
  [ -f /proc/loadavg ] && STATE+=", Load: $(awk '{print $1}' /proc/loadavg)"
  [ -f /proc/meminfo ] && STATE+=", RAM free: $(awk '/MemAvailable/{printf "%.0fMB", $2/1024}' /proc/meminfo)"
  command -v docker >/dev/null 2>&1 && STATE+=", Containers: $(docker ps -q 2>/dev/null | wc -l) running"

  local PROMPT="You are a server assistant. State: $STATE. Alert: $context. Give 2-3 sentences plain-English: what's likely happening and one specific next step. No markdown, no jargon."

  local RESPONSE=""
  case "$PROVIDER" in
    ollama)     RESPONSE=$(_call_ollama "$PROMPT") ;;
    anthropic)  RESPONSE=$(_call_anthropic "$PROMPT") ;;
    openai)     RESPONSE=$(_call_openai "$PROMPT") ;;
  esac

  [ -z "$RESPONSE" ] && return 0

  notify \
    "🤖 AI note ($PROVIDER)" \
    "$RESPONSE" \
    "min" \
    "robot"
}
