# Batch Sitemap Testing Pre-Prompt

## Context
This is the LeadBox Sites Automation project. Use this prompt when you need to test multiple dealership sitemaps from a spreadsheet.

## Variables
- `{{CSV_FILE}}`: Path to CSV file with site URLs
- `{{URL_COLUMN}}`: Column index containing URLs (0-indexed)
- `{{ADDITIONAL_CHECKS}}`: Additional validations to perform beyond accessibility

## Prompt Template

```
Test multiple dealership sitemaps from a spreadsheet in the LeadBox automation project.

CSV File: {{CSV_FILE}}
URL Column: {{URL_COLUMN}}
Additional Checks: {{ADDITIONAL_CHECKS}}

Project Context:
- Framework: Robot Framework
- Existing test: Suites/Sitemap Testing/Verify Multiple Sitemaps.robot
- Keywords available:
  - Read URLs From CSV (in helpers.robot)
  - Verify Sitemap URL (in keywords.robot)

Task Requirements:
1. Read dealership URLs from the provided CSV file
2. For each URL, verify the /sitemap endpoint is accessible
3. Validate each sitemap returns HTTP 200 OK
4. Generate a summary report with pass/fail counts
5. List all failed URLs for investigation

CSV Format:
- Can have headers (will be skipped)
- URLs should start with http:// or https://
- Can be comma or tab-separated
- URLs may or may not include /sitemap suffix (will be added automatically)

Export from Google Sheets:
If the source is Google Sheets:
1. File → Download → CSV (.csv)
2. Save as sites.csv in project root
OR use direct download:
wget "https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv" -O sites.csv

Run the test:
robot "Suites/Sitemap Testing/Verify Multiple Sitemaps.robot"

Expected Output:
- Console log showing each sitemap check
- Summary with total/passed/failed counts
- List of failed URLs
- Test fails if any sitemap is inaccessible

Please provide:
1. Instructions to export/prepare the CSV
2. How to configure the test if needed
3. Command to run the test
4. How to interpret results
```

## Example Usage
Replace variables:
- CSV_FILE: "dealership-sites.csv"
- URL_COLUMN: "0" (first column)
- ADDITIONAL_CHECKS: "Verify sitemap contains valid XML, Check for minimum 10 URLs in sitemap"

## Related Files
- Test Suite: `Suites/Sitemap Testing/Verify Multiple Sitemaps.robot`
- Helper Keyword: `Read URLs From CSV` in `Shared resources/helpers.robot`
- Verification Keyword: `Verify Sitemap URL` in `Shared resources/keywords.robot`
- Example CSV: `sites.csv`
- Complete Guide: `commands/guides/sitemap-verification-guide.md`
