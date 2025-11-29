#!/usr/bin/env bash
set -euo pipefail

# Release script for nix-config
# Creates a semantic version tag and pushes it

BUMP_TYPE="${1:-patch}"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: There are uncommitted changes. Please commit or stash them first." >&2
    exit 1
fi

# Get the latest tag, or default to v0.0.0 if none exists
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# Parse the version (strip leading 'v' if present)
VERSION="${LATEST_TAG#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Default to 0 if any part is empty
MAJOR="${MAJOR:-0}"
MINOR="${MINOR:-0}"
PATCH="${PATCH:-0}"

# Bump the appropriate version part
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Error: Invalid bump type '$BUMP_TYPE'. Use 'major', 'minor', or 'patch'." >&2
        exit 1
        ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "Creating tag: $NEW_TAG (was: $LATEST_TAG)"
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"

echo "Pushing tag..."
git push origin "$NEW_TAG"

echo "Released $NEW_TAG"
