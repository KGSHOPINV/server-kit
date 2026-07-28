#!/bin/bash
# ============================================================
# 07 - CLAUDE CLI + MCP
# Installs Claude Code CLI and pre-configures MCP servers
# ============================================================

set -e

echo "========================================"
echo "  07 - CLAUDE CLI + MCP SETUP"
echo "========================================"

# --- Install Node.js (required for Claude CLI) ---
if ! command -v node &> /dev/null; then
  echo "Installing Node.js 22 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs
fi

echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"

# --- Install Claude CLI ---
echo ""
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

# --- Setup MCP Config ---
echo ""
echo "Setting up MCP configuration..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Copy MCP config
cp "$SCRIPT_DIR/mcp/mcp-config.json" "$CLAUDE_DIR/mcp-config.json"

echo ""
echo "========================================"
echo "  07 - CLAUDE CLI INSTALLED"
echo ""
echo "  Run 'claude' to start."
echo "  MCP servers configured:"
echo "    - filesystem (read/edit server files)"
echo "    - docker (manage containers)"
echo "    - fetch (HTTP requests)"
echo ""
echo "  To authenticate, run: claude"
echo "  and follow the login prompts."
echo "========================================"
