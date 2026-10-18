#!/usr/bin/env bash
set -euo pipefail

ZBX_RAMA="7.4"
CONF="/etc/zabbix/zabbix_agent2.conf"
MODO="${1:-local}"

case "$MODO" in
  local)
    SERVER="127.0.0.1,172.16.0.0/12"
    SERVER_ACTIVE="127.0.0.1"
    HOSTNAME_ZBX="Zabbix server"
    ;;
  remoto)
    SERVER="192.168.60.62"
    SERVER_ACTIVE="192.168.60.62"
    HOSTNAME_ZBX="$(hostname)"
    ;;
  *)
    echo "Uso: bash agente/install-agent2.sh [local|remoto]" >&2
    exit 1
    ;;
esac

echo "[1/4] Repositorio oficial de Zabbix ${ZBX_RAMA}"
UBUNTU="$(. /etc/os-release && echo "$VERSION_ID")"
PAQUETE="zabbix-release_latest_${ZBX_RAMA}+ubuntu${UBUNTU}_all.deb"
wget -q -O "/tmp/${PAQUETE}" \
  "https://repo.zabbix.com/zabbix/${ZBX_RAMA}/release/ubuntu/pool/main/z/zabbix-release/${PAQUETE}"
sudo dpkg -i "/tmp/${PAQUETE}"
sudo apt-get update

echo "[2/4] Paquete zabbix-agent2"
sudo apt-get install -y zabbix-agent2

echo "[3/4] Configuración en ${CONF} (modo ${MODO})"
[[ -f "${CONF}.orig" ]] || sudo cp "$CONF" "${CONF}.orig"
sudo sed -i -E \
  -e "s|^Server=.*|Server=${SERVER}|" \
  -e "s|^ServerActive=.*|ServerActive=${SERVER_ACTIVE}|" \
  -e "s|^Hostname=.*|Hostname=${HOSTNAME_ZBX}|" \
  "$CONF"

if ! grep -qx "Server=${SERVER}" "$CONF"; then
  echo "ERROR: no encuentro la línea Server= en ${CONF}. Revisa el archivo a mano." >&2
  exit 1
fi

sudo systemctl enable zabbix-agent2
sudo systemctl restart zabbix-agent2

echo "[4/4] Cortafuegos"
if [[ "$MODO" == "remoto" ]] && grep -q '^ENABLED=yes' /etc/ufw/ufw.conf; then
  sudo ufw allow from 192.168.60.62 to any port 10050 proto tcp
else
  echo "ufw inactivo o modo local: no hace falta regla"
fi

grep -E '^(Server|ServerActive|Hostname)=' "$CONF"
systemctl is-active zabbix-agent2

# Opciones configuradas:
# ----------------------
# ZBX_RAMA="7.4" -> la rama del server
# MODO="${1:-local}" -> primer argumento; local si no pongo ninguno
# local -> la VM y cualquier contenedor de Docker pueden preguntar
# remoto -> el server llega con la IP de vm-zabbix; Hostname sale de hostname
# *) -> cualquier otro valor enseña el uso y sale con error
# UBUNTU -> versión (24.04) de /etc/os-release para el nombre del paquete
# wget -q -O /tmp -> descarga zabbix-release sin barra de progreso
# [[ -f .orig ]] || cp -> guarda el original solo la primera vez
# sed -i -E "s|^Server=.*|...|" -> cambia la línea entera; el ^ no toca ServerActive=
# | de separador en sed -> los valores llevan /
# grep -qx -> comprueba que la línea quedó exacta
# systemctl enable y restart -> arranca con la VM y lee la configuración nueva
# ENABLED=yes en ufw.conf -> ufw está activo; no depende del idioma del sistema
# ufw allow from 192.168.60.62 ... 10050 -> solo en remoto con ufw activo; solo para vm-zabbix