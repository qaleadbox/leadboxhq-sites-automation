*** Settings ***
Library  SeleniumLibrary

*** Keywords ***

Add Prefix If Needed
    [Arguments]    ${prefix}    ${value}
    ${starts}=    Run Keyword And Return Status    Should Start With    ${value}    1
    IF    ${starts}
        RETURN  ${value}
    END
    ${new}=    Set Variable    ${prefix}${value}
    RETURN    ${new}
