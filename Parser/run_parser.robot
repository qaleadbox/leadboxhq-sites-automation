*** Settings ***
Documentation    Sitemap Parser Runner - Entry point to run the parser
...              This is NOT a test suite, it's a parser utility
...              Use this to parse sitemaps and generate data for tests
Resource    ../Resources/variables.robot
Resource    batch_sitemap_parser.robot
Library    SeleniumLibrary    run_on_failure=Nothing

*** Variables ***
${CSV_FILE}    ../sites.csv
${OPEN_BROWSER}    True

*** Keywords ***
Run Sitemap Parser
    [Documentation]    Main entry point to run the sitemap parser
    ...                Opens browser, parses all sitemaps, generates report

    # Open browser if needed
    IF    ${OPEN_BROWSER}
        Open Browser    about:blank    chrome
    END

    # Parse all sitemaps
    @{results}=    Parse All Sitemaps From CSV    ${CSV_FILE}    ${OPEN_BROWSER}

    # Generate summary report
    &{summary}=    Generate Summary Report    @{results}

    # Close browser if opened
    IF    ${OPEN_BROWSER}
        Close Browser
    END

    # Return results for test suites to use
    RETURN    @{results}

*** Test Cases ***
Parse Sitemaps From CSV
    [Documentation]    Parser execution - generates sitemap data
    [Tags]    parser    sitemap    utility

    @{results}=    Run Sitemap Parser

    # Log results
    Log    Parsing complete. Results available for test suites.    console=True
