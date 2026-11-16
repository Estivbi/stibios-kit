@AGENTS.md
@.claude/stibios/base.md

## Notas específicas de Claude Code

- Los subagentes viven en `.claude/agents/` y se invocan por nombre; los disponibles dependen de los módulos de `stibios.config.yml`. Elige el que sea dueño de la carpeta que vas a tocar.
- Comandos disponibles: `/spec`, `/plan`, `/tasks`, `/test`.
- Antes de commitear, confirma que la identidad Git del repo es la de la persona titular (`git config user.name` y `git config user.email`) y sigue la política de firmas de la base.
- Si el proyecto tiene interfaz (módulo `ui`), lee `DESIGN.md` antes de tocarla.
