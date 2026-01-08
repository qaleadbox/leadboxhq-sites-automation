# Changelog

## [2026-01-06 Documentation Update] - Professional README Rewrite

### Changed
- **commands/README.md** - Complete professional rewrite
  - Restructured for clarity and conciseness
  - Added comprehensive tables for quick reference
  - Improved navigation with better section organization
  - Added sample size recommendations with duration estimates
  - Included all new documentation files (CHANGELOG, DEBUG-COMMANDS, QUICK-CONTEXT)
  - Professional tone and formatting throughout
  - Added maintenance checklist and support section

### Benefits
1. **Better Onboarding**: Clear structure helps new developers get started faster
2. **Quick Reference**: Tables provide at-a-glance information
3. **Professional**: Polished documentation reflects project quality
4. **Comprehensive**: All resources documented in one place

---

## [2026-01-06 Late Night] - Models & Model Trims Section Detection

### Added
- **HTML Section Header Detection**
  - Added `Extract Sitemap URLs By Section` keyword to parse HTML sitemap sections
  - Now detects section headers (h2, h3) like "Pages", "Models", "Models Trims", "Showroom", "Vehicles"
  - Extracts URLs under each section header accurately

### Fixed
- **Models and Model Trims Not Being Tested**
  - **Problem**: Models (50 URLs) and Model Trims (221 URLs) were not being opened
  - **Root Cause**: These URLs don't have distinct path patterns - they're organized by HTML section headers
  - **Solution**: Updated `Extract Sitemap Sections` to detect HTML section structure first, fallback to URL patterns for XML sitemaps

### Results (Addison Chevrolet Erin Mills)
**Before Fix:**
- Models: 0 detected ❌
- Model Trims: 0 detected ❌
- (All miscategorized as new_vehicles)

**After Fix:**
- 58 pages ✅
- 44 used vehicles ✅
- 146 new vehicles ✅
- 28 showroom ✅
- **50 models ✅** (NOW WORKING!)
- **221 model trims ✅** (NOW WORKING!)

### Modified Files
- `Parser/sitemap_parser.robot`
  - Added `Extract Sitemap URLs By Section` keyword
  - Updated `Extract Sitemap Sections` to detect HTML headers first
  - Maintains backward compatibility with XML sitemaps (fallback to URL pattern matching)

### Visual Behavior Note
**"Blinking" Chrome tabs during testing is NORMAL:**
- Each URL test: Opens tab → Switches focus → Tests → Closes → Returns to main
- 4 visual changes per URL in ~4 seconds
- Not a bug - just ChromeDriver behavior
- Options: Use headless mode or minimize browser

### Benefits
1. **Complete Coverage**: All sitemap sections now properly tested
2. **Accurate Categorization**: HTML sections take priority over URL patterns
3. **Backward Compatible**: Still works with XML sitemaps
4. **Better Sampling**: 6 sections tested per site (was 4 before)

---

## [2026-01-06 Late Evening] - Critical URL Categorization Fix

### Fixed
- **URL Categorization Bug** (CRITICAL)
  - **Problem**: All vehicle URLs (660+) were being miscategorized as "pages"
  - **Root Cause**: Detection only looked for `/vehicle/` but real URLs use `/new/`, `/used/`, `/view/`
  - **Impact**: Sampling wasn't working - tried to sample from wrong category
  - **Fix**: Updated vehicle detection to check for multiple patterns:
    - `/vehicle/` - Generic vehicle pages
    - `/view/` - Individual vehicle detail pages (used or new)
    - `/new/` - New vehicle directory pages
    - `/used/` - Used vehicle directory pages
    - `/new-` - New vehicle in URL slug
    - `/used-` - Used vehicle in URL slug

### Results (Addison Chevrolet Erin Mills)
**Before Fix:**
- 660 pages (WRONG - all vehicles miscategorized)
- 0 used vehicles
- 0 new vehicles
- 28 showroom

**After Fix:**
- 189 pages ✅
- 49 used vehicles ✅
- 422 new vehicles ✅
- 28 showroom ✅

### Modified Files
- `Parser/sitemap_parser.robot`
  - **Extract Sitemap Sections** keyword: Complete rewrite of vehicle detection logic
  - Now checks priority: showroom → model_trims → models → vehicles → pages
  - Vehicle category determined by checking all possible URL patterns

### Added
- `commands/DEBUG-COMMANDS.md` - Comprehensive debugging guide with:
  - URL categorization testing scripts
  - Race condition debugging
  - Sitemap analysis commands
  - Performance testing procedures
  - Common issues and fixes
  - Git revert commands

### Benefits
1. **Correct Sampling**: Now properly samples from each category
2. **Performance**: Doesn't try to open 660 pages when only 1 sample requested
3. **Accuracy**: Each URL type properly categorized
4. **Debuggability**: Added comprehensive debugging guide for future issues

---

## [2026-01-06 Evening] - Sampling Clarity & Race Condition Fixes

### Changed
- **Improved Console Log Messages**
  - Changed "Testing X of Y page URLs..." to "Sampling X from Y detected page URLs..."
  - Changed "Testing all X page URLs..." to "Testing all X detected page URLs..."
  - Applied to all sections: pages, used vehicles, new vehicles, showroom, models, model trims
  - Makes it clear that the sample count is respected even when many URLs are detected

- **Fixed Race Conditions in Tab Opening**
  - Increased sleep after opening new tab: `0.5s` → `1s`
  - Added sleep after switching to new window: `0.5s`
  - Increased sleep after closing window: `0.3s` (with additional `0.5s` after switching back)
  - Increased sleep between URL tests in loops: `0.2s` → `0.5s`
  - Prevents window handle conflicts and ensures proper tab cleanup

### Modified Files
- `Shared resources/keywords.robot`
  - **Test Sitemap URLs In Real Time** keyword: Updated all logging messages
  - **Test URL In New Tab** keyword: Improved timing and window handling

### Benefits
1. **Clearer Output**: Users immediately understand sampling behavior
2. **More Stable**: Reduced race conditions when opening/closing tabs
3. **Better Reliability**: Proper delays prevent window handle conflicts

---

## [2026-01-06] - Sitemap Sampling Enhancement

### Added
- **Split Vehicle Categories**
  - Separated `vehicles` into `used_vehicle_samples` and `new_vehicle_samples`
  - Detection based on "used" or "new" keywords in URL (case-insensitive)
  - Defaults to `new_vehicles` if neither keyword found

- **Parameter Suffix Standardization**
  - Added `_samples` suffix to ALL sampling parameters:
    - `pages` → `pages_samples`
    - `vehicles` → `used_vehicle_samples` + `new_vehicle_samples`
    - `showroom` → `showroom_samples`
    - `models` → `models_samples`
    - `model_trims` → `model_trims_samples`

- **Documentation Files**
  - Created `commands/prompts/sitemap-url-sampling.md` - Comprehensive guide to URL sampling
  - Created `commands/QUICK-CONTEXT.md` - Quick reference for starting new AI conversations
  - Created `commands/CHANGELOG.md` - This file

### Modified

#### Parser/sitemap_parser.robot
- **Extract Sitemap Sections** keyword:
  - Added `used_vehicles` and `new_vehicles` sections to dictionary
  - Implemented vehicle type detection logic
  - Updated section categorization

- **Get Test URLs From Sitemap** keyword:
  - Renamed all parameters with `_samples` suffix
  - Split vehicle sampling into used and new categories
  - Updated random sampling logic for both vehicle types
  - Fixed variable naming conflicts with `_int` suffix

#### Shared resources/keywords.robot
- **Validate Contact Links Matches It HREF** keyword:
  - Updated signature with new parameter names
  - Pass through new parameters to validation function

- **Run Multi Site Validation** keyword:
  - Updated signature with new parameter names
  - Updated function calls with new parameters

- **Parse Sitemap And Get Test URLs** keyword:
  - Updated signature with new parameter names
  - Updated console logging format (added `uv` and `nv` indicators)
  - Pass new parameters to sitemap parser

#### Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot
- Updated test case with new parameter names
- Added separate parameters for used and new vehicles

#### commands/config.json
- Added `sitemap_sampling` section with:
  - Section definitions
  - Parameter documentation
  - Detection rules

#### commands/README.md
- Added documentation for `sitemap-url-sampling.md`
- Updated available prompts list

### Console Output Format Updated
```
Old: Found N URLs (p=X v=Y s=Z m=A mt=B)
New: Found N URLs (p=X uv=Y nv=Z s=A m=B mt=C)
```

Where:
- `p` = pages_samples
- `uv` = used_vehicle_samples (NEW)
- `nv` = new_vehicle_samples (NEW)
- `s` = showroom_samples
- `m` = models_samples
- `mt` = model_trims_samples

### Validation
- Dry run test passed successfully
- All syntax validated
- Parameter passing confirmed working

### Benefits
1. **More Granular Control**: Separate sampling for used vs new vehicles
2. **Better Consistency**: All parameters follow `_samples` naming convention
3. **Improved Detection**: Automatic categorization of vehicle types
4. **Documentation**: Comprehensive guides to reduce token usage in future conversations
5. **Quick Context**: Fast project onboarding for AI assistants

### Migration Guide

#### For Test Suites
Update parameter names:
```robot
# Old
pages=2
vehicles=1
showroom=1
models=1
model_trims=1

# New
pages_samples=2
used_vehicle_samples=1
new_vehicle_samples=1
showroom_samples=1
models_samples=1
model_trims_samples=1
```

#### For Keywords
Update function signatures and calls:
```robot
# Old
[Arguments]    ${pages}=None    ${vehicles}=1    ${showroom}=1

# New
[Arguments]    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1
```

### Backward Compatibility
⚠️ **Breaking Changes**: Old parameter names are no longer supported. All existing test suites and keyword calls must be updated.

### Files to Reference in New Conversations
To save tokens when starting a new AI conversation, share:
1. `commands/QUICK-CONTEXT.md` - Essential project overview
2. `commands/prompts/sitemap-url-sampling.md` - Detailed sampling docs (if working with sitemaps)
3. `commands/config.json` - Full configuration (if needed)

### Testing Recommendations

#### Quick Test (Fast)
```robot
pages_samples=1
used_vehicle_samples=1
new_vehicle_samples=1
showroom_samples=1
models_samples=0
model_trims_samples=0
```

#### Standard Test (Balanced)
```robot
pages_samples=3
used_vehicle_samples=2
new_vehicle_samples=2
showroom_samples=1
models_samples=1
model_trims_samples=1
```

#### Comprehensive Test (Thorough)
```robot
pages_samples=None              # ALL pages
used_vehicle_samples=5
new_vehicle_samples=5
showroom_samples=2
models_samples=3
model_trims_samples=2
```

---

**Date**: 2026-01-06
**Impact**: Breaking change - All existing tests need parameter updates
**Status**: Complete and validated
