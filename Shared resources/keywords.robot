** Settings **
Library  SeleniumLibrary
Library    String
Resource    variables.robot
Resource    helpers.robot

** Keywords **
Open LeadBox Portal
    Open Browser                  ${BASE_URL}                       chrome

Validate Contact Links Are Clickable
    ${elements}=    Get WebElements    xpath=//*/text()[normalize-space()]/parent::*

    FOR    ${el}    IN    @{elements}
        ${txt}=    Get Text    ${el}
        ${converted_txt}=    Convert To String    ${txt}

        ${type}=   Detect Text Type    ${converted_txt}
        ${converted_type}=   Convert To String    ${type}

        IF    '${converted_type}' != 'None'

            ${href}=    Execute Javascript    try { let a = arguments[0]?.closest('a'); return a ? a.href : null; } catch(e) { return null; }    ${el}

            Log To Console    ${txt}${href}
            IF    '${href}' == 'None'
                Fail    ${type} "${txt}" is NOT clickable
            END
        END
    END

Validate Contact Links Matches It HREF
    ${tel_links}=    Get WebElements    xpath=//a[starts-with(@href, 'tel:')]
    ${count}=    Get Length    ${tel_links}
    Log To Console    Found ${count} tel: links

    FOR    ${link}    IN    @{tel_links}
        ${txt_raw}=    Get Element Attribute    ${link}    textContent
        ${href_raw}=    Get Element Attribute    ${link}    href

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
            Fail    Phone "${txt_raw}" (digits: ${phone_normalized}) does not match href "${href_raw}" (digits: ${href_normalized})
        END

        Log To Console    ✓ Phone "${phone_normalized}" matches href "${href_normalized}"
    END

Detect Text Type
    [Arguments]    ${txt}

    @{phone_patterns}=    Create List
    ...    1[-\\s]?\\d{3}[-\\s]?\\d{3}[-\\s]?\\d{4}
    ...    \\(?\\d{3}\\)?[-\\s]?\\d{3}[-\\s]?\\d{4}
    ...    \\+?1?[-\\s]?\\(?\\d{3}\\)?[-\\s]?\\d{3}[-\\s]?\\d{4}
    ...    \\d{3}[-\\s\\.]\\d{3}[-\\s\\.]\\d{4}
    ...    1[-\\s\\(]\\d{3}[\\)\\s\\-]\\d{3}[-\\s]\\d{4}

    FOR    ${pattern}    IN    @{phone_patterns}
        ${matches}=    Run Keyword And Ignore Error    Should Match Regexp    ${txt}    ${pattern}
        IF    '${matches[0]}' == 'PASS'
            RETURN    phone
        END
    END

    ${address}=    Set Variable    [A-Z]\\d[A-Z]\\s?\\d[A-Z]\\d
    ${matches}=    Run Keyword And Ignore Error    Should Match Regexp    ${txt}    ${address}
    IF    '${matches[0]}' == 'PASS'
        RETURN    address
    END

    ${email}=    Set Variable    [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}
    ${matches}=    Run Keyword And Ignore Error    Should Match Regexp    ${txt}    ${email}
    IF    '${matches[0]}' == 'PASS'
        RETURN    email
    END

    RETURN    None
