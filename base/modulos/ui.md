## Tests de interfaz (front)

- Los criterios con comportamiento visible se cubren con Playwright (E2E) además de los tests unitarios.
- Antes de dar por hecha una pantalla: capturas en móvil, tablet y escritorio, y comprobación de accesibilidad básica (contraste, foco, etiquetas).
- Los tests E2E salen de los criterios de la spec, no de lo que pinta la pantalla.

## Diseño y UI

- Cada proyecto con interfaz tiene un `DESIGN.md` en la raíz: fuente de verdad de colores, tipografía, espaciado, movimiento y componentes, más su **intensidad de estilo**.
- Antes de tocar UI, el agente `frontend` lee `DESIGN.md`. Si el proyecto no tiene uno, se crea antes de escribir interfaz (a partir de una referencia de Refero Styles o del skill `refero-design`).
- Prohibidos los valores de color, tamaño o espaciado escritos a mano fuera de los tokens definidos en `DESIGN.md`.
- Skills de diseño recomendados: `frontend-design` (base), `ui-ux-pro-max` (paletas y estilos), `web-design-guidelines` (corrección y accesibilidad), `refero-design` (investigar referencias antes de diseñar). Se instalan con `scripts/skills.sh`.
- No mezclar referencias de diseño: se elige una dirección principal y las demás solo aportan detalles concretos.
- Criterio de hecho visual: la pantalla respeta los tokens, funciona en móvil y tablet, y pasa la revisión de accesibilidad.
