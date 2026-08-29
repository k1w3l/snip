# snip

Scripts one-liner para Ubuntu novo.

**Repo:** https://github.com/k1w3l/snip (público)  
**Gitea (LAN):** http://192.168.1.34:3000/kiwel/snip

**Importante:** o `sudo` vai no **bash**, não no `curl`:

```fish
# certo
curl -fsSL URL | sudo bash

# errado
sudo curl -fsSL URL | bash
```

## Links públicos (GitHub raw)

| Script | URL |
|---|---|
| Bootstrap | https://raw.githubusercontent.com/k1w3l/snip/master/bootstrap.sh |
| Extras | https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh |
| Docker | https://raw.githubusercontent.com/k1w3l/snip/master/install-docker.sh |
| Compose update | https://raw.githubusercontent.com/k1w3l/snip/master/compose-update.sh |

## Bootstrap mínimo (update + upgrade + vim)

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/bootstrap.sh | sudo bash
```

## Extras (escolha os pacotes)

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash
```

Por ids / números / tudo:

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash -s -- git htop tmux jq net
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash -s -- --list
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash -s -- --all
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/extras.sh | sudo bash -s -- ufw --enable-ufw
```

Ids: `curl`, `git`, `editors`, `shell` (bash helpers + fish + fastfetch; fish vira shell padrão, `config.fish` roda fastfetch e o script abre o fish no fim), `archive`, `htop`, `tmux`, `jq`, `tree`, `ncdu`, `debug`, `net`, `ssh`, `chrony`, `ufw`, `apt-tools`, `modern`, `dev`.

Se `fastfetch` não existir no apt: adiciona `ppa:zhangsongcui3371/fastfetch`; se falhar, baixa o `.deb` do GitHub releases.

## Docker Engine

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/install-docker.sh | sudo bash
```

## Atualizar stack Compose

`pull` → `up -d` (valida config, `--remove-orphans`, prune dangling). Não precisa de root se o usuário está no grupo `docker`.

```fish
bash compose-update.sh -d /path/to/stack

# só um serviço
bash compose-update.sh -d /path/to/stack web api

# build local + up
bash compose-update.sh -d /path/to/stack --build web

# só pull
bash compose-update.sh -d /path/to/stack --pull-only
```

One-liner (raw):

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/snip/master/compose-update.sh | bash -s -- -d /path/to/stack
```

## LAN (Gitea)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/snip/raw/branch/master/bootstrap.sh | sudo bash
curl -fsSL http://192.168.1.34:3000/kiwel/snip/raw/branch/master/extras.sh | sudo bash
curl -fsSL http://192.168.1.34:3000/kiwel/snip/raw/branch/master/install-docker.sh | sudo bash
```

## Local

```fish
sudo bash bootstrap.sh
sudo bash extras.sh
sudo bash install-docker.sh
bash compose-update.sh -d /path/to/stack
```
