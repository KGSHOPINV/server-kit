#!/bin/bash
# ============================================================
# server-watch.sh — the watcher (runs all alert checks)
# Install to cron: */5 * * * * /usr/local/bin/server-watch
# Or as a systemd timer
# ============================================================

ALERTS_DIR="$(cd "$(dirname "$0")" && pwd)"

run_check() {
  local script="$ALERTS_DIR/$1"
  [ -x "$script" ] && bash "$script" 2>/dev/null &
}

run_check "alert-disk.sh"
run_check "alert-network.sh"
run_check "alert-services.sh"
run_check "alert-load.sh"

wait
