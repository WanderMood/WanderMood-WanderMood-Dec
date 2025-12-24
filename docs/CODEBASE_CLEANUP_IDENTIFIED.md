# Codebase Cleanup - Identified Files & Folders to Delete

## 📊 Summary
**Total Identified for Deletion: ~3.2 GB**

## 🗂️ Categories

### 1. BACKUP FOLDERS (HIGH PRIORITY - ~2.4 GB)
These are complete project backups that are no longer needed:

#### ✅ **DELETE ENTIRELY:**
- **`backups/`** (2.4 GB) - Contains full backup from July 16th
  - `backups/WanderMood_july16th_8PM/` - Complete duplicate project backup
  
- **`current_backup_20250321_205958/`** (43 MB) - Old backup from March 2025
  
- **`Flutter_wandermood/`** (599 MB) - **ENTIRE DUPLICATE PROJECT**
  - This is a complete duplicate Flutter project
  - Contains its own backups, lib, assets, etc.
  - Should be deleted entirely
  
- **`archive/`** (97 MB) - Old archived code and assets
  - Contains old explore screens, mood screens, images
  - All code is outdated and not used

#### ⚠️ **CONSIDER KEEPING (if you need reference):**
- None - all backups are outdated

---

### 2. DUPLICATE/OLD CODE FOLDERS

#### ✅ **DELETE:**
- **`lib_old/`** (64 KB) - Old lib folder, code is outdated
- **`supabase_backup_with_issues/`** (232 KB) - Backup with known issues
- **`lib/archive/`** - Archived code inside lib folder (198 files)
  - Contains old implementations that are no longer used

---

### 3. OLD/DUPLICATE FILES IN ROOT

#### ✅ **DELETE:**
- **`wandermood-ai-dashboard-deploy.ts`** - Old TypeScript file (not in supabase/functions)
- **`wandermood-ai-fixed.ts`** - Old TypeScript file
- **`wandermood-ai-updated.ts`** - Old TypeScript file
- **`wandermood-ai-updated-short.ts`** - Old TypeScript file
- **`example_navigator.dart`** - Example/test file
- **`test_activity_filtering.dart`** - Test file in root
- **`clear_cache_debug.dart`** - Debug utility (can recreate if needed)
- **`app.dart`** - Duplicate (main.dart exists)
- **`functions/`** (root level) - Old functions folder
  - `functions/getCurrentWeather/`
  - `functions/getHistoricalWeather/`
  - These are duplicates of supabase/functions

---

### 4. LOG & TEMPORARY FILES

#### ✅ **DELETE:**
- **`flutter_01.log`** - Build log file
- **`flutter_01.png`** - Screenshot/log image
- **`logs.txt`** - Log file
- **`push.log`** - Git push log

---

### 5. BACKUP FILES (.bak)

#### ✅ **DELETE ALL:**
Found **20+ .bak files** throughout the codebase:
- `features/home/presentation/screens/home_screen.dart.bak`
- `features/home/presentation/screens/home_content.dart.bak`
- `.env.bak`
- Various `.bak` files in Pods (can be regenerated)

**Note:** Pods .bak files will be regenerated, but others should be deleted.

---

### 6. DUPLICATE ASSETS & IMAGES

#### ✅ **DELETE:**
- **`images/`** (root) - Only 4 PNG files, likely duplicates
- **`icons/`** (root) - Duplicate icons (already in assets/)
- **`archive/images/`** - Old images (21 files)
- **`archive/assets/`** - Old assets (31 files)
- **`Flutter_wandermood/images/`** - Duplicate images
- **`Flutter_wandermood/icons/`** - Duplicate icons
- **`Flutter_wandermood/assets/`** - Duplicate assets

---

### 7. OLD DOCUMENTATION FILES

#### ⚠️ **REVIEW & CONSOLIDATE:**
Many duplicate/outdated docs in `docs/` folder. Consider:
- Keeping only the most recent/complete versions
- Consolidating similar docs
- Moving historical docs to a `docs/archive/` if needed for reference

**Examples of potentially redundant docs:**
- Multiple "FIX" docs that are now complete
- Multiple "BUILD" fix docs
- Multiple "API" setup guides
- Multiple "BUG_FIXES" reports

---

### 8. DUPLICATE CONFIG FILES

#### ✅ **DELETE:**
- **`Flutter_wandermood/config.toml`** - Duplicate config
- **`Flutter_wandermood/pubspec.yaml`** - Duplicate (root has main one)
- **`Flutter_wandermood/pubspec.lock`** - Duplicate
- **`archive/pubspec.yaml`** - Old pubspec
- **`archive/pubspec.lock`** - Old lock file

---

### 9. OLD MIGRATION FILES

#### ⚠️ **REVIEW:**
- **`migrations/`** (root) - Check if these are applied
- **`Flutter_wandermood/migrations/`** - Old migrations
- **`supabase_backup_with_issues/migrations_backup/`** - Backup migrations

**Note:** Only delete if migrations are already applied to database.

---

### 10. BUILD ARTIFACTS (Should be in .gitignore)

#### ✅ **VERIFY .gitignore, THEN DELETE:**
- **`build/`** - Build artifacts (should be gitignored)
- **`Pods/`** - CocoaPods (should be gitignored, regenerated)
- **`Flutter_wandermood/Pods/`** - Duplicate Pods
- **`Flutter_wandermood/build/`** - Duplicate build

---

## 📋 DELETION PLAN (By Priority)

### Phase 1: Large Backups (Saves ~3 GB)
1. ✅ Delete `backups/` folder (2.4 GB)
2. ✅ Delete `Flutter_wandermood/` folder (599 MB)
3. ✅ Delete `archive/` folder (97 MB)
4. ✅ Delete `current_backup_20250321_205958/` (43 MB)

### Phase 2: Duplicate Code (Saves ~300 MB)
5. ✅ Delete `lib_old/` folder
6. ✅ Delete `lib/archive/` folder
7. ✅ Delete `supabase_backup_with_issues/` folder
8. ✅ Delete `functions/` (root level)

### Phase 3: Root Level Cleanup
9. ✅ Delete old TypeScript files in root
10. ✅ Delete test/example files in root
11. ✅ Delete log files
12. ✅ Delete duplicate assets/images/icons folders

### Phase 4: File Cleanup
13. ✅ Delete all `.bak` files (except in Pods)
14. ✅ Delete duplicate config files
15. ✅ Review and consolidate docs

### Phase 5: Build Artifacts
16. ✅ Verify .gitignore includes build/Pods
17. ✅ Delete build artifacts if not gitignored

---

## ⚠️ SAFETY CHECKLIST

Before deleting, verify:
- [ ] All important code is in current `lib/` folder
- [ ] All active Edge Functions are in `supabase/functions/`
- [ ] All active migrations are in `supabase/migrations/`
- [ ] Git repository is up to date and committed
- [ ] You have a backup of the entire project (external to this folder)

---

## 📝 RECOMMENDED DELETION ORDER

1. **Start with largest folders** (backups, Flutter_wandermood)
2. **Then remove duplicate code folders** (lib_old, archive)
3. **Clean up root level files** (old .ts, .dart files)
4. **Remove log files**
5. **Delete .bak files**
6. **Review and consolidate docs** (optional, can do later)

---

## 💾 ESTIMATED SPACE SAVED

- **Phase 1:** ~3.1 GB
- **Phase 2:** ~300 MB
- **Phase 3:** ~50 MB
- **Phase 4:** ~10 MB
- **Phase 5:** Variable (build artifacts)

**Total Estimated Savings: ~3.5 GB**

---

## 🎯 NEXT STEPS

1. Review this list
2. Confirm which items to delete
3. Create deletion plan
4. Execute deletion in phases
5. Verify app still works after each phase

