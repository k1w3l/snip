# docker-ubuntu-install

Scripts one-liner para Ubuntu novo na LAN (Gitea homelab).

**Importante:** o `sudo` vai no **bash**, não no `curl`:

```fish
# certo
curl -fsSL URL | sudo bash

# errado — eleva só o curl; e o auto-sudo antigo quebrava com
# "/usr/bin/bash: cannot execute binary file"
sudo curl -fsSL URL | bash
```

## Bootstrap mínimo (update + upgrade + vim)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/bootstrap.sh | sudo bash
```

## Extras (escolha os pacotes)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash
```

Por ids / números / tudo:

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash -s -- git htop tmux jq net
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash -s -- --list
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash -s -- --all
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/extras.sh | sudo bash -s -- ufw --enable-ufw
```

Ids: `curl`, `git`, `editors`, `shell`, `archive`, `htop`, `tmux`, `jq`, `tree`, `ncdu`, `debug`, `net`, `ssh`, `chrony`, `ufw`, `apt-tools`, `modern`, `dev`.

## Docker Engine

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | sudo bash
```

## Local

```fish
sudo bash bootstrap.sh
sudo bash extras.sh
sudo bash install-docker.sh
```
