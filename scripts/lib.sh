#!/usr/bin/env bash
# Funciones comunes de stibios-kit. Se carga con `source`; no se ejecuta.
# Compatible con bash 3.2 (macOS): sin ${var,,} ni arrays asociativos.

# En bash 5.2+ "&" en el reemplazo de ${var//a/b} tendría significado especial.
shopt -u patsub_replacement 2>/dev/null || true

MODULOS_VALIDOS="ui seguridad devops"
AGENTES_NUCLEO="arquitecto backend documentacion pr-reviewer"

agentes_de_modulo() {
  case "$1" in
    ui) echo "frontend" ;;
    seguridad) echo "seguridad" ;;
    devops) echo "devops" ;;
  esac
}

# cfg_get <archivo> <clave> <defecto>: lee `clave: valor` de un YAML plano.
cfg_get() {
  local archivo="$1" clave="$2" defecto="$3" linea valor
  linea="$(grep -E "^${clave}[[:space:]]*:" "$archivo" 2>/dev/null | head -n1 || true)"
  if [ -z "$linea" ]; then printf '%s' "$defecto"; return; fi
  valor="${linea#*:}"
  valor="$(printf '%s' "$valor" | sed -E 's/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  case "$valor" in \#*) valor="" ;; esac
  valor="${valor#\"}"; valor="${valor%\"}"; valor="${valor#\'}"; valor="${valor%\'}"
  printf '%s' "$valor"
}

cargar_config() { # <archivo>
  local f="$1"
  CFG_MODULOS="$(cfg_get "$f" modulos "ui,seguridad,devops" | tr -d ' ')"
  CFG_TRACKER="$(cfg_get "$f" tracker none)"
  CFG_PREFIJO="$(cfg_get "$f" prefijo_ticket TCK)"
  CFG_TICKET_INICIAL="$(cfg_get "$f" ticket_inicial 1)"
  CFG_RAMA="$(cfg_get "$f" rama_principal main)"
  CFG_FORMATO_RAMA="$(cfg_get "$f" formato_rama "{ticket}/{descripcion}")"
  CFG_FIRMAS="$(cfg_get "$f" firmas prohibir)"
  CFG_PR="$(cfg_get "$f" quien_abre_pr persona)"
}

# Imprime un error por línea y devuelve 1 si la configuración cargada no es válida.
validar_config() {
  local errores=0 m
  err() { printf '%s\n' "$1"; errores=$((errores + 1)); }
  for m in ${CFG_MODULOS//,/ }; do
    case " $MODULOS_VALIDOS " in *" $m "*) ;; *) err "modulos: '$m' no existe (válidos: ${MODULOS_VALIDOS})" ;; esac
  done
  case "$CFG_TRACKER" in none|jira|github|linear) ;; *) err "tracker: '$CFG_TRACKER' no válido (none | jira | github | linear)" ;; esac
  printf '%s' "$CFG_PREFIJO" | grep -qE '^[A-Za-z][A-Za-z0-9]*$' || err "prefijo_ticket: '$CFG_PREFIJO' no válido (letras y números, empieza por letra)"
  printf '%s' "$CFG_TICKET_INICIAL" | grep -qE '^[1-9][0-9]*$' || err "ticket_inicial: '$CFG_TICKET_INICIAL' no válido (entero positivo)"
  printf '%s' "$CFG_RAMA" | grep -qE '^[A-Za-z0-9._/-]+$' || err "rama_principal: '$CFG_RAMA' no válida"
  case "$CFG_FORMATO_RAMA" in *"{ticket}"*"{descripcion}"*) ;; *) err "formato_rama: debe contener {ticket} y {descripcion}, en ese orden" ;; esac
  case "$CFG_FIRMAS" in prohibir|permitir) ;; *) err "firmas: '$CFG_FIRMAS' no válido (prohibir | permitir)" ;; esac
  case "$CFG_PR" in persona|agente) ;; *) err "quien_abre_pr: '$CFG_PR' no válido (persona | agente)" ;; esac
  [ "$errores" -eq 0 ]
}

modulo_activo() { case ",$CFG_MODULOS," in *",$1,"*) return 0 ;; esac; return 1; }

# render: sustituye las variables conocidas (stdin → stdout). Las demás {{...}} se dejan.
render() {
  local t ticket_ej ejemplo bloque_pr bloque_firmas bloque_tickets
  t="$(cat)"
  ticket_ej="$(printf '%s' "$CFG_PREFIJO" | tr '[:upper:]' '[:lower:]')-123"
  ejemplo="${CFG_FORMATO_RAMA//\{ticket\}/$ticket_ej}"
  ejemplo="${ejemplo//\{descripcion\}/configurar-subagentes}"

  case "$CFG_PR" in
    agente) bloque_pr='Al terminar un ticket, el agente abre la PR contra `{{RAMA_PRINCIPAL}}` con título y descripción claros. Solo la persona responsable del proyecto la mergea. No se empieza el siguiente ticket hasta que el anterior está mergeado.' ;;
    *) bloque_pr='Las PRs las crea y las mergea la persona responsable del proyecto. Al terminar un ticket, el agente deja la URL de comparación de GitHub, el título y la descripción para pegar. No se empieza el siguiente ticket hasta que el anterior está mergeado.' ;;
  esac
  case "$CFG_FIRMAS" in
    permitir) bloque_firmas='Se permiten firmas o atribuciones de herramienta en commits y PRs (por ejemplo `Co-Authored-By`). El autor principal es la identidad Git configurada en el repo.' ;;
    *) bloque_firmas='Sin firmas ni atribuciones en commits, PRs ni archivos. El autor es la identidad Git configurada en el repo.' ;;
  esac
  case "$CFG_TRACKER" in
    jira) bloque_tickets='Los tickets se gestionan en Jira con el prefijo `{{PREFIJO}}-<n>`. Se redactan antes en `docs/backlog/` (`/ticket`) y se exportan con `/exportar`.' ;;
    github) bloque_tickets='Los tickets se gestionan en GitHub Issues con el identificador local `{{PREFIJO}}-<n>`. Se redactan antes en `docs/backlog/` (`/ticket`) y se exportan con `/exportar`.' ;;
    linear) bloque_tickets='Los tickets se gestionan en Linear con el prefijo `{{PREFIJO}}-<n>`. Se redactan antes en `docs/backlog/` (`/ticket`) y se exportan con `/exportar`.' ;;
    *) bloque_tickets='Los tickets se identifican como `{{PREFIJO}}-<n>` y se redactan en `docs/backlog/` (`/ticket`).' ;;
  esac

  t="${t//\{\{BLOQUE_PR\}\}/$bloque_pr}"
  t="${t//\{\{BLOQUE_FIRMAS\}\}/$bloque_firmas}"
  t="${t//\{\{BLOQUE_TICKETS\}\}/$bloque_tickets}"
  t="${t//\{\{RAMA_PRINCIPAL\}\}/$CFG_RAMA}"
  t="${t//\{\{FORMATO_RAMA\}\}/$CFG_FORMATO_RAMA}"
  t="${t//\{\{EJEMPLO_RAMA\}\}/$ejemplo}"
  t="${t//\{\{PREFIJO\}\}/$CFG_PREFIJO}"
  t="${t//\{\{PROYECTO\}\}/${PROYECTO:-proyecto}}"
  printf '%s\n' "$t"
}

# componer_base <kit>: núcleo + módulos activos (stdout).
componer_base() {
  local kit="$1" m
  render < "$kit/base/core.md"
  for m in ${CFG_MODULOS//,/ }; do
    printf '\n'
    render < "$kit/base/modulos/$m.md"
  done
}
