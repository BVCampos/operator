#!/bin/bash
# Install operator — autonomous AI coding loops
# curl -fsSL https://raw.githubusercontent.com/BVCampos/operator/main/install.sh | bash

set -e

OPERATOR_HOME="$HOME/.operator"
REPO_URL="https://github.com/BVCampos/operator.git"

echo ""
echo "  Installing operator — autonomous AI coding loops"
echo ""

# ── Step 1: Check dependencies ──────────────────────────────────────

check_dep() {
  local cmd=$1
  local install_hint=$2
  local required=$3

  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd"
    return 0
  else
    if [ "$required" = "required" ]; then
      echo "  ✗ $cmd (required) — $install_hint"
      return 1
    else
      echo "  - $cmd (optional) — $install_hint"
      return 0
    fi
  fi
}

echo "Checking dependencies..."
MISSING=0

check_dep git       "install from https://git-scm.com"              required || MISSING=1
check_dep claude    "npm install -g @anthropic-ai/claude-code"      required || MISSING=1
check_dep jq        "brew install jq"                                required || MISSING=1
check_dep tmux      "brew install tmux (needed for ralph)"           optional
check_dep gh        "brew install gh (needed for auto PR creation)"  optional

echo ""

if [ "$MISSING" -eq 1 ]; then
  echo "Missing required dependencies. Install them and re-run."
  exit 1
fi

# ── Step 2: Clone or update operator ────────────────────────────────

if [ -d "$OPERATOR_HOME/repo" ]; then
  echo "Updating operator..."
  git -C "$OPERATOR_HOME/repo" pull --quiet 2>/dev/null || true
else
  # If running from a cloned repo already, use that
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  if [ -f "$SCRIPT_DIR/bin/operator" ]; then
    echo "Using local repo at $SCRIPT_DIR"
    mkdir -p "$OPERATOR_HOME"
    # Symlink instead of clone
    ln -sfn "$SCRIPT_DIR" "$OPERATOR_HOME/repo"
  else
    echo "Cloning operator..."
    mkdir -p "$OPERATOR_HOME"
    git clone "$REPO_URL" "$OPERATOR_HOME/repo" 2>/dev/null || {
      echo "Error: Could not clone operator."
      exit 1
    }
  fi
fi

BIN_DIR="$OPERATOR_HOME/repo/bin"

# ── Step 3: Make scripts executable ─────────────────────────────────

chmod +x "$BIN_DIR"/*

# ── Step 4: Initialize state ────────────────────────────────────────

mkdir -p "$OPERATOR_HOME/logs"
if [ ! -f "$OPERATOR_HOME/sessions.json" ]; then
  echo "[]" > "$OPERATOR_HOME/sessions.json"
fi

# ── Step 5: Install /fix-review for Claude Code ─────────────────────

if [ -d "$HOME/.claude" ]; then
  mkdir -p "$HOME/.claude/commands"
  cp "$OPERATOR_HOME/repo/commands/fix-review.md" "$HOME/.claude/commands/fix-review.md"
  echo "Installed /fix-review command for Claude Code"
fi

# ── Step 6: Add to PATH ────────────────────────────────────────────

# Detect shell config
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "$(which bash 2>/dev/null)" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.zshrc"
fi

PATH_LINE="export PATH=\"$BIN_DIR:\$PATH\""

if grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
  echo "PATH already configured"
else
  echo "" >> "$SHELL_RC"
  echo "# operator — autonomous AI coding loops" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
  echo "Added to PATH in $SHELL_RC"
fi

# ── Done ────────────────────────────────────────────────────────────

echo ""
echo "  ✓ operator installed!"
echo ""
echo "  Restart your shell or run: source $SHELL_RC"
echo ""
echo "  Quick start:"
echo "    operator review --max 3       Review + fix your current branch"
echo "    operator audit --max 5        Audit your codebase"
echo "    operator audit full           Audit → verify → fix pipeline"
echo "    operator ralph start --prd tasks/feature.md"
echo ""
echo "    operator --help               Show all commands"
echo ""
