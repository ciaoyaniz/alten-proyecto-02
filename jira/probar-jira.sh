#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: bash jira/probar-jira.sh URL_JIRA EMAIL [CLAVE_PROYECTO]" >&2
  exit 1
fi

JIRA_URL="${1%/}"
JIRA_USER="$2"
PROYECTO="${3:-ZBX}"

command -v jq > /dev/null || sudo apt-get install -y jq

read -r -s -p "Token de API de Jira: " JIRA_TOKEN
echo

RESPUESTA="$(curl -s -w '\n%{http_code}' -u "${JIRA_USER}:${JIRA_TOKEN}" \
  -H "Accept: application/json" \
  "${JIRA_URL}/rest/api/2/issue/createmeta/${PROYECTO}/issuetypes")"
unset JIRA_TOKEN

CODIGO="$(tail -n 1 <<< "$RESPUESTA")"
CUERPO="$(sed '$d' <<< "$RESPUESTA")"

if [[ "$CODIGO" != "200" ]]; then
  echo "ERROR: Jira respondió HTTP ${CODIGO}" >&2
  exit 1
fi

echo "Tipos de incidencia del proyecto ${PROYECTO}:"
jq -r '(.issueTypes // .values)[].name' <<< "$CUERPO"

# Opciones configuradas:
# ----------------------
# $# -lt 2 -> pide la URL del sitio y mi correo
# JIRA_URL="${1%/}" -> quita la / final de la URL
# PROYECTO="${3:-ZBX}" -> clave del proyecto; ZBX si falta
# command -v jq || install -> instala jq solo si falta
# read -r -s -p -> pide el token sin enseñarlo ni dejarlo en el historial
# curl -s -w '\n%{http_code}' -> añade el código HTTP; curl -s no falla aunque Jira dé error
# -u correo:token -> autenticación básica, cifrada por https
# Accept: application/json -> la respuesta en JSON
# /rest/api/2/issue/createmeta/ZBX/issuetypes -> tipos de incidencia del proyecto
# unset JIRA_TOKEN -> borra el token en cuanto deja de hacer falta
# tail -n 1 y sed '$d' -> separan el código HTTP del cuerpo JSON
# != "200" -> 401 son credenciales malas y 404 un proyecto que no existe
# (.issueTypes // .values)[].name -> nombre de cada tipo; la lista viene de las dos formas