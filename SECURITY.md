# Seguridad

## Cómo reportar una vulnerabilidad

No abras un issue público. Usa los avisos de seguridad privados de GitHub:
<https://github.com/Estivbi/stibios-kit/security/advisories/new>

Incluye qué has encontrado, cómo reproducirlo y su impacto. Responderemos lo antes posible y, una vez corregido, publicaremos una nota en el [CHANGELOG](CHANGELOG.md).

## Qué consideramos en alcance

- Los scripts de `scripts/`, que se ejecutan en tu máquina y escriben en tus proyectos (por ejemplo, ejecución de comandos a partir de valores de `stibios.config.yml` o de tickets, o rutas que escapen del proyecto).
- Los archivos de `mcp/`, que se fusionan en el `.mcp.json` de cada proyecto.
- Los prompts de `agents/` y `commands/`, si permiten acciones externas sin la aprobación que el kit promete (por ejemplo, exportar tickets sin vista previa).

## Qué debes saber al usarlo

- El kit **nunca** guarda secretos. Los tokens (por ejemplo `REFERO_TOKEN`) se definen en tu entorno, no en git.
- `scripts/skills.sh` instala skills de terceros con `npx skills add`. Revisa su contenido antes de instalarlos: no están fijados a una versión.
- Los servidores MCP de `mcp/` son remotos (Atlassian, Linear, Refero) o se ejecutan con `npx` (Playwright, fijado a una versión). Cada uno se autoriza por separado desde Claude Code.
- `/exportar` crea tickets en servicios externos solo tras mostrarte una vista previa y recibir tu aprobación.

## Versiones soportadas

Solo la última versión publicada recibe correcciones.
