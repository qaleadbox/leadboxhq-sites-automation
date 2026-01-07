*** Settings ***
Library  SeleniumLibrary
Library  OperatingSystem
Library  String
Library  Collections
Library  Process

Resource    ../Parser/csv_parser.robot
Resource    ../Parser/sitemap_parser.robot
Resource    variables.robot

*** Keywords ***

Add Prefix If Needed
    [Arguments]    ${prefix}    ${value}
    ${starts}=    Run Keyword And Return Status    Should Start With    ${value}    1
    IF    ${starts}
        RETURN  ${value}
    END
    ${new}=    Set Variable    ${prefix}${value}
    RETURN    ${new}

Verify Phone Links On Current Page
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

Read URLs From CSV
    [Documentation]    Reads URLs from a CSV file and returns them as a list
    ...                Assumes URLs are in the first column or specified column
    [Arguments]    ${csv_path}    ${column_index}=0    ${skip_header}=True

    ${file_content}=    Get File    ${csv_path}
    @{lines}=    Split To Lines    ${file_content}

    @{urls}=    Create List
    ${header_found}=    Set Variable    False

    FOR    ${line}    IN    @{lines}
        # Skip empty lines
        ${line_stripped}=    Strip String    ${line}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${line_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        # Parse CSV line (handle both comma and tab separated)
        @{columns}=    Split String    ${line}    ,
        ${column_count}=    Get Length    ${columns}

        # If only one column, might be tab-separated
        IF    ${column_count} == 1
            @{columns}=    Split String    ${line}    \t
            ${column_count}=    Get Length    ${columns}
        END

        # Look for header row (contains "URL" or "url")
        IF    not ${header_found}
            ${is_header}=    Run Keyword And Return Status    Should Contain    ${line}    URL
            IF    ${is_header}
                ${header_found}=    Set Variable    True
                CONTINUE
            END
        END

        # Skip rows until we find the header
        IF    not ${header_found}
            CONTINUE
        END

        # Make sure we have enough columns
        IF    ${column_count} <= ${column_index}
            CONTINUE
        END

        # Get URL from specified column
        ${url}=    Get From List    ${columns}    ${column_index}
        ${url}=    Strip String    ${url}

        # Remove quotes if present
        ${url}=    Remove String    ${url}    "    '

        # Skip if empty
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${url}
        IF    ${is_empty}
            CONTINUE
        END

        # Validate it looks like a URL
        ${is_url}=    Run Keyword And Return Status    Should Match Regexp    ${url}    ^https?://
        IF    ${is_url}
            Append To List    ${urls}    ${url}
        END
    END

    RETURN    @{urls}

Download CSV From Google Sheets
    [Documentation]    Downloads CSV from Google Sheets if sites.csv doesn't exist
    ${file_exists}=    Run Keyword And Return Status    File Should Exist    sites.csv

    IF    not ${file_exists}
        Log To Console    \nsites.csv not found. Downloading from Google Sheets...

        # Convert Google Sheets URL to CSV export URL
        ${export_url}=    Replace String    ${SPREADSHEET_LINK}    /edit?gid=0#gid=0    /export?format=csv&gid=0
        ${export_url}=    Replace String    ${export_url}    /edit#gid=0    /export?format=csv&gid=0

        Log To Console    Downloading from: ${export_url}

        # Download the CSV file
        ${result}=    Run Process    curl    -L    ${export_url}    -o    sites.csv

        IF    ${result.rc} != 0
            Fail    Failed to download CSV from Google Sheets: ${result.stderr}
        END

        Log To Console    Successfully downloaded sites.csv
    END

Load Sites From Spreadsheet
    Download CSV From Google Sheets
    @{sites}=    Parse Sites From CSV    sites.csv
    RETURN    @{sites}

Navigate To Site Sitemap
    [Arguments]    ${url}    ${name}
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Log To Console    \n${name}: ${sitemap_url}
    Go To    ${sitemap_url}
    Sleep    2s

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
