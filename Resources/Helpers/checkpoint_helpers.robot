*** Settings ***
Library    OperatingSystem
Library    Collections
Library    DateTime


*** Variables ***
${CHECKPOINT_DIR}    ${CURDIR}${/}..${/}..${/}checkpoints
${CHECKPOINT_FILE}    ${CHECKPOINT_DIR}${/}checkpoint.json


*** Keywords ***
Initialize Checkpoint
    [Documentation]    Initialize checkpoint system. Creates checkpoint directory and file if needed.
    [Arguments]    ${total_sites}
    Create Directory    ${CHECKPOINT_DIR}

    ${checkpoint_exists}=    Run Keyword And Return Status    File Should Exist    ${CHECKPOINT_FILE}

    IF    ${checkpoint_exists}
        ${checkpoint}=    Load Checkpoint
        Log    Checkpoint loaded. Sites processed: ${checkpoint['checkpoint']['sites_processed']}    console=True
        RETURN    ${checkpoint}
    ELSE
        ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
        ${test_run_id}=    Catenate    SEPARATOR=_    test_contact_links    ${timestamp}
        ${test_run_id}=    Replace String    ${test_run_id}    :    ${EMPTY}
        ${test_run_id}=    Replace String    ${test_run_id}    -    ${EMPTY}

        &{current_site}=    Create Dictionary    name=${EMPTY}    url=${EMPTY}    status=not_started    sections_processed=@{EMPTY}    pages_tested=0    pages_total=0
        &{checkpoint_data}=    Create Dictionary
        ...    timestamp=${timestamp}
        ...    test_run_id=${test_run_id}
        ...    total_sites=${total_sites}
        ...    sites_processed=0
        ...    current_site=${current_site}
        ...    sites_completed=@{EMPTY}

        &{summary}=    Create Dictionary
        ...    sites_pending=${total_sites}
        ...    total_urls_tested=0
        ...    total_passed=0
        ...    total_failed=0
        ...    failed_sites=@{EMPTY}

        &{checkpoint}=    Create Dictionary    checkpoint=${checkpoint_data}    summary=${summary}

        Save Checkpoint Data    ${checkpoint}
        Log    New checkpoint initialized    console=True
        RETURN    ${checkpoint}
    END

Load Checkpoint
    [Documentation]    Load existing checkpoint from JSON file
    ${checkpoint}=    Evaluate    json.load(open($CHECKPOINT_FILE, 'r', encoding='utf-8'))    json
    RETURN    ${checkpoint}

Save Checkpoint Data
    [Documentation]    Save checkpoint data to JSON file
    [Arguments]    ${checkpoint}
    ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
    Set To Dictionary    ${checkpoint['checkpoint']}    timestamp=${timestamp}
    Evaluate    json.dump($checkpoint, open($CHECKPOINT_FILE, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)    json

Should Skip Site
    [Documentation]    Check if site should be skipped (already completed)
    [Arguments]    ${site_name}    ${checkpoint}

    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    FOR    ${completed_site}    IN    @{sites_completed}
        ${completed_name}=    Get From Dictionary    ${completed_site}    name
        IF    '${completed_name}' == '${site_name}'
            Log    Skipping already completed site: ${site_name}    console=True
            RETURN    ${True}
        END
    END

    RETURN    ${False}

Start Site Processing
    [Documentation]    Mark site as currently being processed
    [Arguments]    ${checkpoint}    ${site_name}    ${site_url}

    &{tested_urls}=    Create Dictionary
    ...    pages=@{EMPTY}
    ...    used_vehicles=@{EMPTY}
    ...    new_vehicles=@{EMPTY}
    ...    showroom=@{EMPTY}
    ...    models=@{EMPTY}
    ...    model_trims=@{EMPTY}

    &{current_site}=    Create Dictionary
    ...    name=${site_name}
    ...    url=${site_url}
    ...    status=in_progress
    ...    sections_processed=@{EMPTY}
    ...    pages_tested=0
    ...    pages_total=0
    ...    tested_urls=${tested_urls}

    Set To Dictionary    ${checkpoint['checkpoint']}    current_site=${current_site}
    Save Checkpoint Data    ${checkpoint}

Complete Site Processing
    [Documentation]    Mark site as completed and update statistics
    [Arguments]    ${checkpoint}    ${site_name}    ${site_url}    ${results}    ${total_tests}    ${passed}    ${failed}

    &{completed_site}=    Create Dictionary
    ...    name=${site_name}
    ...    url=${site_url}
    ...    status=completed
    ...    results=${results}
    ...    total_tests=${total_tests}
    ...    total_passed=${passed}
    ...    total_failed=${failed}

    Append To List    ${checkpoint['checkpoint']['sites_completed']}    ${completed_site}

    ${sites_processed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_processed
    ${sites_processed}=    Evaluate    ${sites_processed} + 1
    Set To Dictionary    ${checkpoint['checkpoint']}    sites_processed=${sites_processed}

    ${total_sites}=    Get From Dictionary    ${checkpoint['checkpoint']}    total_sites
    ${sites_pending}=    Evaluate    ${total_sites} - ${sites_processed}
    Set To Dictionary    ${checkpoint['summary']}    sites_pending=${sites_pending}

    ${total_urls_tested}=    Get From Dictionary    ${checkpoint['summary']}    total_urls_tested
    ${total_urls_tested}=    Evaluate    ${total_urls_tested} + ${total_tests}
    Set To Dictionary    ${checkpoint['summary']}    total_urls_tested=${total_urls_tested}

    ${total_passed_count}=    Get From Dictionary    ${checkpoint['summary']}    total_passed
    ${total_passed_count}=    Evaluate    ${total_passed_count} + ${passed}
    Set To Dictionary    ${checkpoint['summary']}    total_passed=${total_passed_count}

    ${total_failed_count}=    Get From Dictionary    ${checkpoint['summary']}    total_failed
    ${total_failed_count}=    Evaluate    ${total_failed_count} + ${failed}
    Set To Dictionary    ${checkpoint['summary']}    total_failed=${total_failed_count}

    IF    ${failed} > 0
        Append To List    ${checkpoint['summary']['failed_sites']}    ${site_name}
    END

    &{current_site}=    Create Dictionary    name=${EMPTY}    url=${EMPTY}    status=not_started    sections_processed=@{EMPTY}    pages_tested=0    pages_total=0
    Set To Dictionary    ${checkpoint['checkpoint']}    current_site=${current_site}

    Save Checkpoint Data    ${checkpoint}
    Log    Site completed: ${site_name} (${passed}/${total_tests} passed)    console=True

Update Section Progress
    [Documentation]    Update progress for current section being tested
    [Arguments]    ${checkpoint}    ${section_name}    ${pages_tested}    ${pages_total}

    Append To List    ${checkpoint['checkpoint']['current_site']['sections_processed']}    ${section_name}
    Set To Dictionary    ${checkpoint['checkpoint']['current_site']}    pages_tested=${pages_tested}
    Set To Dictionary    ${checkpoint['checkpoint']['current_site']}    pages_total=${pages_total}

    Save Checkpoint Data    ${checkpoint}

Get Sites Processed Count
    [Documentation]    Get count of sites already processed
    [Arguments]    ${checkpoint}
    ${sites_processed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_processed
    RETURN    ${sites_processed}

Reset Checkpoint
    [Documentation]    Delete checkpoint file to start fresh
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${CHECKPOINT_FILE}
    IF    ${exists}
        Remove File    ${CHECKPOINT_FILE}
        Log    Checkpoint file removed. Starting fresh.    console=True
    END

Get Tested URLs For Site
    [Documentation]    Get list of already-tested URLs for current site
    [Arguments]    ${checkpoint}    ${category}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${tested_urls}=    Get From Dictionary    ${current_site}    tested_urls
    ${category_urls}=    Get From Dictionary    ${tested_urls}    ${category}
    RETURN    ${category_urls}

Record Tested URL
    [Documentation]    Record a URL as tested in the checkpoint
    [Arguments]    ${checkpoint}    ${category}    ${url}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${tested_urls}=    Get From Dictionary    ${current_site}    tested_urls
    Append To List    ${tested_urls['${category}']}    ${url}
    Save Checkpoint Data    ${checkpoint}

Should Resume Site
    [Documentation]    Check if site is in_progress and should be resumed
    [Arguments]    ${site_name}    ${checkpoint}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${current_name}=    Get From Dictionary    ${current_site}    name
    ${status}=    Get From Dictionary    ${current_site}    status

    IF    '${current_name}' == '${site_name}' and '${status}' == 'in_progress'
        Log    Resuming in-progress site: ${site_name}    console=True
        RETURN    ${True}
    END

    RETURN    ${False}

Filter Already Tested URLs
    [Documentation]    Filter out already-tested URLs from a list
    [Arguments]    ${all_urls}    ${tested_urls}
    @{filtered}=    Create List

    FOR    ${url}    IN    @{all_urls}
        ${is_tested}=    Evaluate    $url in $tested_urls
        IF    not ${is_tested}
            Append To List    ${filtered}    ${url}
        END
    END

    RETURN    ${filtered}
