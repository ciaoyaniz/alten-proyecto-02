#!/usr/bin/env bash
set -euo pipefail

TIPO="${1:-}"
SEGUNDOS="${2:-180}"

if ! command -v stress-ng > /dev/null; then
  sudo apt-get install -y stress-ng
fi

case "$TIPO" in
  cpu)
    stress-ng --cpu 0 --timeout "${SEGUNDOS}s"
    ;;
  ram)
    TOTAL_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
    DISPONIBLE_KB="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
    OCUPAR_MB=$(( (DISPONIBLE_KB - TOTAL_KB * 12 / 100) / 1024 ))
    if [[ "$OCUPAR_MB" -le 0 ]]; then
      echo "Ya queda menos del 12 % de memoria disponible: no lanzo la prueba" >&2
      exit 1
    fi
    echo "Ocupo ${OCUPAR_MB} MB para dejar disponible un 12 % de la memoria"
    stress-ng --vm 1 --vm-bytes "${OCUPAR_MB}M" --vm-keep --timeout "${SEGUNDOS}s"
    ;;
  disco)
    stress-ng --hdd 4 --hdd-bytes 1G --temp-path /var/tmp --timeout "${SEGUNDOS}s"
    ;;
  *)
    echo "Uso: bash scripts/prueba-carga.sh cpu|ram|disco [segundos]" >&2
    exit 1
    ;;
esac

# Opciones configuradas:
# ----------------------
# TIPO="${1:-}" -> cpu, ram o disco; vacío si falta y set -u no falla
# SEGUNDOS="${2:-180}" -> duración; 180 s dan de sobra para la media de 1 minuto
# command -v stress-ng -> lo instala solo si falta (0.17.06 en Ubuntu 24.04)
# --cpu 0 -> un proceso al 100 % por cada vCPU
# MemTotal y MemAvailable -> memoria total y disponible en KB de /proc/meminfo
# OCUPAR_MB -> lo que hay que ocupar para dejar un 12 % disponible
# -le 0 -> si ya queda menos del 12 % no lanza nada
# --vm 1 --vm-bytes --vm-keep -> reserva esa memoria y la mantiene ocupada
# --hdd 4 --hdd-bytes 1G -> cuatro procesos que escriben y borran archivos de 1 GB
# --temp-path /var/tmp -> no escribe en el repositorio
# --timeout -> la prueba termina sola y no deja la VM bloqueada
# *) -> otro argumento enseña el uso y sale con error