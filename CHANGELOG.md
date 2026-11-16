# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Sin publicar]

## [0.1.0]

Primera versión pública.

### Añadido
- Flujo SDD/TDD común: `base/core.md`, 7 agentes genéricos y comandos `/spec`, `/plan`, `/tasks` y `/test`.
- `stibios.config.yml` por proyecto: módulos, tracker, prefijo y número inicial de ticket, rama principal, formato de rama, política de firmas y quién abre la PR.
- Módulos opcionales `ui`, `seguridad` y `devops`: `base.md` se genera desde el núcleo y los módulos activos, y solo se instalan sus agentes, plantillas y MCP.
- `scripts/doctor.sh`: comprueba configuración, archivos, imports, placeholders, `base.md` al día, `.mcp.json`, backlog y versión.
- Backlog de tickets en `docs/backlog/` con `/ticket` y `/exportar`: exportación a Jira (MCP de Atlassian), GitHub (`gh`) y Linear (MCP), o CSV importable, siempre con vista previa y aprobación.
- Licencia MIT, tests con `bats` (60), `shellcheck` y CI en GitHub Actions (Linux, macOS y bash 3.2).
- Documentos de comunidad: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, plantillas de issues y de PR.

### Cambiado
- La fusión de `.mcp.json` es correcta y estable: lo que ya existe en el proyecto manda y el archivo no se reescribe si no cambia.
- `@playwright/mcp` fijado a `0.0.85`.
- `sync-all.sh` ejecuta `doctor` por proyecto y continúa si uno falla.

### Eliminado
- Referencias a personas y proyectos concretos en las reglas y los agentes.

[Sin publicar]: https://github.com/Estivbi/stibios-kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Estivbi/stibios-kit/releases/tag/v0.1.0
