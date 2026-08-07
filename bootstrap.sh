#!/usr/bin/env bash
# Bootstrap mínimo Ubuntu: update, upgrade e vim.
# Uso one-liner (rede local / Gitea):
#   curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

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
echo "    Extras: curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash"
echo "    Docker: curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | bash"
