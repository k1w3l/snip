#!/usr/bin/env bash
# Bootstrap mínimo Ubuntu: update, upgrade, vim e curl.
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/bootstrap.sh | sudo bash

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

echo "==> Instalando vim e curl"
apt-get install -y vim curl ca-certificates

echo
echo "==> Bootstrap concluído (update + upgrade + vim + curl)."
echo "    Extras: curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash"
echo "    Docker: curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-docker.sh | sudo bash"
