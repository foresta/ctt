#!/usr/bin/env bash
set -euo pipefail

MOD_VERSION=$(grep '"version"' src/moon.mod.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')
MBT_VERSION=$(grep 'pub const VERSION' src/version/version.mbt | sed 's/.*"\([^"]*\)".*/\1/')

if [ "$MOD_VERSION" != "$MBT_VERSION" ]; then
  echo "Version mismatch:"
  echo "  moon.mod.json : $MOD_VERSION"
  echo "  version.mbt   : $MBT_VERSION"
  exit 1
fi

echo "Version OK: $MOD_VERSION"
