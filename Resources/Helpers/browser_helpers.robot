*** Settings ***
Documentation    Browser management and navigation helpers
Resource    ../variables.robot
Resource    ../../Parser/sitemap_parser.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    BuiltIn
Library    Collections
Library    Process

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
    Log To Console    Closing browser...
    TRY
        # First, try to close all windows
        ${handles}=    Get Window Handles
        ${handle_count}=    Get Length    ${handles}
        IF    ${handle_count} > 0
            Log To Console    Closing ${handle_count} browser window(s)...
            FOR    ${handle}    IN    @{handles}
                TRY
                    Switch Window    ${handle}
                    Close Window
                    Sleep    0.1s
                EXCEPT
                    Log To Console    Failed to close window, continuing...
                END
            END
        END
    EXCEPT    AS    ${error}
        Log To Console    Error closing windows: ${error}
    END

    # Now close the browser session
    TRY
        Close Browser
        Sleep    0.5s
        Log To Console    Browser closed successfully
    EXCEPT    AS    ${error}
        Log To Console    Error closing browser: ${error}
        # Force kill Chrome processes as fallback
        Log To Console    Attempting to force kill Chrome processes...
        Run Keyword And Ignore Error    Run Process    pkill    -9    chrome
        Run Keyword And Ignore Error    Run Process    pkill    -9    chromedriver
        Sleep    1s
    END

Navigate To Site Sitemap
    [Documentation]    Navigates to a site's sitemap
    [Arguments]    ${url}    ${name}
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Log To Console    \n${name}: ${sitemap_url}
    Go To    ${sitemap_url}
    Sleep    2s
