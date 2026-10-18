# Guía: memoria RAM disponible baja

**Síntoma:** la memoria disponible baja del 20 % (trigger "RAM disponible baja", etiqueta `guia: ram`).

## Causas posibles

- Un proceso que consume cada vez más memoria y no la libera
- Demasiados servicios o contenedores para la memoria de la máquina
- Una carga de trabajo puntual más grande de lo normal

## Diagnóstico

1. Memoria total, usada y disponible: `free -h`
2. Los procesos que más memoria consumen: `ps aux --sort=-%mem | head`
3. Si es un contenedor: `docker stats --no-stream`
4. Si el sistema ha matado algún proceso por falta de memoria: `journalctl -k | grep -i "out of memory"`

## Resolución

- Si es un servicio: `sudo systemctl restart <servicio>`
- Si es un contenedor: `docker restart <contenedor>`
- Si se repite: ampliar la memoria de la máquina o limitar la del servicio
- Anotar la causa en el ticket de Jira y cerrarlo