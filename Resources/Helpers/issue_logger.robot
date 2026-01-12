*** Settings ***
Library    OperatingSystem
Library    Collections
Library    DateTime


*** Variables ***
${CHECKPOINT_DIR}    ${CURDIR}${/}..${/}..${/}checkpoints
${ISSUES_LOG_FILE}    ${CHECKPOINT_DIR}${/}issues.json


*** Keywords ***
Initialize Issue Log
    [Documentation]    Initialize issue logging system. Creates issues file if needed.
    Create Directory    ${CHECKPOINT_DIR}

    ${issues_exist}=    Run Keyword And Return Status    File Should Exist    ${ISSUES_LOG_FILE}

    IF    ${issues_exist}
        ${issues_data}=    Load Issues
        Log    Issues log loaded. Total issues: ${issues_data['total_issues']}    console=True
        RETURN    ${issues_data}
    ELSE
        &{issues_data}=    Create Dictionary    issues=@{EMPTY}    total_issues=0
        Save Issues Data    ${issues_data}
        Log    New issues log initialized    console=True
        RETURN    ${issues_data}
    END

Load Issues
    [Documentation]    Load existing issues from JSON file
    ${issues_data}=    Evaluate    json.load(open($ISSUES_LOG_FILE, 'r', encoding='utf-8'))    json
    RETURN    ${issues_data}

Save Issues Data
    [Documentation]    Save issues data to JSON file
    [Arguments]    ${issues_data}
    Evaluate    json.dump($issues_data, open($ISSUES_LOG_FILE, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)    json

Log Issue
    [Documentation]    Log a new issue with format: "<site-name> after the <Description>"
    ...    This creates a structured issue entry in the JSON file
    [Arguments]    ${issues_data}    ${site_name}    ${url}    ${description}    ${category}    ${issue_type}=validation_failure    ${details}=${EMPTY}

    ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ

    ${formatted_description}=    Catenate    ${site_name} after the ${description}

    &{issue}=    Create Dictionary
    ...    site_name=${site_name}
    ...    url=${url}
    ...    issue_type=${issue_type}
    ...    description=${formatted_description}
    ...    raw_description=${description}
    ...    category=${category}
    ...    timestamp=${timestamp}

    IF    '${details}' != '${EMPTY}'
        Set To Dictionary    ${issue}    details=${details}
    END

    Append To List    ${issues_data['issues']}    ${issue}

    ${total_issues}=    Get From Dictionary    ${issues_data}    total_issues
    ${total_issues}=    Evaluate    ${total_issues} + 1
    Set To Dictionary    ${issues_data}    total_issues=${total_issues}

    Save Issues Data    ${issues_data}
    Log    Issue logged: ${formatted_description}    console=True

Get Issues For Site
    [Documentation]    Get all issues for a specific site
    [Arguments]    ${issues_data}    ${site_name}

    @{site_issues}=    Create List

    FOR    ${issue}    IN    @{issues_data['issues']}
        ${issue_site}=    Get From Dictionary    ${issue}    site_name
        IF    '${issue_site}' == '${site_name}'
            Append To List    ${site_issues}    ${issue}
        END
    END

    RETURN    ${site_issues}

Get Total Issues Count
    [Documentation]    Get total number of issues logged
    [Arguments]    ${issues_data}
    ${total}=    Get From Dictionary    ${issues_data}    total_issues
    RETURN    ${total}

Clear Issues Log
    [Documentation]    Delete issues file to start fresh
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${ISSUES_LOG_FILE}
    IF    ${exists}
        Remove File    ${ISSUES_LOG_FILE}
        Log    Issues log removed. Starting fresh.    console=True
    END
