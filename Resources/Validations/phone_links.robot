*** Settings ***
Documentation    Phone link validation keywords
Resource    ../variables.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    String
Library    BuiltIn

*** Keywords ***
Validate Phone Links
    [Documentation]    Validates phone links on the current page
    Verify Phone Links On Current Page

Verify Phone Links On Current Page
    [Documentation]    Verifies that phone link text matches href attribute
    ...    Returns a dictionary with validation results and error details
    ${tel_links}=    Get WebElements    xpath=//a[starts-with(@href, 'tel:')]
    ${count}=    Get Length    ${tel_links}
    Log To Console    Found ${count} tel: links

    ${failed_count}=    Set Variable    0
    @{errors}=    Create List

    FOR    ${link}    IN    @{tel_links}
        ${txt_raw}=    Get Element Attribute    ${link}    textContent
        ${href_raw}=    Get Element Attribute    ${link}    href

        ${txt_stripped}=    Strip String    ${txt_raw}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${txt_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        ${has_letters}=    Run Keyword And Return Status    Should Match Regexp    ${txt_raw}    .*[A-Za-z].*
        IF    ${has_letters}
            Log To Console    Skipping non-numeric text: "${txt_raw}"
            CONTINUE
        END

        ${phone_normalized}=    Replace String Using Regexp    ${txt_raw}    [^0-9]    ${EMPTY}
        ${href_normalized}=    Replace String Using Regexp    ${href_raw}    [^0-9]    ${EMPTY}

        ${phone_normalized}=    Add Prefix If Needed    1    ${phone_normalized}
        ${href_normalized}=    Add Prefix If Needed    1    ${href_normalized}

        ${matches}=    Run Keyword And Return Status    Should Be Equal    ${phone_normalized}    ${href_normalized}

        IF    not ${matches}
            ${failed_count}=    Evaluate    ${failed_count} + 1
            ${error_msg}=    Set Variable    Phone "${txt_raw}" (${phone_normalized}) != href "${href_raw}" (${href_normalized})
            Append To List    ${errors}    ${error_msg}
            Log To Console    ✗ ${error_msg}
        ELSE
            Log To Console    ✓ Phone "${phone_normalized}" matches href "${href_normalized}"
        END
    END

    IF    ${failed_count} > 0
        FOR    ${error}    IN    @{errors}
            Log    ${error}
        END
        Fail    ${failed_count} phone link(s) failed verification
    END

Verify Phone Links With Details
    [Documentation]    Verifies phone links and returns detailed results without failing
    ...    Returns: Dictionary with status (PASS/FAIL), error_count, errors list, description, and unique_id
    ${tel_links}=    Get WebElements    xpath=//a[starts-with(@href, 'tel:')]
    ${count}=    Get Length    ${tel_links}
    Log To Console    Found ${count} tel: links

    ${failed_count}=    Set Variable    0
    @{errors}=    Create List
    ${unique_id}=    Set Variable    ${EMPTY}

    FOR    ${link}    IN    @{tel_links}
        ${txt_raw}=    Get Element Attribute    ${link}    textContent
        ${href_raw}=    Get Element Attribute    ${link}    href

        ${txt_stripped}=    Strip String    ${txt_raw}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${txt_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        ${has_letters}=    Run Keyword And Return Status    Should Match Regexp    ${txt_raw}    .*[A-Za-z].*
        IF    ${has_letters}
            Log To Console    Skipping non-numeric text: "${txt_raw}"
            CONTINUE
        END

        ${phone_normalized}=    Replace String Using Regexp    ${txt_raw}    [^0-9]    ${EMPTY}
        ${href_normalized}=    Replace String Using Regexp    ${href_raw}    [^0-9]    ${EMPTY}

        ${phone_normalized}=    Add Prefix If Needed    1    ${phone_normalized}
        ${href_normalized}=    Add Prefix If Needed    1    ${href_normalized}

        ${matches}=    Run Keyword And Return Status    Should Be Equal    ${phone_normalized}    ${href_normalized}

        IF    not ${matches}
            ${failed_count}=    Evaluate    ${failed_count} + 1
            ${error_msg}=    Set Variable    Phone "${txt_raw}" (${phone_normalized}) != href "${href_raw}" (${href_normalized})
            Append To List    ${errors}    ${error_msg}
            Log To Console    ✗ ${error_msg}

            # Extract unique identifier (only for the first error to avoid duplicates)
            IF    '${unique_id}' == '${EMPTY}'
                ${unique_id}=    Get Parent Span Identifier    ${link}
            END
        ELSE
            Log To Console    ✓ Phone "${phone_normalized}" matches href "${href_normalized}"
        END
    END

    IF    ${failed_count} > 0
        ${status}=    Set Variable    FAIL
        ${description}=    Set Variable    ${failed_count} phone link(s) text does not match href attribute
        ${details}=    Catenate    SEPARATOR=\n    @{errors}
    ELSE
        ${status}=    Set Variable    PASS
        ${description}=    Set Variable    All phone links validated successfully
        ${details}=    Set Variable    ${EMPTY}
    END

    &{result}=    Create Dictionary
    ...    status=${status}
    ...    error_count=${failed_count}
    ...    errors=${errors}
    ...    description=${description}
    ...    details=${details}
    ...    unique_id=${unique_id}

    RETURN    ${result}

Get Parent Span Identifier
    [Documentation]    Extracts a unique identifier for the parent container of a phone link
    ...    Returns a combination of parent tag, class, and id to uniquely identify the parent element
    [Arguments]    ${link}

    # Try to get the closest parent with an id or meaningful class
    ${parent_id}=    Execute Javascript
    ...    const link = arguments[0];
    ...    let parent = link.parentElement;
    ...    while (parent && parent !== document.body) {
    ...        if (parent.id) return 'id:' + parent.id;
    ...        if (parent.className && typeof parent.className === 'string') {
    ...            const classes = parent.className.trim();
    ...            if (classes) return 'class:' + classes;
    ...        }
    ...        parent = parent.parentElement;
    ...    }
    ...    // Fallback: use tag name + text content hash
    ...    const tag = link.parentElement?.tagName || 'unknown';
    ...    const text = link.parentElement?.textContent?.substring(0, 50) || '';
    ...    return 'tag:' + tag + ':text:' + text.replace(/[^a-zA-Z0-9]/g, '').substring(0, 20);
    ...    ARGUMENTS    ${link}

    RETURN    ${parent_id}

Add Prefix If Needed
    [Documentation]    Adds prefix to phone number if it doesn't start with 1
    [Arguments]    ${prefix}    ${value}
    ${starts}=    Run Keyword And Return Status    Should Start With    ${value}    1
    IF    ${starts}
        RETURN  ${value}
    END
    ${new}=    Set Variable    ${prefix}${value}
    RETURN    ${new}
