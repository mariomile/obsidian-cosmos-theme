#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

TMP_THEME="$(mktemp)"
trap 'rm -f "$TMP_THEME"' EXIT

./build.sh
cp theme.css "$TMP_THEME"
./build.sh

if ! cmp -s "$TMP_THEME" theme.css; then
  echo "theme.css is not reproducible across consecutive builds" >&2
  exit 1
fi

echo "theme.css reproducible (byte-for-byte)"
