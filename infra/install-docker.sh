#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "ERROR: ejecuta el script con tu usuario, no como root ni con sudo delante." >&2
  exit 1
fi

echo "[1/4] Dependencias y clave GPG de Docker"
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[2/4] Repositorio oficial de Docker"
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update

echo "[3/4] Docker Engine, cliente, containerd y plugins"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

echo "[4/4] Usuario ${USER} en el grupo docker"
getent group docker > /dev/null || sudo groupadd docker
sudo usermod -aG docker "$USER"

sudo docker --version
sudo docker compose version
echo "Cierra la sesión y vuelve a entrar para usar docker sin sudo."

# Opciones configuradas:
# ----------------------
# set -euo pipefail -> para en el primer error, variable sin definir o tubería que falla
# id -u -eq 0 -> no deja lanzarlo como root; añadiría a root al grupo docker
# install -m 0755 -d -> carpeta de claves de apt legible para todos
# curl -fsSL -> falla si hay error, sin barra de progreso y sigue redirecciones
# chmod a+r docker.asc -> apt puede leer la clave
# CODENAME -> versión de Ubuntu (noble) sacada de /etc/os-release
# tee ... <<EOF > /dev/null -> escribe docker.sources en /etc sin repetirlo en pantalla
# Components: stable -> solo versiones estables
# Signed-By -> la clave que firma los paquetes
# docker-ce, docker-ce-cli, containerd.io -> motor, cliente y el que ejecuta los contenedores
# docker-buildx-plugin y docker-compose-plugin -> plugins de build y de Compose
# systemctl enable --now -> arranca Docker ahora y en cada arranque
# getent group docker || groupadd -> crea el grupo solo si no existe
# usermod -aG docker -> me añade al grupo; sin -a me quitaría de sudo
# sudo docker --version -> con sudo porque la sesión aún no tiene el grupo