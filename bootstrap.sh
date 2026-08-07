#!/usr/bin/env bash
# Bootstrap base de uma máquina Ubuntu nova (pacotes essenciais + utilitários).
# Uso one-liner (rede local / Gitea):
#   curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash
#
# Flags opcionais:
#   --with-dev     build-essential, python3-venv/pip, cmake, pkg-config
#   --with-ufw     ativa UFW permitindo OpenSSH
#   --skip-upgrade só apt update + install (sem upgrade)
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

WITH_DEV=0
WITH_UFW=0
SKIP_UPGRADE=0

for arg in "$@"; do
  case "$arg" in
    --with-dev) WITH_DEV=1 ;;
    --with-ufw) WITH_UFW=1 ;;
    --skip-upgrade) SKIP_UPGRADE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "flag desconhecida: $arg (use --help)" >&2
      exit 1
      ;;
  esac
done

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
else
  echo "erro: /etc/os-release não encontrado" >&2
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *"debian"* && "${ID:-}" != "debian" ]]; then
  echo "aviso: distro ${ID:-?} — script pensado para Ubuntu/Debian" >&2
fi

echo "==> ${PRETTY_NAME:-Linux} ($(uname -m))"
echo "==> apt update"
apt-get update -y

if [[ "$SKIP_UPGRADE" -eq 0 ]]; then
  echo "==> apt upgrade"
  apt-get upgrade -y
fi

# Base pedida + utilitários úteis em VM/CT/servidor novo
PKGS=(
  vim
  curl
  wget
  ca-certificates
  gnupg
  apt-transport-https
  software-properties-common
  git
  rsync
  unzip
  zip
  tar
  jq
  tree
  htop
  tmux
  ncdu
  lsof
  strace
  dnsutils
  net-tools
  iproute2
  iputils-ping
  traceroute
  mtr-tiny
  openssh-client
  openssh-server
  sudo
  less
  man-db
  bash-completion
  locales
  chrony
  ufw
)

if [[ "$WITH_DEV" -eq 1 ]]; then
  PKGS+=(
    build-essential
    cmake
    pkg-config
    python3
    python3-pip
    python3-venv
  )
fi

echo "==> Instalando pacotes base"
apt-get install -y "${PKGS[@]}"

# Aliases úteis se existirem no Ubuntu (nomes empacotados)
OPTIONAL=(
  ripgrep
  fd-find
  bat
  fzf
)
echo "==> Tentando pacotes opcionais (ignora se indisponíveis)"
for pkg in "${OPTIONAL[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    apt-get install -y "$pkg" || true
  fi
done

# Symlinks amigáveis quando o Ubuntu usa nomes batcat / fdfind
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  update-alternatives --install /usr/local/bin/bat bat "$(command -v batcat)" 10 2>/dev/null || \
    ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

systemctl enable --now ssh chrony 2>/dev/null || true

if [[ "$WITH_UFW" -eq 1 ]]; then
  echo "==> UFW: permitir OpenSSH e ativar"
  ufw allow OpenSSH
  ufw --force enable
  ufw status verbose
else
  echo "==> UFW instalado mas não ativado (passe --with-ufw para ativar com SSH liberado)"
fi

echo "==> Limpeza apt"
apt-get autoremove -y
apt-get clean

echo
echo "==> Bootstrap concluído."
echo "    Próximo (Docker): curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | bash"
if [[ "$WITH_DEV" -eq 0 ]]; then
  echo "    Dev tools: reexecute com --with-dev"
fi
