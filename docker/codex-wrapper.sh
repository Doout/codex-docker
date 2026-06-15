#!/usr/bin/env bash
set -euo pipefail

state_home="${CODEX_HOME:-/root/.codex}"

if [[ -x "${state_home}/packages/standalone/current/bin/codex" ]]; then
  exec "${state_home}/packages/standalone/current/bin/codex" "$@"
fi

if [[ -x "${state_home}/packages/standalone/current/codex" ]]; then
  exec "${state_home}/packages/standalone/current/codex" "$@"
fi

if [[ -x "/opt/codex-home/packages/standalone/current/bin/codex" ]]; then
  exec "/opt/codex-home/packages/standalone/current/bin/codex" "$@"
fi

if [[ -x "/opt/codex-home/packages/standalone/current/codex" ]]; then
  exec "/opt/codex-home/packages/standalone/current/codex" "$@"
fi

echo "No CLI runtime found. Rebuild the image or rerun the standalone installer." >&2
exit 127
