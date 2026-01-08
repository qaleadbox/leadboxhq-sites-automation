# Sitemap URL Sampling Pre-Prompt

## Context
This is the LeadBox Sites Automation project. This prompt explains the sitemap URL sampling functionality for multi-site testing of dealership websites.

## Overview
The project includes functionality to extract URLs from dealership sitemaps and test random samples from different sections of the website.

## URL Sections
The sitemap parser categorizes URLs into the following sections:

1. **pages** - All general website pages (e.g., home, about, services)
2. **used_vehicles** - Vehicle detail pages containing "used" in the URL
3. **new_vehicles** - Vehicle detail pages containing "new" in the URL (default if neither found)
4. **showroom** - Showroom/inventory listing pages
5. **models** - Vehicle model pages
6. **model_trims** - Model trim/variant pages

## Parameters (All with `_samples` suffix)

### `pages_samples`
- **Type**: Integer or "None"
- **Default**: None
- **Behavior**:
  - If "None": Tests ALL page URLs (no sampling)
  - If number: Tests N random pages
- **Example**: `pages_samples=2` tests 2 random pages

### `used_vehicle_samples`
- **Type**: Integer
- **Default**: 1
- **Detection**: URLs containing "used" (case-insensitive)
- **Example**: `used_vehicle_samples=3` tests 3 random used vehicles

### `new_vehicle_samples`
- **Type**: Integer
- **Default**: 1
- **Detection**: URLs containing "new" (case-insensitive), or default if neither "used" nor "new"
- **Example**: `new_vehicle_samples=2` tests 2 random new vehicles

### `showroom_samples`
- **Type**: Integer
- **Default**: 1
- **Detection**: URLs containing "/showroom/"
- **Example**: `showroom_samples=1` tests 1 showroom page

### `models_samples`
- **Type**: Integer
- **Default**: 1
- **Detection**: URLs containing "/models/"
- **Example**: `models_samples=2` tests 2 model pages

### `model_trims_samples`
- **Type**: Integer
- **Default**: 1
- **Detection**: URLs containing "/model-trims/"
- **Example**: `model_trims_samples=1` tests 1 trim page

## How It Works

### 1. URL Extraction (`Extract Sitemap Sections`)
- Located in: `Parser/sitemap_parser.robot`
- Parses sitemap (XML or HTML format)
- Categorizes each URL into sections based on path patterns
- Returns a dictionary with all sections

### 2. Vehicle Type Detection
For URLs containing `/vehicle/`:
```robot
IF url contains "used":
    → Add to used_vehicles list
ELSE IF url contains "new":
    → Add to new_vehicles list
ELSE:
    → Default to new_vehicles list
```

### 3. Random Sampling (`Get Test URLs From Sitemap`)
- Located in: `Parser/sitemap_parser.robot`
- Takes sample parameters for each section
- Returns random samples from each section
- Pages can be ALL (None) or sampled (number)

### 4. Multi-Site Testing (`Validate Contact Links Matches It HREF`)
- Located in: `Shared resources/keywords.robot`
- Reads sites from spreadsheet
- For each site: fetches sitemap, extracts URLs, tests samples
- Tracks passed/failed results

## Example Usage

### Test Suite Configuration
```robot
*** Test Cases ***
Test contact links from sitemap URLs
    Validate Contact Links Matches It HREF
    ...    multi_site=True
    ...    pages_samples=2
    ...    used_vehicle_samples=1
    ...    new_vehicle_samples=1
    ...    showroom_samples=1
    ...    models_samples=1
    ...    model_trims_samples=1
```

### Direct Keyword Call
```robot
@{test_urls}=    Get Test URLs From Sitemap
...    ${sitemap_source}
...    pages_samples=None          # Test ALL pages
...    used_vehicle_samples=3      # 3 random used vehicles
...    new_vehicle_samples=2       # 2 random new vehicles
...    showroom_samples=1          # 1 showroom page
...    models_samples=2            # 2 model pages
...    model_trims_samples=1       # 1 trim page
```

## Console Output Format
```
Site: Dealership Name
Found 25 URLs (p=2 uv=1 nv=1 s=1 m=1 mt=1)
Testing: https://dealer.com/about
Testing: https://dealer.com/contact
Testing: https://dealer.com/vehicle/used-2020-honda-civic
Testing: https://dealer.com/vehicle/new-2024-toyota-camry
Testing: https://dealer.com/showroom
Testing: https://dealer.com/models/honda
Testing: https://dealer.com/model-trims/civic-ex
```

Legend:
- `p` = pages_samples
- `uv` = used_vehicle_samples
- `nv` = new_vehicle_samples
- `s` = showroom_samples
- `m` = models_samples
- `mt` = model_trims_samples

## Files Reference

### Core Parser
- **File**: `Parser/sitemap_parser.robot`
- **Keywords**:
  - `Extract Sitemap Sections` - Categorizes URLs into sections
  - `Get Test URLs From Sitemap` - Returns sampled URLs for testing

### Multi-Site Testing
- **File**: `Shared resources/keywords.robot`
- **Keywords**:
  - `Validate Contact Links Matches It HREF` - Main validation keyword
  - `Run Multi Site Validation` - Batch processing for multiple sites
  - `Parse Sitemap And Get Test URLs` - Fetches and parses sitemap

### Test Suites
- **File**: `Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot`
- **Purpose**: Tests contact links on sampled URLs across multiple sites

## Best Practices

### Sample Size Recommendations
- **Development/Quick Tests**: Use small samples (1-2 per section)
- **Pre-Production**: Use medium samples (3-5 per section)
- **Full Regression**: Use large samples or `pages_samples=None` for all pages

### Performance Considerations
- Each URL opens in a new browser tab (2s delay per page)
- Large sample sizes will increase test execution time
- Consider running in parallel for large batches

### Typical Test Configuration
```robot
# Quick smoke test (fast)
pages_samples=1
used_vehicle_samples=1
new_vehicle_samples=1
showroom_samples=1
models_samples=0
model_trims_samples=0

# Standard test (balanced)
pages_samples=3
used_vehicle_samples=2
new_vehicle_samples=2
showroom_samples=1
models_samples=1
model_trims_samples=1

# Comprehensive test (thorough)
pages_samples=None              # ALL pages
used_vehicle_samples=5
new_vehicle_samples=5
showroom_samples=2
models_samples=3
model_trims_samples=2
```

## Extending the Functionality

### Add New Section
1. Update `Extract Sitemap Sections` to detect new URL pattern
2. Add new section to dictionary
3. Add new `_samples` parameter to `Get Test URLs From Sitemap`
4. Add sampling logic for the new section
5. Update all calling keywords with new parameter

### Modify Vehicle Detection
Current detection uses simple substring matching. To improve:

```robot
# More sophisticated detection
${is_used}=    Run Keyword And Return Status
...    Should Match Regexp    ${url_lower}    /vehicle/(used|pre-owned|certified)/

${is_new}=    Run Keyword And Return Status
...    Should Match Regexp    ${url_lower}    /vehicle/(new|brand-new)/
```

## Troubleshooting

### Issue: Not enough URLs in a section
**Behavior**: If section has fewer URLs than requested samples, all available URLs are used
**Example**:
- Request: `used_vehicle_samples=5`
- Available: 2 used vehicles
- Result: Tests 2 vehicles (all available)

### Issue: URLs not categorized correctly
**Solution**: Check URL patterns in sitemap. May need to adjust detection logic in `Extract Sitemap Sections`

### Issue: Want to skip a section
**Solution**: Set sample count to 0
```robot
models_samples=0           # Skip model pages
model_trims_samples=0      # Skip trim pages
```

## Related Files
- Config: `commands/config.json`
- CSV Parser: `Parser/csv_parser.robot`
- Helpers: `Shared resources/helpers.robot`
- Variables: `Shared resources/variables.robot`
