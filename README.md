# docker-ubuntu-install

Scripts one-liner para Ubuntu novo na LAN (Gitea homelab).

## Bootstrap base (vim + utilitários)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash
```

Com extras:

```fish
# ferramentas de compilação / Python
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash -s -- --with-dev

# ativa UFW liberando OpenSSH
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash -s -- --with-ufw

# os dois
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash -s -- --with-dev --with-ufw
```

Inclui: `vim`, `git`, `curl`/`wget`, `htop`, `tmux`, `jq`, `tree`, `ncdu`, `rsync`, rede (`dnsutils`, `mtr-tiny`, …), `openssh-server`, `chrony`, `ufw` (só ativa com `--with-ufw`), e tenta `ripgrep`/`fd-find`/`bat`/`fzf` se existirem no apt.

## Docker Engine

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | bash
```

## Local

```fish
bash bootstrap.sh
bash install-docker.sh
```
