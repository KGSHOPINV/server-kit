#!/bin/bash
# ============================================================
# notify.sh — core ntfy sender (universal)
# Source this or call directly
# Usage: notify.sh "Title" "Body" [priority] [tags]
# Priority: min low default high urgent
# ============================================================

# Config — override in ~/.server-alerts.conf
NTFY_URL="${NTFY_URL:-http://localhost:8085}"
NTFY_TOPIC="${NTFY_TOPIC:-$(hostname 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo 'server')}"
NTFY_TOKEN="${NTFY_TOKEN:-}"

# Load local config if present
[ -f "$HOME/.server-alerts.conf" ] && source "$HOME/.server-alerts.conf"

notify() {
  local title="${1:-Alert}"
  local body="${2:-No details}"
  local priority="${3:-default}"
  local tags="${4:-server}"

  local url="$NTFY_URL/$NTFY_TOPIC"

  local -a headers=(
    -H "Title: $title"
    -H "Priority: $priority"
    -H "Tags: $tags"
    -H "Content-Type: text/plain"
  )

  [ -n "$NTFY_TOKEN" ] && headers+=(-H "Authorization: Bearer $NTFY_TOKEN")

  curl -s -o /dev/null --max-time 5 \
    "${headers[@]}" \
    -d "$body" \
    "$url" 2>/dev/null

  return $?
}

# Run directly if called as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  notify "$1" "$2" "${3:-default}" "${4:-server}"
fi
