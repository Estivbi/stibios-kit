# stibios-kit

Base común para tus proyectos con Claude Code: flujo SDD/TDD, agentes, comandos, MCP y skills de diseño. Se instala en proyectos nuevos y se sincroniza en los existentes.

## Contenido

| Carpeta | Qué es | Al instalar |
|---|---|---|
| `base/` | `core.md` (SDD/TDD, ramas, commits, seguridad) y `modulos/` (`ui`, `seguridad`, `devops`) | Se **genera** `.claude/stibios/base.md` según la configuración; se regenera en cada sync |
| `agents/` | Agentes genéricos. Núcleo: arquitecto, backend, documentacion, pr-reviewer. Por módulo: frontend (`ui`), seguridad, devops | Solo se copian los que faltan y los de módulos activos |
| `commands/` | `/spec`, `/plan`, `/tasks`, `/test` | Se sobrescriben en cada sync |
| `templates/` | `stibios.config.yml`, `AGENTS.md`, `CLAUDE.md`, `DESIGN.md` (solo con `ui`) | Solo si no existen |
| `mcp/` | `ui.mcp.json` (Playwright, módulo `ui`) y `refero.mcp.json` (opcional, plan Pro) | Se fusiona con `.mcp.json` sin pisar |
| `scripts/` | `install.sh`, `sync-all.sh`, `doctor.sh`, `skills.sh` | — |

## Requisitos

- Bash (en Windows, usa WSL), `git` y `jq` (para fusionar `.mcp.json`).
- Node.js (`npx`) para el MCP de Playwright y para `skills.sh`.
- [Claude Code](https://claude.com/claude-code). `AGENTS.md` es un formato que leen también otras herramientas, pero `agents/` y `commands/` son específicos de Claude Code.

## Instalación del kit

```bash
git clone https://github.com/estivbi/stibios-kit.git
export STIBIOS_KIT="$PWD/stibios-kit"   # añádelo a tu shell para reutilizarlo
```

## Configuración

Cada proyecto tiene un `stibios.config.yml` en la raíz. `install.sh` lo crea con valores por defecto y no lo vuelve a tocar.

```yaml
modulos: ui, seguridad, devops   # vacío = solo el núcleo
tracker: none                    # none | jira | github | linear
prefijo_ticket: TCK
rama_principal: main
formato_rama: "{ticket}/{descripcion}"
firmas: prohibir                 # prohibir | permitir
quien_abre_pr: persona           # persona | agente
```

| Módulo | Añade |
|---|---|
| `ui` | Agente `frontend`, `DESIGN.md`, reglas de diseño y de tests de interfaz, MCP de Playwright |
| `seguridad` | Agente `seguridad` y su regla de revisión antes de la PR |
| `devops` | Agente `devops` y su regla de CI |

Tras editar la configuración, ejecuta `install.sh` otra vez: regenera `base.md` y copia los agentes de los módulos nuevos. Un proyecto sin interfaz: `install.sh . --modulos seguridad,devops`.

## Proyecto nuevo

```bash
mkdir mi-proyecto && cd mi-proyecto && git init
"$STIBIOS_KIT/scripts/install.sh" .
"$STIBIOS_KIT/scripts/skills.sh"      # skills de diseño de skills.sh
# rellena AGENTS.md (stack, estructura) y DESIGN.md (tokens)
"$STIBIOS_KIT/scripts/doctor.sh" .      # comprueba la instalación
```

## Proyecto que ya existe

```bash
"$STIBIOS_KIT/scripts/install.sh" ~/proyectos/mi-proyecto
```

No pisa `AGENTS.md`, `CLAUDE.md` ni `DESIGN.md`. Añade los imports que falten a tu `CLAUDE.md` y fusiona `.mcp.json`. Revisa el diff y commitea como `chore(kit): incorporar base de Stibios`.

## Comprobar un proyecto

`scripts/doctor.sh [ruta]` verifica la configuración, los archivos y los imports, avisa de `{{...}}` sin rellenar, de una `base.md` desactualizada o editada a mano, y de un `.mcp.json` inválido. Sale con error si algo falla; `sync-all.sh` lo ejecuta por ti.

## Cambiar la forma de trabajar

1. Edita `base/core.md`, un módulo de `base/modulos/`, un agente o un comando en este repo y haz commit.
2. `scripts/sync-all.sh` lo propaga a todos los proyectos registrados en `projects.txt`.
3. En cada proyecto, revisa el diff y commitea (`chore(kit): actualizar base de Stibios`).

`install.sh` registra cada proyecto en `projects.txt` automáticamente. Ese archivo es local y está en `.gitignore`.

## Refero

- **Refero Styles** (refero.style): gratis para copiar un `DESIGN.md` de referencia al proyecto.
- **Skill `refero-design`**: `scripts/skills.sh --con-refero`. Funciona sin MCP.
- **Refero MCP**: requiere plan Pro. `install.sh <proyecto> --con-refero` añade la entrada a `.mcp.json`; define `REFERO_TOKEN` en tu entorno, nunca en git.

## Reglas del kit

- Lo específico de un proyecto vive en su `AGENTS.md`, nunca en el kit.
- Sin secretos en este repo.
- Los agentes del kit son genéricos; si un proyecto necesita uno distinto, se edita en el proyecto y `install.sh` ya no lo pisa (salvo `--force-agents`).
- Las dependencias externas (MCP, skills) se fijan a una versión concreta cuando es posible.

## Licencia

[MIT](LICENSE).
