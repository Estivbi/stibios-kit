#!/usr/bin/env bash
# Comprueba que un proyecto tiene el kit bien instalado y configurado.
# Uso: scripts/doctor.sh [ruta-del-proyecto]   (por defecto, la carpeta actual)
# Sale con código 1 si hay errores (✗); los avisos (⚠) no fallan.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$KIT_DIR/scripts/lib.sh"

DEST="${1:-.}"
[ -d "$DEST" ] || { echo "No existe la carpeta: $DEST" >&2; exit 1; }
DEST="$(cd "$DEST" && pwd)"
PROYECTO="$(basename "$DEST")"
ERRORES=0
AVISOS=0

ok()    { printf '✓ %s\n' "$1"; }
aviso() { printf '⚠ %s\n' "$1"; AVISOS=$((AVISOS + 1)); }
fallo() { printf '✗ %s\n' "$1"; ERRORES=$((ERRORES + 1)); }

echo "Comprobando $DEST"

# 1. Configuración
CONFIG="$DEST/stibios.config.yml"
if [ ! -f "$CONFIG" ]; then
  fallo "falta stibios.config.yml (ejecuta scripts/install.sh $DEST)"
  echo; echo "$ERRORES error(es), $AVISOS aviso(s)"; exit 1
fi
cargar_config "$CONFIG"
if ERR_CFG="$(validar_config)"; then
  ok "stibios.config.yml válido (módulos: ${CFG_MODULOS:-ninguno})"
else
  while IFS= read -r l; do fallo "stibios.config.yml → $l"; done <<< "$ERR_CFG"
  echo; echo "$ERRORES error(es), $AVISOS aviso(s)"; exit 1
fi

# 2. Archivos del proyecto
for f in CLAUDE.md AGENTS.md .claude/stibios/base.md; do
  if [ -f "$DEST/$f" ]; then ok "existe $f"; else fallo "falta $f"; fi
done
if modulo_activo ui; then
  if [ -f "$DEST/DESIGN.md" ]; then ok "existe DESIGN.md"; else fallo "falta DESIGN.md (módulo ui activo)"; fi
fi

# 3. Placeholders sin rellenar
for f in AGENTS.md DESIGN.md; do
  [ -f "$DEST/$f" ] || continue
  [ "$f" = "DESIGN.md" ] && ! modulo_activo ui && continue
  n="$(grep -c '{{' "$DEST/$f" || true)"
  if [ "$n" -gt 0 ]; then aviso "$f tiene $n línea(s) con {{...}} sin rellenar"; else ok "$f sin placeholders"; fi
done

# 4. Imports de CLAUDE.md
if [ -f "$DEST/CLAUDE.md" ]; then
  for imp in '@AGENTS.md' '@.claude/stibios/base.md'; do
    if grep -qF "$imp" "$DEST/CLAUDE.md"; then ok "CLAUDE.md importa $imp"; else fallo "CLAUDE.md no importa $imp"; fi
  done
fi

# 5. base.md al día respecto a la configuración y al kit
if [ -f "$DEST/.claude/stibios/base.md" ]; then
  if componer_base "$KIT_DIR" | cmp -s - "$DEST/.claude/stibios/base.md"; then
    ok "base.md al día"
  else
    aviso "base.md desactualizado o editado a mano (ejecuta scripts/install.sh $DEST)"
  fi
fi

# 6. Agentes y comandos
AGENTES="$AGENTES_NUCLEO"
for m in ${CFG_MODULOS//,/ }; do AGENTES="$AGENTES $(agentes_de_modulo "$m")"; done
for a in $AGENTES; do
  [ -f "$DEST/.claude/agents/$a.md" ] || fallo "falta el agente $a"
done
for m in $MODULOS_VALIDOS; do
  modulo_activo "$m" && continue
  a="$(agentes_de_modulo "$m")"
  [ -f "$DEST/.claude/agents/$a.md" ] && aviso "el agente $a sigue en el proyecto pero el módulo $m está desactivado"
done
for c in "$KIT_DIR"/commands/*.md; do
  [ -f "$DEST/.claude/commands/$(basename "$c")" ] || fallo "falta el comando /$(basename "$c" .md)"
done

# 6b. Herramientas del backlog y tickets
for h in backlog.sh lib.sh; do
  if [ ! -f "$DEST/.claude/stibios/$h" ]; then fallo "falta .claude/stibios/$h (ejecuta scripts/install.sh $DEST)"
  elif ! cmp -s "$KIT_DIR/scripts/$h" "$DEST/.claude/stibios/$h"; then aviso ".claude/stibios/$h desactualizado (ejecuta scripts/install.sh $DEST)"
  fi
done
if [ -d "$DEST/docs/backlog" ] && [ -f "$DEST/.claude/stibios/backlog.sh" ]; then
  if SAL="$(cd "$DEST" && bash .claude/stibios/backlog.sh validar)"; then
    ok "backlog válido ($(printf '%s' "$SAL" | tail -n1))"
  else
    while IFS= read -r l; do case "$l" in ✗*) fallo "backlog → ${l#✗ }" ;; esac; done <<< "$SAL"
  fi
fi

# 7. MCP
if [ -f "$DEST/.mcp.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    if jq -e . "$DEST/.mcp.json" >/dev/null 2>&1; then
      ok ".mcp.json es JSON válido"
      if modulo_activo ui && ! jq -e '.mcpServers.playwright' "$DEST/.mcp.json" >/dev/null 2>&1; then
        aviso ".mcp.json no tiene el servidor playwright (módulo ui)"
      fi
      if grep -q '@latest' "$DEST/.mcp.json"; then
        aviso ".mcp.json usa @latest: fija la versión (el kit usa $(jq -r '.mcpServers.playwright.args[1]' "$KIT_DIR/mcp/ui.mcp.json"))"
      fi
    else
      fallo ".mcp.json no es JSON válido"
    fi
  else
    aviso "jq no instalado: no se valida .mcp.json"
  fi
elif modulo_activo ui; then
  aviso "falta .mcp.json (módulo ui)"
fi
case "$CFG_TRACKER" in
  jira|linear)
    srv="$(jq -r '.mcpServers | keys[0]' "$KIT_DIR/mcp/$CFG_TRACKER.mcp.json" 2>/dev/null || echo "$CFG_TRACKER")"
    if ! { [ -f "$DEST/.mcp.json" ] && grep -q "\"$srv\"" "$DEST/.mcp.json"; }; then
      aviso "tracker $CFG_TRACKER sin MCP '$srv' en .mcp.json (ejecuta scripts/install.sh $DEST)"
    fi ;;
esac

# 8. Versión del kit
if [ -f "$DEST/.claude/stibios/.kit-version" ] && git -C "$KIT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
  inst="$(cat "$DEST/.claude/stibios/.kit-version")"
  act="$(git -C "$KIT_DIR" rev-parse --short HEAD)"
  if [ "$inst" = "$act" ]; then ok "kit en la versión $act"; else aviso "el proyecto tiene el kit $inst y el kit actual es $act"; fi
fi

echo
echo "$ERRORES error(es), $AVISOS aviso(s)"
[ "$ERRORES" -eq 0 ]
