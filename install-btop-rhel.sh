#!/usr/bin/env bash
# Instala btop em RHEL / Rocky / Alma / CentOS Stream / Oracle Linux (via EPEL).
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-btop-rhel.sh | sudo bash

# curl|bash: $0 vira /usr/bin/bash (binário). Reexecuta o restante do stdin como root.
if [[ "$(id -u)" -ne 0 ]]; then
  src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" && "$src" == *.sh ]]; then
    exec sudo -E bash "$src" "$@"
  fi
  exec sudo -E bash -s -- "$@"
fi

set -euo pipefail

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

echo "==> ${PRETTY_NAME:-Linux} (id=${ID:-?}, el=${MAJOR:-?}, arch=$(uname -m))"

if command -v btop >/dev/null 2>&1; then
  echo "==> btop já instalado: $(btop --version 2>/dev/null || command -v btop)"
  exit 0
fi

# Fedora traz btop no repositório base — sem EPEL.
if [[ "${ID:-}" == "fedora" ]]; then
  echo "==> dnf install btop (Fedora)"
  dnf install -y btop
  echo "==> $(btop --version 2>/dev/null || echo btop instalado)"
  exit 0
fi

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
    # Imagens cloud (RHUI) usam ids diferentes.
    while read -r repo; do
      [[ -n "$repo" ]] || continue
      enable_repo "$repo"
    done < <(dnf repolist --all 2>/dev/null | awk '{print $1}' | grep -Ei 'codeready|crb' || true)
    ;;
  ol)
    if [[ "$MAJOR" -ge 9 ]]; then
      enable_repo "ol${MAJOR}_codeready_builder"
    else
      enable_repo "ol${MAJOR}_codeready_builder"
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
  # Oracle: pacote oficial do vendor quando existir; senão RPM Fedora.
  if dnf install -y oracle-epel-release-el"${MAJOR}" 2>/dev/null; then
    :
  else
    dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR}.noarch.rpm"
  fi
else
  dnf install -y epel-release
fi

echo "==> dnf install btop"
dnf install -y btop

echo "==> $(btop --version 2>/dev/null || echo btop instalado)"
echo "==> btop instalado com sucesso."
