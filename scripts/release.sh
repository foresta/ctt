#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>  (e.g. 0.2.0)"
  exit 1
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$'; then
  echo "Error: '$VERSION' is not a valid semver (expected e.g. 1.2.3 or 1.2.3-beta)"
  exit 1
fi

TAG="v$VERSION"

echo "Bumping to $VERSION ..."

# Update moon.mod.json
sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" src/moon.mod.json

# Update version.mbt
sed -i '' "s/pub const VERSION : String = \"[^\"]*\"/pub const VERSION : String = \"$VERSION\"/" src/version/version.mbt

# Verify consistency
./scripts/check-version.sh

git add src/moon.mod.json src/version/version.mbt
git commit -m "chore: release $TAG"
git tag "$TAG"

echo ""
echo "Done. Push with:"
echo "  git push origin main $TAG"
