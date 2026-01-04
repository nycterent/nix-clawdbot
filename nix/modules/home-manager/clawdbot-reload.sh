#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: clawdbot-reload [test|prod|both]

Re-render Clawdbot config via Home Manager (no sudo) and restart gateway(s).

Defaults to: test
EOF
}

instance="${1:-test}"

case "$instance" in
  test) labels=("com.steipete.clawdbot.gateway.nix-test") ;;
  prod) labels=("com.steipete.clawdbot.gateway.nix") ;;
  both) labels=("com.steipete.clawdbot.gateway.nix" "com.steipete.clawdbot.gateway.nix-test") ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

if command -v hm-apply >/dev/null 2>&1; then
  hm-apply
elif [[ -n "${CLAWDBOT_RELOAD_HM_CMD:-}" ]]; then
  eval "$CLAWDBOT_RELOAD_HM_CMD"
else
  echo "[clawdbot-reload] no Home Manager command available." >&2
  echo "[clawdbot-reload] install hm-apply or set CLAWDBOT_RELOAD_HM_CMD." >&2
  exit 1
fi

for label in "${labels[@]}"; do
  /bin/launchctl kickstart -k "gui/$UID/$label"
done
