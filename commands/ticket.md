---
description: Crea tickets de backlog (docs/backlog/) a partir de una idea, listos para exportar a Jira, GitHub o Linear
argument-hint: <descripción de lo que se quiere conseguir>
---

Convierte esta idea en tickets de backlog: $ARGUMENTS

1. Lee `AGENTS.md` y `stibios.config.yml` (prefijo de ticket y tracker). Ejecuta `bash .claude/stibios/backlog.sh listar` para no duplicar tickets existentes.
2. Si la idea es grande, propón primero una épica con sus historias. Presenta la lista (título, tipo, prioridad, padre, dependencias) y **espera confirmación** antes de crear nada.
3. Para cada ticket, ejecuta `bash .claude/stibios/backlog.sh nuevo "<título en infinitivo>" <tipo> <prioridad>` (tipos: epica, historia, tarea, bug, subtarea; prioridades: alta, media, baja). Devuelve la ruta; edita ese archivo y completa:
   - descripción (qué y por qué, 2-5 frases);
   - criterios de aceptación en formato **dado / cuando / entonces**, cada uno verificable con un test;
   - `padre`, `dependencias`, `etiquetas` y `estimacion` solo si hay base para ponerlos;
   - `estado: listo` cuando esté completo; si falta información, déjalo en `borrador` y di qué falta.
4. Ejecuta `bash .claude/stibios/backlog.sh validar` y corrige lo que falle.
5. Resume lo creado. Si el tracker no es `none`, sugiere `/exportar`. No exportes nada ni implementes nada.
