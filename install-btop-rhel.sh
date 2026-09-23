#!/usr/bin/env bash
# Compat: install-btop-rhel.sh foi renomeado para install-rhel-extras.sh.
# Redireciona args (htop/btop/--both) para o script novo.
echo "==> aviso: install-btop-rhel.sh → install-rhel-extras.sh" >&2

src="${BASH_SOURCE[0]:-}"
if [[ -n "$src" && -f "$src" && "$src" == *.sh ]]; then
  sibling="$(cd "$(dirname "$src")" && pwd)/install-rhel-extras.sh"
  if [[ -f "$sibling" ]]; then
    exec bash "$sibling" "$@"
  fi
fi

curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-rhel-extras.sh | exec bash -s -- "$@"
