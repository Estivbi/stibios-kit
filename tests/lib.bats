#!/usr/bin/env bats
load test_helper

setup() { source "$KIT/scripts/lib.sh"; CFG="$BATS_TEST_TMPDIR/c.yml"; }

@test "cfg_get devuelve el defecto si falta la clave" {
  : > "$CFG"
  [ "$(cfg_get "$CFG" tracker none)" = "none" ]
}

@test "cfg_get quita comentarios, espacios y comillas" {
  printf 'tracker:   jira   # comentario\nformato_rama: "{ticket}/{descripcion}"\nraro: \x27x y\x27\n' > "$CFG"
  [ "$(cfg_get "$CFG" tracker none)" = "jira" ]
  [ "$(cfg_get "$CFG" formato_rama x)" = "{ticket}/{descripcion}" ]
  [ "$(cfg_get "$CFG" raro x)" = "x y" ]
}

@test "cfg_get respeta un valor en blanco (no usa el defecto)" {
  printf 'modulos:    # ninguno\n' > "$CFG"
  [ "$(cfg_get "$CFG" modulos ui)" = "" ]
}

@test "validar_config acepta los valores por defecto" {
  cargar_config /dev/null
  run validar_config
  [ "$status" -eq 0 ]
}

@test "validar_config lista todos los errores" {
  printf 'modulos: foo\ntracker: x\nprefijo_ticket: 1A\nticket_inicial: 0\nfirmas: si\nquien_abre_pr: nadie\nformato_rama: "{ticket}"\n' > "$CFG"
  cargar_config "$CFG"
  run validar_config
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 7 ]
}

@test "render sustituye variables y deja las desconocidas" {
  cargar_config /dev/null
  PROYECTO="mi-app"
  run bash -c "source '$KIT/scripts/lib.sh'; cargar_config /dev/null; PROYECTO='mi-app'; printf '%s' '{{PROYECTO}} {{OTRA}} {{RAMA_PRINCIPAL}}' | render"
  [ "$output" = "mi-app {{OTRA}} main" ]
}

@test "render no interpreta & en los valores" {
  run bash -c "source '$KIT/scripts/lib.sh'; cargar_config /dev/null; PROYECTO='a&b'; printf '%s' '{{PROYECTO}}' | render"
  [ "$output" = "a&b" ]
}

@test "version_kit usa el tag si lo hay y VERSION si no hay git" {
  d="$BATS_TEST_TMPDIR/k"; mkdir -p "$d"; echo 9.9.9 > "$d/VERSION"
  [ "$(version_kit "$d")" = "v9.9.9" ]
}
