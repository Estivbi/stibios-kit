#!/usr/bin/env bats
load test_helper

setup() { setup_proyecto; instalar --modulos "" >/dev/null; }

@test "nuevo numera desde 1 y crea el archivo desde la plantilla" {
  run backlog nuevo "Primer ticket"
  [ "$status" -eq 0 ]
  [ "$output" = "docs/backlog/TCK-1.md" ]
  grep -q '^id: TCK-1$' "$PROY/docs/backlog/TCK-1.md"
  grep -q '^tipo: historia' "$PROY/docs/backlog/TCK-1.md"
  run backlog nuevo "Segundo"
  [ "$output" = "docs/backlog/TCK-2.md" ]
}

@test "nuevo respeta prefijo_ticket, ticket_inicial y los specs existentes" {
  config prefijo_ticket KAN
  config ticket_inicial 34
  run backlog nuevo "A"
  [ "$output" = "docs/backlog/KAN-34.md" ]
  mkdir -p "$PROY/docs/specs"; touch "$PROY/docs/specs/KAN-50.md"
  run backlog nuevo "B"
  [ "$output" = "docs/backlog/KAN-51.md" ]
}

@test "nuevo sanea las comillas del título y valida tipo y prioridad" {
  backlog nuevo 'Crear "login"' >/dev/null
  [ "$(backlog campo TCK-1 titulo)" = "Crear 'login'" ]
  run backlog nuevo "X" cosa
  [ "$status" -eq 1 ]
  run backlog nuevo "X" tarea urgente
  [ "$status" -eq 1 ]
}

@test "validar: un borrador con la plantilla solo da aviso" {
  backlog nuevo "A" >/dev/null
  run backlog validar
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 error(es), 1 aviso(s)"* ]]
}

@test "validar: un ticket listo con la plantilla sin completar es error" {
  backlog nuevo "A" >/dev/null
  awk '/^estado:/ {print "estado: listo"; next} {print}' "$PROY/docs/backlog/TCK-1.md" > "$PROY/x" && mv "$PROY/x" "$PROY/docs/backlog/TCK-1.md"
  run backlog validar
  [ "$status" -eq 1 ]
  [[ "$output" == *"texto de la plantilla"* ]]
}

@test "validar: padre inexistente, dependencia inexistente, subtarea sin padre y exportado sin externo" {
  backlog nuevo "A" subtarea >/dev/null
  backlog nuevo "B" >/dev/null
  awk '/^padre:/ {print "padre: TCK-99"; next} /^dependencias:/ {print "dependencias: [TCK-98]"; next} /^estado:/ {print "estado: exportado"; next} {print}' "$PROY/docs/backlog/TCK-2.md" > "$PROY/x" && mv "$PROY/x" "$PROY/docs/backlog/TCK-2.md"
  run backlog validar
  [ "$status" -eq 1 ]
  [[ "$output" == *"una subtarea necesita 'padre'"* ]]
  [[ "$output" == *"el padre 'TCK-99' no existe"* ]]
  [[ "$output" == *"la dependencia 'TCK-98' no existe"* ]]
  [[ "$output" == *"estado exportado sin 'externo'"* ]]
}

@test "validar: el id debe coincidir con el nombre del archivo" {
  backlog nuevo "A" >/dev/null
  mv "$PROY/docs/backlog/TCK-1.md" "$PROY/docs/backlog/TCK-7.md"
  run backlog validar
  [ "$status" -eq 1 ]
  [[ "$output" == *"no coincide con el nombre del archivo"* ]]
}

@test "validar sin tickets no falla" {
  run backlog validar
  [ "$status" -eq 0 ]
}

@test "campo y cuerpo: el cuerpo no incluye el front-matter y conserva reglas horizontales" {
  backlog nuevo "A" >/dev/null
  printf '\n---\n\nregla\n' >> "$PROY/docs/backlog/TCK-1.md"
  run backlog cuerpo TCK-1
  [[ "$output" == "## Descripción"* ]]
  [[ "$output" != *"titulo:"* ]]
  [[ "$output" == *"regla"* ]]
}

@test "csv jira: cabecera, mapeo, orden épica → subtarea, etiquetas y escapado" {
  backlog nuevo "Épica" epica alta >/dev/null
  backlog nuevo 'Historia "uno"' historia media >/dev/null
  backlog nuevo "Sub" subtarea baja >/dev/null
  for i in 1 2 3; do completar_ticket "TCK-$i"; done
  awk '/^padre:/ {print "padre: TCK-1"; next} /^etiquetas:/ {print "etiquetas: [a, b]"; next} {print}' "$PROY/docs/backlog/TCK-2.md" > "$PROY/x" && mv "$PROY/x" "$PROY/docs/backlog/TCK-2.md"
  awk '/^padre:/ {print "padre: TCK-2"; next} {print}' "$PROY/docs/backlog/TCK-3.md" > "$PROY/x" && mv "$PROY/x" "$PROY/docs/backlog/TCK-3.md"
  run backlog csv jira
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Issue id,Issue Type,Summary,Priority,Description,Parent,Story point estimate,Labels,Labels" ]
  [[ "${lines[1]}" == '"TCK-1","Epic"'* ]]
  [[ "$output" == *"\"TCK-2\",\"Story\",\"Historia 'uno'\",\"Medium\""* ]]
  [[ "$output" == *'"TCK-3","Sub-task","Sub","Low"'* ]]
  [[ "$output" == *'"a","b"'* ]]
  [[ "$output" != *"titulo:"* ]]
}

@test "csv: sin tickets listos falla; destino desconocido falla; linear tiene su cabecera" {
  backlog nuevo "A" >/dev/null
  run backlog csv jira
  [ "$status" -eq 1 ]
  run backlog csv trello
  [ "$status" -eq 1 ]
  completar_ticket TCK-1
  run backlog csv linear
  [ "${lines[0]}" = "Title,Description,Priority,Labels,Estimate" ]
}

@test "marcar registra el ticket externo y la URL; exportado deja de ser seleccionable" {
  backlog nuevo "A" >/dev/null
  completar_ticket TCK-1
  run backlog marcar TCK-1 KAN-34 https://x.atlassian.net/browse/KAN-34
  [ "$status" -eq 0 ]
  [ "$(backlog campo TCK-1 estado)" = "exportado" ]
  [ "$(backlog campo TCK-1 externo)" = "KAN-34" ]
  [ "$(backlog campo TCK-1 url)" = "https://x.atlassian.net/browse/KAN-34" ]
  run backlog csv jira
  [ "$status" -eq 1 ]
  run backlog validar
  [ "$status" -eq 0 ]
}

@test "listar muestra una fila por ticket" {
  backlog nuevo "A" >/dev/null
  backlog nuevo "B" >/dev/null
  run backlog listar
  [ "${#lines[@]}" -eq 3 ]
}

@test "IDs con caracteres raros se rechazan" {
  run backlog campo '../etc/passwd' titulo
  [ "$status" -eq 1 ]
}
