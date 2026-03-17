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

# Stall timeout (minutes). Kill process if no new output for this long.
# Override with --timeout or CLAUDE_TIMEOUT env.
CLAUDE_TIMEOUT=${CLAUDE_TIMEOUT:-15}
SPIN_TIMED_OUT=false

# Spinner that runs in background while a process works.
# If an output file is provided (3rd arg), monitors it for stalls —
# kills the process if no new output appears for CLAUDE_TIMEOUT minutes.
# Without an output file, runs indefinitely (backwards compat for tsc/tests).
spin() {
  local pid=$1
  local label=$2
  local outfile=${3:-}
  local stall_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false

  local last_size=0
  local last_change=$SECONDS
  local check_counter=0

  # Non-TTY fallback (log files, pipes)
  if [ ! -t 1 ]; then
    echo "  $label..."
    while kill -0 "$pid" 2>/dev/null; do
      if [ -n "$outfile" ]; then
        check_counter=$((check_counter + 1))
        if (( check_counter % 10 == 0 )); then
          local current_size
          current_size=$(wc -c < "$outfile" 2>/dev/null || echo 0)
          current_size=${current_size// /}
          if [ "$current_size" != "$last_size" ]; then
            last_size=$current_size
            last_change=$SECONDS
          elif (( SECONDS - last_change >= stall_secs )); then
            kill "$pid" 2>/dev/null || true
            SPIN_TIMED_OUT=true
            echo "  ✗ $label no output for ${CLAUDE_TIMEOUT}m — process killed"
            return
          fi
        fi
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
    # Check for stall every ~5 seconds
    if [ -n "$outfile" ]; then
      check_counter=$((check_counter + 1))
      if (( check_counter % 50 == 0 )); then
        local current_size
        current_size=$(wc -c < "$outfile" 2>/dev/null || echo 0)
        current_size=${current_size// /}
        if [ "$current_size" != "$last_size" ]; then
          last_size=$current_size
          last_change=$SECONDS
        elif (( SECONDS - last_change >= stall_secs )); then
          kill "$pid" 2>/dev/null || true
          SPIN_TIMED_OUT=true
          printf "\033[2K\r  ✗ %s no output for %dm — process killed\n" "$label" "$CLAUDE_TIMEOUT"
          return
        fi
      fi
    fi
    local elapsed=$(( SECONDS - start ))
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
# Usage: spin_all "label" work_dir PID1 PID2 ...
# Monitors work_dir for growing output files. Kills all remaining
# processes if combined output stalls for CLAUDE_TIMEOUT minutes.
spin_all() {
  local label=$1
  local work_dir=$2
  shift 2
  local stall_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false

  local last_size=0
  local last_change=$SECONDS
  local check_counter=0

  if [ ! -t 1 ]; then
    echo "  $label — $# sections..."
    while true; do
      local running=0
      for pid in "$@"; do
        kill -0 "$pid" 2>/dev/null && running=$((running + 1))
      done
      [ $running -eq 0 ] && break
      check_counter=$((check_counter + 1))
      if (( check_counter % 10 == 0 )); then
        local current_size
        current_size=$(cat "$work_dir"/output-*.md 2>/dev/null | wc -c || echo 0)
        current_size=${current_size// /}
        if [ "$current_size" != "$last_size" ]; then
          last_size=$current_size
          last_change=$SECONDS
        elif (( SECONDS - last_change >= stall_secs )); then
          for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
          SPIN_TIMED_OUT=true
          echo "  ✗ $label no output for ${CLAUDE_TIMEOUT}m — killed $running remaining"
          return
        fi
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

    # Check for stall every ~5 seconds
    check_counter=$((check_counter + 1))
    if (( check_counter % 50 == 0 )); then
      local current_size
      current_size=$(cat "$work_dir"/output-*.md 2>/dev/null | wc -c || echo 0)
      current_size=${current_size// /}
      if [ "$current_size" != "$last_size" ]; then
        last_size=$current_size
        last_change=$SECONDS
      elif (( SECONDS - last_change >= stall_secs )); then
        for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
        local done_count=$(( total - running ))
        SPIN_TIMED_OUT=true
        printf "\033[2K\r  ✗ %s no output for %dm — %d/%d complete, killed %d remaining\n" \
          "$label" "$CLAUDE_TIMEOUT" "$done_count" "$total" "$running"
        return
      fi
    fi

    local elapsed=$(( SECONDS - start ))
    local done_count=$(( total - running ))
    printf "\033[2K\r  %s %s — %d/%d sections complete (%dm%02ds)" \
      "${chars:i++%${#chars}:1}" "$label" "$done_count" "$total" \
      "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
    sleep 0.1
  done

  local t=$(( SECONDS - start ))
  printf "\033[2K\r  ✓ All %d sections — %s (%dm%02ds)\n" "$total" "$label" "$(( t / 60 ))" "$(( t % 60 ))"
}
