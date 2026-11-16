---
description: Exporta tickets del backlog al tracker configurado (Jira, GitHub, Linear) o a CSV
argument-hint: <ID ...> | listos  [--csv]
---

Exporta tickets del backlog: $ARGUMENTS

1. Lee `tracker` y `prefijo_ticket` de `stibios.config.yml`. Si el tracker es `none` o se pidió `--csv`, ofrece el CSV (paso 6).
2. Ejecuta `bash .claude/stibios/backlog.sh validar`. Si hay errores, para y corrígelos antes.
3. Selecciona los tickets: los IDs indicados o, con `listos`, los que están en estado `listo` (`backlog.sh listar`). Salta los ya `exportado`.
4. **Vista previa obligatoria.** Muestra qué se va a crear (ID, tipo, título, prioridad, padre, etiquetas, destino) y **espera aprobación explícita**. Sin ella no se crea nada fuera del repo.
5. Crea los tickets en orden épica → historia → tarea → bug → subtarea, para que los padres existan antes que sus hijos:
   - **jira**: con las herramientas del MCP de Atlassian (`getAccessibleAtlassianResources`, `getVisibleJiraProjects`, `getJiraProjectIssueTypesMetadata`, `createJiraIssue`). El proyecto Jira es `prefijo_ticket`; si no existe, pregunta. Mapeo: epica→Epic, historia→Story, tarea→Task, bug→Bug, subtarea→Sub-task; alta/media/baja→High/Medium/Low. Descripción: `backlog.sh cuerpo <ID>`.
   - **github**: `gh issue create --title ... --body-file ... --label ...` (etiquetas de tipo y prioridad). Para el padre, escribe "Parte de #N" en el cuerpo.
   - **linear**: con el MCP de Linear.
   - Si la herramienta no está disponible, usa el paso 6.
6. **CSV**: `mkdir -p docs/backlog/export && bash .claude/stibios/backlog.sh csv jira|linear [ID...] > docs/backlog/export/<destino>.csv` e indica cómo importarlo en el tracker (en Jira: Ajustes ▸ Sistema ▸ Importación externa ▸ CSV; revisa el mapeo de columnas). El CSV no marca los tickets como exportados.
7. Tras crear cada ticket, registra el resultado: `bash .claude/stibios/backlog.sh marcar <ID> <clave|#número> <url>`. Si algo falla, comprueba en el tracker si se llegó a crear antes de reintentar, para no duplicar.
8. Termina con la lista de tickets creados y sus enlaces, y propone el commit `docs(backlog): exportar tickets a <tracker>`. No hagas el commit sin que se pida.
