#!/usr/bin/env bash
# Deploy Cosmos theme into an Obsidian vault.
# Usage: ./deploy.sh /path/to/vault
# No build step — theme.css is the source. Copies theme.css + manifest.json
# into <vault>/.obsidian/themes/Cosmos/.
set -euo pipefail

VAULT="${1:-}"
if [[ -z "$VAULT" ]]; then
  echo "Usage: ./deploy.sh /path/to/vault" >&2
  exit 1
fi
if [[ ! -d "$VAULT/.obsidian" ]]; then
  echo "Error: '$VAULT' has no .obsidian/ — not an Obsidian vault." >&2
  exit 1
fi

DEST="$VAULT/.obsidian/themes/Cosmos"
mkdir -p "$DEST"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safety net: backup the currently-deployed theme.css before overwriting, so
# a bad deploy is always one `cp` away from being undone (restore.sh uses the tag).
if [[ -f "$DEST/theme.css" ]]; then
  cp "$DEST/theme.css" "$DEST/theme.css.bak"
  echo "Backup → $DEST/theme.css.bak"
fi

cp "$SRC/theme.css"    "$DEST/theme.css"
cp "$SRC/manifest.json" "$DEST/manifest.json"

echo "Cosmos deployed → $DEST"
echo "In Obsidian: Settings → Appearance → Themes → Cosmos"
