#!/usr/bin/env bash
# Instala la status line de Claude Code:
#   1. copia statusline.sh a ~/.claude/statusline.sh
#   2. registra el campo "statusLine" en ~/.claude/settings.json
# Es idempotente: se puede ejecutar tantas veces como se quiera.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq >/dev/null 2>&1 || {
  echo "ERROR: falta 'jq'. Instálalo y vuelve a ejecutar (ver README)." >&2
  exit 1
}

mkdir -p "$CLAUDE_DIR"
cp "$SRC_DIR/statusline.sh" "$TARGET"
chmod +x "$TARGET"
echo "OK  script copiado -> $TARGET"

# Ruta que se escribe en settings.json. En Windows (Git Bash) hay que usar la
# ruta nativa con barras normales: Claude Code lanza el comando desde cmd.exe,
# donde "~" y "/c/Users/..." no existen.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) SL_PATH="$(cygpath -m "$TARGET")" ;;
  *)                    SL_PATH="$TARGET" ;;
esac
COMMAND="bash \"$SL_PATH\""

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  echo "OK  backup de settings.json creado"
else
  echo '{}' > "$SETTINGS"
fi

tmp="$SETTINGS.tmp.$$"
jq --arg cmd "$COMMAND" \
   '.statusLine = {type:"command", command:$cmd, padding:0}' \
   "$SETTINGS" > "$tmp" && mv -f "$tmp" "$SETTINGS"

echo "OK  settings.json actualizado"
echo
echo "Listo. Reinicia Claude Code (o abre una sesión nueva) para verlo."
