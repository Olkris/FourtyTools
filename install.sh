INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARE_DIR="$HOME/.local/share/42l"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR" "$SHARE_DIR"
cp "$INSTALLER_DIR/42l.mk" "$SHARE_DIR/42l.mk"
cp "$INSTALLER_DIR/42l.sh" "$BIN_DIR/42l"
chmod +x "$BIN_DIR/42l"

printf "\033[1;31m42l installed!\033[0m\n"
