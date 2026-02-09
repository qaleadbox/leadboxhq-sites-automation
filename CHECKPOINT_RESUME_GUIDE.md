# Checkpoint/Resume Feature Guide

## Overview

The automation now includes a **checkpoint/resume mechanism** that:
- Automatically saves progress after each site is tested
- Logs all issues with detailed descriptions in JSON format
- Allows resuming from where it stopped if interrupted
- Provides structured data for analysis

## How It Works

### Automatic Checkpoint Saving

When you run the test suite:
1. Progress is automatically saved after each site completes
2. If the test is interrupted (Ctrl+C, crash, etc.), you can resume later
3. Already-completed sites are skipped on resume
4. All issues are logged with the format: `"<site-name> after the <Description>"`

### File Locations

**Checkpoint file:** `./checkpoints/checkpoint.json`
- Contains progress tracking data
- Shows which sites have been completed
- Includes pass/fail statistics

**Issues log:** `./checkpoints/issues.json`
- Contains all validation failures
- Includes site name, URL, description, details, category, timestamp

## Usage

### Running with Checkpoint/Resume (Default)

Simply run the test as usual:

```bash
robot "Suites/Functional & Accessibility Testing/Test contact links (address, phone number, social media).robot"
```

The checkpoint system is **enabled by default**. If you run the test again:
- Already completed sites will be skipped automatically
- New sites will be tested
- Progress will continue from where it stopped

### Starting Fresh

To start from the beginning (ignore previous checkpoint):

```bash
# Delete checkpoint files
rm -rf checkpoints/

# Then run the test
robot "Suites/Functional & Accessibility Testing/Test contact links (address, phone number, social media).robot"
```

### Disabling Checkpoint

To disable the checkpoint system entirely, modify the test suite file:

```robot
Parse Sitemap URLs
...    validation_keyword=Validate Contact Links Matches It HREF
...    use_checkpoint=false    # Add this line
```

## JSON File Formats

### checkpoint.json Structure

```json
{
  "checkpoint": {
    "timestamp": "2026-01-09T15:30:45Z",
    "test_run_id": "test_contact_links_20260109_153045",
    "total_sites": 106,
    "sites_processed": 45,
    "expected_validations": [
      "Validate Contact Links Matches It HREF",
      "Validate URL Links Matches It HREF",
      "Validate Page URL Is Secure HTTPS"
    ],
    "sites_completed": [
      {
        "name": "Site Name",
        "url": "https://example.com",
        "runned_validations": "3/3",
        "results": {
          "passed": 8,
          "failed": 0
        },
        "total_tests": 8,
        "total_passed": 8,
        "total_failed": 0,
        "section_counters": {
          "pages": "68/68",
          "used_vehicles": "1/1",
          "new_vehicles": "1/1",
          "showroom": "1/1",
          "models": "1/1",
          "model_trims": "1/1"
        },
        "pages_link_tracking": {
          "tested_links": {},
          "all_pages_covered": {
            "Validate Contact Links Matches It HREF": true,
            "Validate URL Links Matches It HREF": true,
            "Validate Page URL Is Secure HTTPS": true
          }
        }
      }
    ]
  },
  "summary": {
    "sites_pending": 61,
    "total_urls_tested": 234,
    "total_passed": 231,
    "total_failed": 3,
    "failed_sites": ["Site A", "Site B"]
  }
}
```

### issues.json Structure

```json
{
  "issues": [
    {
      "site_name": "Addison Chevrolet Erin Mills",
      "url": "https://addisononerinmills.com/about",
      "issue_type": "validation_failure",
      "description": "Addison Chevrolet Erin Mills after the 1 phone link(s) text does not match href attribute",
      "raw_description": "1 phone link(s) text does not match href attribute",
      "category": "Pages",
      "details": "Phone \"(416) 123-4567\" (4161234567) != href \"tel:+14165551234\" (14165551234)",
      "timestamp": "2026-01-09T15:28:30Z"
    }
  ],
  "total_issues": 1
}
```

## Understanding the Issue Log Format

Each issue includes:

- **site_name**: The dealer site where the issue occurred
- **url**: The specific page URL that failed
- **description**: Formatted as `"<site-name> after the <Description>"` (as requested)
- **raw_description**: The description without the site name prefix
- **category**: Type of page (Pages, Used Vehicle, New Vehicle, Showroom, Model, Model Trim)
- **details**: Detailed error information (e.g., phone number mismatches)
- **timestamp**: When the issue was detected
- **issue_type**: Type of validation failure (default: "validation_failure")

## Benefits

1. **Resume Capability**: Never start from scratch after interruptions
2. **Progress Tracking**: Always know how many sites are complete vs. pending
3. **Issue Analysis**: Structured JSON data for easy parsing and reporting
4. **Time Savings**: Skip already-validated sites on subsequent runs
5. **Data Persistence**: All results preserved across runs

## Example Workflow

### First Run (Interrupted)

```bash
# Start testing
robot "Suites/Functional & Accessibility Testing/Test contact links..."

# Testing in progress...
# Site 1: PASS
# Site 2: PASS
# Site 3: FAIL (logged to issues.json)
# [Interrupted with Ctrl+C]
```

### Resume

```bash
# Resume testing (automatically skips sites 1-3)
robot "Suites/Functional & Accessibility Testing/Test contact links..."

# Output: "Skipping already completed site: Site 1"
# Output: "Skipping already completed site: Site 2"
# Output: "Skipping already completed site: Site 3"
# Continues with Site 4...
```

### Analyze Issues

```bash
# View issues
cat checkpoints/issues.json

# Count issues
jq '.total_issues' checkpoints/issues.json

# Filter issues by site
jq '.issues[] | select(.site_name == "Site Name")' checkpoints/issues.json

# Get all failed sites
jq -r '.issues[].site_name' checkpoints/issues.json | sort -u
```

## Technical Details

### New Files Created

1. **Resources/Helpers/checkpoint_helpers.robot**
   - Keywords: Initialize Checkpoint, Load Checkpoint, Save Checkpoint Data, Should Skip Site, etc.

2. **Resources/Helpers/issue_logger.robot**
   - Keywords: Initialize Issue Log, Load Issues, Log Issue, Save Issues Data, etc.

3. **Resources/Validations/phone_links.robot** (modified)
   - Added: Verify Phone Links With Details (returns detailed results)

4. **Resources/Validations/contact_links.robot** (modified)
   - Added: Validate Contact Links With Details (wrapper for detailed validation)

5. **Resources/Integrated Tests/multi_site_testing.robot** (modified)
   - Added checkpoint/resume logic
   - Created: Test Sitemap URLs In Real Time With Details
   - Created: Test URL In New Tab With Details

### Backward Compatibility

The original keywords still work:
- `Test Sitemap URLs In Real Time` (without details)
- `Test URL In New Tab` (without details)
- `Verify Phone Links On Current Page` (with Fail on error)

The new "With Details" variants are used when checkpointing is enabled.

## Troubleshooting

### Issue: Checkpoint not loading

**Solution:** Check that `./checkpoints/checkpoint.json` exists and is valid JSON.

### Issue: Sites being re-tested

**Solution:** Verify that site names match exactly between runs. Site name changes will cause re-testing.

### Issue: Want to test specific sites only

**Solution:** Delete checkpoint files and modify `sites.csv` to include only desired sites.

### Issue: Checkpoint file too large

**Solution:** Normal. Checkpoint files grow with the number of sites. They are stored efficiently as JSON.

## Advanced: Customizing Checkpoint Behavior

### Change Checkpoint Directory

Edit `Resources/variables.robot`:

```robot
${CHECKPOINT_DIR}    /custom/path/to/checkpoints
```

### Add Custom Issue Fields

Modify `Resources/Helpers/issue_logger.robot` → `Log Issue` keyword to add custom fields to the issue dictionary.

### Export Issues to CSV

```bash
jq -r '.issues[] | [.site_name, .url, .raw_description, .category] | @csv' checkpoints/issues.json > issues.csv
```

## FAQ

**Q: Does checkpoint slow down the tests?**
A: Minimal impact. Checkpoint saves take <100ms per site.

**Q: Can I use checkpoint with different validation keywords?**
A: Yes! The system now tracks validations dynamically. Pass any validation keywords to `Parse Sitemap URLs` and the checkpoint will track them independently. The `runned_validations` field shows progress (e.g., "2/3" means 2 out of 3 validations completed).

**Q: What happens if I change sampling parameters?**
A: Checkpoint tracks at site level, not URL level. Changing samples will re-test with new samples.

**Q: Can I merge multiple checkpoint files?**
A: Yes, but requires manual JSON merging. Both `sites_completed` arrays and `issues` arrays can be combined.

## Support

For questions or issues with the checkpoint/resume feature, check:
1. This guide
2. Comments in the Robot Framework files
3. The JSON files themselves for data structure examples
