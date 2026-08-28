#!/usr/bin/env bash
set -euo pipefail

flutter_bin="${FLUTTER_BIN:-flutter/bin/flutter}"

if [[ ! -x "$flutter_bin" ]]; then
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git flutter
fi

"$flutter_bin" config --enable-web
"$flutter_bin" pub get

dart_defines=(
  "--dart-define=ENABLE_SUPABASE_PRIMARY=true"
  "--dart-define=APP_VERSION=${VERCEL_GIT_COMMIT_SHA:-local}"
)

# Do not pass empty Vercel variables: an empty dart-define overrides the safe
# public defaults bundled in lib/config/supabase_public_config.dart.
if [[ -n "${SUPABASE_URL:-}" ]]; then
  dart_defines+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
fi
if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  dart_defines+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY")
fi
if [[ -n "${SUPABASE_AUTH_REDIRECT_URL:-}" ]]; then
  dart_defines+=("--dart-define=SUPABASE_AUTH_REDIRECT_URL=$SUPABASE_AUTH_REDIRECT_URL")
fi

"$flutter_bin" build web --release "${dart_defines[@]}"
