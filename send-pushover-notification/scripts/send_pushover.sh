#!/usr/bin/env bash
set -euo pipefail

title="Codex Task Complete"
message=""
priority="0"
sound=""
device=""
url=""
url_title=""
dry_run=0

usage() {
  cat <<'EOF'
Usage:
  send_pushover.sh --message "<text>" [options]

Required:
  --message <text>       Notification body

Optional:
  --title <text>         Notification title (default: Codex Task Complete)
  --priority <value>     Pushover priority (default: 0)
  --sound <name>         Pushover sound name
  --device <name>        Target device name
  --url <value>          Supplemental URL
  --url-title <text>     Supplemental URL title
  --dry-run              Print payload without sending
  -h, --help             Show this help

Environment:
  PUSHOVER_API_TOKEN     Required app API token
  PUSHOVER_USER_KEY      Required user key
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      title="${2:-}"
      shift 2
      ;;
    --message)
      message="${2:-}"
      shift 2
      ;;
    --priority)
      priority="${2:-}"
      shift 2
      ;;
    --sound)
      sound="${2:-}"
      shift 2
      ;;
    --device)
      device="${2:-}"
      shift 2
      ;;
    --url)
      url="${2:-}"
      shift 2
      ;;
    --url-title)
      url_title="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not installed." >&2
  exit 1
fi

if [[ -z "${PUSHOVER_API_TOKEN:-}" ]]; then
  echo "PUSHOVER_API_TOKEN is not set." >&2
  exit 1
fi

if [[ -z "${PUSHOVER_USER_KEY:-}" ]]; then
  echo "PUSHOVER_USER_KEY is not set." >&2
  exit 1
fi

if [[ -z "${message}" ]]; then
  echo "--message is required." >&2
  usage >&2
  exit 1
fi

if [[ "${dry_run}" -eq 1 ]]; then
  echo "Dry run: skipping request."
  echo "endpoint=https://api.pushover.net/1/messages.json"
  echo "title=${title}"
  echo "message=${message}"
  echo "priority=${priority}"
  if [[ -n "${sound}" ]]; then
    echo "sound=${sound}"
  fi
  if [[ -n "${device}" ]]; then
    echo "device=${device}"
  fi
  if [[ -n "${url}" ]]; then
    echo "url=${url}"
  fi
  if [[ -n "${url_title}" ]]; then
    echo "url_title=${url_title}"
  fi
  exit 0
fi

curl_args=(
  --fail
  --silent
  --show-error
  --request POST
  "https://api.pushover.net/1/messages.json"
  --data-urlencode "token=${PUSHOVER_API_TOKEN}"
  --data-urlencode "user=${PUSHOVER_USER_KEY}"
  --data-urlencode "title=${title}"
  --data-urlencode "message=${message}"
  --data-urlencode "priority=${priority}"
)

if [[ -n "${sound}" ]]; then
  curl_args+=(--data-urlencode "sound=${sound}")
fi
if [[ -n "${device}" ]]; then
  curl_args+=(--data-urlencode "device=${device}")
fi
if [[ -n "${url}" ]]; then
  curl_args+=(--data-urlencode "url=${url}")
fi
if [[ -n "${url_title}" ]]; then
  curl_args+=(--data-urlencode "url_title=${url_title}")
fi

curl "${curl_args[@]}" >/dev/null

echo "Pushover notification sent."
