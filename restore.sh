#!/usr/bin/env bash
# Restore Cosmos to a known-good tagged version and redeploy it to a vault.
# "Torna com'era": revert totale del tema alla versione taggata (default:
# l'ultimo restore-point cosmos-restore-*), poi deploy nel vault.
#
# Usage: ./restore.sh /path/to/vault [tag]
#   - tag opzionale; default = l'ultimo tag cosmos-restore-* per data.
#
# Nota: revert SOFT alternativo (senza toccare git) → in Obsidian
#   Settings → Style Settings → Cosmos → spegni "Craft sidebar nav"
#   (o Cosmos Flavour → Standard). Questo script è il revert HARD/totale.
set -euo pipefail

VAULT="${1:-}"
if [[ -z "$VAULT" ]]; then
  echo "Usage: ./restore.sh /path/to/vault [tag]" >&2
  exit 1
fi
if [[ ! -d "$VAULT/.obsidian" ]]; then
  echo "Error: '$VAULT' has no .obsidian/ — not an Obsidian vault." >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

TAG="${2:-}"
if [[ -z "$TAG" ]]; then
  TAG="$(git tag --list 'cosmos-restore-*' --sort=-refname | head -1)"
fi
if [[ -z "$TAG" ]]; then
  echo "Error: no restore tag found (cosmos-restore-*) and none passed." >&2
  exit 1
fi
if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "Error: tag '$TAG' does not exist." >&2
  exit 1
fi

echo "Restoring theme.css + manifest.json from tag: $TAG"
git checkout "$TAG" -- theme.css manifest.json

./deploy.sh "$VAULT"
echo "Restored to $TAG. Reload Obsidian (Cmd+R) to see it."
echo "Tip: 'git checkout HEAD -- theme.css manifest.json' per tornare all'ultima versione di lavoro."
