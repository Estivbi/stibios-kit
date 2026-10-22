#!/usr/bin/env bash
# Instala los skills de skills.sh del kit en el proyecto actual.
# Uso (desde la raíz del proyecto): /ruta/a/stibios-kit/scripts/skills.sh [--con-refero]
# Edita la lista de abajo para añadir o quitar skills; no instales más de los necesarios.
set -euo pipefail

CON_REFERO=0
[ "${1:-}" = "--con-refero" ] && CON_REFERO=1

# Base de diseño frontend
npx skills add anthropics/skills -s frontend-design
npx skills add nextlevelbuilder/ui-ux-pro-max-skill
npx skills add vercel-labs/agent-skills --skill web-design-guidelines

# Opcional: criterio de movimiento y pulido
# npx skills add emilkowalski/skills

# Investigación de referencias antes de diseñar (la skill funciona sin MCP;
# el MCP de Refero requiere plan Pro, actívalo con install.sh --con-refero)
if [ "$CON_REFERO" -eq 1 ]; then
  npx skills add referodesign/refero_skill --skill refero-design --agent claude-code
fi

echo "Skills instalados."
