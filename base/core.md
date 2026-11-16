# Base Stibios — Forma de trabajar común a todos los proyectos

Este archivo lo **genera** `stibios-kit` en `.claude/stibios/base.md` a partir de `stibios.config.yml`. No lo edites dentro del proyecto: cambia la configuración y ejecuta `scripts/install.sh`, o cambia el kit y propágalo con `scripts/sync-all.sh`. Lo específico del proyecto (stack, estructura, tickets) va en `AGENTS.md`. Si algo del `AGENTS.md` del proyecto choca con este archivo, manda el del proyecto.

## Flujo SDD y TDD

Todo ticket sigue: spec → test en rojo → código en verde → refactor → documentación → revisión.

1. **Spec** (`arquitecto`): `docs/specs/<TICKET>.md` con contexto, alcance, fuera de alcance y criterios de aceptación en formato dado / cuando / entonces. Se aprueba antes de seguir.
2. **Tests en rojo**: se escriben desde los criterios, nunca desde la implementación. Se comprueba que fallan por el motivo correcto y se commitean (`test(<TICKET>): ...`).
3. **Código en verde**: lo mínimo para que pasen (`feat(<TICKET>): ...`).
4. **Refactor** con los tests en verde.
5. **Documentación** (`documentacion`): `docs/tickets/<TICKET>-<nombre>.md`, ADRs nuevos y `docs/estado.md`.
6. **Revisión** (`pr-reviewer` y, si procede, `seguridad`) antes de abrir la PR.

Un ticket está hecho cuando: cada criterio de la spec tiene test y pasa, el linter y los tipos están limpios, la documentación está al día y los revisores no tienen bloqueos. Nunca se salta, desactiva ni pone en cuarentena un test para conseguir el verde.

## Trabajo en paralelo

- Cada agente toca solo las carpetas de las que es dueño; si necesita un cambio en otra, lo pide al agente dueño.
- Commits pequeños y frecuentes; antes de empezar y de commitear, `git pull --ff-only`.
- Los contratos entre agentes (esquema de datos, OpenAPI, eventos) se fijan primero en la spec y los fija el `arquitecto`.

## Ramas, commits y PRs

- {{BLOQUE_TICKETS}}
- Una rama por ticket, desde `{{RAMA_PRINCIPAL}}`, con nombre en español que explique lo que hace. Formato: `{{FORMATO_RAMA}}`, por ejemplo `{{EJEMPLO_RAMA}}`.
- `{{RAMA_PRINCIPAL}}` es la rama por defecto y está protegida. Las ramas van contra `{{RAMA_PRINCIPAL}}`.
- {{BLOQUE_PR}}
- Conventional Commits con descripción en español, en infinitivo: `tipo(<TICKET>): descripción` con `feat`, `fix`, `test`, `docs`, `refactor`, `chore`, `ci`, `build`.
- {{BLOQUE_FIRMAS}}
- Nunca se reescribe el historial de una rama compartida (sin rebase, amend ni push --force).

## Calidad común

Tipado estricto, linter y formateador del stack, sin código muerto, funciones pequeñas con un solo propósito, nombres claros en español para el dominio y en inglés para los términos técnicos habituales. Las capas y dependencias concretas las define el `AGENTS.md` del proyecto.

## Documentación

- El repositorio es la fuente de verdad y sirve como material de enseñanza para replicar la estrategia.
- `docs/backlog/`: tickets por hacer (`<ID>.md` con front-matter y criterios dado / cuando / entonces), listos para exportar al tracker.
- `docs/specs/`: qué se construye y cómo se sabrá que está bien.
- `docs/tickets/`: qué se construyó, paso a paso, cómo replicarlo y qué se aprendió. Se escribe en cada ticket, antes de la PR.
- `docs/adr/NNNN-<titulo>.md`: una decisión por archivo (contexto, opciones, decisión, consecuencias). Inmutables: si cambia, un ADR nuevo sustituye al anterior.
- `docs/estado.md`: foto actual del repo; se actualiza tras cada merge.

## Seguridad y secretos

- Ningún secreto en git. Solo `.env.example` con nombres de variables y valores ficticios.
- Todo acceso a datos requiere autenticación, salvo lo que `AGENTS.md` marque expresamente como público.
- Las acciones externas irreversibles (enviar un email, publicar, cobrar) pasan por aprobación manual.
- Sin servicios de pago innecesarios: toda infraestructura se evalúa primero contra planes gratuitos o ya contratados.
