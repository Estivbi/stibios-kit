# Contribuir a stibios-kit

¡Gracias por querer mejorar el kit! Este documento explica cómo trabajar en él.

## Entorno

Necesitas bash, `git`, `jq`, Node.js, [`bats`](https://bats-core.readthedocs.io) y [`shellcheck`](https://www.shellcheck.net).

```bash
npm install -g bats@1.13.0
shellcheck -x -P SCRIPTDIR scripts/*.sh    # estático
bats tests                                 # tests
```

La CI ejecuta lo mismo en Linux y macOS (incluido el bash 3.2 de macOS). Una PR no se mergea con la CI en rojo.

## Cómo trabajamos (el kit se aplica a sí mismo)

- Cambios con tests: si cambias el comportamiento de un script, añade o ajusta un test en `tests/`. Los tests salen de lo que el kit promete, no de la implementación.
- Una rama por cambio, desde `main`: `tipo/descripcion-corta`. PR contra `main`.
- Commits [Conventional Commits](https://www.conventionalcommits.org/es/) con la descripción en español y en infinitivo: `feat(install): ...`, `fix(backlog): ...`, `docs: ...`.
- Sin datos personales, nombres de proyectos ni secretos. Lo específico de un proyecto vive en su `AGENTS.md`, nunca en el kit (un test lo comprueba).

## Reglas de los scripts

- Deben funcionar con **bash 3.2** (macOS): sin `${var,,}`, sin arrays asociativos, sin `sed -i`, sin `readarray`.
- `set -euo pipefail`, variables entre comillas y `shellcheck` limpio. Las excepciones se justifican en un comentario `# shellcheck disable=...`.
- Los textos para la persona usuaria van en español.
- Nada que cree algo fuera del repo del proyecto sin aprobación explícita.

## Añadir un módulo

1. `base/modulos/<nombre>.md` con las reglas que aporta.
2. Si añade un agente: `agents/<agente>.md` y la entrada en `agentes_de_modulo` y `MODULOS_VALIDOS` de `scripts/lib.sh`.
3. Si necesita MCP, plantillas o archivos: instálalos en `scripts/install.sh` solo con `modulo_activo <nombre>`.
4. Tests en `tests/install.bats` y `tests/doctor.bats`, y la fila en la tabla de módulos del README.

## Añadir un agente o un comando

- Agentes: front-matter con `name` (igual al archivo), `description` y `tools`, y la línea que remite a `AGENTS.md` y `.claude/stibios/base.md`. Genérico: nada de un proyecto concreto.
- Comandos: front-matter con `description` y `argument-hint`. Si hacen algo con efecto externo, exige vista previa y aprobación.

## Versiones y publicación

[SemVer](https://semver.org/lang/es/): `MAJOR` para cambios incompatibles (renombrar claves de configuración o rutas instaladas), `MINOR` para funcionalidad nueva y `PATCH` para correcciones.

1. Actualiza `VERSION` y mueve lo pendiente del `CHANGELOG.md` a la nueva versión.
2. Mergea a `main` con la CI en verde.
3. Etiqueta el commit: `git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z`, y crea la release en GitHub con las notas del changelog.

Los proyectos pueden fijar una versión con `git clone --branch vX.Y.Z`.
