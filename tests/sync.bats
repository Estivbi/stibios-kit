#!/usr/bin/env bats
load test_helper

setup() { setup_proyecto; }

@test "sync-all propaga a los proyectos registrados y avisa de los que no existen" {
  instalar --modulos "" >/dev/null
  echo "$BATS_TEST_TMPDIR/borrado" >> "$STIBIOS_REGISTRO"
  echo "viejo" >> "$PROY/.claude/stibios/base.md"
  run "$KIT/scripts/sync-all.sh" --sin-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"no existe: $BATS_TEST_TMPDIR/borrado"* ]]
  ! grep -q '^viejo$' "$PROY/.claude/stibios/base.md"
}

@test "sync-all sigue con el resto si un proyecto tiene la configuración inválida" {
  instalar --modulos "" >/dev/null
  otro="$BATS_TEST_TMPDIR/otro"; mkdir -p "$otro"; printf 'tracker: x\n' > "$otro/stibios.config.yml"
  echo "$otro" > "$STIBIOS_REGISTRO"; echo "$PROY" >> "$STIBIOS_REGISTRO"
  echo "viejo" >> "$PROY/.claude/stibios/base.md"
  run "$KIT/scripts/sync-all.sh" --sin-pull
  [ "$status" -eq 1 ]
  [[ "$output" == *"install.sh falló"* ]]
  ! grep -q '^viejo$' "$PROY/.claude/stibios/base.md"
}

@test "sync-all sin registro falla con un mensaje claro" {
  rm -f "$STIBIOS_REGISTRO"
  run "$KIT/scripts/sync-all.sh" --sin-pull
  [ "$status" -eq 1 ]
}
