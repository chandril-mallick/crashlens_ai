#!/usr/bin/env bash
# CrashLens AI — Build Setup Script
# Run this once after each Mac restart (or whenever /tmp is cleared).
# The build/ symlink lets Flutter find the APK while keeping all Gradle
# intermediates on the internal SSD (avoids macOS ._* file corruption on T7).
set -euo pipefail

SYMLINK="/Volumes/T7/crash_lens/build"
TARGET="/tmp/crashlens_build"

echo "🔧 Setting up CrashLens build environment..."

# Re-create the target on internal disk
mkdir -p "$TARGET"

# Remove stale symlink or directory, then re-link
if [ -L "$SYMLINK" ]; then
  rm "$SYMLINK"
elif [ -d "$SYMLINK" ]; then
  echo "⚠️  '$SYMLINK' is a real directory — removing it first."
  rm -rf "$SYMLINK"
fi

ln -s "$TARGET" "$SYMLINK"
echo "✅ Symlink: $SYMLINK → $TARGET"
echo "   Run: flutter build apk --debug"
