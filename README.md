# docker-ubuntu-install

Scripts one-liner para Ubuntu novo.

**Repo:** https://github.com/k1w3l/docker-ubuntu-install (público)  
**Gitea (LAN):** http://192.168.1.34:3000/kiwel/docker-ubuntu-install

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
| Bootstrap | https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/bootstrap.sh |
| Extras | https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh |
| Docker | https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/install-docker.sh |

## Bootstrap mínimo (update + upgrade + vim)

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/bootstrap.sh | sudo bash
```

## Extras (escolha os pacotes)

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh | sudo bash
```

Por ids / números / tudo:

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh | sudo bash -s -- git htop tmux jq net
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh | sudo bash -s -- --list
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh | sudo bash -s -- --all
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/extras.sh | sudo bash -s -- ufw --enable-ufw
```

Ids: `curl`, `git`, `editors`, `shell` (bash helpers + fish + fastfetch), `archive`, `htop`, `tmux`, `jq`, `tree`, `ncdu`, `debug`, `net`, `ssh`, `chrony`, `ufw`, `apt-tools`, `modern`, `dev`.

## Docker Engine

```fish
curl -fsSL https://raw.githubusercontent.com/k1w3l/docker-ubuntu-install/master/install-docker.sh | sudo bash
```

## LAN (Gitea)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | sudo bash
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | sudo bash
```

## Local

```fish
sudo bash bootstrap.sh
sudo bash extras.sh
sudo bash install-docker.sh
```
