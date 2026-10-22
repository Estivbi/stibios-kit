#!/usr/bin/env bash
# Propaga los cambios del kit a todos los proyectos registrados en projects.txt.
# Uso: scripts/sync-all.sh   (haz antes `git pull` en el kit)
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRO="$KIT_DIR/projects.txt"

[ -f "$REGISTRO" ] || { echo "No hay projects.txt todavía." >&2; exit 1; }

git -C "$KIT_DIR" pull --ff-only 2>/dev/null || echo "(kit sin remoto o sin cambios que traer)"

while IFS= read -r proyecto || [ -n "$proyecto" ]; do
  [ -z "$proyecto" ] && continue
  if [ -d "$proyecto" ]; then
    echo "→ $proyecto"
    "$KIT_DIR/scripts/install.sh" "$proyecto" >/dev/null
    if git -C "$proyecto" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$proyecto" status --short .claude CLAUDE.md .mcp.json | sed 's/^/    /'
    fi
  else
    echo "✗ no existe: $proyecto (quítalo de projects.txt)"
  fi
done < "$REGISTRO"

echo "Hecho. Revisa los cambios en cada proyecto y commitea como chore(kit): actualizar base de Stibios."
