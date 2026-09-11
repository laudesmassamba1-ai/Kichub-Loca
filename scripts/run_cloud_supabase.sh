#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Missing Supabase env vars."
  echo "Example:"
  echo "  export SUPABASE_URL='https://xxxxx.supabase.co'"
  echo "  export SUPABASE_ANON_KEY='xxxxx'"
  echo "  ./scripts/run_cloud_supabase.sh"
  exit 1
fi

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -d chrome \
  --web-port 3000
