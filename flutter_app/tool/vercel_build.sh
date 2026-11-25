#!/usr/bin/env bash
set -euo pipefail
npm test
: "${SUPABASE_URL:?Configure SUPABASE_URL na Vercel}"
: "${SUPABASE_ANON_KEY:?Configure SUPABASE_ANON_KEY na Vercel}"
flutter/bin/flutter analyze lib test
flutter/bin/flutter test --reporter expanded
flutter/bin/flutter build web --release --no-web-resources-cdn \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
