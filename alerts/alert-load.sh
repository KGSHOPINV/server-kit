#!/bin/bash
# alert-load.sh — CPU/RAM high usage alert
# Uses /proc (Linux universal) — no distro-specific commands

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

LOAD_WARN="${LOAD_WARN:-80}"    # CPU % threshold
MEM_WARN="${MEM_WARN:-90}"     # RAM % threshold
[ -f "$HOME/.server-alerts.conf" ] && source "$HOME/.server-alerts.conf"

HOST=$(hostname -s 2>/dev/null || echo "server")
STATE_FILE="/tmp/.load-alert-state"

# CPU load — from /proc/loadavg (universally available on Linux)
LOAD_1MIN=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
CPUS=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
# Load percentage = (load_1min / cpus) * 100
CPU_PCT=$(awk "BEGIN {printf \"%d\", ($LOAD_1MIN / $CPUS) * 100}")

# RAM — from /proc/meminfo (universally available)
MEM_TOTAL=$(awk '/MemTotal/  {print $2}' /proc/meminfo 2>/dev/null || echo "1")
MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo "1")
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_PCT=$(awk "BEGIN {printf \"%d\", ($MEM_USED / $MEM_TOTAL) * 100}")

MEM_USED_H=$(awk "BEGIN {printf \"%.1fG\", $MEM_USED / 1048576}")
MEM_TOTAL_H=$(awk "BEGIN {printf \"%.1fG\", $MEM_TOTAL / 1048576}")

PROBLEMS=()
PRIORITY="default"

[ "$CPU_PCT" -ge "$LOAD_WARN" ] 2>/dev/null && \
  PROBLEMS+=("CPU load: ${CPU_PCT}% (load avg ${LOAD_1MIN} across ${CPUS} cores)") && \
  PRIORITY="high"

[ "$MEM_PCT" -ge "$MEM_WARN" ] 2>/dev/null && \
  PROBLEMS+=("RAM: ${MEM_PCT}% used (${MEM_USED_H} / ${MEM_TOTAL_H})") && \
  PRIORITY="high"

[ ${#PROBLEMS[@]} -eq 0 ] && exit 0

# Debounce — only alert if sustained (state unchanged for >1 cycle)
CURR_STATE="${CPU_PCT}:${MEM_PCT}"
PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "")

if [ "$CURR_STATE" != "$PREV_STATE" ]; then
  echo "$CURR_STATE" > "$STATE_FILE"
  exit 0  # First detection — wait for next cycle to confirm
fi

# Confirmed sustained — alert
TOP_PROCS=""
if command -v ps >/dev/null 2>&1; then
  TOP_PROCS=$(ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=6 {printf "  %-20s CPU:%-5s MEM:%s\n", $11, $3, $4}')
fi

notify \
  "⚠️ High load on $HOST" \
  "$(printf '%s\n' "${PROBLEMS[@]}")

Top processes:
$TOP_PROCS" \
  "$PRIORITY" \
  "warning,fire"
