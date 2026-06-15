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

setup_ssh_access() {
  local state_home="${CODEX_HOME:-/root/.codex}"
  local ssh_home="${state_home}/ssh"
  local host_key_dir="${ssh_home}/host_keys"
  local authorized_keys="${ssh_home}/authorized_keys"
  local authorized_keys_file="${SSH_AUTHORIZED_KEYS_FILE:-/workspace/.container/authorized_keys}"

  mkdir -p /run/sshd "${host_key_dir}" "${ssh_home}"

  if [[ ! -f "${host_key_dir}/ssh_host_ed25519_key" ]]; then
    ssh-keygen -q -t ed25519 -N "" -f "${host_key_dir}/ssh_host_ed25519_key"
  fi

  if [[ ! -f "${host_key_dir}/ssh_host_rsa_key" ]]; then
    ssh-keygen -q -t rsa -b 4096 -N "" -f "${host_key_dir}/ssh_host_rsa_key"
  fi

  ln -sf "${host_key_dir}/ssh_host_ed25519_key" /etc/ssh/ssh_host_ed25519_key
  ln -sf "${host_key_dir}/ssh_host_ed25519_key.pub" /etc/ssh/ssh_host_ed25519_key.pub
  ln -sf "${host_key_dir}/ssh_host_rsa_key" /etc/ssh/ssh_host_rsa_key
  ln -sf "${host_key_dir}/ssh_host_rsa_key.pub" /etc/ssh/ssh_host_rsa_key.pub

  if [[ -n "${SSH_AUTHORIZED_KEYS:-}" ]]; then
    printf '%s\n' "${SSH_AUTHORIZED_KEYS}" > "${authorized_keys}"
  elif [[ -f "${authorized_keys_file}" ]]; then
    cp "${authorized_keys_file}" "${authorized_keys}"
  elif [[ ! -f "${authorized_keys}" ]]; then
    touch "${authorized_keys}"
    echo "No SSH authorized keys configured. Add keys to ${authorized_keys} or ${authorized_keys_file}."
  fi

  chmod 700 "${ssh_home}" "${host_key_dir}"
  chmod 600 "${authorized_keys}" "${host_key_dir}"/ssh_host_*_key
  chmod 644 "${host_key_dir}"/ssh_host_*_key.pub

  /usr/sbin/sshd -t
}

start_sshd() {
  if [[ "${START_SSHD:-1}" != "1" ]]; then
    return
  fi

  setup_ssh_access
  /usr/sbin/sshd -D -e &
}

mkdir -p "${CODEX_HOME:-/root/.codex}" /workspace /root/.cache

seed_runtime
install_workspace_apt_packages
start_sshd

exec "$@"
