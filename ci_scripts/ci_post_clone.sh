#!/bin/sh
# Xcode Cloud runs this after `git clone`, before resolving SPM packages /
# running xcodebuild. The runner is a clean VM, so we must regenerate the
# gitignored MeowPassword.xcodeproj from project.yml or xcodebuild has nothing
# to open. Also bumps the build number to the commit count for a fresh
# TestFlight build.
set -euo pipefail

echo "▶︎ ci_post_clone.sh: bootstrapping xcodegen build environment"

# Xcode Cloud invokes this with CWD = ci_scripts/. Hop to the repo root so
# xcodegen finds ./project.yml.
cd "$(dirname "$0")/.."
echo "  • repo root: $(pwd)"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "  • installing xcodegen via Homebrew…"
  brew install xcodegen
fi

# Build number = commit count (monotonic). MARKETING_VERSION stays in project.yml.
#
# This MUST be patched into project.yml *before* `xcodegen generate`, not exported
# as an env var. The old `export CURRENT_PROJECT_VERSION=…` never reached the
# build: xcodegen had already baked the static "1" into the project, and Xcode
# Cloud runs `xcodebuild archive` in a *separate shell* that never sees the export.
# Every archive uploaded as build 1, so App Store Connect kept the first and
# rejected the rest as duplicates ("some builds not available"). Editing the
# gitignored, freshly-cloned project.yml here is safe — the CI VM is ephemeral.
BUILD_NUMBER="$(git rev-list --count HEAD)"
echo "  • CURRENT_PROJECT_VERSION → $BUILD_NUMBER (patching project.yml)"
/usr/bin/sed -i '' -E "s/^([[:space:]]*CURRENT_PROJECT_VERSION: )\"[0-9]+\"/\1\"$BUILD_NUMBER\"/" project.yml
grep -n "CURRENT_PROJECT_VERSION:" project.yml   # echo the patched line into the CI log

echo "  • generating MeowPassword.xcodeproj from project.yml"
xcodegen generate

echo "✓ ci_post_clone.sh done"
