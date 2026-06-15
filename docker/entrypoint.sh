#!/usr/bin/env bash
set -euo pipefail

seed_runtime() {
  local state_home="${CODEX_HOME:-/root/.codex}"
  local state_runtime="${state_home}/packages/standalone"
  local seed_runtime="/opt/codex-home/packages/standalone"

  if [[ -x "${state_runtime}/current/bin/codex" || -x "${state_runtime}/current/codex" ]]; then
    return
  fi

  if [[ ! -d "${seed_runtime}" ]]; then
    return
  fi

  echo "Seeding CLI runtime into persistent CODEX_HOME"
  mkdir -p "${state_home}/packages"
  rm -rf "${state_runtime}"
  cp -a "${seed_runtime}" "${state_runtime}"
}

install_workspace_apt_packages() {
  local package_file="${WORKSPACE_APT_PACKAGES:-/workspace/.container/apt-packages.txt}"

  if [[ "${INSTALL_WORKSPACE_APT:-0}" != "1" || ! -f "${package_file}" ]]; then
    return
  fi

  local packages=()
  while IFS= read -r package; do
    packages+=("${package}")
  done < <(grep -Ev '^[[:space:]]*(#|$)' "${package_file}" | awk '{print $1}')

  if (( ${#packages[@]} == 0 )); then
    return
  fi

  local missing=()
  local package
  for package in "${packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q "install ok installed"; then
      missing+=("${package}")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    return
  fi

  echo "Installing workspace apt packages: ${missing[*]}"
  apt-get update
  apt-get install -y --no-install-recommends "${missing[@]}"
  rm -rf /var/lib/apt/lists/*
}

mkdir -p "${CODEX_HOME:-/root/.codex}" /workspace /root/.cache

seed_runtime
install_workspace_apt_packages

exec "$@"
