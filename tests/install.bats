#!/usr/bin/env bats
load test_helper

setup() { setup_proyecto; }

@test "instalación por defecto: config, base, agentes, plantillas, MCP y herramientas" {
  run instalar
  [ "$status" -eq 0 ]
  for f in stibios.config.yml AGENTS.md CLAUDE.md DESIGN.md .mcp.json \
           .claude/stibios/base.md .claude/stibios/backlog.sh .claude/stibios/lib.sh .claude/stibios/ticket.md \
           .claude/commands/ticket.md .claude/commands/exportar.md; do
    [ -f "$PROY/$f" ]
  done
  [ "$(ls "$PROY/.claude/agents" | wc -l)" -eq 7 ]
  jq -e '.mcpServers.playwright' "$PROY/.mcp.json" >/dev/null
  [ -s "$PROY/.claude/stibios/.kit-version" ]
  grep -qxF "$PROY" "$STIBIOS_REGISTRO"
}

@test "--modulos vacío instala solo el núcleo" {
  run instalar --modulos ""
  [ "$status" -eq 0 ]
  [ "$(ls "$PROY/.claude/agents" | tr '\n' ' ')" = "arquitecto.md backend.md documentacion.md pr-reviewer.md " ]
  [ ! -f "$PROY/DESIGN.md" ]
  [ ! -f "$PROY/.mcp.json" ]
  ! grep -q 'Diseño y UI' "$PROY/.claude/stibios/base.md"
}

@test "--modulos seguridad instala el agente de seguridad y su regla" {
  run instalar --modulos seguridad
  [ -f "$PROY/.claude/agents/seguridad.md" ]
  [ ! -f "$PROY/.claude/agents/frontend.md" ]
  grep -q 'Revisión de seguridad' "$PROY/.claude/stibios/base.md"
}

@test "la configuración existente no se sobrescribe y --modulos avisa" {
  instalar >/dev/null
  config prefijo_ticket KAN
  run instalar --modulos ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"se ignora"* ]]
  grep -q '^prefijo_ticket: KAN' "$PROY/stibios.config.yml"
  grep -q '^modulos: ui, seguridad, devops' "$PROY/stibios.config.yml"
}

@test "configuración inválida: falla con todos los errores y no instala" {
  printf 'modulos: foo\ntracker: x\n' > "$PROY/stibios.config.yml"
  run instalar
  [ "$status" -eq 1 ]
  [[ "$output" == *"modulos: 'foo'"* ]]
  [[ "$output" == *"tracker: 'x'"* ]]
  [ ! -d "$PROY/.claude/agents" ]
}

@test "opción desconocida o ruta inexistente fallan" {
  run instalar --nada
  [ "$status" -eq 1 ]
  run "$KIT/scripts/install.sh" "$BATS_TEST_TMPDIR/no-existe"
  [ "$status" -eq 1 ]
}

@test "es idempotente: una segunda instalación no cambia nada" {
  instalar >/dev/null
  antes="$(cd "$PROY" && find . -path ./.git -prune -o -type f -print | sort | while IFS= read -r f; do cksum < "$f"; done)"
  instalar >/dev/null
  despues="$(cd "$PROY" && find . -path ./.git -prune -o -type f -print | sort | while IFS= read -r f; do cksum < "$f"; done)"
  [ "$antes" = "$despues" ]
}

@test "un agente editado a mano se conserva; --force-agents lo restaura" {
  instalar >/dev/null
  echo "cambio local" >> "$PROY/.claude/agents/backend.md"
  instalar >/dev/null
  grep -q 'cambio local' "$PROY/.claude/agents/backend.md"
  instalar --force-agents >/dev/null
  ! grep -q 'cambio local' "$PROY/.claude/agents/backend.md"
}

@test "AGENTS.md, DESIGN.md y CLAUDE.md existentes no se tocan; se añaden los imports" {
  echo "# mi agents" > "$PROY/AGENTS.md"
  echo "# mi design" > "$PROY/DESIGN.md"
  echo "# mi claude" > "$PROY/CLAUDE.md"
  instalar >/dev/null
  [ "$(cat "$PROY/AGENTS.md")" = "# mi agents" ]
  [ "$(cat "$PROY/DESIGN.md")" = "# mi design" ]
  grep -qxF '@.claude/stibios/base.md' "$PROY/CLAUDE.md"
  grep -qxF '@AGENTS.md' "$PROY/CLAUDE.md"
  instalar >/dev/null
  [ "$(grep -c '@AGENTS.md' "$PROY/CLAUDE.md")" -eq 1 ]
}

@test "las plantillas sustituyen el nombre del proyecto" {
  instalar >/dev/null
  grep -q 'proyecto' "$PROY/AGENTS.md"
  grep -q '{{FRONT}}' "$PROY/AGENTS.md"
}

@test ".mcp.json: lo del proyecto manda y se conservan las demás claves" {
  echo '{"mcpServers":{"x":{"command":"a"},"playwright":{"command":"propio"}},"otro":1}' > "$PROY/.mcp.json"
  run instalar --con-refero
  [ "$status" -eq 0 ]
  [ "$(jq -r '.mcpServers.playwright.command' "$PROY/.mcp.json")" = "propio" ]
  [ "$(jq -r '.mcpServers.x.command' "$PROY/.mcp.json")" = "a" ]
  [ "$(jq -r '.otro' "$PROY/.mcp.json")" = "1" ]
  jq -e '.mcpServers.refero' "$PROY/.mcp.json" >/dev/null
}

@test ".mcp.json no se reescribe si no hay cambios (sin ruido de formato)" {
  printf '{"mcpServers":{"playwright":{"command":"npx","args":["-y","@playwright/mcp@0.0.85"]}}}\n' > "$PROY/.mcp.json"
  antes="$(cksum < "$PROY/.mcp.json")"
  instalar >/dev/null
  [ "$antes" = "$(cksum < "$PROY/.mcp.json")" ]
}

@test "--con-refero sin el módulo ui avisa y no toca .mcp.json" {
  run instalar --modulos "" --con-refero
  [ "$status" -eq 0 ]
  [[ "$output" == *"necesita el módulo ui"* ]]
  [ ! -f "$PROY/.mcp.json" ]
}

@test "tracker jira añade el MCP de Atlassian; github no añade ninguno" {
  instalar --modulos "" >/dev/null
  config tracker jira
  instalar >/dev/null
  jq -e '.mcpServers.atlassian' "$PROY/.mcp.json" >/dev/null
  rm "$PROY/.mcp.json"
  config tracker github
  instalar >/dev/null
  [ ! -f "$PROY/.mcp.json" ]
}

@test "base.md refleja la configuración" {
  instalar >/dev/null
  config rama_principal develop
  config prefijo_ticket KAN
  config formato_rama '"feature/{ticket}-{descripcion}"'
  config quien_abre_pr agente
  config firmas permitir
  config tracker jira
  instalar >/dev/null
  b="$PROY/.claude/stibios/base.md"
  grep -q 'desde `develop`' "$b"
  grep -q 'feature/kan-123-configurar-subagentes' "$b"
  grep -q 'el agente abre la PR contra `develop`' "$b"
  grep -q 'Se permiten firmas' "$b"
  grep -q 'gestionan en Jira con el prefijo `KAN-<n>`' "$b"
  ! grep -q '{{' "$b"
}
