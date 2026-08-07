# docker-ubuntu-install

Instala Docker Engine, CLI, containerd, Buildx e Compose plugin no Ubuntu via repositório oficial.

## One-liner (máquina nova na LAN)

```fish
curl -fsSL http://192.168.1.34:3000/kiwel/docker-ubuntu-install/raw/branch/master/install-docker.sh | bash
```

O script eleva para root com `sudo` se necessário.

## Local

```fish
bash install-docker.sh
```

## Notas

- Detecta o codename do Ubuntu (`VERSION_CODENAME`) em vez de fixar `noble`.
- Roda `apt-get update` + `upgrade` e depois instala os pacotes Docker.
- Adiciona o usuário que invocou o `sudo` ao grupo `docker`.
