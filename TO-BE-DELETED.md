# TO-BE-DELETED - Complete List of Files and Folders

**Generated:** $(date)  
**Total Estimated Size:** ~3.5 GB  
**Status:** ⚠️ NOT YET DELETED - FOR REVIEW ONLY

---

## 📁 PHASE 1: LARGE BACKUP FOLDERS (~3.1 GB)

### ✅ Entire Folders to Delete:

1. **`backups/`** (2.4 GB)
   - `backups/WanderMood_july16th_8PM/` - Complete project backup
   - Contains 3,084+ files (1,806 Dart files, 277 PNG, 177 JPG, etc.)

2. **`Flutter_wandermood/`** (599 MB)
   - Entire duplicate Flutter project
   - Contains its own lib/, assets/, ios/, android/, etc.
   - Has nested backups inside: `Flutter_wandermood/backups/`
   - Has nested backups: `Flutter_wandermood/current_backup_20250321_205958/`
   - Has nested backups: `Flutter_wandermood/WanderMoodV1_backup_20250321_173502/`
   - Has nested backups: `Flutter_wandermood/WanderMoodV2_backup_20250321_203113/`

3. **`archive/`** (97 MB)
   - Old archived code and assets
   - `archive/lib/` - 173 files (169 Dart files)
   - `archive/assets/` - 31 files (19 JPG, 7 JSON, 2 JPEG)
   - `archive/images/` - 21 files (19 JPG, 2 JPEG)
   - `archive/explore_20250326_181748/`
   - `archive/explore_20250326_233345/`
   - `archive/explore_screens/`
   - `archive/mood_screens_cleanup_20250713_195440/`
   - `archive/old_diary_screens/`
   - `archive/old_home_screens/`
   - `archive/place_detail_20250624_220646/`
   - `archive/place_detail_20250624_220950/`
   - `archive/places_explore_screen_old.dart`
   - `archive/docs/`
   - `archive/icons/`
   - `archive/pubspec.yaml`
   - `archive/pubspec.lock`
   - `archive/README.md`
   - `archive/todo_list.md`
   - `archive/analysis_options.yaml`

4. **`current_backup_20250321_205958/`** (43 MB)
   - Old backup from March 2025
   - `current_backup_20250321_205958/lib/` - 89 files
   - `current_backup_20250321_205958/assets/` - 20 files
   - `current_backup_20250321_205958/pubspec.yaml`
   - `current_backup_20250321_205958/pubspec.lock`
   - `current_backup_20250321_205958/analysis_options.yaml`

---

## 📁 PHASE 2: DUPLICATE/OLD CODE FOLDERS (~300 MB)

5. **`lib_old/`** (64 KB)
   - `lib_old/core/`
   - `lib_old/features/`
   - `lib_old/main.dart`

6. **`lib/archive/`** (~200 MB)
   - Entire archived code folder inside lib/
   - Contains 198 files (194 Dart files, 2 .bak, 2 .sql)
   - Old implementations no longer used

7. **`supabase_backup_with_issues/`** (232 KB)
   - Backup with known issues
   - `supabase_backup_with_issues/migrations_backup/`
   - `supabase_backup_with_issues/functions/`
   - Contains 26 files (16 SQL, 6 TS, 2 JSON)

---

## 📁 PHASE 3: ROOT LEVEL FILES & FOLDERS

### Old TypeScript Files (Root Level):

8. **`wandermood-ai-dashboard-deploy.ts`** (root)
9. **`wandermood-ai-fixed.ts`** (root)
10. **`wandermood-ai-updated.ts`** (root)
11. **`wandermood-ai-updated-short.ts`** (root)

### Test/Example Files (Root Level):

12. **`example_navigator.dart`** (root)
13. **`test_activity_filtering.dart`** (root)
14. **`clear_cache_debug.dart`** (root)
15. **`app.dart`** (root - duplicate, main.dart exists)

### Old Functions Folder (Root Level):

16. **`functions/`** (root level - duplicate of supabase/functions)
   - `functions/getCurrentWeather/index.ts`
   - `functions/getHistoricalWeather/index.ts`

### Log Files:

17. **`flutter_01.log`**
18. **`flutter_01.png`**
19. **`logs.txt`**
20. **`push.log`**

### Duplicate Asset Folders:

21. **`images/`** (root - only 4 PNG files, likely duplicates)
22. **`icons/`** (root - duplicate icons, already in assets/)

---

## 📁 PHASE 4: BACKUP FILES (.bak)

### All .bak Files (excluding Pods - those regenerate):

23. **`.env.bak`** (root)
24. **`features/home/presentation/screens/home_screen.dart.bak`**
25. **`lib/archive/20250327_093243/features/home/presentation/screens/home_content.dart.bak`**
26. **`lib/archive/20250327_093243/features/home/presentation/screens/home_screen.dart.bak`**
27. **`lib/features/home/presentation/screens/archive/home_screen.dart.bak`**
28. **`lib/features/home/presentation/screens/archived_home_screens/home_screen.dart.bak`**

### Note: Build/Pods .bak files will be regenerated:
- `build/ios/.../*.bak` (will regenerate)
- `ios/Pods/GoogleMaps/.../*.bak` (will regenerate)

---

## 📁 PHASE 5: DUPLICATE CONFIG & DOCS

### Duplicate Config Files in Flutter_wandermood:

26. **`Flutter_wandermood/config.toml`**
27. **`Flutter_wandermood/pubspec.yaml`**
28. **`Flutter_wandermood/pubspec.lock`**
29. **`Flutter_wandermood/analysis_options.yaml`**
30. **`Flutter_wandermood/README.md`**
31. **`Flutter_wandermood/todo_list.md`**
32. **`Flutter_wandermood/App_Fix.md`**
33. **`Flutter_wandermood/Explore_doc.md`**
34. **`Flutter_wandermood/main.dart`** (duplicate)
35. **`Flutter_wandermood/app.dart`** (duplicate)

### Old Migration Files (Review First):

36. **`migrations/`** (root level - verify if already applied)
   - Check if these migrations are already in supabase/migrations/
   - Only delete if confirmed applied

37. **`Flutter_wandermood/migrations/`**
   - `Flutter_wandermood/migrations/20240321000000_create_helper_functions.sql`
   - `Flutter_wandermood/migrations/20240321000001_create_moods_table.sql`
   - `Flutter_wandermood/migrations/20240321000002_create_activities_table.sql`
   - `Flutter_wandermood/migrations/20240321000003_create_mood_stats_function.sql`

---

## 📁 PHASE 6: BUILD ARTIFACTS (Verify .gitignore First)

### Build Folders (Should be in .gitignore):

38. **`build/`** (root - verify gitignored)
39. **`Flutter_wandermood/build/`** (if exists)
40. **`Pods/`** (root - verify gitignored, regenerated)
41. **`Flutter_wandermood/Pods/`** (duplicate)

---

## 📋 COMPLETE FILE LIST (Detailed)

### Backup Folders:
```
backups/
├── WanderMood_july16th_8PM/
│   └── [3,084+ files - entire project backup]

Flutter_wandermood/
├── [Entire duplicate project - 599 MB]
├── backups/
├── current_backup_20250321_205958/
├── WanderMoodV1_backup_20250321_173502/
└── WanderMoodV2_backup_20250321_203113/

archive/
├── lib/ [173 files]
├── assets/ [31 files]
├── images/ [21 files]
└── [various old screen folders]

current_backup_20250321_205958/
├── lib/ [89 files]
└── assets/ [20 files]
```

### Code Folders:
```
lib_old/
├── core/
├── features/
└── main.dart

lib/archive/
└── [198 files - old implementations]

supabase_backup_with_issues/
├── migrations_backup/
└── functions/
```

### Root Level Files:
```
wandermood-ai-dashboard-deploy.ts
wandermood-ai-fixed.ts
wandermood-ai-updated.ts
wandermood-ai-updated-short.ts
example_navigator.dart
test_activity_filtering.dart
clear_cache_debug.dart
app.dart
flutter_01.log
flutter_01.png
logs.txt
push.log
```

### Root Level Folders:
```
functions/ (old, duplicate)
images/ (4 PNG files)
icons/ (duplicate)
```

### .bak Files:
```
features/home/presentation/screens/home_screen.dart.bak
features/home/presentation/screens/home_content.dart.bak
.env.bak
[+ various in Pods - will regenerate]
```

---

## ⚠️ SAFETY CHECKLIST

Before deleting, verify:
- [ ] All important code is in current `lib/` folder
- [ ] All active Edge Functions are in `supabase/functions/`
- [ ] All active migrations are in `supabase/migrations/`
- [ ] **Main `docs/` folder is NOT in this deletion list** ✅ VERIFIED
- [ ] **Root `README.md` is NOT in this deletion list** ✅ VERIFIED
- [ ] Git repository is up to date and committed
- [ ] You have an external backup of the entire project
- [ ] You've reviewed this list and confirmed deletions

### 📚 DOCUMENTATION SAFETY VERIFICATION

**✅ CONFIRMED SAFE:**
- Main `docs/` folder (96 files) - **NOT listed for deletion**
- Root `README.md` - **NOT listed for deletion**
- `docs/database/` - **NOT listed for deletion**
- `docs/Wander_Doc.md/` - **NOT listed for deletion**

**⚠️ Only these docs are being deleted (safe):**
- `archive/docs/` - Old archived docs
- `Flutter_wandermood/` folder docs - Duplicate project docs
- `backups/` folder docs - Backup docs

**See `docs/DOCUMENTATION_SAFETY_CHECK.md` for full verification.**

---

## 📊 SUMMARY STATISTICS

- **Total Folders to Delete:** ~15 major folders
- **Total Files to Delete:** ~4,000+ files
- **Total Size:** ~3.5 GB
- **Largest Items:**
  - backups/ (2.4 GB)
  - Flutter_wandermood/ (599 MB)
  - archive/ (97 MB)
  - current_backup_20250321_205958/ (43 MB)

---

## 🎯 DELETION ORDER RECOMMENDATION

1. **Phase 1:** Large backups (saves 3.1 GB)
2. **Phase 2:** Duplicate code folders (saves 300 MB)
3. **Phase 3:** Root level cleanup (saves 50 MB)
4. **Phase 4:** .bak files (saves 10 MB)
5. **Phase 5:** Review migrations before deleting
6. **Phase 6:** Build artifacts (verify .gitignore first)

---

## 📝 NOTES

- This file is a **reference list only** - nothing has been deleted yet
- Review each phase before execution
- Consider keeping one backup externally before deleting
- Some items (like build/Pods) may regenerate automatically
- Migration files should be verified as applied before deletion

---

**Status:** ✅ LIST COMPLETE - READY FOR REVIEW

