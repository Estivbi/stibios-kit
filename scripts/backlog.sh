#!/usr/bin/env bash
# Gestiona el backlog de tickets de un proyecto (docs/backlog/*.md).
# Se ejecuta desde la raíz del proyecto: bash .claude/stibios/backlog.sh <comando>
#
#   listar                          tabla de tickets
#   nuevo <título> [tipo] [prior.]  crea docs/backlog/<ID>.md desde la plantilla (imprime la ruta)
#   validar                         comprueba front-matter, enlaces y criterios (exit 1 si hay errores)
#   campo <ID> <clave>              valor de un campo del front-matter
#   cuerpo <ID>                     texto del ticket sin front-matter
#   csv <jira|linear> [ID...]       CSV importable (por defecto, los tickets en estado `listo`)
#   marcar <ID> <externo> [url]     registra el ticket externo y pasa el estado a `exportado`
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$AQUI/lib.sh"

RAIZ="${STIBIOS_PROYECTO:-$PWD}"
BACKLOG="$RAIZ/docs/backlog"
if [ -f "$AQUI/ticket.md" ]; then PLANTILLA="$AQUI/ticket.md"; else PLANTILLA="$AQUI/../templates/ticket.md"; fi

TIPOS="epica historia tarea bug subtarea"
PRIORIDADES="alta media baja"
ESTADOS="borrador listo exportado"

die() { echo "backlog: $1" >&2; exit 1; }
en_lista() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

config() {
  local f="$RAIZ/stibios.config.yml"
  [ -f "$f" ] || die "no hay stibios.config.yml en $RAIZ (ejecuta install.sh del kit)"
  cargar_config "$f"
}

archivo_de() { # <ID> → ruta o error
  printf '%s' "$1" | grep -qE '^[A-Za-z][A-Za-z0-9]*-[0-9]+$' || die "ID no válido: $1"
  [ -f "$BACKLOG/$1.md" ] || die "no existe $BACKLOG/$1.md"
  printf '%s' "$BACKLOG/$1.md"
}

frontmatter() { awk 'NR==1 && !/^---[[:space:]]*$/ {exit} NR==1 {next} /^---[[:space:]]*$/ {exit} {print}' "$1"; }

valor() { # <archivo> <clave>
  local linea v
  linea="$(frontmatter "$1" | grep -E "^$2[[:space:]]*:" | head -n1 || true)"
  v="${linea#*:}"
  v="$(printf '%s' "$v" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  case "$v" in
    \"*) v="${v#\"}"; v="${v%%\"*}" ;;
    *) v="$(printf '%s' "$v" | sed -E 's/[[:space:]]+#.*$//; s/^#.*$//; s/[[:space:]]+$//')" ;;
  esac
  printf '%s' "$v"
}

lista() { # <archivo> <clave> → un elemento por línea
  valor "$1" "$2" | sed -E 's/^\[//; s/\]$//' | tr ',' '\n' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$' || true
}

cuerpo_de() { # texto tras el front-matter (o el archivo entero si no lo tiene)
  if head -n1 "$1" | grep -q '^---[[:space:]]*$'; then
    # quita el front-matter y la línea en blanco que lo sigue (awk: el sed de BSD no admite `1{/^$/d}`)
    awk 'n < 2 && /^---[[:space:]]*$/ {n++; next} n >= 2 && !c++ && /^$/ {next} n >= 2 {print}' "$1"
  else
    cat "$1"
  fi
}

archivos() { local f; for f in "$BACKLOG"/*.md; do [ -f "$f" ] && printf '%s\n' "$f"; done; return 0; }

siguiente_id() {
  config
  local max=0 f b n
  for f in "$BACKLOG/$CFG_PREFIJO"-*.md "$RAIZ/docs/specs/$CFG_PREFIJO"-*.md "$RAIZ/docs/tickets/$CFG_PREFIJO"-*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"; n="${b#"$CFG_PREFIJO"-}"; n="${n%%[!0-9]*}"
    if [ -n "$n" ] && [ "$n" -gt "$max" ]; then max="$n"; fi
  done
  n=$((max + 1))
  if [ "$n" -lt "$CFG_TICKET_INICIAL" ]; then n="$CFG_TICKET_INICIAL"; fi
  printf '%s-%s' "$CFG_PREFIJO" "$n"
}

cmd_listar() {
  local f
  printf '%-10s %-9s %-8s %-10s %s\n' ID TIPO PRIORIDAD ESTADO TITULO
  archivos | while IFS= read -r f; do
    printf '%-10s %-9s %-8s %-10s %s\n' "$(valor "$f" id)" "$(valor "$f" tipo)" "$(valor "$f" prioridad)" "$(valor "$f" estado)" "$(valor "$f" titulo)"
  done
}

cmd_nuevo() {
  local titulo="${1:-}" tipo="${2:-historia}" prior="${3:-media}" id ruta t comilla
  [ -n "$titulo" ] || die "uso: nuevo <título> [tipo] [prioridad]"
  en_lista "$tipo" "$TIPOS" || die "tipo no válido: $tipo ($TIPOS)"
  en_lista "$prior" "$PRIORIDADES" || die "prioridad no válida: $prior ($PRIORIDADES)"
  comilla="'"   # en bash 3.2, ${var//x/\'} conserva la barra; con una variable es portable
  titulo="${titulo//\"/$comilla}"
  id="$(siguiente_id)"
  mkdir -p "$BACKLOG"
  ruta="$BACKLOG/$id.md"
  [ ! -e "$ruta" ] || die "ya existe $ruta"
  t="$(cat "$PLANTILLA")"
  t="${t//\{\{ID\}\}/$id}"
  t="${t//\{\{TITULO\}\}/$titulo}"
  t="${t//\{\{TIPO\}\}/$tipo}"
  t="${t//\{\{PRIORIDAD\}\}/$prior}"
  printf '%s\n' "$t" > "$ruta"
  printf '%s\n' "docs/backlog/$id.md"
}

cmd_validar() {
  local errores=0 avisos=0 f id base tipo prior estado padre d k cuerpo
  e() { printf '✗ %s: %s\n' "$base" "$1"; errores=$((errores + 1)); }
  w() { printf '⚠ %s: %s\n' "$base" "$1"; avisos=$((avisos + 1)); }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f" .md)"
    if [ -z "$(frontmatter "$f")" ]; then e "sin front-matter"; continue; fi
    for k in id titulo tipo prioridad estado; do
      [ -n "$(valor "$f" "$k")" ] || e "falta el campo '$k'"
    done
    id="$(valor "$f" id)"; tipo="$(valor "$f" tipo)"; prior="$(valor "$f" prioridad)"
    estado="$(valor "$f" estado)"; padre="$(valor "$f" padre)"
    [ -z "$id" ] || [ "$id" = "$base" ] || e "el id '$id' no coincide con el nombre del archivo"
    [ -z "$tipo" ] || en_lista "$tipo" "$TIPOS" || e "tipo '$tipo' no válido ($TIPOS)"
    [ -z "$prior" ] || en_lista "$prior" "$PRIORIDADES" || e "prioridad '$prior' no válida ($PRIORIDADES)"
    [ -z "$estado" ] || en_lista "$estado" "$ESTADOS" || e "estado '$estado' no válido ($ESTADOS)"
    if [ -n "$padre" ]; then
      [ "$padre" != "$base" ] || e "es su propio padre"
      [ -f "$BACKLOG/$padre.md" ] || e "el padre '$padre' no existe en docs/backlog/"
    elif [ "$tipo" = "subtarea" ]; then
      e "una subtarea necesita 'padre'"
    fi
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      [ -f "$BACKLOG/$d.md" ] || e "la dependencia '$d' no existe en docs/backlog/"
    done <<< "$(lista "$f" dependencias)"
    cuerpo="$(cuerpo_de "$f")"
    if [ "$tipo" != "epica" ]; then
      if ! printf '%s' "$cuerpo" | grep -qi 'dado' || ! printf '%s' "$cuerpo" | grep -qi 'entonces'; then
        if [ "$estado" = "borrador" ]; then w "sin criterios dado / cuando / entonces"; else e "sin criterios dado / cuando / entonces (obligatorios fuera del estado borrador)"; fi
      fi
    fi
    if printf '%s' "$cuerpo" | grep -qF 'Qué se quiere conseguir y por qué, en 2-5 frases' \
      || { [ "$tipo" != "epica" ] && printf '%s' "$cuerpo" | grep -qF 'un contexto, **cuando** ocurre algo'; }; then
      if [ "$estado" = "borrador" ]; then w "descripción o criterios sin completar (texto de la plantilla)"; else e "descripción o criterios sin completar (texto de la plantilla)"; fi
    fi
    if [ "$estado" = "exportado" ] && [ -z "$(valor "$f" externo)" ]; then e "estado exportado sin 'externo'"; fi
  done <<< "$(archivos)"
  if [ -z "$(archivos)" ]; then echo "(sin tickets en docs/backlog/)"; fi
  echo "$errores error(es), $avisos aviso(s)"
  [ "$errores" -eq 0 ]
}

cmd_campo() { local f; f="$(archivo_de "${1:-}")"; valor "$f" "${2:?uso: campo <ID> <clave>}"; printf '\n'; }
cmd_cuerpo() { local f; f="$(archivo_de "${1:-}")"; cuerpo_de "$f"; }

csv_celda() { # escapa según RFC 4180
  local s="$1" dq='"'
  s="${s//$dq/$dq$dq}"
  printf '"%s"' "$s"
}

orden_tipos() { echo "epica historia tarea bug subtarea"; }

seleccion() { # IDs explícitos o los `listo`, ordenados épica → subtarea
  local t f id
  if [ $# -gt 0 ]; then
    for t in $(orden_tipos); do
      for id in "$@"; do
        f="$(archivo_de "$id")"
        [ "$(valor "$f" tipo)" = "$t" ] && printf '%s\n' "$f"
      done
    done
  else
    for t in $(orden_tipos); do
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        [ "$(valor "$f" tipo)" = "$t" ] && [ "$(valor "$f" estado)" = "listo" ] && printf '%s\n' "$f"
      done <<< "$(archivos)"
    done
  fi
  return 0
}

cmd_csv() {
  local destino="${1:-}"; shift || true
  case "$destino" in jira|linear) ;; *) die "uso: csv <jira|linear> [ID...]" ;; esac
  local ficheros f nl=0 max=0 cab i e tipo prior etq
  ficheros="$(seleccion "$@")"
  [ -n "$ficheros" ] || die "no hay tickets para exportar (estado 'listo' o IDs explícitos)"
  if [ "$destino" = "jira" ]; then
    while IFS= read -r f; do nl="$(lista "$f" etiquetas | grep -c . || true)"; [ "$nl" -gt "$max" ] && max="$nl"; done <<< "$ficheros"
    [ "$max" -ge 1 ] || max=1
    cab='Issue id,Issue Type,Summary,Priority,Description,Parent,Story point estimate'
    i=0; while [ "$i" -lt "$max" ]; do cab="$cab,Labels"; i=$((i + 1)); done
    echo "$cab"
  else
    echo 'Title,Description,Priority,Labels,Estimate'
  fi
  while IFS= read -r f; do
    tipo="$(valor "$f" tipo)"; prior="$(valor "$f" prioridad)"; e="$(valor "$f" estimacion)"
    local desc; desc="$(cuerpo_de "$f")"$'\n\n'"Ref: $(valor "$f" id)"
    if [ "$destino" = "jira" ]; then
      case "$tipo" in epica) tipo=Epic ;; historia) tipo=Story ;; tarea) tipo=Task ;; bug) tipo=Bug ;; subtarea) tipo=Sub-task ;; esac
      case "$prior" in alta) prior=High ;; media) prior=Medium ;; baja) prior=Low ;; esac
      printf '%s,%s,%s,%s,%s,%s,%s' "$(csv_celda "$(valor "$f" id)")" "$(csv_celda "$tipo")" "$(csv_celda "$(valor "$f" titulo)")" \
        "$(csv_celda "$prior")" "$(csv_celda "$desc")" "$(csv_celda "$(valor "$f" padre)")" "$(csv_celda "$e")"
      i=0; etq="$(lista "$f" etiquetas)"
      while [ "$i" -lt "$max" ]; do
        printf ',%s' "$(csv_celda "$(printf '%s\n' "$etq" | sed -n "$((i + 1))p")")"; i=$((i + 1))
      done
      printf '\n'
    else
      case "$prior" in alta) prior=High ;; media) prior=Medium ;; baja) prior=Low ;; esac
      etq="$(lista "$f" etiquetas | paste -sd, -)"
      printf '%s,%s,%s,%s,%s\n' "$(csv_celda "$(valor "$f" titulo)")" "$(csv_celda "$desc")" "$(csv_celda "$prior")" "$(csv_celda "$etq")" "$(csv_celda "$e")"
    fi
  done <<< "$ficheros"
}

cmd_marcar() {
  local f; f="$(archivo_de "${1:-}")"
  local ext="${2:?uso: marcar <ID> <externo> [url]}" url="${3:-}"
  EXT="$ext" URL="$url" awk '
    /^---[[:space:]]*$/ { n++ }
    n == 1 && /^externo:/ { print "externo: " ENVIRON["EXT"]; next }
    n == 1 && /^url:/     { print "url: " ENVIRON["URL"]; next }
    n == 1 && /^estado:/  { print "estado: exportado"; next }
    { print }' "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
  echo "$1 → $ext"
}

CMD="${1:-}"; [ $# -gt 0 ] && shift
case "$CMD" in
  listar) cmd_listar ;;
  nuevo) cmd_nuevo "$@" ;;
  validar) cmd_validar ;;
  campo) cmd_campo "$@" ;;
  cuerpo) cmd_cuerpo "$@" ;;
  csv) cmd_csv "$@" ;;
  marcar) cmd_marcar "$@" ;;
  *) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 1 ;;
esac
