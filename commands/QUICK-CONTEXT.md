# Quick Context for AI Assistants

**Share this file at the start of new conversations to provide project context efficiently.**

## Project Identity
- **Name**: LeadBox Sites Automation
- **Type**: Robot Framework Test Automation
- **Domain**: Automotive Dealership Websites (IMS/Concesionary)
- **Purpose**: Web QA scanning and testing for dealership websites

## Key Directories
```
Suites/                              # Test suites
Shared resources/                    # Shared keywords, variables, helpers
Parser/                              # Parsers (sitemap, CSV)
commands/                            # This folder - prompts & docs
```

## Core Testing Features

### 1. Contact Link Validation
- Phone numbers, email addresses, postal codes
- Validates links are clickable and HREF matches text
- Pattern detection using regex

### 2. Sitemap URL Sampling
**Parameters (all end with `_samples`):**
- `pages_samples` - Pages (None=all, or number)
- `used_vehicle_samples` - Used vehicle pages
- `new_vehicle_samples` - New vehicle pages
- `showroom_samples` - Showroom/inventory pages
- `models_samples` - Vehicle model pages
- `model_trims_samples` - Model trim pages

**Detection:**
- Used vehicles: `/vehicle/` + "used" keyword
- New vehicles: `/vehicle/` + "new" keyword (or default)
- Other sections: URL path patterns

### 3. Multi-Site Batch Testing
- Tests multiple dealership sites from CSV/spreadsheet
- Opens each URL in new tab, validates, tracks results
- Provides pass/fail summary

## Key Files

### Parsers
- `Parser/sitemap_parser.robot` - Sitemap parsing, URL extraction, section categorization
- `Parser/csv_parser.robot` - CSV/spreadsheet parsing

### Shared Resources
- `Shared resources/keywords.robot` - Main test keywords
- `Shared resources/helpers.robot` - Helper functions
- `Shared resources/variables.robot` - Global variables

### Main Test Suite
- `Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot`

## Commands Folder Resources

### Pre-Prompts (commands/prompts/)
- `test-creation.md` - Create new test suites
- `keyword-creation.md` - Create new keywords
- `debugging.md` - Debug failing tests
- `refactor.md` - Refactor code
- `site-analysis.md` - Analyze dealership sites
- `batch-sitemap-testing.md` - Batch sitemap testing
- `sitemap-url-sampling.md` - **IMPORTANT** - Full docs on URL sampling

### Templates (commands/templates/)
- `test-suite-template.robot` - Test suite template
- `keyword-template.robot` - Keyword template

### Configuration
- `commands/config.json` - Full project configuration

## Common Patterns (Regex)
```
Phone: \(?\\d{3}\)?[-\s]?\d{3}[-\s]?\d{4}
Email: [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}
Postal (CA): [A-Z]\d[A-Z]\s?\d[A-Z]\d
```

## Libraries Used
- SeleniumLibrary (browser automation)
- String (text manipulation)
- RequestsLibrary (HTTP requests)

## Running Tests
```bash
# Activate venv
source venv/bin/activate

# Run specific test
robot "Suites/path/to/test.robot"

# View reports
# log.html, output.xml, report.html (auto-generated)
```

## Quick Tips for AI Assistants

1. **For detailed sitemap sampling info**: Read `commands/prompts/sitemap-url-sampling.md`
2. **For full config**: Read `commands/config.json`
3. **For batch testing guide**: Read `commands/guides/sitemap-verification-guide.md`
4. **When creating tests**: Use templates in `commands/templates/`
5. **All parameters end with `_samples`** - Remember this suffix for all sampling parameters

## Recent Changes
- **[2026-01-06 Evening]** Improved sampling log clarity & fixed race conditions
  - Log messages now say "Sampling X from Y detected URLs..." (clearer)
  - Increased delays between tab operations to prevent race conditions
- **[2026-01-06]** Split `vehicles` into `used_vehicle_samples` and `new_vehicle_samples`
- Added `_samples` suffix to ALL sampling parameters
- Vehicle type detection: "used" vs "new" keywords in URL
- Updated all keywords, parsers, and test suites with new parameters

## Need More Context?
If you need deeper understanding of any component:
1. Read the specific file from the structure above
2. Check `commands/prompts/` for relevant pre-prompt
3. Review `commands/config.json` for complete configuration
4. Reference `commands/README.md` for available resources

---

**Last Updated**: 2026-01-06
**Version**: 1.0.0
