*** Settings ***
Documentation    Security validation keywords
Library    SeleniumLibrary    run_on_failure=Nothing
Library    String

*** Keywords ***
Validate Page URL Is Secure HTTPS
    [Documentation]    Validates that the current page is loaded over HTTPS
    ...                Fails if the URL does not start with https://
    ${current_url}=    Get Location
    ${is_https}=    Run Keyword And Return Status    Should Start With    ${current_url}    https://

    IF    not ${is_https}
        Fail    Page is not secure. URL does not use HTTPS: ${current_url}
    END

    Log To Console    ✓ Page is secure (HTTPS): ${current_url}
