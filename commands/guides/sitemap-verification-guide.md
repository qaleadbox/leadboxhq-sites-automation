# Sitemap Verification Guide

## Overview
This guide explains how to verify sitemap accessibility for multiple dealership websites using the automated test suite.

## Quick Start

### 1. Export Your Google Sheets to CSV

**Option A: Manual Export**
1. Open your Google Sheets with site URLs
2. Click `File` → `Download` → `Comma Separated Values (.csv)`
3. Save as `sites.csv` in the project root directory

**Option B: Google Sheets Direct Link**
If your sheet is publicly accessible:
1. Get the sheet ID from the URL: `https://docs.google.com/spreadsheets/d/SHEET_ID/edit`
2. Download directly using:
   ```bash
   wget "https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv" -O sites.csv
   ```

### 2. Prepare Your CSV File

Your CSV should have URLs in a column. Example format:

```csv
Site URL
https://dealership1.com
https://dealership2.com
https://dealership3.com
```

**Supported Formats:**
- With header row (recommended)
- Without header row (set `${SKIP_HEADER}` to `False` in test)
- Comma-separated (`,`) or tab-separated
- URLs with or without trailing slash
- URLs with or without `/sitemap` suffix (will be added automatically)

### 3. Configure the Test (if needed)

Edit `Suites/Sitemap Testing/Verify Multiple Sitemaps.robot`:

```robot
*** Variables ***
${CSV_FILE}    sites.csv          # Path to your CSV file
${URL_COLUMN}    0                 # Column index (0 = first column)
${SKIP_HEADER}    True             # Skip first row if it's a header
```

**Multi-column CSV Example:**
If your CSV has multiple columns and URLs are in the 2nd column:

```csv
Dealership Name,Website URL,Location
Dealer One,https://dealer1.com,Toronto
Dealer Two,https://dealer2.com,Vancouver
```

Set `${URL_COLUMN}    1` (0-indexed, so 1 = second column)

### 4. Run the Test

```bash
# Activate virtual environment
source venv/bin/activate

# Run the sitemap verification test
robot "Suites/Sitemap Testing/Verify Multiple Sitemaps.robot"
```

## Expected Output

```
========================================
Found 50 URLs in sites.csv
========================================

Checking: https://dealer1.com/sitemap
✓ SUCCESS: https://dealer1.com/sitemap is accessible

Checking: https://dealer2.com/sitemap
✓ SUCCESS: https://dealer2.com/sitemap is accessible

...

========================================
SUMMARY
========================================
Total Sites: 50
Passed: 48
Failed: 2

Failed URLs:
- https://broken-site1.com
- https://broken-site2.com

✗ FAILED: 2 sitemap(s) failed to load. See log above for details.
```

## How It Works

### 1. CSV Parsing (`Read URLs From CSV` keyword)
- Located in: `Shared resources/helpers.robot`
- Reads CSV file line by line
- Handles both comma and tab-separated values
- Skips empty lines and header rows
- Validates that each entry looks like a URL (starts with `http://` or `https://`)
- Returns a list of valid URLs

### 2. Sitemap Verification (`Verify Sitemap URL` keyword)
- Located in: `Shared resources/keywords.robot`
- Takes a base URL (e.g., `https://dealer.com`)
- Automatically appends `/sitemap` if not present
- Makes an HTTP GET request using RequestsLibrary
- Expects a 200 OK response
- Returns `True` if accessible, `False` if not
- Logs detailed results to console

### 3. Batch Testing (`Verify All Sitemaps Are Accessible` test)
- Located in: `Suites/Sitemap Testing/Verify Multiple Sitemaps.robot`
- Reads all URLs from CSV
- Loops through each URL
- Verifies sitemap accessibility
- Tracks passed/failed counts
- Displays summary with failed URLs
- Test fails if any sitemap is inaccessible

## Troubleshooting

### Issue: "File not found" error
**Solution:** Ensure `sites.csv` is in the project root directory, or update `${CSV_FILE}` variable with the correct path.

```robot
${CSV_FILE}    /absolute/path/to/sites.csv
# OR relative path
${CSV_FILE}    data/sites.csv
```

### Issue: No URLs found in CSV
**Solutions:**
1. Check that URLs start with `http://` or `https://`
2. Verify the column index is correct (0 = first column)
3. If your CSV has no header, set `${SKIP_HEADER}    False`
4. Check for hidden characters or encoding issues

### Issue: Sitemap returns 404
**Possible Causes:**
1. Site doesn't have a `/sitemap` endpoint
2. Sitemap is at a different path (e.g., `/sitemap.xml`, `/sitemap_index.xml`)
3. Site is down or blocking automated requests
4. URL in CSV is incorrect

**Solutions:**
1. Manually check the sitemap URL in a browser
2. Update the `Verify Sitemap URL` keyword to check alternate paths:
   ```robot
   # Try /sitemap.xml if /sitemap fails
   ${sitemap_url}=    Set Variable    ${base_url}/sitemap.xml
   ```

### Issue: SSL/Certificate errors
**Solution:** If a site has SSL certificate issues, you can modify the `Create Session` call:

```robot
Create Session    sitemap_check    ${sitemap_url}    verify=False
```

⚠️ **Warning:** Only disable SSL verification for testing purposes on trusted sites.

### Issue: Request timeout
**Solution:** Increase the timeout in the `GET On Session` call:

```robot
${response}=    GET On Session    sitemap_check    /    expected_status=200    timeout=60
```

## Advanced Usage

### Check Different Endpoints
Modify the `Verify Sitemap URL` keyword to check different paths:

```robot
# Check /sitemap.xml instead of /sitemap
${sitemap_url}=    Set Variable    ${base_url}/sitemap.xml

# Or check multiple endpoints
@{endpoints}=    Create List    /sitemap    /sitemap.xml    /sitemap_index.xml
FOR    ${endpoint}    IN    @{endpoints}
    ${url}=    Set Variable    ${base_url}${endpoint}
    # Try each endpoint
END
```

### Extract and Parse Sitemap Content
Add keyword to parse sitemap XML:

```robot
Parse Sitemap XML
    [Arguments]    ${sitemap_url}
    ${response}=    GET    ${sitemap_url}
    ${xml_content}=    Set Variable    ${response.text}

    # Extract URLs from sitemap
    @{urls}=    Get Regexp Matches    ${xml_content}    <loc>(.+?)</loc>    1
    RETURN    @{urls}
```

### Run Tests on All Sitemap URLs
Create a new test that:
1. Gets all dealership sites
2. For each site, fetch and parse sitemap
3. Run your existing tests on each URL from the sitemap

## CSV Format Examples

### Simple Format (Single Column)
```csv
Site URL
https://dealer1.com
https://dealer2.com
```

### With Additional Data
```csv
Dealership,URL,Region
Motor World,https://motorworld.com,Ontario
Auto Plus,https://autoplus.com,BC
```

### Tab-Separated
```tsv
Site URL
https://dealer1.com
https://dealer2.com
```

### Without Header
```csv
https://dealer1.com
https://dealer2.com
https://dealer3.com
```
(Remember to set `${SKIP_HEADER}    False`)

## Integration with Existing Tests

Once you verify sitemaps are accessible, you can integrate with your existing contact link tests:

```robot
*** Test Cases ***
Test All Sites From CSV
    @{sites}=    Read URLs From CSV    sites.csv

    FOR    ${site}    IN    @{sites}
        # Update BASE_URL for each site
        Set Global Variable    ${BASE_URL}    ${site}

        # Run existing tests
        Open LeadBox Portal
        Validate Contact Links Are Clickable
        Close Browser
    END
```

## Files Reference

| File | Purpose |
|------|---------|
| `sites.csv` | Contains list of dealership URLs |
| `Shared resources/helpers.robot` | Contains `Read URLs From CSV` keyword |
| `Shared resources/keywords.robot` | Contains `Verify Sitemap URL` keyword |
| `Suites/Sitemap Testing/Verify Multiple Sitemaps.robot` | Main test suite |

## Next Steps

1. **Validate sitemap content:** Parse sitemap XML and verify all URLs are valid
2. **Run full test suite:** Use sitemap URLs to run all your tests on each page
3. **Schedule automated runs:** Set up cron job or CI/CD to run tests regularly
4. **Add reporting:** Generate HTML report with pass/fail status for each site
