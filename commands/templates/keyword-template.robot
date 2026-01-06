*** Keywords ***
{{KEYWORD_NAME}}
    [Documentation]    {{DESCRIPTION}}
    ...                {{ADDITIONAL_INFO}}
    [Arguments]    {{ARGUMENTS}}

    # Implementation here
    Log To Console    Executing: {{KEYWORD_NAME}}

    # Example: Get elements
    # ${elements}=    Get WebElements    xpath=//selector

    # Example: Loop through elements
    # FOR    ${element}    IN    @{elements}
    #     ${text}=    Get Text    ${element}
    #     Log To Console    Found: ${text}
    # END

    # Example: Conditional logic
    # IF    '${condition}' == 'expected'
    #     Log To Console    Condition met
    # ELSE
    #     Fail    Condition not met: ${condition}
    # END

    # Example: Return value
    # RETURN    ${result}
