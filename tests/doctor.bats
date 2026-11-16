#!/usr/bin/env bats
load test_helper

setup() { setup_proyecto; }

@test "proyecto recién instalado: sin errores, con aviso de placeholders" {
  instalar >/dev/null
  run doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"AGENTS.md tiene"*"sin rellenar"* ]]
  [[ "$output" == *"base.md al día"* ]]
  [[ "$output" == *"0 error(es)"* ]]
}

@test "sin stibios.config.yml: error" {
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"falta stibios.config.yml"* ]]
}

@test "configuración inválida: error con el motivo" {
  instalar >/dev/null
  config firmas si
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"firmas: 'si'"* ]]
}

@test "base.md editada a mano: aviso" {
  instalar >/dev/null
  echo "extra" >> "$PROY/.claude/stibios/base.md"
  run doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"base.md desactualizado"* ]]
}

@test "CLAUDE.md sin imports: error" {
  instalar >/dev/null
  echo "# vacío" > "$PROY/CLAUDE.md"
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"no importa @AGENTS.md"* ]]
}

@test "falta un agente: error" {
  instalar >/dev/null
  rm "$PROY/.claude/agents/arquitecto.md"
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"falta el agente arquitecto"* ]]
}

@test "agente de un módulo desactivado: aviso" {
  instalar >/dev/null
  config modulos devops
  instalar >/dev/null
  run doctor
  [[ "$output" == *"el agente frontend sigue en el proyecto"* ]]
}

@test ".mcp.json inválido: error; con @latest: aviso" {
  instalar >/dev/null
  echo '{' > "$PROY/.mcp.json"
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *".mcp.json no es JSON válido"* ]]
  echo '{"mcpServers":{"playwright":{"command":"npx","args":["-y","@playwright/mcp@latest"]}}}' > "$PROY/.mcp.json"
  run doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"usa @latest"* ]]
}

@test "tracker jira sin MCP de Atlassian: aviso" {
  instalar --modulos "" >/dev/null
  config tracker jira
  run doctor
  [[ "$output" == *"sin MCP 'atlassian'"* ]]
}

@test "herramientas del backlog desactualizadas: aviso" {
  instalar >/dev/null
  echo "# x" >> "$PROY/.claude/stibios/backlog.sh"
  run doctor
  [[ "$output" == *"backlog.sh desactualizado"* ]]
}

@test "backlog con errores: doctor falla" {
  instalar >/dev/null
  backlog nuevo "Algo" subtarea >/dev/null
  run doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"backlog → "* ]]
}

@test "versión del kit distinta de la instalada: aviso" {
  instalar >/dev/null
  echo "v0.0.0" > "$PROY/.claude/stibios/.kit-version"
  run doctor
  [[ "$output" == *"el kit actual es"* ]]
}
