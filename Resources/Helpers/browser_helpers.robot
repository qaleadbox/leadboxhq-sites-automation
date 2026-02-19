*** Settings ***
Documentation    Browser management and navigation helpers
Resource    ../variables.robot
Resource    ../../Parser/sitemap_parser.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    BuiltIn
Library    Collections
Library    Process
Library    ${CURDIR}${/}compact_json.py

*** Keywords ***
Open LeadBox Portal
    [Documentation]    Opens browser with proper configuration (headless/headed)
    [Arguments]    ${url}=about:blank
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    IF    '${HEADLESS}' == 'true'
        Call Method    ${chrome_options}    add_argument    headless
        Call Method    ${chrome_options}    add_argument    no-sandbox
        Call Method    ${chrome_options}    add_argument    disable-dev-shm-usage
        Call Method    ${chrome_options}    add_argument    disable-gpu
    END
    Open Browser    ${url}    chrome    options=${chrome_options}

    # Set timeouts to prevent hanging
    Set Selenium Timeout    30 seconds
    Set Selenium Implicit Wait    10 seconds
    Set Selenium Page Load Timeout    30 seconds

Cleanup Browser Windows
    [Documentation]    Closes all windows except the main one to prevent memory buildup
    TRY
        ${all_handles}=    Get Window Handles
        ${main_handle}=    Get From List    ${all_handles}    0

        ${handles_count}=    Get Length    ${all_handles}
        IF    ${handles_count} > 1
            Log To Console    Cleaning up ${handles_count - 1} extra window(s)...
            FOR    ${handle}    IN    @{all_handles}
                IF    '${handle}' != '${main_handle}'
                    TRY
                        Switch Window    ${handle}
                        Run Keyword And Ignore Error    Close Window
                        Sleep    0.2s
                    EXCEPT
                        Log To Console    Failed to close window ${handle}, continuing...
                    END
                END
            END
            Run Keyword And Ignore Error    Switch Window    ${main_handle}
            Sleep    0.5s
        END
    EXCEPT    AS    ${error}
        Log To Console    Cleanup windows failed: ${error}
    END

Close Browser Safely
    [Documentation]    Ensures browser is closed properly with fallback mechanisms

    # Flush checkpoint instantly (no-op, but kept for compatibility)
    Flush All Pending Writes

    # Force kill Chrome immediately - don't try to close gracefully
    Log To Console    \n⚡ Force killing Chrome processes...
    Run Keyword And Ignore Error    Run Process    pkill    -9    chrome    chromedriver
    Sleep    0.5s

    # Try to close browser session (will likely fail since Chrome is dead, that's OK)
    Run Keyword And Ignore Error    Close Browser

    Log To Console    ✓ Cleanup complete

Set Window Size For Testing
    [Documentation]    Sets browser window to specific size for responsive testing
    ...                Common breakpoints: 1920x1080 (desktop), 1280x1024 (small desktop), 768x1024 (tablet), 375x667 (mobile)
    [Arguments]    ${width}=1920    ${height}=1080
    Set Window Size    ${width}    ${height}
    Sleep    0.5s    # Allow time for browser reflow and rendering
    Log To Console    >>> BROWSER: Window size set to ${width}x${height}

Navigate To Site Sitemap
    [Documentation]    Navigates to a site's sitemap
    [Arguments]    ${url}    ${name}
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Log To Console    \n${name}: ${sitemap_url}
    Go To    ${sitemap_url}
    Sleep    2s
