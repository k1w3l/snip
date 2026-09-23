#!/usr/bin/env bash
# Extras TUI / produtividade para RHEL / Rocky / Alma / CentOS Stream / Oracle / Fedora.
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-rhel-extras.sh | sudo bash
#
# Exemplos:
#   bash install-rhel-extras.sh                 # menu interativo
#   bash install-rhel-extras.sh btop yazi
#   bash install-rhel-extras.sh 1 3 5
#   bash install-rhel-extras.sh --all
#   bash install-rhel-extras.sh --list

# curl|bash: $0 vira /usr/bin/bash (binário). Reexecuta o restante do stdin como root.
if [[ "$(id -u)" -ne 0 ]]; then
  src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" && "$src" == *.sh ]]; then
    exec sudo -E bash "$src" "$@"
  fi
  exec sudo -E bash -s -- "$@"
fi

set -euo pipefail

# id#título#uso#origem#bins (espaço)#pacotes dnf (espaço)
# origem: dnf | copr:user/project
CATALOG=(
  "htop#Monitor clássico de processos#Uso: htop — setas navegam, F9 mata processo, F5 árvore, q sai#dnf#htop#htop"
  "btop#Monitor moderno (CPU/mem/disco/rede/procs)#Uso: btop — Esc sai; 1–4 ligam/desligam caixas; m ordena processos#dnf#btop#btop"
  "yazi#File manager rápido (async/Rust)#Uso: yazi — hjkl navega, Enter abre, Space marca, q sai#copr:lihaohong/yazi#yazi#yazi"
  "ranger#File manager com preview (Vim-like)#Uso: ranger — hjkl navega, Enter abre, q sai, :delete apaga#dnf#ranger#ranger"
  "mc#Midnight Commander (dois painéis)#Uso: mc — Tab troca painel, F5 copia, F6 move, F8 apaga, F10 sai#dnf#mc#mc"
  "nnn#File manager minimalista e rápido#Uso: nnn — setas/hjkl, Enter entra, n cria, d apaga, q sai#dnf#nnn#nnn"
  "ncdu#Uso de disco interativo (ncurses)#Uso: ncdu /caminho — Enter entra, d apaga, g gráfico, q sai#dnf#ncdu#ncdu"
  "fzf#Fuzzy finder interativo#Uso: fzf; find . | fzf; vim \"\$(fzf)\" — Enter escolhe, Ctrl-C cancela#dnf#fzf#fzf"
  "lazygit#Git TUI (stage/commit/push)#Uso: lazygit no repo — Space stage, c commit, P push, q sai#copr:dejan/lazygit#lazygit#lazygit"
  "tig#Browser de histórico Git#Uso: tig; tig status — Enter detalha commit, q sai#dnf#tig#tig"
  "micro#Editor de texto intuitivo (estilo nano+)#Uso: micro arquivo — Ctrl-S salva, Ctrl-Q sai, Ctrl-E comando#dnf#micro#micro"
  "neovim#Editor Vim moderno#Uso: nvim arquivo — i insere, Esc, :wq salva e sai, :q! descarta#dnf#nvim#neovim"
  "tmux#Multiplexador de sessões no terminal#Uso: tmux; Ctrl-b c janela; Ctrl-b % split; Ctrl-b d detach; tmux a#dnf#tmux#tmux"
  "bat#cat com syntax highlight e pager#Uso: bat arquivo; bat -p arquivo (sem pager) — q sai do pager#dnf#bat#bat"
  "ripgrep#Busca rápida em arquivos (melhor que grep)#Uso: rg padrão [path]; rg -i erro /var/log#dnf#rg#ripgrep"
  "jq#Processador JSON na CLI#Uso: jq . file.json; curl -fsSL URL | jq '.key'#dnf#jq#jq"
)

DO_ALL=0
DO_LIST=0
WANT=()
SELECTED_IDX=()

usage() {
  cat <<'EOF'
install-rhel-extras.sh — TUI / produtividade para família Red Hat

  (sem args)           menu interativo
  <id> [id...]         ids do catálogo (ex: btop yazi lazygit)
  <n> [n...]           números do catálogo (ex: 1 3 5)
  --all                tudo do catálogo
  --list               lista o catálogo (com uso)
  -h, --help           esta ajuda
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --list) DO_LIST=1 ;;
    --all) DO_ALL=1 ;;
    # compat com o script antigo
    --both) WANT+=(htop btop) ;;
    -*)
      echo "flag desconhecida: $arg" >&2
      usage >&2
      exit 1
      ;;
    *) WANT+=("$arg") ;;
  esac
done

catalog_len() { echo "${#CATALOG[@]}"; }

catalog_field() {
  local i="$1" field="$2"
  echo "${CATALOG[$((i - 1))]}" | cut -d'#' -f"$field"
}

catalog_id() { catalog_field "$1" 1; }
catalog_title() { catalog_field "$1" 2; }
catalog_usage() { catalog_field "$1" 3; }
catalog_origin() { catalog_field "$1" 4; }
catalog_bins() { catalog_field "$1" 5; }
catalog_pkgs() { catalog_field "$1" 6; }

find_index_by_id() {
  local needle="$1" i id
  for i in $(seq 1 "$(catalog_len)"); do
    id="$(catalog_id "$i")"
    if [[ "$id" == "$needle" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

print_catalog() {
  local i
  echo "Catálogo RHEL extras (TUI / produtividade):"
  echo
  for i in $(seq 1 "$(catalog_len)"); do
    printf "  %2d) %-10s %s\n" "$i" "$(catalog_id "$i")" "$(catalog_title "$i")"
    printf "      %s\n" "$(catalog_usage "$i")"
    printf "      origem: %s\n" "$(catalog_origin "$i")"
    echo
  done
}

resolve_selection() {
  local token idx
  SELECTED_IDX=()
  if [[ "$DO_ALL" -eq 1 ]]; then
    for idx in $(seq 1 "$(catalog_len)"); do
      SELECTED_IDX+=("$idx")
    done
    return
  fi

  for token in "${WANT[@]}"; do
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      if [[ "$token" -ge 1 && "$token" -le "$(catalog_len)" ]]; then
        SELECTED_IDX+=("$token")
      else
        echo "erro: número fora do catálogo: $token" >&2
        exit 1
      fi
    else
      if idx="$(find_index_by_id "$token")"; then
        SELECTED_IDX+=("$idx")
      else
        echo "erro: id desconhecido: $token (use --list)" >&2
        exit 1
      fi
    fi
  done
}

prompt_interactive() {
  local line raw parts
  print_catalog
  echo "Digite números e/ou ids separados por espaço (ex: 2 3 yazi lazygit)."
  echo "Também aceita: all"
  if [[ -r /dev/tty ]]; then
    read -r -p "> " line </dev/tty
  else
    echo "erro: sem TTY para menu — passe ids na linha de comando (ex: … | sudo bash -s -- btop yazi)" >&2
    exit 1
  fi

  raw="${line//,/ }"
  # shellcheck disable=SC2206
  parts=($raw)
  if [[ ${#parts[@]} -eq 0 ]]; then
    echo "nada selecionado; saindo."
    exit 0
  fi
  if [[ ${#parts[@]} -eq 1 && "${parts[0]}" == "all" ]]; then
    DO_ALL=1
    resolve_selection
    return
  fi
  WANT=("${parts[@]}")
  resolve_selection
}

item_already_installed() {
  local i="$1" bin
  # shellcheck disable=SC2206
  local bins=($(catalog_bins "$i"))
  for bin in "${bins[@]}"; do
    if ! command -v "$bin" >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

ensure_el_repos() {
  if [[ "${ID:-}" == "fedora" ]]; then
    return 0
  fi

  if [[ -z "${MAJOR:-}" ]]; then
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

  case "${ID:-}" in
    rhel)
      if command -v subscription-manager >/dev/null 2>&1; then
        local arch
        arch="$(uname -m)"
        echo "==> Habilitando CodeReady Linux Builder (subscription-manager)"
        subscription-manager repos --enable "codeready-builder-for-rhel-${MAJOR}-${arch}-rpms" \
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
}

enable_copr() {
  local project="$1"
  echo "==> COPR: $project"
  dnf install -y dnf-plugins-core
  # -y evita prompt "Are you sure?"
  if ! dnf copr enable -y "$project"; then
    echo "erro: falha ao habilitar COPR $project" >&2
    return 1
  fi
}

if [[ "$DO_LIST" -eq 1 ]]; then
  print_catalog
  exit 0
fi

if [[ "$DO_ALL" -eq 1 || ${#WANT[@]} -gt 0 ]]; then
  resolve_selection
else
  prompt_interactive
fi

if [[ ${#SELECTED_IDX[@]} -eq 0 ]]; then
  echo "nada selecionado; saindo."
  exit 0
fi

mapfile -t SELECTED_IDX < <(printf '%s\n' "${SELECTED_IDX[@]}" | sort -n | uniq)

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
echo "==> Selecionado:"
for idx in "${SELECTED_IDX[@]}"; do
  printf "  - %s — %s\n" "$(catalog_id "$idx")" "$(catalog_title "$idx")"
  printf "    %s\n" "$(catalog_usage "$idx")"
done

TO_INSTALL_IDX=()
for idx in "${SELECTED_IDX[@]}"; do
  if item_already_installed "$idx"; then
    echo "==> $(catalog_id "$idx") já instalado ($(catalog_bins "$idx"))"
  else
    TO_INSTALL_IDX+=("$idx")
  fi
done

if [[ ${#TO_INSTALL_IDX[@]} -eq 0 ]]; then
  echo "==> Nada a instalar."
  exit 0
fi

NEED_EPEL=0
COPRS=()
PKGS=()
for idx in "${TO_INSTALL_IDX[@]}"; do
  origin="$(catalog_origin "$idx")"
  case "$origin" in
    dnf) NEED_EPEL=1 ;;
    copr:*)
      COPRS+=("${origin#copr:}")
      ;;
    *)
      echo "erro: origem desconhecida em $(catalog_id "$idx"): $origin" >&2
      exit 1
      ;;
  esac
  # shellcheck disable=SC2206
  PKGS+=($(catalog_pkgs "$idx"))
done

mapfile -t COPRS < <(printf '%s\n' "${COPRS[@]:-}" | sed '/^$/d' | sort -u)
mapfile -t PKGS < <(printf '%s\n' "${PKGS[@]}" | sort -u)

if [[ "$NEED_EPEL" -eq 1 || ${#COPRS[@]} -gt 0 ]]; then
  # COPR em EL costuma depender de EPEL; Fedora também precisa de plugins.
  if [[ "${ID:-}" != "fedora" ]]; then
    ensure_el_repos
  else
    echo "==> Dependências (dnf-plugins-core)"
    dnf install -y dnf-plugins-core
  fi
fi

for copr in "${COPRS[@]:-}"; do
  [[ -n "$copr" ]] || continue
  enable_copr "$copr"
done

echo "==> dnf install ${PKGS[*]}"
if ! dnf install -y "${PKGS[@]}"; then
  echo "aviso: install em lote falhou; tentando pacote a pacote" >&2
  for pkg in "${PKGS[@]}"; do
    dnf install -y "$pkg" || echo "aviso: pulou $pkg" >&2
  done
fi

echo
echo "==> Instalado / disponível:"
for idx in "${TO_INSTALL_IDX[@]}"; do
  id="$(catalog_id "$idx")"
  bins="$(catalog_bins "$idx")"
  # shellcheck disable=SC2206
  bin_arr=($bins)
  if command -v "${bin_arr[0]}" >/dev/null 2>&1; then
    printf "  ✓ %s — %s\n" "$id" "$(catalog_usage "$idx")"
  else
    printf "  ✗ %s — binário %s não encontrado após install\n" "$id" "${bin_arr[0]}" >&2
  fi
done
echo "==> Concluído."
