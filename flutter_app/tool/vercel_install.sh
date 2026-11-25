#!/usr/bin/env bash
set -euo pipefail
npm ci --ignore-scripts
# The SDK is a build dependency, never an application asset.
if [ ! -x flutter/bin/flutter ] || ! git -C flutter describe --tags --exact-match 2>/dev/null | grep -qx '3.38.5'; then
  if [ -d flutter ]; then mv flutter "${TMPDIR:-/tmp}/vantopay-flutter-cache-$(date +%s)"; fi
  git clone --depth 1 --branch 3.38.5 https://github.com/flutter/flutter.git flutter
fi
flutter/bin/flutter config --no-analytics
flutter/bin/flutter pub get
