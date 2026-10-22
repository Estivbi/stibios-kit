#!/usr/bin/env bash
# Instala o actualiza el kit de Stibios en un proyecto.
# Uso: scripts/install.sh <ruta-del-proyecto> [--con-refero] [--force-agents]
#
# - base.md y comandos: siempre se sobrescriben (los gestiona el kit).
# - agentes: solo se copian los que faltan (el proyecto puede personalizarlos),
#   salvo con --force-agents.
# - AGENTS.md, CLAUDE.md, DESIGN.md: nunca se sobrescriben si ya existen.
# - .mcp.json: se fusiona sin pisar lo que ya hubiera.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"
CON_REFERO=0
FORCE_AGENTS=0

if [ -z "$DEST" ]; then
  echo "Uso: $0 <ruta-del-proyecto> [--con-refero] [--force-agents]" >&2
  exit 1
fi
shift
for arg in "$@"; do
  case "$arg" in
    --con-refero) CON_REFERO=1 ;;
    --force-agents) FORCE_AGENTS=1 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
  esac
done

[ -d "$DEST" ] || { echo "No existe la carpeta: $DEST" >&2; exit 1; }
DEST="$(cd "$DEST" && pwd)"
PROYECTO="$(basename "$DEST")"

mkdir -p "$DEST/.claude/stibios" "$DEST/.claude/agents" "$DEST/.claude/commands"

# 1. Base y comandos (gestionados por el kit)
cp "$KIT_DIR/base/base.md" "$DEST/.claude/stibios/base.md"
for f in "$KIT_DIR"/commands/*.md; do
  cp "$f" "$DEST/.claude/commands/$(basename "$f")"
done

# 2. Agentes (solo los que faltan)
for f in "$KIT_DIR"/agents/*.md; do
  target="$DEST/.claude/agents/$(basename "$f")"
  if [ ! -f "$target" ] || [ "$FORCE_AGENTS" -eq 1 ]; then
    cp "$f" "$target"
    echo "  agente: $(basename "$f")"
  fi
done

# 3. Plantillas (solo si no existen)
copiar_plantilla() {
  local nombre="$1"
  if [ ! -f "$DEST/$nombre" ]; then
    # sustituye el nombre del proyecto sin usar sed -i (compatible con macOS)
    while IFS= read -r linea || [ -n "$linea" ]; do
      printf '%s\n' "${linea//\{\{PROYECTO\}\}/$PROYECTO}"
    done < "$KIT_DIR/templates/$nombre" > "$DEST/$nombre"
    echo "  creado: $nombre (rellena los {{...}})"
  else
    echo "  existe: $nombre (no se toca)"
  fi
}
copiar_plantilla "AGENTS.md"
copiar_plantilla "DESIGN.md"

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

# 4. MCP (fusión sin pisar)
fusionar_mcp() {
  local origen="$1"
  local destino="$DEST/.mcp.json"
  if [ ! -f "$destino" ]; then
    cp "$origen" "$destino"
  elif command -v jq >/dev/null 2>&1; then
    jq -s '.[0] * .[1] | .mcpServers = (.[1].mcpServers + .[0].mcpServers)' \
      <(cat "$destino") <(cat "$origen") > "$destino.tmp" 2>/dev/null \
      || jq -s '{mcpServers: (.[1].mcpServers + .[0].mcpServers)}' "$destino" "$origen" > "$destino.tmp"
    mv "$destino.tmp" "$destino"
  else
    echo "  aviso: instala jq para fusionar .mcp.json; añade a mano $(basename "$origen")" >&2
  fi
}
fusionar_mcp "$KIT_DIR/mcp/base.mcp.json"
[ "$CON_REFERO" -eq 1 ] && fusionar_mcp "$KIT_DIR/mcp/refero.mcp.json"

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

echo "Kit instalado en $DEST (versión $VERSION)"
echo "Siguiente paso: rellena AGENTS.md y DESIGN.md, y ejecuta scripts/skills.sh en el proyecto."
