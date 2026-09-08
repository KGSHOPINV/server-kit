#!/bin/bash
# ai-models — Manage Ollama AI models
# Installed to /usr/local/bin/ai-models by server-kit

set -euo pipefail

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

show_header() {
  echo ""
  echo "  ╔══════════════════════════════╗"
  echo "  ║     AI Model Manager         ║"
  echo "  ║     Ollama at :11434         ║"
  echo "  ╚══════════════════════════════╝"
  echo ""
}

check_ollama() {
  if ! curl -sf "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "  ✗ Ollama is not running at $OLLAMA_URL"
    echo "  Start it: cd /srv/docker/ollama && docker compose up -d"
    echo ""
    exit 1
  fi
}

list_models() {
  echo "  Installed models:"
  echo ""
  curl -sf "$OLLAMA_URL/api/tags" | python3 -c "
import json, sys
data = json.load(sys.stdin)
models = data.get('models', [])
if not models:
    print('  (no models installed)')
else:
    for m in models:
        name = m.get('name', '')
        size = m.get('size', 0)
        size_gb = round(size / 1e9, 1)
        print(f'  • {name}  ({size_gb} GB)')
"
  echo ""
}

pull_model() {
  echo -n "  Model name to pull (e.g. llama3, mistral, phi3): "
  read -r MODEL
  [ -z "$MODEL" ] && echo "  Cancelled." && return
  echo ""
  echo "  Pulling $MODEL — this may take a while..."
  curl -sf -X POST "$OLLAMA_URL/api/pull" -d "{\"name\":\"$MODEL\"}" | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line)
        status = d.get('status','')
        if status:
            print(f'  {status}', end='\r', flush=True)
    except:
        pass
print()
"
  echo "  Done."
}

delete_model() {
  list_models
  echo -n "  Model name to delete: "
  read -r MODEL
  [ -z "$MODEL" ] && echo "  Cancelled." && return
  curl -sf -X DELETE "$OLLAMA_URL/api/delete" -d "{\"name\":\"$MODEL\"}" > /dev/null
  echo "  Deleted $MODEL."
}

show_header
check_ollama

while true; do
  echo "  1) List installed models"
  echo "  2) Pull a new model"
  echo "  3) Delete a model"
  echo "  0) Back"
  echo ""
  read -rp "  Choice: " CHOICE
  echo ""
  case "$CHOICE" in
    1) list_models ;;
    2) pull_model ;;
    3) delete_model ;;
    0) exit 0 ;;
    *) echo "  Invalid." ;;
  esac
done
