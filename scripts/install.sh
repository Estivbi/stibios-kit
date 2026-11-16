#!/usr/bin/env bash
# Instala o actualiza el kit de Stibios en un proyecto.
# Uso: scripts/install.sh <ruta-del-proyecto> [--modulos ui,seguridad,devops] [--con-refero] [--force-agents]
#
# - stibios.config.yml: se crea si falta y nunca se sobrescribe. Define módulos y reglas.
# - base.md: se genera siempre desde el núcleo + módulos activos (lo gestiona el kit).
# - comandos: siempre se sobrescriben (los gestiona el kit).
# - agentes: solo se copian los que faltan (el proyecto puede personalizarlos),
#   salvo con --force-agents. Solo los del núcleo y de los módulos activos.
# - AGENTS.md, CLAUDE.md, DESIGN.md: nunca se sobrescriben si ya existen.
# - .mcp.json: se fusiona sin pisar lo que ya hubiera (Playwright con `ui`; Jira/Linear según `tracker`).
# - .claude/stibios/backlog.sh y ticket.md: herramientas del backlog, gestionadas por el kit.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$KIT_DIR/scripts/lib.sh"

USO="Uso: $0 <ruta-del-proyecto> [--modulos ui,seguridad,devops] [--con-refero] [--force-agents]"
DEST="${1:-}"
CON_REFERO=0
FORCE_AGENTS=0
MODULOS_FLAG=""
MODULOS_FLAG_DADO=0

[ -n "$DEST" ] || { echo "$USO" >&2; exit 1; }
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --con-refero) CON_REFERO=1 ;;
    --force-agents) FORCE_AGENTS=1 ;;
    --modulos)
      [ $# -ge 2 ] || { echo "--modulos necesita un valor (puede ir vacío: \"\")" >&2; exit 1; }
      MODULOS_FLAG="$2"; MODULOS_FLAG_DADO=1; shift ;;
    *) echo "Opción desconocida: $1" >&2; echo "$USO" >&2; exit 1 ;;
  esac
  shift
done

[ -d "$DEST" ] || { echo "No existe la carpeta: $DEST" >&2; exit 1; }
DEST="$(cd "$DEST" && pwd)"
PROYECTO="$(basename "$DEST")"
CONFIG="$DEST/stibios.config.yml"

# 0. Configuración (se crea solo si falta)
if [ ! -f "$CONFIG" ]; then
  cargar_config /dev/null
  render < "$KIT_DIR/templates/stibios.config.yml" > "$CONFIG"
  if [ "$MODULOS_FLAG_DADO" -eq 1 ]; then
    while IFS= read -r linea || [ -n "$linea" ]; do
      case "$linea" in
        modulos:*) printf 'modulos: %s\n' "$MODULOS_FLAG" ;;
        *) printf '%s\n' "$linea" ;;
      esac
    done < "$CONFIG" > "$CONFIG.tmp"
    mv "$CONFIG.tmp" "$CONFIG"
  fi
  echo "  creado: stibios.config.yml"
elif [ "$MODULOS_FLAG_DADO" -eq 1 ]; then
  echo "  aviso: --modulos se ignora porque stibios.config.yml ya existe; edítalo a mano" >&2
fi

cargar_config "$CONFIG"
if ! ERRORES="$(validar_config)"; then
  echo "stibios.config.yml no es válido:" >&2
  while IFS= read -r l; do printf '  - %s\n' "$l" >&2; done <<< "$ERRORES"
  exit 1
fi

mkdir -p "$DEST/.claude/stibios" "$DEST/.claude/agents" "$DEST/.claude/commands"

# 1. Base (generada) y comandos (gestionados por el kit)
componer_base "$KIT_DIR" > "$DEST/.claude/stibios/base.md"
for f in "$KIT_DIR"/commands/*.md; do
  cp "$f" "$DEST/.claude/commands/$(basename "$f")"
done
# herramientas del backlog (las usan /ticket y /exportar sin necesitar el kit)
cp "$KIT_DIR/scripts/backlog.sh" "$KIT_DIR/scripts/lib.sh" "$KIT_DIR/templates/ticket.md" "$DEST/.claude/stibios/"
chmod +x "$DEST/.claude/stibios/backlog.sh"

# 2. Agentes del núcleo y de los módulos activos (solo los que faltan)
AGENTES="$AGENTES_NUCLEO"
for m in ${CFG_MODULOS//,/ }; do AGENTES="$AGENTES $(agentes_de_modulo "$m")"; done
for nombre in $AGENTES; do
  origen="$KIT_DIR/agents/$nombre.md"
  target="$DEST/.claude/agents/$nombre.md"
  if [ ! -f "$target" ] || [ "$FORCE_AGENTS" -eq 1 ]; then
    cp "$origen" "$target"
    echo "  agente: $nombre.md"
  fi
done

# 3. Plantillas (solo si no existen)
copiar_plantilla() {
  local nombre="$1"
  if [ ! -f "$DEST/$nombre" ]; then
    render < "$KIT_DIR/templates/$nombre" > "$DEST/$nombre"
    echo "  creado: $nombre (rellena los {{...}})"
  else
    echo "  existe: $nombre (no se toca)"
  fi
}
copiar_plantilla "AGENTS.md"
modulo_activo ui && copiar_plantilla "DESIGN.md"

# CLAUDE.md: si existe, solo asegura los imports; si no, copia la plantilla
if [ -f "$DEST/CLAUDE.md" ]; then
  grep -q '@.claude/stibios/base.md' "$DEST/CLAUDE.md" || {
    printf '\n@.claude/stibios/base.md\n' >> "$DEST/CLAUDE.md"
    echo "  CLAUDE.md: añadido import de la base"
  }
  [ -f "$DEST/AGENTS.md" ] && { grep -q '@AGENTS.md' "$DEST/CLAUDE.md" || printf '@AGENTS.md\n' >> "$DEST/CLAUDE.md"; }
else
  cp "$KIT_DIR/templates/CLAUDE.md" "$DEST/CLAUDE.md"
  echo "  creado: CLAUDE.md"
fi

# 4. MCP (fusión sin pisar); solo con el módulo ui
fusionar_mcp() {
  local origen="$1"
  local destino="$DEST/.mcp.json"
  if [ ! -f "$destino" ]; then
    cp "$origen" "$destino"
  elif command -v jq >/dev/null 2>&1; then
    # lo que ya había en el proyecto manda sobre el kit
    jq -s '{mcpServers: (.[1].mcpServers + .[0].mcpServers)} as $m | .[0] * $m' \
      "$destino" "$origen" > "$destino.tmp"
    # solo se reescribe si cambia el contenido (evita ruido de formato en el diff)
    if [ "$(jq -S . "$destino.tmp")" = "$(jq -S . "$destino")" ]; then
      rm -f "$destino.tmp"
    else
      mv "$destino.tmp" "$destino"
    fi
  else
    echo "  aviso: instala jq para fusionar .mcp.json; añade a mano $(basename "$origen")" >&2
  fi
}
if modulo_activo ui; then
  fusionar_mcp "$KIT_DIR/mcp/ui.mcp.json"
  [ "$CON_REFERO" -eq 1 ] && fusionar_mcp "$KIT_DIR/mcp/refero.mcp.json"
elif [ "$CON_REFERO" -eq 1 ]; then
  echo "  aviso: --con-refero necesita el módulo ui; actívalo en stibios.config.yml" >&2
fi

# MCP del tracker (Jira / Linear); GitHub usa la CLI `gh`
case "$CFG_TRACKER" in
  jira) fusionar_mcp "$KIT_DIR/mcp/jira.mcp.json" ;;
  linear) fusionar_mcp "$KIT_DIR/mcp/linear.mcp.json" ;;
esac

# 5. Versión instalada
VERSION="sin-git"
if git -C "$KIT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
  VERSION="$(git -C "$KIT_DIR" rev-parse --short HEAD)"
fi
printf '%s\n' "$VERSION" > "$DEST/.claude/stibios/.kit-version"

# 6. Registro de proyectos (para sync-all.sh)
REGISTRO="$KIT_DIR/projects.txt"
touch "$REGISTRO"
grep -qxF "$DEST" "$REGISTRO" || printf '%s\n' "$DEST" >> "$REGISTRO"

echo "Kit instalado en $DEST (versión $VERSION, módulos: ${CFG_MODULOS:-ninguno})"
echo "Siguiente paso: rellena AGENTS.md$(modulo_activo ui && echo ' y DESIGN.md'), y ejecuta scripts/doctor.sh $DEST para comprobarlo."
