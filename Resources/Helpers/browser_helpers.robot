*** Settings ***
Documentation    Browser management and navigation helpers
Resource    ../variables.robot
Library    SeleniumLibrary    run_on_failure=Nothing

*** Keywords ***
Open LeadBox Portal
    [Documentation]    Opens browser with proper configuration (headless/headed)
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    IF    '${HEADLESS}' == 'true'
        Call Method    ${chrome_options}    add_argument    headless
        Call Method    ${chrome_options}    add_argument    no-sandbox
        Call Method    ${chrome_options}    add_argument    disable-dev-shm-usage
        Call Method    ${chrome_options}    add_argument    disable-gpu
    END
    Open Browser    ${BASE_URL}    chrome    options=${chrome_options}

Cleanup Browser Windows
    [Documentation]    Closes all windows except the main one to prevent memory buildup
    ${all_handles}=    Get Window Handles
    ${main_handle}=    Get From List    ${all_handles}    0

    ${handles_count}=    Get Length    ${all_handles}
    IF    ${handles_count} > 1
        FOR    ${handle}    IN    @{all_handles}
            IF    '${handle}' != '${main_handle}'
                Switch Window    ${handle}
                Close Window
            END
        END
        Switch Window    ${main_handle}
        Log To Console    Closed ${handles_count - 1} extra window(s)
    END

Navigate To Site Sitemap
    [Documentation]    Navigates to a site's sitemap
    [Arguments]    ${url}    ${name}
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Log To Console    \n${name}: ${sitemap_url}
    Go To    ${sitemap_url}
    Sleep    2s
