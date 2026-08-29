#!/usr/bin/env bash
# Pacotes opcionais para Ubuntu — escolha o que instalar.
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash
#
# Exemplos:
#   bash extras.sh                  # menu interativo
#   bash extras.sh git htop tmux    # por id
#   bash extras.sh 1 3 5            # por número do catálogo
#   bash extras.sh --all
#   bash extras.sh --list
#   bash extras.sh ufw --enable-ufw

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

# id|descrição|pacotes (espaço)
CATALOG=(
  "curl|HTTP client e CA|curl wget ca-certificates"
  "git|Controle de versão|git"
  "editors|Editores extras|nano neovim"
  "shell|Shell helpers (bash, fish, fastfetch)|bash-completion less man-db fish fastfetch"
  "archive|Arquivos|unzip zip tar rsync"
  "htop|Monitor de processos|htop"
  "tmux|Multiplexador de terminal|tmux"
  "jq|JSON CLI|jq"
  "tree|Árvore de diretórios|tree"
  "ncdu|Uso de disco|ncdu"
  "debug|Debug / introspecção|lsof strace"
  "net|Rede (dig, mtr, traceroute…)|dnsutils net-tools iproute2 iputils-ping traceroute mtr-tiny"
  "ssh|OpenSSH client + server|openssh-client openssh-server"
  "chrony|NTP|chrony"
  "ufw|Firewall UFW (não ativa sozinho)|ufw"
  "apt-tools|Extras APT (gpg, transport)|gnupg apt-transport-https software-properties-common"
  "modern|rg / fd / bat / fzf|ripgrep fd-find bat fzf"
  "dev|Build + Python|build-essential cmake pkg-config python3 python3-pip python3-venv"
)

ENABLE_UFW=0
DO_ALL=0
DO_LIST=0
WANT=()

usage() {
  cat <<'EOF'
extras.sh — instala pacotes opcionais à escolha

  (sem args)           menu interativo
  <id> [id...]         ids do catálogo (ex: git htop tmux)
  <n> [n...]           números do catálogo (ex: 1 3 5)
  --all                tudo do catálogo
  --list               só lista o catálogo
  --enable-ufw         após instalar ufw: allow OpenSSH + enable
  -h, --help           esta ajuda
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --list) DO_LIST=1 ;;
    --all) DO_ALL=1 ;;
    --enable-ufw) ENABLE_UFW=1 ;;
    -*)
      echo "flag desconhecida: $arg" >&2
      usage >&2
      exit 1
      ;;
    *) WANT+=("$arg") ;;
  esac
done

catalog_len() { echo "${#CATALOG[@]}"; }

catalog_id() {
  local i="$1"
  echo "${CATALOG[$((i - 1))]}" | cut -d'|' -f1
}

catalog_desc() {
  local i="$1"
  echo "${CATALOG[$((i - 1))]}" | cut -d'|' -f2
}

catalog_pkgs() {
  local i="$1"
  echo "${CATALOG[$((i - 1))]}" | cut -d'|' -f3
}

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
  echo "Catálogo de extras:"
  for i in $(seq 1 "$(catalog_len)"); do
    printf "  %2d) %-12s %s\n" "$i" "$(catalog_id "$i")" "$(catalog_desc "$i")"
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
  local line raw parts token idx
  print_catalog
  echo
  echo "Digite números e/ou ids separados por espaço (ex: 1 3 git tmux)."
  echo "Também aceita: all"
  if [[ -r /dev/tty ]]; then
    read -r -p "> " line </dev/tty
  else
    echo "erro: sem TTY para menu — passe ids na linha de comando (ex: extras.sh git htop)" >&2
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

post_install_hooks() {
  local idx id
  for idx in "${SELECTED_IDX[@]}"; do
    id="$(catalog_id "$idx")"
    case "$id" in
      ssh)
        systemctl enable --now ssh 2>/dev/null || true
        ;;
      chrony)
        systemctl enable --now chrony 2>/dev/null || true
        ;;
      modern)
        if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
          ln -sf "$(command -v batcat)" /usr/local/bin/bat
        fi
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
          ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        fi
        ;;
      shell)
        configure_fish_shell
        ;;
      ufw)
        if [[ "$ENABLE_UFW" -eq 1 ]]; then
          echo "==> UFW: allow OpenSSH + enable"
          ufw allow OpenSSH
          ufw --force enable
          ufw status verbose
        else
          echo "==> ufw instalado; para ativar: ufw allow OpenSSH && ufw enable"
          echo "    (ou rode de novo com --enable-ufw)"
        fi
        ;;
    esac
  done
}

selection_has() {
  local want="$1" idx
  for idx in "${SELECTED_IDX[@]}"; do
    if [[ "$(catalog_id "$idx")" == "$want" ]]; then
      return 0
    fi
  done
  return 1
}

target_login_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    echo "$SUDO_USER"
  elif [[ "$(id -u)" -eq 0 ]]; then
    # root direto: não força fish em root a menos que seja a sessão atual
    echo "root"
  else
    id -un
  fi
}

ensure_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    echo "==> fastfetch já instalado: $(command -v fastfetch)"
    return 0
  fi

  echo "==> Resolvendo fastfetch"
  apt-get update -y
  if apt-cache show fastfetch >/dev/null 2>&1; then
    apt-get install -y fastfetch && return 0
  fi

  echo "==> fastfetch não está nos repositórios padrão; adicionando PPA"
  apt-get install -y software-properties-common ca-certificates gnupg
  if add-apt-repository -y ppa:zhangsongcui3371/fastfetch; then
    apt-get update -y
    if apt-get install -y fastfetch; then
      return 0
    fi
  fi

  echo "==> PPA falhou; baixando .deb do GitHub releases"
  local arch deb_arch url tmp
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) deb_arch=amd64 ;;
    arm64) deb_arch=aarch64 ;;
    *)
      echo "erro: arquitetura sem .deb pronto do fastfetch: $arch" >&2
      return 1
      ;;
  esac
  url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${deb_arch}.deb"
  tmp="$(mktemp --suffix=.deb)"
  curl -fsSL -o "$tmp" "$url"
  apt-get install -y "$tmp"
  rm -f "$tmp"
  command -v fastfetch >/dev/null 2>&1
}

configure_fish_shell() {
  local user home fish_path conf marker
  user="$(target_login_user)"
  home="$(getent passwd "$user" | cut -d: -f6)"
  fish_path="$(command -v fish || true)"

  if [[ -z "$fish_path" ]]; then
    echo "aviso: fish não encontrado; pulando shell padrão" >&2
    return 0
  fi

  if [[ -z "$home" || ! -d "$home" ]]; then
    echo "aviso: home de $user não encontrado; pulando config fish" >&2
    return 0
  fi

  if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    echo "$fish_path" >> /etc/shells
  fi

  echo "==> Definindo fish como shell padrão de ${user}"
  chsh -s "$fish_path" "$user"

  mkdir -p "$home/.config/fish"
  conf="$home/.config/fish/config.fish"
  marker="# snip: fastfetch on interactive shell"
  touch "$conf"
  if ! grep -qF "$marker" "$conf" 2>/dev/null; then
    echo "==> Adicionando fastfetch ao config.fish de ${user}"
    cat >>"$conf" <<EOF

$marker
if status is-interactive
    and command -q fastfetch
    fastfetch
end
EOF
  else
    echo "==> config.fish já carrega fastfetch"
  fi
  chown -R "$user":"$user" "$home/.config/fish"
}

launch_fish_if_requested() {
  selection_has shell || return 0
  command -v fish >/dev/null 2>&1 || return 0

  local user
  user="$(target_login_user)"
  echo "==> Abrindo fish"
  if [[ "$user" != "root" && "$(id -u)" -eq 0 ]]; then
    exec sudo -u "$user" -H fish -l
  fi
  exec fish -l
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

# dedupe índices
mapfile -t SELECTED_IDX < <(printf '%s\n' "${SELECTED_IDX[@]}" | sort -n | uniq)

PKGS=()
echo "==> Selecionado:"
for idx in "${SELECTED_IDX[@]}"; do
  printf "  - %s (%s)\n" "$(catalog_id "$idx")" "$(catalog_desc "$idx")"
  # shellcheck disable=SC2206
  PKGS+=($(catalog_pkgs "$idx"))
done

# fastfetch: tratar à parte (repo/PPA/.deb) — remove do lote apt
INSTALL_FASTFETCH=0
FILTERED=()
for pkg in "${PKGS[@]}"; do
  if [[ "$pkg" == "fastfetch" ]]; then
    INSTALL_FASTFETCH=1
  else
    FILTERED+=("$pkg")
  fi
done
if [[ ${#FILTERED[@]} -gt 0 ]]; then
  mapfile -t PKGS < <(printf '%s\n' "${FILTERED[@]}" | sort -u)
else
  PKGS=()
fi

echo "==> apt update"
apt-get update -y

if [[ ${#PKGS[@]} -gt 0 ]]; then
  echo "==> Instalando: ${PKGS[*]}"
  if ! apt-get install -y "${PKGS[@]}"; then
    echo "aviso: install em lote falhou; tentando pacote a pacote" >&2
    for pkg in "${PKGS[@]}"; do
      apt-get install -y "$pkg" || echo "aviso: pulou $pkg" >&2
    done
  fi
fi

if [[ "$INSTALL_FASTFETCH" -eq 1 ]] || selection_has shell; then
  ensure_fastfetch || echo "aviso: não foi possível instalar fastfetch" >&2
fi

post_install_hooks

echo "==> Extras instalados."
launch_fish_if_requested
