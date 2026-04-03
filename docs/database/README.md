# Database Scripts

This folder contains historical database fix scripts, cleanup scripts, and reference schemas.

## ⚠️ Important Notes

- **These scripts are NOT actively used in the codebase**
- **Real migrations are in:** `supabase/migrations/`
- **These are kept for historical reference only**

## File Categories

### Fix Scripts
- `fix_places_cache_schema.sql` - Fixes missing columns in places_cache table
- `fix_places_cache_schema_mismatch.sql` - Fixes schema mismatches
- `fix_user_preferences_table.sql` - Fixes user_preferences table schema
- `fix_all_database_issues.sql` - Comprehensive fix script
- `fix_database_schema_comprehensive.sql` - Comprehensive schema fix

### Cleanup Scripts
- `clean_wandermood_database.sql` - Clean database setup
- `delete_all_users.sql` - Delete all users (⚠️ DANGEROUS)
- `delete_all_users_safe.sql` - Safe user deletion with checks

### Reference Schemas
- `fixed_wandermood_database.sql` - Fixed database schema reference
- `robust_wandermood_database.sql` - Robust database schema reference
- `supabase_places_cache_schema.sql` - Places cache schema reference

## Active Migrations

All active database migrations are located in:
```
supabase/migrations/
```

These migrations are versioned and run automatically by Supabase.

### `scripts/` (one-off maintenance)

- `scripts/reset_places_cache_and_backfill.sql` — reset/backfill places cache (run manually when needed)
- `scripts/apply_user_preferences_migration.sql` — user preferences migration helper (run manually when needed)

## Usage

⚠️ **Do not run these scripts directly on production!**

If you need to apply database changes:
1. Create a new migration in `supabase/migrations/`
2. Use proper versioning (YYYYMMDD_HHMMSS_description.sql)
3. Test in development first
4. Apply via Supabase Dashboard or CLI

