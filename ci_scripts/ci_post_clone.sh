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

echo "  • generating MeowPassword.xcodeproj from project.yml"
xcodegen generate

# Build number = commit count (monotonic). MARKETING_VERSION stays in project.yml.
BUILD_NUMBER="$(git rev-list --count HEAD)"
echo "  • CURRENT_PROJECT_VERSION → $BUILD_NUMBER"
/usr/libexec/PlistBuddy -c "Print" project.yml >/dev/null 2>&1 || true
export CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

echo "✓ ci_post_clone.sh done"
