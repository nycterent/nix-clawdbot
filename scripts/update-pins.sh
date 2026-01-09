#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_file="$repo_root/nix/sources/clawdbot-source.nix"
app_file="$repo_root/nix/packages/clawdbot-app.nix"

latest_sha=$(git ls-remote https://github.com/clawdbot/clawdbot.git refs/heads/main | awk '{print $1}')
if [[ -z "$latest_sha" ]]; then
  echo "Failed to resolve clawdbot main SHA" >&2
  exit 1
fi

source_url="https://github.com/clawdbot/clawdbot/archive/${latest_sha}.tar.gz"
source_hash=$(nix store prefetch-file --json "$source_url" | sed -n 's/.*"hash": "\([^"]*\)".*/\1/p')
if [[ -z "$source_hash" ]]; then
  echo "Failed to resolve source hash" >&2
  exit 1
fi

perl -0pi -e "s/rev = \"[^\"]+\";/rev = \"${latest_sha}\";/" "$source_file"
perl -0pi -e "s/hash = \"[^\"]+\";/hash = \"${source_hash}\";/" "$source_file"

release_tag=$(gh api /repos/clawdbot/clawdbot/releases/latest --jq '.tag_name')
if [[ -z "$release_tag" ]]; then
  echo "Failed to resolve latest release tag" >&2
  exit 1
fi

app_url=$(gh api /repos/clawdbot/clawdbot/releases/latest --jq '.assets[] | select(.name | test("^Clawdis-.*\\.zip$")) | .browser_download_url' | head -n 1)
if [[ -z "$app_url" ]]; then
  echo "Failed to resolve Clawdis app asset URL" >&2
  exit 1
fi

app_hash=$(nix store prefetch-file --json "$app_url" | sed -n 's/.*"hash": "\([^"]*\)".*/\1/p')
if [[ -z "$app_hash" ]]; then
  echo "Failed to resolve app hash" >&2
  exit 1
fi

app_version="${release_tag#v}"
perl -0pi -e "s/version = \"[^\"]+\";/version = \"${app_version}\";/" "$app_file"
perl -0pi -e "s#url = \"[^\"]+\";#url = \"${app_url}\";#" "$app_file"
perl -0pi -e "s/hash = \"[^\"]+\";/hash = \"${app_hash}\";/" "$app_file"

build_log=$(mktemp)
if ! nix build .#clawdbot-gateway --accept-flake-config >"$build_log" 2>&1; then
  pnpm_hash=$(grep -Eo 'got: *sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n 1 | sed 's/.*got: *//')
  if [[ -z "$pnpm_hash" ]]; then
    cat "$build_log" >&2
    rm -f "$build_log"
    exit 1
  fi
  perl -0pi -e "s/pnpmDepsHash = \"[^\"]+\";/pnpmDepsHash = \"${pnpm_hash}\";/" "$source_file"
  nix build .#clawdbot-gateway --accept-flake-config
fi
rm -f "$build_log"

nix build .#clawdbot-app --accept-flake-config

if git diff --quiet; then
  echo "No pin changes detected."
  exit 0
fi

git add "$source_file" "$app_file"
git commit -F - <<'EOF'
🤖 codex: bump clawdbot pins (no-issue)

What:
- pin clawdbot source to latest upstream main
- refresh macOS app pin to latest release asset
- update source and app hashes

Why:
- keep nix-clawdbot on latest upstream for yolo mode

Tests:
- nix build .#clawdbot-gateway --accept-flake-config
- nix build .#clawdbot-app --accept-flake-config
EOF

git push origin HEAD:main
