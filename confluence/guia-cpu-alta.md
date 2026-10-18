# Guía: CPU alta en servidor

**Síntoma:** el uso de CPU pasa del 80 % de media durante un minuto (trigger "CPU alta", etiqueta `guia: cpu`).

## Causas posibles

- Un proceso que consume mucha CPU o se ha quedado en bucle
- Un pico de trabajo programado (cron, copias de seguridad)
- Más carga de la que la máquina puede atender

## Diagnóstico

1. Carga general y procesos: `top`
2. Los que más CPU consumen: `ps aux --sort=-%cpu | head`
3. Si es un contenedor: `docker stats --no-stream`
4. Errores recientes del sistema: `journalctl -p err -b`

## Resolución

- Si es un servicio: `sudo systemctl restart <servicio>`
- Si es un proceso sin control: `kill <PID>` (`kill -9` solo como último recurso)
- Anotar la causa en el ticket de Jira y cerrarlo