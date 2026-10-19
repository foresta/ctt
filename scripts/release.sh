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

# Update moon.mod (keeps module metadata in sync with tag)
sed -i '' "s/^version = \"[^\"]*\"/version = \"$VERSION\"/" src/moon.mod

# Date the Unreleased section of the changelog, unless the version heading
# was already written by hand.
if ! grep -q "^## \[$VERSION\]" CHANGELOG.md; then
  TODAY="$(date +%Y-%m-%d)"
  perl -0pi -e "s/^## \\[Unreleased\\]\n/## [Unreleased]\n\n## [$VERSION] - $TODAY\n/m" CHANGELOG.md
fi

git add src/moon.mod CHANGELOG.md
git commit -m "chore: release $TAG"
git tag "$TAG"

echo ""
echo "Done. Push with:"
echo "  git push origin main $TAG"
