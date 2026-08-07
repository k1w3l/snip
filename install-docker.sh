#!/usr/bin/env bash
# Instala Docker Engine + Compose no Ubuntu (repositório oficial).
# Uso one-liner (rede local / Gitea) — sudo no bash, não no curl:
#   curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | sudo bash

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
else
  echo "erro: /etc/os-release não encontrado (só Ubuntu/Debian suportados)" >&2
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "erro: este script é para Ubuntu (detectado: ${ID:-desconhecido})" >&2
  exit 1
fi

CODENAME="${VERSION_CODENAME:-}"
if [[ -z "$CODENAME" ]]; then
  echo "erro: não foi possível detectar VERSION_CODENAME" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"

echo "==> Ubuntu ${VERSION_ID:-?} (${CODENAME}), arch=${ARCH}"
echo "==> apt update / upgrade"
apt-get update -y
apt-get upgrade -y

echo "==> Dependências"
apt-get install -y ca-certificates curl gnupg

echo "==> Keyring e repositório Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

echo "==> Instalar Docker Engine + plugins"
apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable --now docker

echo "==> Versões instaladas"
docker --version
docker compose version

INVOKING_USER="${SUDO_USER:-}"
if [[ -n "$INVOKING_USER" && "$INVOKING_USER" != "root" ]]; then
  usermod -aG docker "$INVOKING_USER"
  echo "==> Usuário '${INVOKING_USER}' adicionado ao grupo docker (faça logout/login ou: newgrp docker)"
fi

echo "==> Docker instalado com sucesso."
