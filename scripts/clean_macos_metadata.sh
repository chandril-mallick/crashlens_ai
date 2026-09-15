#!/usr/bin/env bash
# Removes macOS metadata files that cause Android Gradle build failures
# when the project is on an external volume (T7, etc.)
# Run before `flutter build apk` if you see "._*" errors in Gradle.
set -euo pipefail

echo "🧹 Cleaning macOS metadata files..."
find "$(dirname "$0")" -name "._*" -type f -delete
echo "✅ Done. Run: flutter build apk --debug"
