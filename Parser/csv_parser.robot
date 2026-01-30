*** Settings ***
Documentation    CSV Parser - Reads and parses CSV files with site URLs
Library    OperatingSystem
Library    String
Library    Collections

*** Keywords ***
Parse Sites From CSV
    [Documentation]    Parses CSV file and returns list of site dictionaries
    ...                Each site dict contains: name, url, version, status, etc.
    [Arguments]    ${csv_path}

    ${file_content}=    Get File    ${csv_path}
    @{lines}=    Split To Lines    ${file_content}

    @{sites}=    Create List
    ${header_found}=    Set Variable    False
    @{headers}=    Create List

    FOR    ${line}    IN    @{lines}
        # Skip empty lines
        ${line_stripped}=    Strip String    ${line}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${line_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        # Parse CSV columns
        @{columns}=    Split String    ${line}    ,
        ${column_count}=    Get Length    ${columns}

        # Look for header row
        IF    not ${header_found}
            ${is_header}=    Run Keyword And Return Status    Should Contain    ${line}    URL
            IF    ${is_header}
                ${header_found}=    Set Variable    True
                @{headers}=    Set Variable    ${columns}
                CONTINUE
            END
        END

        # Skip rows until header is found
        IF    not ${header_found}
            CONTINUE
        END

        # Make sure we have enough columns
        IF    ${column_count} < 2
            CONTINUE
        END

        # Parse row into dictionary
        &{site}=    Parse Site Row    ${columns}    ${headers}

        # Only add if URL exists
        IF    '${site}[url]' != ''
            Append To List    ${sites}    ${site}
        END
    END

    RETURN    @{sites}

Parse Site Row
    [Documentation]    Parses a single CSV row into a site dictionary
    [Arguments]    ${columns}    ${headers}

    &{site}=    Create Dictionary
    ...    name=${EMPTY}
    ...    url=${EMPTY}
    ...    version=${EMPTY}
    ...    status=${EMPTY}
    ...    theme=${EMPTY}

    # Map columns to dictionary
    ${header_count}=    Get Length    ${headers}
    ${column_count}=    Get Length    ${columns}

    FOR    ${i}    IN RANGE    ${column_count}
        IF    ${i} >= ${header_count}
            BREAK
        END

        ${header}=    Get From List    ${headers}    ${i}
        ${header}=    Strip String    ${header}
        ${value}=    Get From List    ${columns}    ${i}
        ${value}=    Strip String    ${value}
        ${value}=    Remove String    ${value}    "    '

        # Map to dictionary keys
        ${is_dealer_name}=    Run Keyword And Return Status    Should Be Equal    ${header}    Dealer Name
        ${is_url}=    Run Keyword And Return Status    Should Be Equal    ${header}    URL
        ${is_version}=    Run Keyword And Return Status    Should Be Equal    ${header}    Website Version
        ${is_status}=    Run Keyword And Return Status    Should Be Equal    ${header}    Status
        ${is_theme}=    Run Keyword And Return Status    Should Be Equal    ${header}    Theme

        IF    ${is_dealer_name}
            Set To Dictionary    ${site}    name=${value}
        ELSE IF    ${is_url}
            ${is_valid_url}=    Run Keyword And Return Status    Should Match Regexp    ${value}    ^https?://
            IF    ${is_valid_url}
                Set To Dictionary    ${site}    url=${value}
            END
        ELSE IF    ${is_version}
            Set To Dictionary    ${site}    version=${value}
        ELSE IF    ${is_status}
            Set To Dictionary    ${site}    status=${value}
        ELSE IF    ${is_theme}
            Set To Dictionary    ${site}    theme=${value}
        END
    END

    RETURN    &{site}

Get URLs From Sites
    [Documentation]    Extracts just the URLs from a list of site dictionaries
    [Arguments]    @{sites}

    @{urls}=    Create List

    FOR    ${site}    IN    @{sites}
        ${url}=    Get From Dictionary    ${site}    url
        IF    '${url}' != ''
            Append To List    ${urls}    ${url}
        END
    END

    RETURN    @{urls}

Filter Sites By Status
    [Documentation]    Filters sites by status (e.g., "Published", "In Progress")
    [Arguments]    ${status}    @{sites}

    @{filtered}=    Create List

    FOR    ${site}    IN    @{sites}
        ${site_status}=    Get From Dictionary    ${site}    status
        IF    '${site_status}' == '${status}'
            Append To List    ${filtered}    ${site}
        END
    END

    RETURN    @{filtered}

Filter Sites By Version
    [Documentation]    Filters sites by version (e.g., "V5", "V6")
    [Arguments]    ${version}    @{sites}

    @{filtered}=    Create List

    FOR    ${site}    IN    @{sites}
        ${site_version}=    Get From Dictionary    ${site}    version
        IF    '${site_version}' == '${version}'
            Append To List    ${filtered}    ${site}
        END
    END

    RETURN    @{filtered}
