#!/usr/bin/env bash
# Instala htop e/ou btop em RHEL / Rocky / Alma / CentOS Stream / Oracle Linux (via EPEL).
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-btop-rhel.sh | sudo bash
#
# Exemplos:
#   bash install-btop-rhel.sh            # menu interativo
#   bash install-btop-rhel.sh btop
#   bash install-btop-rhel.sh htop
#   bash install-btop-rhel.sh htop btop  # ambos
#   bash install-btop-rhel.sh --both

# curl|bash: $0 vira /usr/bin/bash (binário). Reexecuta o restante do stdin como root.
if [[ "$(id -u)" -ne 0 ]]; then
  src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" && "$src" == *.sh ]]; then
    exec sudo -E bash "$src" "$@"
  fi
  exec sudo -E bash -s -- "$@"
fi

set -euo pipefail

WANT_HTOP=0
WANT_BTOP=0

usage() {
  cat <<'EOF'
install-btop-rhel.sh — instala htop e/ou btop (família Red Hat)

  (sem args)           menu interativo
  htop                 só htop
  btop                 só btop
  htop btop | --both   os dois
  -h, --help           esta ajuda
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --both) WANT_HTOP=1; WANT_BTOP=1 ;;
    htop) WANT_HTOP=1 ;;
    btop) WANT_BTOP=1 ;;
    *)
      echo "arg desconhecido: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

prompt_choice() {
  local ans
  echo
  echo "Escolha o monitor a instalar:"
  echo "  1) htop"
  echo "  2) btop"
  echo "  3) ambos (htop + btop)"
  echo
  if [[ -r /dev/tty ]]; then
    read -r -p "> " ans </dev/tty
  else
    echo "erro: sem TTY para menu — passe a escolha na linha de comando (ex: … | sudo bash -s -- btop)" >&2
    exit 1
  fi
  case "$ans" in
    1|htop) WANT_HTOP=1 ;;
    2|btop) WANT_BTOP=1 ;;
    3|ambos|both|htop+btop|"htop btop") WANT_HTOP=1; WANT_BTOP=1 ;;
    *)
      echo "erro: escolha inválida: $ans (use 1, 2 ou 3)" >&2
      exit 1
      ;;
  esac
}

if [[ "$WANT_HTOP" -eq 0 && "$WANT_BTOP" -eq 0 ]]; then
  prompt_choice
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
else
  echo "erro: /etc/os-release não encontrado" >&2
  exit 1
fi

ID_LIKE_LOWER="$(echo "${ID_LIKE:-} ${ID:-}" | tr '[:upper:]' '[:lower:]')"
is_el_family=0
case " ${ID_LIKE_LOWER} " in
  *" rhel "*|*" centos "*|*" fedora "*) is_el_family=1 ;;
esac
case "${ID:-}" in
  rhel|rocky|almalinux|centos|ol|fedora) is_el_family=1 ;;
esac

if [[ "$is_el_family" -ne 1 ]]; then
  echo "erro: este script é para família Red Hat (detectado: ${ID:-desconhecido})" >&2
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  echo "erro: dnf não encontrado" >&2
  exit 1
fi

MAJOR="$(rpm -E '%{rhel}' 2>/dev/null || true)"
if [[ -z "$MAJOR" || "$MAJOR" == "%{rhel}" ]]; then
  MAJOR="${VERSION_ID%%.*}"
fi

PKGS=()
[[ "$WANT_HTOP" -eq 1 ]] && PKGS+=(htop)
[[ "$WANT_BTOP" -eq 1 ]] && PKGS+=(btop)

echo "==> ${PRETTY_NAME:-Linux} (id=${ID:-?}, el=${MAJOR:-?}, arch=$(uname -m))"
echo "==> Pacotes: ${PKGS[*]}"

# Já instalados? pula o que existir; sai se nada restar.
TO_INSTALL=()
for pkg in "${PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "==> $pkg já instalado: $($pkg --version 2>/dev/null | head -n1 || command -v "$pkg")"
  else
    TO_INSTALL+=("$pkg")
  fi
done

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
  echo "==> Nada a instalar."
  exit 0
fi

# Fedora: htop/btop no repo base — sem EPEL.
if [[ "${ID:-}" == "fedora" ]]; then
  echo "==> dnf install ${TO_INSTALL[*]} (Fedora)"
  dnf install -y "${TO_INSTALL[@]}"
else
  if [[ -z "$MAJOR" ]]; then
    echo "erro: não foi possível detectar a major version EL" >&2
    exit 1
  fi

  echo "==> Dependências (dnf-plugins-core)"
  dnf install -y dnf-plugins-core

  enable_repo() {
    local repo="$1"
    if dnf repolist --all 2>/dev/null | awk '{print $1}' | grep -qx "$repo"; then
      echo "==> Habilitando repositório: $repo"
      dnf config-manager --set-enabled "$repo" || true
    fi
  }

  # CRB (EL9+) / PowerTools (EL8) / CodeReady (RHEL / Oracle).
  case "${ID:-}" in
    rhel)
      if command -v subscription-manager >/dev/null 2>&1; then
        ARCH="$(uname -m)"
        echo "==> Habilitando CodeReady Linux Builder (subscription-manager)"
        subscription-manager repos --enable "codeready-builder-for-rhel-${MAJOR}-${ARCH}-rpms" \
          || subscription-manager repos --enable "codeready-builder-for-rhel-${MAJOR}-$(arch)-rpms" \
          || true
      fi
      while read -r repo; do
        [[ -n "$repo" ]] || continue
        enable_repo "$repo"
      done < <(dnf repolist --all 2>/dev/null | awk '{print $1}' | grep -Ei 'codeready|crb' || true)
      ;;
    ol)
      enable_repo "ol${MAJOR}_codeready_builder"
      if [[ "$MAJOR" -lt 9 ]]; then
        enable_repo "ol${MAJOR}_PowerTools"
      fi
      ;;
    *)
      if [[ "$MAJOR" -ge 9 ]]; then
        enable_repo crb
      else
        enable_repo powertools
        enable_repo PowerTools
      fi
      ;;
  esac

  echo "==> EPEL"
  if rpm -q epel-release >/dev/null 2>&1; then
    echo "    epel-release já instalado"
  elif [[ "${ID:-}" == "rhel" ]]; then
    dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR}.noarch.rpm"
  elif [[ "${ID:-}" == "ol" ]]; then
    if dnf install -y oracle-epel-release-el"${MAJOR}" 2>/dev/null; then
      :
    else
      dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR}.noarch.rpm"
    fi
  else
    dnf install -y epel-release
  fi

  echo "==> dnf install ${TO_INSTALL[*]}"
  dnf install -y "${TO_INSTALL[@]}"
fi

for pkg in "${TO_INSTALL[@]}"; do
  echo "==> $($pkg --version 2>/dev/null | head -n1 || echo "$pkg instalado")"
done
echo "==> Instalação concluída: ${TO_INSTALL[*]}"
