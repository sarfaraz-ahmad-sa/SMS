#!/usr/bin/env bash
set -euo pipefail

flutter_bin="${FLUTTER_BIN:-flutter/bin/flutter}"

if [[ ! -x "$flutter_bin" ]]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION:-3.44.9}" \
    https://github.com/flutter/flutter.git flutter
fi

"$flutter_bin" config --enable-web
"$flutter_bin" pub get

dart_defines=(
  "--dart-define=ENABLE_SUPABASE_PRIMARY=true"
  "--dart-define=APP_VERSION=${VERCEL_GIT_COMMIT_SHA:-local}"
)

# Fail before building if buyer-owned configuration is missing.
: "${SUPABASE_URL:?Set SUPABASE_URL for your own project}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set a public Supabase client key}"
dart_defines+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
dart_defines+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY")
if [[ -n "${BRAND_CONFIG_FILE:-}" ]]; then
  dart_defines+=("--dart-define-from-file=$BRAND_CONFIG_FILE")
fi
if [[ -n "${SUPABASE_AUTH_REDIRECT_URL:-}" ]]; then
  dart_defines+=("--dart-define=SUPABASE_AUTH_REDIRECT_URL=$SUPABASE_AUTH_REDIRECT_URL")
fi

"$flutter_bin" build web --release "${dart_defines[@]}"
