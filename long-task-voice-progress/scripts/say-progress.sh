#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: say-progress.sh <message>" >&2
  exit 1
fi

message="$*"
voice="${SAY_PROGRESS_VOICE:-Samantha}"
rate="${SAY_PROGRESS_RATE:-190}"
mute="${SAY_PROGRESS_MUTE:-0}"

echo "[progress] ${message}"

if [ "${mute}" = "1" ]; then
  exit 0
fi

speak() {
  if command -v say >/dev/null 2>&1; then
    # macOS
    local args=(-v "${voice}")
    if [[ "${rate}" =~ ^[0-9]+$ ]]; then
      args+=(-r "${rate}")
    fi
    say "${args[@]}" "${message}" &
  elif command -v spd-say >/dev/null 2>&1; then
    # Linux (speech-dispatcher)
    spd-say -- "${message}" &
  elif command -v espeak >/dev/null 2>&1; then
    # Linux (espeak)
    local args=()
    if [[ "${rate}" =~ ^[0-9]+$ ]]; then
      args+=(-s "${rate}")
    fi
    espeak "${args[@]}" "${message}" &
  else
    return 0
  fi
  disown 2>/dev/null || true
}

if ! speak; then
  echo "[progress] Audio delivery failed; continuing without speech." >&2
fi
