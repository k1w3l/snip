#!/usr/bin/env bash
# Bootstrap mínimo Ubuntu: update, upgrade e vim.
# Uso one-liner (rede local / Gitea) — sudo no bash, não no curl:
#   curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | sudo bash

# curl|bash: $0 vira /usr/bin/bash (binário). Reexecuta o restante do stdin como root.
if [[ "$(id -u)" -ne 0 ]]; then
  src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" && "$src" == *.sh ]]; then
    exec sudo -E bash "$src" "$@"
  fi
  exec sudo -E bash -s -- "$@"
fi

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
fi

echo "==> ${PRETTY_NAME:-Linux} ($(uname -m))"
echo "==> apt update"
apt-get update -y

echo "==> apt upgrade"
apt-get upgrade -y

echo "==> Instalando vim"
apt-get install -y vim

echo
echo "==> Bootstrap concluído (update + upgrade + vim)."
echo "    Extras: curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash"
echo "    Docker: curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | sudo bash"
