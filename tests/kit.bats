#!/usr/bin/env bats
# Estructura y coherencia del propio kit.

setup() { KIT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

@test "cada agente tiene front-matter con name igual al archivo, description y tools" {
  for f in "$KIT"/agents/*.md; do
    n="$(basename "$f" .md)"
    grep -q "^name: $n$" "$f"
    grep -q '^description: .\+' "$f"
    grep -q '^tools: .\+' "$f"
  done
}

@test "cada comando tiene description" {
  for f in "$KIT"/commands/*.md; do
    grep -q '^description: .\+' "$f"
  done
}

@test "todos los JSON de mcp/ son válidos y ninguno usa @latest" {
  for f in "$KIT"/mcp/*.json; do
    jq -e . "$f" >/dev/null
    ! grep -q '@latest' "$f"
  done
}

@test "no quedan datos personales ni referencias antiguas en el kit" {
  run grep -rnE 'Carol|kan-33|sync\.sh|carolinarb|@gmail' "$KIT" --exclude-dir=.git --exclude-dir=tests --exclude=CHANGELOG.md
  [ "$status" -eq 1 ]
}

@test "los placeholders de base/ son todos conocidos por render()" {
  conocidos='RAMA_PRINCIPAL|FORMATO_RAMA|EJEMPLO_RAMA|PREFIJO|PROYECTO|BLOQUE_PR|BLOQUE_FIRMAS|BLOQUE_TICKETS'
  run bash -c "grep -rhoE '\{\{[A-Z_]+\}\}' '$KIT/base' | tr -d '{}' | sort -u | grep -vxE '$conocidos'"
  [ "$status" -eq 1 ]
}

@test "cada módulo válido tiene su archivo en base/modulos/ y su agente en agents/" {
  source "$KIT/scripts/lib.sh"
  for m in $MODULOS_VALIDOS; do
    [ -f "$KIT/base/modulos/$m.md" ]
    a="$(agentes_de_modulo "$m")"
    [ -f "$KIT/agents/$a.md" ]
  done
}

@test "los agentes del núcleo existen" {
  source "$KIT/scripts/lib.sh"
  for a in $AGENTES_NUCLEO; do [ -f "$KIT/agents/$a.md" ]; done
}

@test "VERSION es semver y el CHANGELOG la menciona" {
  v="$(tr -d '[:space:]' < "$KIT/VERSION")"
  [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
  grep -q "\[$v\]" "$KIT/CHANGELOG.md"
}
