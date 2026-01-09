*** Settings ***
Documentation    CSV file operations and Google Sheets integration
Resource    ../variables.robot
Resource    ../../Parser/csv_parser.robot
Library    OperatingSystem
Library    String
Library    Process

*** Keywords ***
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
    [Documentation]    Loads sites from Google Sheets (downloads if needed)
    Download CSV From Google Sheets
    @{sites}=    Parse Sites From CSV    sites.csv
    RETURN    @{sites}
