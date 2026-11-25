#!/usr/bin/env bash
set -euo pipefail
# Remote integration checks use disposable accounts only on previews.
# Production builds never create test accounts or probe the live website.
if [ "${VERCEL_ENV:-}" = "preview" ]; then
  node tool/auth_diagnostics.mjs
  node tool/auth_integration.mjs
  node tool/auth_browser_smoke.mjs
fi
npm test
: "${SUPABASE_URL:?Configure SUPABASE_URL na Vercel}"
: "${SUPABASE_ANON_KEY:?Configure SUPABASE_ANON_KEY na Vercel}"
flutter/bin/flutter analyze lib test
flutter/bin/flutter test --reporter expanded
flutter/bin/flutter build web --release --no-web-resources-cdn --pwa-strategy=none \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
