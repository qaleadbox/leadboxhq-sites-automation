# Debug Commands for Future Fixes

## URL Categorization Debugging

### Test URL Categorization Logic
```bash
# Create test script to verify URL patterns
cat > /tmp/test_sitemap_urls.py << 'EOF'
test_urls = [
    "https://addisononeglinton.com/new/2025-chevrolet-trailblazer/",
    "https://addisononerinmills.com/view/new-2026-gmc-sierra-1500-1449480/",
    "https://addisongm.com/view/used-2022-chevrolet-trailblazer-1571041/",
    "https://addisononeglinton.com/showroom/2026-chevrolet-trax_51114/",
    "https://example.com/models/chevrolet/",
    "https://example.com/model-trims/corvette-z06/",
]

for url in test_urls:
    url_lower = url.lower()

    # Check patterns
    has_vehicle = '/vehicle/' in url_lower
    has_view = '/view/' in url_lower
    has_new = '/new/' in url_lower or '/new-' in url_lower
    has_used = '/used/' in url_lower or '/used-' in url_lower
    has_showroom = '/showroom/' in url_lower
    has_models = '/models/' in url_lower
    has_trims = '/model-trims/' in url_lower

    is_vehicle = has_vehicle or has_view or has_new or has_used

    print(f"\nURL: {url}")
    print(f"  Patterns: vehicle={has_vehicle}, view={has_view}, new={has_new}, used={has_used}")
    print(f"  Is Vehicle: {is_vehicle}")

    # Categorize
    if has_showroom:
        cat = "showroom"
    elif has_trims:
        cat = "model_trims"
    elif has_models:
        cat = "models"
    elif is_vehicle:
        if 'used' in url_lower:
            cat = "used_vehicles"
        else:
            cat = "new_vehicles"
    else:
        cat = "pages"

    print(f"  Category: {cat}")
EOF

python3 /tmp/test_sitemap_urls.py
```

### Quick Test Run (Single Site)
```bash
# Test with minimal samples to verify categorization
robot -v SITE_INDEX:1 "Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot"
```

### Check URL Counts Per Section
```bash
# Run test and grep for section counts
robot "Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot" 2>&1 | grep -E "(Sampling|detected)"
```

### Full Test with Detailed Output
```bash
# Run with all output visible
robot "Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot" 2>&1 | tee test_output.log
```

## Race Condition Debugging

### Monitor Window Handles
Add debugging to `Test URL In New Tab` keyword:
```robot
${all_handles}=    Get Window Handles
Log To Console    Window handles: ${all_handles}
```

### Test with Longer Delays
Increase Sleep values in `Test URL In New Tab`:
```robot
Sleep    2s    # After opening tab
Sleep    1s    # After switching
Sleep    1s    # After closing
Sleep    1s    # After switching back
```

### Check for Orphaned Windows
```robot
${handles_count}=    Get Length    ${all_handles}
Log To Console    Active windows: ${handles_count}
```

## Sitemap Analysis Commands

### Extract All URLs from Sitemap (Python)
```python
import requests
from bs4 import BeautifulSoup
import re

url = "https://addisononerinmills.com/sitemap"
response = requests.get(url)
urls = re.findall(r'<loc>(.+?)</loc>', response.text)

# Categorize
categories = {
    'pages': [],
    'used_vehicles': [],
    'new_vehicles': [],
    'showroom': [],
    'models': [],
    'model_trims': []
}

for url in urls:
    url_lower = url.lower()

    if '/showroom/' in url_lower:
        categories['showroom'].append(url)
    elif '/model-trims/' in url_lower:
        categories['model_trims'].append(url)
    elif '/models/' in url_lower:
        categories['models'].append(url)
    elif any(x in url_lower for x in ['/vehicle/', '/view/', '/new/', '/used/']):
        if 'used' in url_lower:
            categories['used_vehicles'].append(url)
        else:
            categories['new_vehicles'].append(url)
    else:
        categories['pages'].append(url)

# Print counts
for cat, urls in categories.items():
    print(f"{cat}: {len(urls)}")
```

### Extract URLs from Sitemap (Robot Framework)
```robot
*** Test Cases ***
Debug Sitemap URLs
    Open Browser    https://addisononerinmills.com/sitemap    chrome
    Sleep    2s
    ${source}=    Get Source
    &{sections}=    Extract Sitemap Sections    ${source}

    @{pages}=    Get From Dictionary    ${sections}    pages
    @{used}=    Get From Dictionary    ${sections}    used_vehicles
    @{new}=    Get From Dictionary    ${sections}    new_vehicles
    @{showroom}=    Get From Dictionary    ${sections}    showroom

    ${pages_count}=    Get Length    ${pages}
    ${used_count}=    Get Length    ${used}
    ${new_count}=    Get Length    ${new}
    ${showroom_count}=    Get Length    ${showroom}

    Log To Console    Pages: ${pages_count}
    Log To Console    Used Vehicles: ${used_count}
    Log To Console    New Vehicles: ${new_count}
    Log To Console    Showroom: ${showroom_count}

    Close Browser
```

## Performance Testing

### Test with Increasing Sample Sizes
```bash
# Test 1: Minimal (1 each)
robot -v PAGES:1 -v USED:1 -v NEW:1 "Suites/.../Multi-Site Contact Links From Sitemap URLs.robot"

# Test 2: Small (3 each)
robot -v PAGES:3 -v USED:3 -v NEW:3 "Suites/.../Multi-Site Contact Links From Sitemap URLs.robot"

# Test 3: Medium (10 each)
robot -v PAGES:10 -v USED:10 -v NEW:10 "Suites/.../Multi-Site Contact Links From Sitemap URLs.robot"

# Test 4: All pages
robot -v PAGES:None -v USED:5 -v NEW:5 "Suites/.../Multi-Site Contact Links From Sitemap URLs.robot"
```

### Memory Usage Monitoring
```bash
# Monitor memory while test runs
watch -n 5 'ps aux | grep chrome'

# Or with robot
robot --listener 'process_listener.py' "Suites/.../test.robot"
```

## Common Issues & Fixes

### Issue: All vehicles categorized as "pages"
**Symptom**: "Sampling 1 from 660 detected page URLs" (too many pages)
**Fix**: Update vehicle detection patterns in `Parser/sitemap_parser.robot`:
```robot
${has_vehicle_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /vehicle/
${has_view_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /view/
${has_new_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /new/
${has_used_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /used/
${is_vehicle}=    Evaluate    ${has_vehicle_path} or ${has_view_path} or ${has_new_path} or ${has_used_path}
```

### Issue: Window handle errors
**Symptom**: "No window found" or "StaleElementReferenceException"
**Fix**: Increase sleep delays in `Test URL In New Tab` keyword

### Issue: Browser crashes with too many tabs
**Symptom**: Chrome crashes or freezes
**Fix**:
1. Ensure `Cleanup Browser Windows` is called after each section
2. Reduce sample sizes for testing
3. Increase delays between URL tests

## Git Commands for Reverting

### Check what changed
```bash
git status
git diff "Shared resources/keywords.robot"
git diff "Parser/sitemap_parser.robot"
```

### Revert specific file
```bash
git checkout HEAD -- "Parser/sitemap_parser.robot"
```

### View file from previous commit
```bash
git show HEAD~1:"Parser/sitemap_parser.robot"
```

### Create backup before changes
```bash
cp "Parser/sitemap_parser.robot" "Parser/sitemap_parser.robot.bak"
```

## Quick Reference

### URL Pattern Detection
| Pattern | Matches |
|---------|---------|
| `/new/` | New vehicle pages |
| `/used/` | Used vehicle pages |
| `/view/` | Individual vehicle detail pages |
| `/vehicle/` | Generic vehicle pages |
| `/showroom/` | Showroom/inventory pages |
| `/models/` | Vehicle model pages |
| `/model-trims/` | Model trim pages |

### Sample Size Recommendations
| Test Type | pages | used | new | showroom | models | trims |
|-----------|-------|------|-----|----------|--------|-------|
| Quick     | 1     | 1    | 1   | 1        | 0      | 0     |
| Standard  | 3     | 2    | 2   | 1        | 1      | 1     |
| Full      | None  | 5    | 5   | 2        | 3      | 2     |

---

**Last Updated**: 2026-01-06
**Purpose**: Save debugging commands for future troubleshooting
