*** Settings ***
Documentation    Batch Sitemap Parser - Processes multiple sites from CSV
...              This is the main parser that orchestrates CSV and sitemap parsing
Resource    csv_parser.robot
Resource    sitemap_parser.robot

*** Keywords ***
Parse All Sitemaps From CSV
    [Documentation]    Master parser that reads CSV and processes all sitemaps
    ...                Returns list of results with status for each site
    [Arguments]    ${csv_path}    ${open_in_browser}=True

    # Parse CSV to get site data
    @{sites}=    Parse Sites From CSV    ${csv_path}
    ${site_count}=    Get Length    ${sites}

    Log To Console    \n========================================
    Log To Console    Parsed ${site_count} sites from CSV
    Log To Console    ========================================

    # Process each site
    @{results}=    Create List

    FOR    ${site}    IN    @{sites}
        ${url}=    Get From Dictionary    ${site}    url
        ${name}=    Get From Dictionary    ${site}    name

        IF    '${url}' == ''
            Log To Console    \nSkipping ${name} - No URL
            CONTINUE
        END

        &{result}=    Process Single Sitemap    ${url}    ${name}    ${open_in_browser}
        Append To List    ${results}    ${result}
    END

    RETURN    @{results}

Process Single Sitemap
    [Documentation]    Processes a single sitemap URL
    ...                Returns result dictionary with all details
    [Arguments]    ${url}    ${name}    ${open_in_browser}=True

    Log To Console    \nProcessing: ${name}
    Log To Console    URL: ${url}

    &{result}=    Create Dictionary
    ...    name=${name}
    ...    base_url=${url}
    ...    sitemap_url=${EMPTY}
    ...    accessible=False
    ...    has_xml=False
    ...    url_count=0
    ...    error=${EMPTY}

    # Build sitemap URL
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Set To Dictionary    ${result}    sitemap_url=${sitemap_url}

    IF    ${open_in_browser}
        # Navigate in browser
        ${nav_success}=    Navigate To Sitemap    ${url}

        IF    not ${nav_success}
            Set To Dictionary    ${result}    error=Navigation failed
            Log To Console    ✗ FAILED: Could not navigate to ${sitemap_url}
            RETURN    &{result}
        END

        # Wait for page load
        Sleep    2s

        # Verify sitemap
        &{verification}=    Verify Sitemap Loaded    ${sitemap_url}

        ${success}=    Get From Dictionary    ${verification}    success
        ${has_xml}=    Get From Dictionary    ${verification}    has_xml
        ${error_type}=    Get From Dictionary    ${verification}    error_type

        Set To Dictionary    ${result}    accessible=${success}    has_xml=${has_xml}

        IF    '${error_type}' != 'None'
            Set To Dictionary    ${result}    error=${error_type}
            Log To Console    ✗ FAILED: ${sitemap_url} - Error ${error_type}
        ELSE IF    ${has_xml}
            # Count URLs in sitemap
            ${page_source}=    Get Source
            ${url_count}=    Count Sitemap URLs    ${page_source}
            Set To Dictionary    ${result}    url_count=${url_count}
            Log To Console    ✓ SUCCESS: ${sitemap_url} - ${url_count} URLs found
        ELSE
            Log To Console    ⚠ WARNING: ${sitemap_url} loaded but no XML sitemap detected
        END
    END

    RETURN    &{result}

Generate Summary Report
    [Documentation]    Generates a summary report from parsing results
    [Arguments]    @{results}

    ${total}=    Get Length    ${results}
    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    ${total_urls}=    Set Variable    0
    @{failed_sites}=    Create List

    FOR    ${result}    IN    @{results}
        ${accessible}=    Get From Dictionary    ${result}    accessible
        ${url_count}=    Get From Dictionary    ${result}    url_count
        ${name}=    Get From Dictionary    ${result}    name

        IF    ${accessible}
            ${passed}=    Evaluate    ${passed} + 1
            ${total_urls}=    Evaluate    ${total_urls} + ${url_count}
        ELSE
            ${failed}=    Evaluate    ${failed} + 1
            Append To List    ${failed_sites}    ${name}
        END
    END

    # Display summary
    Log To Console    \n========================================
    Log To Console    PARSING SUMMARY
    Log To Console    ========================================
    Log To Console    Total Sites: ${total}
    Log To Console    Accessible: ${passed}
    Log To Console    Failed: ${failed}
    Log To Console    Total URLs Found: ${total_urls}

    IF    ${failed} > 0
        Log To Console    \nFailed Sites:
        FOR    ${name}    IN    @{failed_sites}
            Log To Console    - ${name}
        END
    END

    &{summary}=    Create Dictionary
    ...    total=${total}
    ...    passed=${passed}
    ...    failed=${failed}
    ...    total_urls=${total_urls}
    ...    failed_sites=${failed_sites}

    RETURN    &{summary}
