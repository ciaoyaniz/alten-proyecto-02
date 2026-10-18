# Guía: disco saturado (iowait)

**Síntoma:** la CPU pasa más del 20 % del tiempo esperando al disco durante un minuto (trigger "Disco saturado (CPU iowait)", etiqueta `guia: disco`).

## Causas posibles

- Un proceso que lee o escribe sin parar (copias de seguridad, logs, una base de datos)
- El disco casi lleno
- Un disco lento o con fallos

## Diagnóstico

1. Espacio libre en cada disco: `df -h`
2. Tiempo de espera de la CPU (columna `wa`): `top`
3. Los procesos que más leen y escriben: `sudo iotop -o` (paquete `iotop`)
4. Errores del disco: `sudo dmesg | grep -i error`

## Resolución

- Si es un proceso: esperar a que termine o pararlo con `kill <PID>`
- Si el disco está lleno: borrar logs antiguos o imágenes sin usar con `docker system prune`
- Si es el disco: revisarlo o cambiarlo
- Anotar la causa en el ticket de Jira y cerrarlo