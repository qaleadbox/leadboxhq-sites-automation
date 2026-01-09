*** Settings ***
Documentation    Text type detection helpers
Library    String

*** Keywords ***
Detect Text Type
    [Documentation]    Detects if text is a phone number, email, or address
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
