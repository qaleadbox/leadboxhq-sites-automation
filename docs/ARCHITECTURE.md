# LeadBox HQ Sites Automation - Architecture

## Overview

This is a Robot Framework test automation system designed to validate contact links and other functionality across 100+ automotive dealership websites. The system features checkpoint/resume support, intelligent URL tracking, and efficient multi-validation testing.

## Core Components

### 1. Multi-Site Testing Framework
**Location:** `Resources/Integrated Tests/multi_site_testing.robot`

**Main Keyword:** `Parse Sitemap URLs`

#### Parameters:
- `@{validation_keywords}` - **List of validation keywords** to run on each URL
- `${pages_samples}` - Number of pages to test (default: `None` = all pages)
- `${used_vehicle_samples}` - Sample size for used vehicle pages (default: 1)
- `${new_vehicle_samples}` - Sample size for new vehicle pages (default: 1)
- `${showroom_samples}` - Sample size for showroom pages (default: 1)
- `${models_samples}` - Sample size for model pages (default: 1)
- `${model_trims_samples}` - Sample size for model trim pages (default: 1)
- `${skip_*_if_sampled}` - Skip section if at least one sample already tested (default: false)

#### Usage Example:
```robot
Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    Validate URL Links Matches It HREF
    ...    Validate Page URL Is Secure HTTPS
    ...    pages_samples=None
    ...    used_vehicle_samples=1
```

### 2. Multi-Validation System

**Key Feature:** Each URL is tested **once** with **all validations**, not multiple passes.

#### How It Works:
1. System parses list of validation keywords
2. For each URL, determines which validations are needed
3. Opens URL once and runs all pending validations
4. Tracks each validation independently in checkpoint

#### Keyword: `Test URL With Multiple Validations`
```robot
# Opens URL once, runs all validations, returns results per validation
${results}=    Test URL With Multiple Validations    ${url}    ${validation_list}
# Returns: {
#   "Validate Contact Links Matches It HREF": {status: PASS/FAIL, description: ..., details: ...},
#   "Validate Accessibility": {status: PASS/FAIL, ...}
# }
```

### 3. Checkpoint System

**Location:** `Resources/Helpers/checkpoint_helpers.robot`

**Files:**
- `checkpoints/checkpoint.json` - Main checkpoint with progress tracking
- `checkpoints/issues.json` - Logged issues/failures

#### Checkpoint Structure:
```json
{
  "checkpoint": {
    "timestamp": "2026-01-26T19:40:05Z",
    "test_run_id": "test_contact_links_...",
    "total_sites": 106,
    "sites_processed": 2,
    "expected_validations": [  // List of validation keywords being tested
      "Validate Contact Links Matches It HREF",
      "Validate URL Links Matches It HREF",
      "Validate Page URL Is Secure HTTPS"
    ],
    "sites_completed": [
      {
        "name": "Site Name",
        "url": "https://example.com",
        "runned_validations": "2/3",  // X/Y where X=completed validations, Y=total validations
        "section_counters": {
          "pages": "0/0",           // Placeholder - NOT USED (we use tested_links instead)
          "used_vehicles": "1/1",
          "new_vehicles": "1/1",
          "showroom": "1/1",
          "models": "1/1",
          "model_trims": "1/1"
        },
        "validation_tracking": {
          "pages": {
            "tested_links": {
              "https://example.com/about": ["Validation1", "Validation2"],
              "https://example.com/contact": ["Validation1"]
            },
            "all_covered": {
              "Validation1": true,      // All pages tested with this validation
              "Validation2": false
            }
          },
          "used_vehicles": {"tested_links": {}, "all_covered": {}},
          "new_vehicles": {"tested_links": {}, "all_covered": {}},
          "showroom": {"tested_links": {}, "all_covered": {}},
          "models": {"tested_links": {}, "all_covered": {}},
          "model_trims": {"tested_links": {}, "all_covered": {}}
        }
      }
    ]
  }
}
```

#### Key Concepts:

**Section Counters:**
- Format: `"tested/total"` (e.g., `"45/68"`)
- Tracks progress through each section
- Pages section uses link tracking (detailed)
- Other sections use simple sampling counters

**Validation Tracking (All sections):**
- Each section (pages, used_vehicles, etc.) has its own tracking
- Tracks which URLs were tested with which validations
- Prevents duplicate testing
- Each URL can be tested with multiple validations independently
- `all_covered` flag set when all URLs tested with specific validation
- Pages section fully uses this tracking; other sections being migrated

**Resume Logic:**
- Sites with incomplete `runned_validations` (e.g., "1/3" meaning 1 out of 3 validations completed) are resumed
- System checks both counters AND `all_pages_covered` flags to determine which validations need to run
- Validations are tracked independently per site

### 4. Validation Keywords

**Location:** `Resources/Validations/*.robot`

#### Available Validations:

1. **`Validate Contact Links Matches It HREF`**
   - File: `Resources/Validations/contact_links.robot`
   - Validates phone numbers in links match href format
   - Uses: `Verify Phone Links On Current Page`

2. **`Validate Contact Links Are Clickable`**
   - File: `Resources/Validations/contact_links.robot`
   - Validates all contact info (phone, email, address) is clickable

3. **`Validate Page URL Is Secure HTTPS`**
   - File: `Resources/Validations/security.robot`
   - Validates that the current page uses HTTPS protocol
   - Simple validation to ensure secure connections

4. **`Validate URL Links Matches It HREF`**
   - File: `Resources/Validations/url_links.robot`
   - Validates that all text containing "http://" or "https://" is clickable
   - Verifies the displayed URL text matches the actual href attribute
   - Checks for non-clickable URLs (text not inside <a> tags)

#### Creating New Validations:

```robot
# In Resources/Validations/your_validation.robot
Validate Your Feature
    [Documentation]    Validates specific feature on current page
    # Your validation logic here
    # Fail if validation fails, pass if successful
```

Then use it:
```robot
Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    Validate Your Feature
```

### 5. Sitemap Parser

**Location:** `Parser/sitemap_parser.robot`

**Keyword:** `Extract Sitemap Sections`

Extracts URLs from site sitemap and categorizes them:
- **Pages** - General content pages
- **Used Vehicles** - Used inventory listings
- **New Vehicles** - New inventory listings
- **Showroom** - Showroom/browse pages
- **Models** - Model information pages
- **Model Trims** - Specific trim pages

Uses HTML section headers if available, falls back to URL pattern matching.

### 6. Issue Logger

**Location:** `Resources/Helpers/issue_logger.robot`

**File:** `checkpoints/issues.json`

Logs failures with details:
```json
{
  "issues": [
    {
      "site_name": "Site Name",
      "url": "https://example.com/page",
      "description": "Phone link mismatch",
      "category": "Page",
      "details": "Expected tel:+1234567890, got tel:1234567890",
      "unique_id": "unique-span-id",  // Prevents duplicate logging
      "timestamp": "2026-01-26T19:40:05Z"
    }
  ]
}
```

## Workflow

### Initial Run:
1. Load sites from Google Sheets
2. Create checkpoint structure
3. For each site:
   - Load sitemap
   - Extract URLs by section
   - Initialize counters (e.g., `"pages": "0/68"`)
   - Test sampled URLs with all validations
   - Track results per validation per URL
   - Update counters and checkpoint
   - Mark site as completed

### Resume Run:
1. Load existing checkpoint
2. Skip sites marked as `"completed"` with all counters complete
3. Resume sites with `"status": "in_progress"`
4. For each resumed site:
   - Check which validations are incomplete
   - Find URLs not tested with pending validations
   - Test only what's needed
   - Continue from where it left off

## Best Practices

### Adding New Test Suites:
```robot
*** Test Cases ***
Test Your Feature
    Parse Sitemap URLs
    ...    Validate Your Feature 1
    ...    Validate Your Feature 2
    ...    pages_samples=10           # Sample 10 pages
    ...    used_vehicle_samples=1     # Sample 1 used vehicle
    # ...
```

### Multiple Validations:
- **Always pass as list**, not comma-separated string
- Each validation runs once per URL
- Results tracked independently
- Failed validations don't stop other validations

### Checkpoint Management:
- **Reset:** Delete `checkpoints/checkpoint.json` to start fresh
- **Resume:** Keep file to continue from last run
- **Issues:** Check `checkpoints/issues.json` for failures

### Performance Tips:
1. Use sampling for large sites (`pages_samples=50` instead of `None`)
2. Use `skip_*_if_sampled=true` when you just need coverage checks
3. Multiple validations per URL saves time vs separate runs
4. Headless mode (`${HEADLESS}=true`) is faster but less stable

## Key Files

```
leadboxhq-sites-automation/
├── Suites/
│   └── Functional & Accessibility Testing/
│       └── Test contact links.robot          # Main test suite
├── Resources/
│   ├── Integrated Tests/
│   │   └── multi_site_testing.robot          # Core framework
│   ├── Validations/
│   │   ├── contact_links.robot               # Contact validations
│   │   └── phone_links.robot                 # Phone-specific logic
│   └── Helpers/
│       ├── checkpoint_helpers.robot          # Checkpoint system
│       ├── issue_logger.robot                # Issue logging
│       ├── browser_helpers.robot             # Browser utilities
│       └── csv_helpers.robot                 # Google Sheets loader
├── Parser/
│   └── sitemap_parser.robot                  # Sitemap extraction
├── checkpoints/
│   ├── checkpoint.json                       # Progress tracking
│   └── issues.json                           # Failed tests log
└── Resources/
    └── variables.robot                        # Configuration
```

## Configuration

**File:** `Resources/variables.robot`

```robot
${SPREADSHEET_LINK}    https://docs.google.com/...
${HEADLESS}            false    # true = no UI, false = show browser
${USE_CHECKPOINT}      true     # Enable checkpoint/resume
```

## Troubleshooting

### Pages Section Always Skips:
**Symptom:** Counter shows `"45/68"` but sections skips

**Cause:** `all_pages_covered` flag incorrectly set to `true`

**Fix:** Remove the validation from `all_pages_covered` in checkpoint.json:
```json
"all_pages_covered": {}  // Remove any validations listed here
```

### Browser Crashes in Headless:
**Cause:** Memory issues with many tabs

**Fix:** System auto-restarts browser and retries site

### Duplicate Issues Logged:
**Cause:** Same element failing multiple times

**Solution:** System uses `unique_id` to deduplicate issues automatically

## Future Enhancements

- [ ] Parallel site testing
- [ ] Visual regression testing
- [ ] Performance metrics tracking
- [ ] Automated PR creation for failures
- [ ] CI/CD integration
