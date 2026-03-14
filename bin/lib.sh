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

# Spinner that runs in background while a process works
spin() {
  local pid=$1
  local label=$2
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local start=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    local elapsed=$(( SECONDS - start ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    printf "\r  %s %s (%dm%02ds)" "${chars:i++%${#chars}:1}" "$label" "$mins" "$secs"
    sleep 0.1
  done
  local total=$(( SECONDS - start ))
  local mins=$(( total / 60 ))
  local secs=$(( total % 60 ))
  printf "\r  ✓ %s completed (%dm%02ds)\n" "$label" "$mins" "$secs"
}
