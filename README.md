# docker-ubuntu-install

Scripts one-liner para Ubuntu novo na LAN (Gitea homelab).

## Bootstrap mínimo (update + upgrade + vim)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | bash
```

## Extras (escolha os pacotes)

Menu interativo (precisa de TTY — baixe ou rode local se o pipe atrapalhar):

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash
```

Por ids / números / tudo:

```fish
# ids
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash -s -- git htop tmux jq net

# números do catálogo
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash -s -- 1 5 6

# tudo
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash -s -- --all

# listar catálogo
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash -s -- --list

# UFW instalado e ativado (OpenSSH liberado)
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | bash -s -- ufw --enable-ufw
```

Ids do catálogo: `curl`, `git`, `editors`, `shell`, `archive`, `htop`, `tmux`, `jq`, `tree`, `ncdu`, `debug`, `net`, `ssh`, `chrony`, `ufw`, `apt-tools`, `modern`, `dev`.

## Docker Engine

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | bash
```

## Local

```fish
bash bootstrap.sh
bash extras.sh
bash install-docker.sh
```
