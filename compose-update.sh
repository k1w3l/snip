#!/usr/bin/env bash
# Atualiza stack Docker Compose: pull das imagens + recreate (up -d).
# Uso one-liner — sudo no bash, não no curl:
#   curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/compose-update.sh | sudo bash -s -- -d /path/to/stack
#
# Exemplos:
#   compose-update.sh -d /opt/myapp
#   compose-update.sh -d /opt/myapp -f docker-compose.yml web api
#   compose-update.sh -d /opt/myapp --build web
#   compose-update.sh -d /opt/myapp --pull-only
#   compose-update.sh -d /opt/myapp --no-prune
set -euo pipefail

COMPOSE_DIR="."
COMPOSE_FILES=()
PROJECT_NAME=""
SERVICES=()
DO_BUILD=0
PULL_ONLY=0
NO_PRUNE=0
DRY_RUN=0
WAIT_TIMEOUT=""

usage() {
  cat <<'EOF'
compose-update.sh — atualiza containers via docker compose

  -d, --dir DIR          diretório do projeto (default: .)
  -f, --file FILE        compose file (repetível)
  -p, --project NAME     nome do projeto compose
  --build                também build (ou só build se --pull-only não)
  --pull-only            só docker compose pull
  --no-prune             não remove imagens dangling após update
  --wait SECONDS         aguarda healthcheck (docker compose up --wait)
  --dry-run              mostra comandos sem executar
  -h, --help             esta ajuda

  [SERVICE ...]          só estes serviços (--no-deps no up)

Fluxo padrão: compose config → pull → up -d [--no-deps] → (opcional) prune dangling
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      COMPOSE_DIR="${2:-}"
      shift 2
      ;;
    -f|--file)
      COMPOSE_FILES+=("${2:-}")
      shift 2
      ;;
    -p|--project)
      PROJECT_NAME="${2:-}"
      shift 2
      ;;
    --build) DO_BUILD=1; shift ;;
    --pull-only) PULL_ONLY=1; shift ;;
    --no-prune) NO_PRUNE=1; shift ;;
    --wait)
      WAIT_TIMEOUT="${2:-}"
      shift 2
      ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      SERVICES+=("$@")
      break
      ;;
    -*)
      echo "opção desconhecida: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      SERVICES+=("$1")
      shift
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '+'
    printf ' %q' "$@"
    echo
    return 0
  fi
  "$@"
}

compose() {
  local -a cmd=(docker compose)
  local f
  for f in "${COMPOSE_FILES[@]}"; do
    cmd+=(-f "$f")
  done
  if [[ -n "$PROJECT_NAME" ]]; then
    cmd+=(-p "$PROJECT_NAME")
  fi
  run "${cmd[@]}" "$@"
}

resolve_compose_dir() {
  if [[ ! -d "$COMPOSE_DIR" ]]; then
    echo "erro: diretório não existe: $COMPOSE_DIR" >&2
    exit 1
  fi
  COMPOSE_DIR="$(cd "$COMPOSE_DIR" && pwd)"
}

detect_compose_file() {
  if [[ ${#COMPOSE_FILES[@]} -gt 0 ]]; then
    return 0
  fi
  local candidate
  for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    if [[ -f "$COMPOSE_DIR/$candidate" ]]; then
      COMPOSE_FILES+=("$candidate")
      return 0
    fi
  done
  echo "erro: nenhum compose file em $COMPOSE_DIR (use -f)" >&2
  exit 1
}

if ! command -v docker >/dev/null 2>&1; then
  echo "erro: docker não encontrado" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "erro: plugin docker compose não disponível (use 'docker compose', não 'compose')" >&2
  exit 1
fi

resolve_compose_dir
detect_compose_file

echo "==> Projeto: $COMPOSE_DIR"
echo "==> Compose: ${COMPOSE_FILES[*]}"
if [[ ${#SERVICES[@]} -gt 0 ]]; then
  echo "==> Serviços: ${SERVICES[*]}"
fi

(
  cd "$COMPOSE_DIR"

  echo "==> Validando compose config"
  compose config -q

  if [[ "$PULL_ONLY" -eq 1 ]]; then
    if [[ ${#SERVICES[@]} -gt 0 ]]; then
      compose pull "${SERVICES[@]}"
    else
      compose pull
    fi
    echo "==> Pull concluído."
    exit 0
  fi

  if [[ "$DO_BUILD" -eq 1 ]]; then
    if [[ ${#SERVICES[@]} -gt 0 ]]; then
      compose build "${SERVICES[@]}"
    else
      compose build
    fi
  else
    if [[ ${#SERVICES[@]} -gt 0 ]]; then
      compose pull "${SERVICES[@]}"
    else
      compose pull
    fi
  fi

  local -a up_args=(up -d --remove-orphans)
  if [[ -n "$WAIT_TIMEOUT" ]]; then
    up_args+=(--wait --wait-timeout "$WAIT_TIMEOUT")
  fi
  if [[ ${#SERVICES[@]} -gt 0 ]]; then
    up_args+=(--no-deps)
    up_args+=("${SERVICES[@]}")
  fi
  if [[ "$DO_BUILD" -eq 1 ]]; then
    up_args+=(--build)
  fi

  echo "==> Recriando containers"
  compose "${up_args[@]}"

  echo "==> Status"
  if [[ ${#SERVICES[@]} -gt 0 ]]; then
    compose ps "${SERVICES[@]}"
  else
    compose ps
  fi
)

if [[ "$NO_PRUNE" -eq 0 && "$PULL_ONLY" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
  echo "==> Removendo imagens dangling"
  docker image prune -f >/dev/null 2>&1 || true
fi

echo "==> Update concluído."
