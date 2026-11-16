# Utilidades comunes de los tests (bats).

KIT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup_proyecto() {
  PROY="$BATS_TEST_TMPDIR/proyecto"
  mkdir -p "$PROY"
  git -C "$PROY" init -q
  export STIBIOS_REGISTRO="$BATS_TEST_TMPDIR/projects.txt"
}

instalar() { "$KIT/scripts/install.sh" "$PROY" "$@"; }
doctor() { "$KIT/scripts/doctor.sh" "$PROY" "$@"; }
backlog() { (cd "$PROY" && bash .claude/stibios/backlog.sh "$@"); }

# Cambia `clave: valor` en stibios.config.yml sin sed -i (portable).
config() {
  local clave="$1" valor="$2" f="$PROY/stibios.config.yml"
  awk -v k="$clave" -v v="$valor" 'BEGIN{FS=":"} $1==k {print k ": " v; next} {print}' "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
}

# Rellena un ticket del backlog con contenido válido y lo pone en estado `listo`.
completar_ticket() {
  local id="$1" f="$PROY/docs/backlog/$1.md"
  awk '
    /^estado:/ {print "estado: listo"; next}
    /Qué se quiere conseguir/ {print "Descripción real del ticket."; next}
    /un contexto, \*\*cuando\*\* ocurre algo/ {print "- **Dado** un usuario, **cuando** pulsa el botón, **entonces** ve el resultado."; next}
    {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
