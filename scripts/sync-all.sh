#!/usr/bin/env bash
# Propaga los cambios del kit a todos los proyectos registrados en projects.txt.
# Uso: scripts/sync-all.sh [--sin-pull]
# Por defecto hace `git pull --ff-only` en el kit antes de propagar.
# STIBIOS_REGISTRO=<archivo> cambia la lista de proyectos (por defecto, projects.txt del kit).
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRO="${STIBIOS_REGISTRO:-$KIT_DIR/projects.txt}"

[ -f "$REGISTRO" ] || { echo "No hay registro de proyectos ($REGISTRO) todavía." >&2; exit 1; }

case "${1:-}" in
  "") git -C "$KIT_DIR" pull --ff-only 2>/dev/null || echo "(kit sin remoto o sin cambios que traer)" ;;
  --sin-pull) ;;
  *) echo "Uso: $0 [--sin-pull]" >&2; exit 1 ;;
esac

FALLOS=0
while IFS= read -r proyecto || [ -n "$proyecto" ]; do
  [ -z "$proyecto" ] && continue
  if [ -d "$proyecto" ]; then
    echo "→ $proyecto"
    if ! "$KIT_DIR/scripts/install.sh" "$proyecto" >/dev/null; then
      echo "    ✗ install.sh falló en este proyecto (revisa stibios.config.yml); sigo con el siguiente"
      FALLOS=$((FALLOS + 1))
      continue
    fi
    "$KIT_DIR/scripts/doctor.sh" "$proyecto" | grep -E '^(⚠|✗)' | sed 's/^/    /' || true
    if git -C "$proyecto" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$proyecto" status --short .claude CLAUDE.md .mcp.json | sed 's/^/    /'
    fi
  else
    echo "✗ no existe: $proyecto (quítalo de projects.txt)"
  fi
done < "$REGISTRO"

[ "$FALLOS" -eq 0 ] || { echo "$FALLOS proyecto(s) con errores." >&2; exit 1; }
echo "Hecho. Revisa los cambios en cada proyecto y commitea como chore(kit): actualizar base de Stibios."
