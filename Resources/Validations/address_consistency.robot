*** Settings ***
Documentation    Address format consistency validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections
Library    String

*** Variables ***
# Site-level validation tracking (suite scope)
&{ADDRESS_VALIDATION_STATE}    # Dictionary to track validation state per site
${MIN_PAGES_TO_VALIDATE}    3    # Minimum pages to test before skipping

*** Keywords ***
Validate Address Format Consistency
    [Documentation]    Validates address format consistency between header and footer (SITE-LEVEL)
    ...                Tests at least 3 pages per site. If all pass, skips remaining pages.
    ...                Fails if addresses are inconsistent or missing, passes silently on success
    ...                Use this keyword in Parse Sitemap URLs for multi-site testing
    ${result}=    Check Address Consistency
    ${status}=    Get From Dictionary    ${result}    status
    IF    '${status}' == 'FAIL'
        ${description}=    Get From Dictionary    ${result}    description
        Fail    ${description}
    ELSE IF    '${status}' == 'SKIP'
        # Site already validated on previous pages - skip silently
        ${description}=    Get From Dictionary    ${result}    description
        Log To Console    >>> ADDRESS CONSISTENCY: ⊘ SKIP - ${description}
    END

Validate Address Opt In
    [Documentation]    Checks if the site has address links in header and footer
    ...                Validates presence and consistency of address format
    ...                Returns detailed results without failing
    ${result}=    Check Address Consistency
    RETURN    ${result}

Reset Address Validation State
    [Documentation]    Resets the validation state (call at start of new site)
    Set Suite Variable    &{ADDRESS_VALIDATION_STATE}    &{EMPTY}
    Log    Address validation state reset for new test run

Get Current Site Name
    [Documentation]    Extracts current site name from URL for tracking
    ${current_url}=    Get Location
    ${site_name}=    Evaluate    __import__('urllib.parse', fromlist=['']).urlparse('${current_url}').netloc
    RETURN    ${site_name}

Initialize Site Validation State
    [Documentation]    Initialize validation state for a site if not exists
    [Arguments]    ${site_name}
    ${site_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${ADDRESS_VALIDATION_STATE}    ${site_name}
    IF    not ${site_exists}
        &{site_data}=    Create Dictionary
        ...    pages_tested=0
        ...    pages_passed=0
        ...    pages_failed=0
        ...    validation_complete=${False}
        ...    has_failure=${False}
        Set To Dictionary    ${ADDRESS_VALIDATION_STATE}    ${site_name}=${site_data}
        Log    Initialized address validation state for site: ${site_name}
    END

Update Site Validation State
    [Documentation]    Update validation state after testing a page
    [Arguments]    ${site_name}    ${passed}
    ${site_data}=    Get From Dictionary    ${ADDRESS_VALIDATION_STATE}    ${site_name}

    # Increment pages tested
    ${pages_tested}=    Get From Dictionary    ${site_data}    pages_tested
    ${pages_tested}=    Evaluate    ${pages_tested} + 1
    Set To Dictionary    ${site_data}    pages_tested=${pages_tested}

    # Update pass/fail counts
    IF    ${passed}
        ${pages_passed}=    Get From Dictionary    ${site_data}    pages_passed
        ${pages_passed}=    Evaluate    ${pages_passed} + 1
        Set To Dictionary    ${site_data}    pages_passed=${pages_passed}
    ELSE
        ${pages_failed}=    Get From Dictionary    ${site_data}    pages_failed
        ${pages_failed}=    Evaluate    ${pages_failed} + 1
        Set To Dictionary    ${site_data}    pages_failed=${pages_failed}
        Set To Dictionary    ${site_data}    has_failure=${True}
    END

    # Check if we can mark validation as complete (3 consecutive passes)
    ${has_failure}=    Get From Dictionary    ${site_data}    has_failure
    IF    not ${has_failure} and ${pages_tested} >= ${MIN_PAGES_TO_VALIDATE}
        Set To Dictionary    ${site_data}    validation_complete=${True}
        Log    Address validation complete for site after ${pages_tested} pages - will skip remaining pages
    END

Check Address Consistency
    [Documentation]    Validates address link presence and consistency between header and footer (SITE-LEVEL)
    ...                Returns: Dictionary with validation results and details

    # Get current site name with error handling
    TRY
        ${site_name}=    Get Current Site Name
    EXCEPT    AS    ${error}
        Log To Console    ${\n}>>> ADDRESS CONSISTENCY: ✗ ERROR - Failed to get site name: ${error}
        ${result}=    Create Dictionary
        ...    status=FAIL
        ...    description=Failed to extract site name from URL: ${error}
        ...    details=@{EMPTY}
        ...    address_data=&{EMPTY}
        RETURN    ${result}
    END

    # Initialize site state if needed
    Initialize Site Validation State    ${site_name}

    # Check if validation is already complete for this site
    ${site_data}=    Get From Dictionary    ${ADDRESS_VALIDATION_STATE}    ${site_name}
    ${validation_complete}=    Get From Dictionary    ${site_data}    validation_complete
    ${pages_tested}=    Get From Dictionary    ${site_data}    pages_tested

    IF    ${validation_complete}
        # Site already validated successfully - skip remaining pages
        ${description}=    Set Variable    Site validated (${pages_tested} pages passed) - skipping remaining pages
        ${result}=    Create Dictionary
        ...    status=SKIP
        ...    description=${description}
        ...    details=@{EMPTY}
        ...    address_data=&{EMPTY}
        RETURN    ${result}
    END

    # Perform validation
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Address format is consistent between header and footer
    @{details}=    Create List
    ${address_data}=    Create Dictionary
    @{passed_checks}=    Create List
    @{failed_checks}=    Create List

    Log To Console    ${\n}>>> ADDRESS CONSISTENCY: Checking [header address, footer address, consistency]...

    TRY
        # 1. CHECK HEADER ADDRESS
        # Looking for: span or div containing an <a> tag with href starting with maps URL
        # Valid patterns: https://maps.app.goo.gl/ or https://g.page/
        ${header_address_exists}=    Set Variable    ${False}
        ${header_address_url}=    Set Variable    ${EMPTY}

        # Try to find address link in header using JavaScript
        ${header_result}=    Execute JavaScript
        ...    const header = document.querySelector('header');
        ...    if (!header) return {found: false, url: ''};
        ...    const links = header.querySelectorAll('a[href*="maps.app.goo.gl"], a[href*="g.page"]');
        ...    if (links.length > 0) {
        ...        return {found: true, url: links[0].href};
        ...    }
        ...    return {found: false, url: ''};

        ${header_address_exists}=    Set Variable    ${header_result['found']}
        ${header_address_url}=    Set Variable    ${header_result['url']}

        Set To Dictionary    ${address_data}    header_address_exists=${header_address_exists}
        Set To Dictionary    ${address_data}    header_address_url=${header_address_url}

        IF    ${header_address_exists}
            Append To List    ${details}    Header address found: ${header_address_url}
            Append To List    ${passed_checks}    header address present
        ELSE
            Append To List    ${details}    Header address not found: No <a> with href containing 'maps.app.goo.gl' or 'g.page'
        END

        # 2. CHECK FOOTER ADDRESS
        ${footer_address_exists}=    Set Variable    ${False}
        ${footer_address_url}=    Set Variable    ${EMPTY}

        # Try to find address link in footer using JavaScript
        ${footer_result}=    Execute JavaScript
        ...    const footer = document.querySelector('footer');
        ...    if (!footer) return {found: false, url: ''};
        ...    const links = footer.querySelectorAll('a[href*="maps.app.goo.gl"], a[href*="g.page"]');
        ...    if (links.length > 0) {
        ...        return {found: true, url: links[0].href};
        ...    }
        ...    return {found: false, url: ''};

        ${footer_address_exists}=    Set Variable    ${footer_result['found']}
        ${footer_address_url}=    Set Variable    ${footer_result['url']}

        Set To Dictionary    ${address_data}    footer_address_exists=${footer_address_exists}
        Set To Dictionary    ${address_data}    footer_address_url=${footer_address_url}

        IF    ${footer_address_exists}
            Append To List    ${details}    Footer address found: ${footer_address_url}
            Append To List    ${passed_checks}    footer address present
        ELSE
            Append To List    ${details}    Footer address not found: No <a> with href containing 'maps.app.goo.gl' or 'g.page'
        END

        # 3. VALIDATE CONSISTENCY
        # If both are present, they should match
        # If neither are present, validation passes (dealer didn't opt in for address links)
        # If only one is present, it's inconsistent - FAIL

        IF    ${header_address_exists} and ${footer_address_exists}
            # Both present - check if they match
            IF    '${header_address_url}' == '${footer_address_url}'
                ${description}=    Set Variable    Address format is consistent (header and footer match)
                Append To List    ${passed_checks}    consistency
            ELSE
                # Addresses don't match - inconsistent
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    Address inconsistent: Header and footer have different addresses
                Append To List    ${failed_checks}    address mismatch
                Append To List    ${details}    Header: ${header_address_url}
                Append To List    ${details}    Footer: ${footer_address_url}
            END
        ELSE IF    not ${header_address_exists} and not ${footer_address_exists}
            # Neither present - dealer did not add address links, this is acceptable
            ${description}=    Set Variable    No address links found (dealer did not add address links)
            Append To List    ${passed_checks}    no address links
        ELSE IF    not ${header_address_exists} and ${footer_address_exists}
            # Only footer has address - inconsistent
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Address inconsistent: Present in footer but missing in header
            Append To List    ${failed_checks}    header address missing
        ELSE IF    ${header_address_exists} and not ${footer_address_exists}
            # Only header has address - inconsistent
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Address inconsistent: Present in header but missing in footer
            Append To List    ${failed_checks}    footer address missing
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error checking address consistency: ${error}
        Append To List    ${details}    Exception: ${error}
        Log To Console    >>> ADDRESS CONSISTENCY: ✗ FAIL - Error: ${error}
    END

    # Update site validation state
    Update Site Validation State    ${site_name}    ${passed}

    # Get updated site data after state change
    ${site_data_updated}=    Get From Dictionary    ${ADDRESS_VALIDATION_STATE}    ${site_name}

    # Determine status and log summary
    ${status}=    Set Variable If    ${passed}    PASS    FAIL
    IF    '${status}' == 'PASS'
        ${passed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{passed_checks}
        ${pages_tested_now}=    Get From Dictionary    ${site_data_updated}    pages_tested
        Log To Console    >>> ADDRESS CONSISTENCY: ✓ PASS - All checks passed [${passed_list}] (page ${pages_tested_now}/${MIN_PAGES_TO_VALIDATE})
    ELSE
        ${failed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{failed_checks}
        Log To Console    >>> ADDRESS CONSISTENCY: ✗ FAIL - Failed checks: [${failed_list}]
        # Log detailed comparison if available
        ${details_count}=    Get Length    ${details}
        IF    ${details_count} > 0
            FOR    ${detail}    IN    @{details}
                ${detail_stripped}=    Strip String    ${detail}
                ${detail_length}=    Get Length    ${detail_stripped}
                IF    ${detail_length} > 0
                    ${log_msg}=    Catenate    SEPARATOR=${EMPTY}    >>> ADDRESS CONSISTENCY:${SPACE}${SPACE}${SPACE}    ${detail_stripped}
                    Log To Console    ${log_msg}
                END
            END
        END
    END

    # Build result dictionary
    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}
    ...    address_data=${address_data}

    RETURN    ${result}
