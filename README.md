# stibios-kit

Base común para todos los proyectos de Stibios: flujo SDD/TDD, agentes, comandos, MCP y skills de diseño. Se instala en proyectos nuevos y se sincroniza en los existentes.

## Contenido

| Carpeta | Qué es | Al instalar |
|---|---|---|
| `base/base.md` | Reglas comunes (SDD/TDD, diseño, ramas, commits, seguridad) | Se copia a `.claude/stibios/base.md`; se sobrescribe en cada sync |
| `agents/` | Agentes genéricos (arquitecto, frontend, backend, seguridad, devops, documentacion, pr-reviewer) | Solo se copian los que faltan |
| `commands/` | `/spec`, `/plan`, `/tasks`, `/test` | Se sobrescriben en cada sync |
| `templates/` | `AGENTS.md`, `CLAUDE.md`, `DESIGN.md` | Solo si no existen |
| `mcp/` | `base.mcp.json` (Playwright) y `refero.mcp.json` (opcional, plan Pro) | Se fusiona con `.mcp.json` sin pisar |
| `scripts/` | `install.sh`, `sync-all.sh`, `skills.sh` | — |

## Proyecto nuevo

```bash
mkdir mi-proyecto && cd mi-proyecto && git init
~/stibios/stibios-kit/scripts/install.sh .
~/stibios/stibios-kit/scripts/skills.sh      # skills de diseño de skills.sh
# rellena AGENTS.md (stack, estructura) y DESIGN.md (tokens)
```

## Proyecto que ya existe

```bash
~/stibios/stibios-kit/scripts/install.sh ~/proyectos/mi-proyecto
```

No pisa `AGENTS.md`, `CLAUDE.md` ni `DESIGN.md`. Añade los imports que falten a tu `CLAUDE.md` y fusiona `.mcp.json`. Revisa el diff y commitea como `chore(kit): incorporar base de Stibios`.

## Cambiar la forma de trabajar

1. Edita `base/base.md`, un agente o un comando en este repo y haz commit.
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
