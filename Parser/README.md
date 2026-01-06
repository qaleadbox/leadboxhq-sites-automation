# Sitemap Parser

A modular parser for processing multiple dealership websites and their sitemaps. This is **NOT a test suite** - it's a utility that parses data for tests to use.

## Purpose

The parser reads a CSV file with dealership URLs, navigates to each sitemap, and collects structured data. Test suites can then use this data to run coordinated tests across multiple sites.

## Architecture

```
Parser/
├── csv_parser.robot              # CSV file parsing & filtering
├── sitemap_parser.robot          # Sitemap URL handling & XML parsing
├── batch_sitemap_parser.robot    # Orchestrates batch processing
├── run_parser.robot              # Entry point to run parser
└── README.md                      # This file
```

## Components

### 1. CSV Parser (`csv_parser.robot`)

**Purpose:** Parses CSV files with site data

**Key Keywords:**
- `Parse Sites From CSV` - Reads CSV and returns list of site dictionaries
- `Get URLs From Sites` - Extracts just URLs from parsed sites
- `Filter Sites By Status` - Filters by status (Published, In Progress, etc.)
- `Filter Sites By Version` - Filters by version (V5, V6, etc.)

**Data Structure:**
```robot
${site} = {
    name: "Dealer Name"
    url: "https://example.com"
    version: "V6"
    status: "Published"
    theme: "Egypt"
}
```

### 2. Sitemap Parser (`sitemap_parser.robot`)

**Purpose:** Handles sitemap URLs and XML parsing

**Key Keywords:**
- `Build Sitemap URL` - Constructs `/sitemap` URL from base URL
- `Navigate To Sitemap` - Opens sitemap in browser
- `Verify Sitemap Loaded` - Checks if page is valid sitemap
- `Extract Sitemap URLs` - Parses XML and extracts all URLs
- `Count Sitemap URLs` - Counts URLs in sitemap

### 3. Batch Sitemap Parser (`batch_sitemap_parser.robot`)

**Purpose:** Orchestrates batch processing of multiple sites

**Key Keywords:**
- `Parse All Sitemaps From CSV` - Master parser for all sites
- `Process Single Sitemap` - Processes one sitemap
- `Generate Summary Report` - Creates summary statistics

**Result Structure:**
```robot
${result} = {
    name: "Dealer Name"
    base_url: "https://example.com"
    sitemap_url: "https://example.com/sitemap"
    accessible: True
    has_xml: True
    url_count: 150
    error: None
}
```

### 4. Run Parser (`run_parser.robot`)

**Purpose:** Entry point to execute the parser

**Variables:**
- `${CSV_FILE}` - Path to CSV file (default: ../sites.csv)
- `${OPEN_BROWSER}` - Whether to open browser (default: True)

## Usage

### Run the Parser

```bash
# Activate environment
source venv/bin/activate

# Run the parser
robot Parser/run_parser.robot
```

### Use Parser in Test Suites

```robot
*** Settings ***
Resource    ../Parser/batch_sitemap_parser.robot

*** Test Cases ***
Test All Sites
    # Parse all sitemaps
    @{results}=    Parse All Sitemaps From CSV    sites.csv    open_in_browser=False

    # Run tests on each result
    FOR    ${result}    IN    @{results}
        ${url}=    Get From Dictionary    ${result}    base_url
        ${accessible}=    Get From Dictionary    ${result}    accessible

        IF    ${accessible}
            # Run your tests here
            Test Contact Links    ${url}
        END
    END
```

### Filter and Process Specific Sites

```robot
*** Test Cases ***
Test Only V6 Published Sites
    # Parse CSV
    @{sites}=    Parse Sites From CSV    sites.csv

    # Filter by version and status
    @{v6_sites}=    Filter Sites By Version    V6    @{sites}
    @{published}=    Filter Sites By Status    Published    @{v6_sites}

    # Get URLs
    @{urls}=    Get URLs From Sites    @{published}

    # Run tests on filtered URLs
    FOR    ${url}    IN    @{urls}
        Test Site    ${url}
    END
```

## Output

The parser provides:

1. **Console Output:**
```
========================================
Parsed 94 sites from CSV
========================================

Processing: Addison Chevrolet Eglinton
URL: https://addisononeglinton.com
✓ SUCCESS: https://addisononeglinton.com/sitemap - 150 URLs found

...

========================================
PARSING SUMMARY
========================================
Total Sites: 3
Accessible: 3
Failed: 0
Total URLs Found: 450
```

2. **Structured Data:**
```robot
@{results} = [
    {name, base_url, sitemap_url, accessible, has_xml, url_count, error},
    {name, base_url, sitemap_url, accessible, has_xml, url_count, error},
    ...
]
```

## Integration with Tests

The parser is designed to work as a gear in a synchronized system:

```robot
# Test Suite Example
*** Settings ***
Resource    ../Parser/batch_sitemap_parser.robot
Resource    ../Shared resources/keywords.robot

*** Test Cases ***
Coordinated Multi-Site Testing
    [Documentation]    Run tests on all sites like synchronized gears

    # Gear 1: Parse sitemaps
    @{results}=    Parse All Sitemaps From CSV    sites.csv

    # Gear 2: Validate contact links on each site
    FOR    ${result}    IN    @{results}
        ${url}=    Get From Dictionary    ${result}    base_url
        Open Browser    ${url}    chrome
        Validate Contact Links Are Clickable
        Close Browser
    END

    # Gear 3: Generate final report
    &{summary}=    Generate Summary Report    @{results}
```

## Configuration

Edit `run_parser.robot` to configure:

```robot
*** Variables ***
${CSV_FILE}    ../sites.csv        # Path to your CSV file
${OPEN_BROWSER}    True             # Set False for headless parsing
```

## Modular Design Benefits

1. **Reusability** - Each component can be used independently
2. **Maintainability** - Changes to one component don't break others
3. **Testability** - Each keyword can be tested separately
4. **Composability** - Build complex workflows from simple parts
5. **Clarity** - Clear separation of concerns

## Example: Complex Workflow

```robot
*** Test Cases ***
Advanced Multi-Site Validation
    # Step 1: Parse and filter
    @{sites}=    Parse Sites From CSV    sites.csv
    @{v6_published}=    Filter Sites By Version    V6    @{sites}
    @{v6_published}=    Filter Sites By Status    Published    @{v6_published}

    # Step 2: Verify sitemaps
    Open Browser    about:blank    chrome
    @{results}=    Create List

    FOR    ${site}    IN    @{v6_published}
        ${url}=    Get From Dictionary    ${site}    url
        &{result}=    Process Single Sitemap    ${url}    ${site}[name]    True
        Append To List    ${results}    ${result}
    END

    Close Browser

    # Step 3: Run tests only on accessible sites
    FOR    ${result}    IN    @{results}
        ${accessible}=    Get From Dictionary    ${result}    accessible
        IF    ${accessible}
            ${url}=    Get From Dictionary    ${result}    base_url
            Run Full Test Suite On Site    ${url}
        END
    END

    # Step 4: Generate report
    &{summary}=    Generate Summary Report    @{results}
```

## Notes

- Parser runs in browser to show visual feedback
- Set `${OPEN_BROWSER}=False` for headless mode
- Results are structured data, not pass/fail tests
- Use parser data to drive actual test suites
- CSV parser auto-detects headers and skips empty rows
