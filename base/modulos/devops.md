## Infraestructura y CI

- La CI ejecuta lo mismo que se ejecuta en local: linter, tipos y tests. Una rama no se mergea con la CI en rojo.
- Todo cambio de infraestructura vive en `infra/` o `.github/` y lo hace el agente `devops`; si cambia una decisión previa, se documenta en un ADR.
