#!/usr/bin/env bash
# Deploy the delete-user Edge Function to Supabase.
#
# Prerequisites:
#   1. Supabase CLI: https://supabase.com/docs/guides/cli
#   2. Get a personal access token: https://supabase.com/dashboard/account/tokens
#   3. Export it: export SUPABASE_ACCESS_TOKEN="your-token"
#
# Then run from repo root:
#   ./supabase/deploy-delete-user.sh
# Or with inline token (avoid committing this):
#   SUPABASE_ACCESS_TOKEN="your-token" ./supabase/deploy-delete-user.sh

set -e
PROJECT_REF="${SUPABASE_PROJECT_REF:-oojpipspxwdmiyaymldo}"

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
  echo "Error: SUPABASE_ACCESS_TOKEN is not set."
  echo "Get a token from: https://supabase.com/dashboard/account/tokens"
  echo "Then run: SUPABASE_ACCESS_TOKEN=your-token $0"
  exit 1
fi

echo "Deploying delete-user to project $PROJECT_REF ..."
supabase functions deploy delete-user --project-ref "$PROJECT_REF"
echo "Done. delete-user is live at https://$PROJECT_REF.supabase.co/functions/v1/delete-user"
