#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="src/version/version.mbt"

# 1. Explicit env var (used by CI)
if [ -n "${CTT_VERSION:-}" ]; then
  VERSION="$CTT_VERSION"
# 2. HEAD is exactly on a tag
elif git describe --tags --exact-match HEAD 2>/dev/null >/dev/null; then
  VERSION=$(git describe --tags --exact-match HEAD | sed 's/^v//')
# 3. Neither — leave version.mbt untouched ("dev" or whatever is committed)
else
  exit 0
fi

NEW_CONTENT='///|
pub const VERSION : String = "'"$VERSION"'"
'

CURRENT_CONTENT=$(cat "$VERSION_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_CONTENT" != "$NEW_CONTENT" ]; then
  printf '%s' "$NEW_CONTENT" > "$VERSION_FILE"
  echo "gen-version: wrote $VERSION to $VERSION_FILE"
fi
