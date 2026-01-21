*** Settings ***
Documentation    Contact link validation keywords
Resource    ../variables.robot
Resource    ../Helpers/text_detection.robot
Resource    phone_links.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    String

*** Keywords ***
Validate Contact Links Are Clickable
    [Documentation]    Validates that all contact information (phone, email, address) is clickable
    ${elements}=    Get WebElements    xpath=//*/text()[normalize-space()]/parent::*

    FOR    ${el}    IN    @{elements}
        ${txt}=    Get Text    ${el}
        ${converted_txt}=    Convert To String    ${txt}

        ${type}=   Detect Text Type    ${converted_txt}
        ${converted_type}=   Convert To String    ${type}

        IF    '${converted_type}' != 'None'

            ${href}=    Execute Javascript    try { let a = arguments[0]?.closest('a'); return a ? a.href : null; } catch(e) { return null; }    ${el}

            Log To Console    ${txt} → ${href}
            IF    '${href}' == 'None'
                Fail    ${type} "${txt}" is NOT clickable
            END
        END
    END

Validate Contact Links Matches It HREF
    [Documentation]    Validates that contact link text matches its HREF attribute
    ...                Can be used in any test to validate phone links on the current page
    ...                Example: Navigate to a page, then call this keyword to validate
    Verify Phone Links On Current Page

Validate Contact Links With Details
    [Documentation]    Validates contact links and returns detailed results without failing
    ...                Returns: Dictionary with validation results and error details
    ${result}=    Verify Phone Links With Details
    RETURN    ${result}
