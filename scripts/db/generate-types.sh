#!/usr/bin/env bash
set -euo pipefail

echo "Generating TypeScript types from local Supabase instance..."
supabase gen types typescript --local > packages/database/src/types.ts
echo "Types successfully written to packages/database/src/types.ts"

