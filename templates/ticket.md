---
id: {{ID}}
titulo: "{{TITULO}}"
tipo: {{TIPO}}              # epica | historia | tarea | bug | subtarea
prioridad: {{PRIORIDAD}}    # alta | media | baja
estimacion:                 # puntos u horas; opcional
padre:                      # ID del ticket padre (épica o historia); opcional
dependencias: []            # [TCK-1, TCK-2]
etiquetas: []               # [backend, auth]
estado: borrador            # borrador | listo | exportado
externo:                    # clave en el tracker (KAN-34, #12); la rellena /exportar
url:                        # enlace en el tracker; la rellena /exportar
---

## Descripción

Qué se quiere conseguir y por qué, en 2-5 frases.

## Criterios de aceptación

- **Dado** un contexto, **cuando** ocurre algo, **entonces** se observa un resultado verificable con un test.

## Notas

Enlaces, riesgos, preguntas abiertas.
