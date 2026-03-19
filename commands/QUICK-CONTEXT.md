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

### 1. Interface & Content Testing (NEW)
**Suite**: `Suites/Interface & Content Testing.robot`

**Validations:**
- **Favicons** - Presence and format validation (.ico, .png, .jpg, .svg, .gif)
- **SEO Metadata** - Capitalization, template variables (%%var%%), og:site_name consistency, sitemap consistency
- **Header Layout** - Structure, navigation, tab wrapping detection at breakpoints
- **Compare Tool** - Validates presence and consistency of compare tool icons in header and vehicle cards
- **Address Consistency** - Validates address link consistency between header and footer (checks for maps URLs: https://maps.app.goo.gl/ or https://g.page/)

**Features:**
- Concise console output format (matches across all validations)
- Checkpoint system for resumable multi-site testing
- Configurable tab wrapping checks (`CHECK_TAB_WRAPPING`, `TAB_WRAPPING_TEST_WIDTHS` in variables.robot)
- Window width reporting when tab wrapping detected

**Output Format:**
```
>>> [VALIDATION NAME]: Checking [check1, check2, check3]...
>>> [VALIDATION NAME]: ✓ PASS - All checks passed [list]
>>> [VALIDATION NAME]: ✗ FAIL - Failed checks: [list]
>>>    Detailed error message
```

### 2. Contact Link Validation
- Phone numbers, email addresses, postal codes
- Validates links are clickable and HREF matches text
- Pattern detection using regex

### 3. Sitemap URL Sampling
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

### 4. Multi-Site Batch Testing
- **Sitemap Mode**: Tests multiple dealership sites from CSV/spreadsheet
- **Unitary Mode**: Tests single website via sitemap (manually enter URL in variables.robot)
- Opens sitemap, samples URLs from each section (pages, vehicles, models, etc.)
- Checkpoint system for resumable testing (sitemap mode)
- Issues log for tracking failures across sites
- Provides pass/fail summary

## Key Files

### Parsers
- `Parser/sitemap_parser.robot` - Sitemap parsing, URL extraction, section categorization
- `Parser/csv_parser.robot` - CSV/spreadsheet parsing

### Resources
- `Resources/variables.robot` - Global variables, test configuration
- `Resources/Helpers/browser_helpers.robot` - Browser window management
- `Resources/Helpers/csv_helpers.robot` - CSV operations
- `Resources/Validations/favicon.robot` - Favicon validation keywords
- `Resources/Validations/seo_metadata.robot` - SEO metadata validation keywords
- `Resources/Validations/header_layout.robot` - Header layout validation keywords
- `Resources/Validations/compare_tool.robot` - Compare Tool validation keywords
- `Resources/Validations/address_consistency.robot` - Address consistency validation keywords
- `Resources/Integrated Tests/multi_site_testing.robot` - Multi-site testing framework

### Main Test Suites
- `Suites/Interface & Content Testing.robot` - Interface & content validations
- `Suites/Functional & Accessibility Testing/Multi-Site Contact Links From Sitemap URLs.robot` - Contact link testing

## Commands Folder Resources

### Pre-Prompts (commands/prompts/)
- `test-creation.md` - Create new test suites
- `keyword-creation.md` - Create new keywords
- `debugging.md` - Debug failing tests
- `refactor.md` - Refactor code
- `site-analysis.md` - Analyze dealership sites
- `batch-sitemap-testing.md` - Batch sitemap testing
- `sitemap-url-sampling.md` - **IMPORTANT** - Full docs on URL sampling
- `favicon-testing.md` - Favicon validation implementation
- `header-layout-testing.md` - Header layout validation implementation
- `seo-metadata-validation.md` - SEO metadata validation implementation
- `HEADER_TAB_WRAPPING_CONFIG.md` - Tab wrapping configuration guide

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
- **[2026-03-19]** Added Address Consistency validation
  - New validation: Verifies address format consistency between header and footer
  - Checks for address links with maps URLs (https://maps.app.goo.gl/ or https://g.page/)
  - Validates presence in both header and footer and ensures they match
  - Follows standard validation output format
- **[2026-03-19]** Optimized Compare Tool validation performance
  - Reduced delay from 2s to 0.5s (75% faster)
  - Saves 1.5 seconds per page tested
  - No impact on validation accuracy
- **[2026-03-19]** Enhanced Unitary Mode functionality
  - Changed from single page testing to full website sitemap testing
  - Now uses same sampling logic as sitemap mode but for single manually-entered website
  - Set TEST_MODE=unitary and UNITARY_PAGE_URL to test entire website via sitemap
- **[2026-02-24]** Updated Compare Tool validation detection
  - Changed page detection from URL-based to element-based (filter divs)
  - Added three validation methods:
    1. Filter div with class 'filter filter-4 pr-2'
    2. Filter container div with id 'filter__container'
    3. Vehicle cards div with class 'width-card height-card shadow-cards vehicle-car-1 vehicle-car__section' inside span.contents
  - More reliable detection of pages with Compare Tool functionality
- **[2026-02-19]** Enhanced header layout validation output
  - Added window width reporting for tab wrapping failures
  - Concise output format matching other validations
  - Format: "overflow detected at window width 1350px (Y-diff: 80px)"
- **[2026-02-18]** Implemented Interface & Content Testing Suite
  - Added favicon validation (presence, format checking)
  - Added SEO metadata validation (capitalization, template vars, og:site_name, sitemap consistency)
  - Added header layout validation (structure, navigation, tab wrapping detection)
  - Standardized console output format across all validations
  - Checkpoint system for resumable multi-site testing
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

## Configuration Variables

### Tab Wrapping Detection (variables.robot)
- `CHECK_TAB_WRAPPING` - Enable/disable tab wrapping checks (true/false)
- `TAB_WRAPPING_TEST_WIDTHS` - Comma-separated list of widths to test (e.g., "1366,1024,768")
- `TAB_WRAPPING_HEIGHT` - Height for window during tests (default: 1024)

### Multi-Site Testing
- `FORCE_SPREADSHEET_DATA_FETCH` - Force fresh data fetch vs cached CSV (true/false)
- Checkpoint file: `checkpoints/checkpoint.json`
- Issues log: `checkpoints/issues.json`

---

**Last Updated**: 2026-03-19
**Version**: 2.1.0
