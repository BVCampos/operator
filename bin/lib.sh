#!/bin/bash
# lib.sh — shared functions for operator scripts

# Logging — writes to stdout and LOG_FILE (if set)
log() {
  local msg="[$(date '+%H:%M:%S')] $1"
  echo "$msg"
  [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
}

# Initialize logging for a named script
setup_log() {
  local name=$1
  LOG_DIR="$HOME/.operator/logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/${name}-$(date +%Y%m%d-%H%M%S).log"
}

# Default timeout for claude invocations (minutes). Override with --timeout or CLAUDE_TIMEOUT env.
CLAUDE_TIMEOUT=${CLAUDE_TIMEOUT:-30}
SPIN_TIMED_OUT=false

# Spinner that runs in background while a process works
# Kills the process if CLAUDE_TIMEOUT is exceeded.
spin() {
  local pid=$1
  local label=$2
  local timeout_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false

  # Non-TTY fallback (log files, pipes)
  if [ ! -t 1 ]; then
    echo "  $label..."
    local start=$SECONDS
    while kill -0 "$pid" 2>/dev/null; do
      if (( SECONDS - start >= timeout_secs )); then
        kill "$pid" 2>/dev/null || true
        SPIN_TIMED_OUT=true
        echo "  ✗ $label timed out after ${CLAUDE_TIMEOUT}m — process killed"
        return
      fi
      sleep 1
    done
    echo "  ✓ $label completed"
    return
  fi

  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local start=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    local elapsed=$(( SECONDS - start ))
    if (( elapsed >= timeout_secs )); then
      kill "$pid" 2>/dev/null || true
      SPIN_TIMED_OUT=true
      printf "\033[2K\r  ✗ %s timed out after %dm — process killed\n" "$label" "$CLAUDE_TIMEOUT"
      return
    fi
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    printf "\033[2K\r  %s %s (%dm%02ds)" "${chars:i++%${#chars}:1}" "$label" "$mins" "$secs"
    sleep 0.1
  done
  local total=$(( SECONDS - start ))
  local mins=$(( total / 60 ))
  local secs=$(( total % 60 ))
  printf "\033[2K\r  ✓ %s completed (%dm%02ds)\n" "$label" "$mins" "$secs"
}

# Combined spinner for multiple parallel processes.
# Usage: spin_all "label" PID1 PID2 ...
# Kills all remaining processes if CLAUDE_TIMEOUT is exceeded.
spin_all() {
  local label=$1
  shift
  local timeout_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false

  if [ ! -t 1 ]; then
    echo "  $label — $# sections..."
    local start=$SECONDS
    while true; do
      local running=0
      for pid in "$@"; do
        kill -0 "$pid" 2>/dev/null && running=$((running + 1))
      done
      [ $running -eq 0 ] && break
      if (( SECONDS - start >= timeout_secs )); then
        for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
        SPIN_TIMED_OUT=true
        echo "  ✗ $label timed out after ${CLAUDE_TIMEOUT}m — killed $running remaining"
        return
      fi
      sleep 1
    done
    echo "  ✓ $label complete"
    return
  fi

  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local start=$SECONDS
  local total=$#

  while true; do
    local running=0
    for pid in "$@"; do
      kill -0 "$pid" 2>/dev/null && running=$((running + 1))
    done
    [ $running -eq 0 ] && break

    local elapsed=$(( SECONDS - start ))
    if (( elapsed >= timeout_secs )); then
      for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
      local done_count=$(( total - running ))
      SPIN_TIMED_OUT=true
      printf "\033[2K\r  ✗ %s timed out after %dm — %d/%d complete, killed %d remaining\n" \
        "$label" "$CLAUDE_TIMEOUT" "$done_count" "$total" "$running"
      return
    fi

    local done_count=$(( total - running ))
    printf "\033[2K\r  %s %s — %d/%d sections complete (%dm%02ds)" \
      "${chars:i++%${#chars}:1}" "$label" "$done_count" "$total" \
      "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
    sleep 0.1
  done

  local t=$(( SECONDS - start ))
  printf "\033[2K\r  ✓ All %d sections — %s (%dm%02ds)\n" "$total" "$label" "$(( t / 60 ))" "$(( t % 60 ))"
}
