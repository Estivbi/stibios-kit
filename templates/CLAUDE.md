@AGENTS.md
@.claude/stibios/base.md

## Notas específicas de Claude Code

- Los subagentes se invocan por nombre (`arquitecto`, `frontend`, `backend`, `seguridad`, `devops`, `documentacion`, `pr-reviewer`). Elige el que sea dueño de la carpeta que vas a tocar.
- Comandos disponibles: `/spec`, `/plan`, `/tasks`, `/test`.
- Antes de commitear, confirma que la identidad Git del repo es la de la persona titular (`git config user.name` y `git config user.email`) y que no hay firma de herramienta.
- Antes de tocar interfaz, lee `DESIGN.md`.
