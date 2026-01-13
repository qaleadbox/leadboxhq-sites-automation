*** Settings ***
Library    OperatingSystem
Library    Collections
Library    DateTime
Library    String
Library    ${CURDIR}${/}compact_json.py


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
        # If checkpoint is None (corrupted), create new one
        IF    ${checkpoint} is ${None}
            Log    Checkpoint corrupted, creating new one    console=True
        ELSE
            Log    Checkpoint loaded. Sites processed: ${checkpoint['checkpoint']['sites_processed']}    console=True
            RETURN    ${checkpoint}
        END
    END

    # Create new checkpoint (either file doesn't exist or was corrupted)
    ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
    ${test_run_id}=    Catenate    SEPARATOR=_    test_contact_links    ${timestamp}
    ${test_run_id}=    Replace String    ${test_run_id}    :    ${EMPTY}
    ${test_run_id}=    Replace String    ${test_run_id}    -    ${EMPTY}

    &{section_counters}=    Create Dictionary
    ...    used_vehicles=0/0
    ...    new_vehicles=0/0
    ...    showroom=0/0
    ...    models=0/0
    ...    model_trims=0/0

    &{tested_links_dict}=    Create Dictionary
    &{all_pages_covered_dict}=    Create Dictionary
    &{pages_link_tracking}=    Create Dictionary
    ...    tested_links=${tested_links_dict}
    ...    all_pages_covered=${all_pages_covered_dict}

    &{current_site}=    Create Dictionary
    ...    name=${EMPTY}
    ...    url=${EMPTY}
    ...    status=not_started
    ...    section_counters=${section_counters}
    ...    pages_link_tracking=${pages_link_tracking}

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

Load Checkpoint
    [Documentation]    Load existing checkpoint from JSON file
    TRY
        ${file_content}=    Get File    ${CHECKPOINT_FILE}
        ${file_length}=    Get Length    ${file_content}
        IF    ${file_length} == 0
            Log    Checkpoint file is empty, returning None    console=True
            RETURN    ${None}
        END
        ${checkpoint}=    Evaluate    json.load(open($CHECKPOINT_FILE, 'r', encoding='utf-8'))    json
        RETURN    ${checkpoint}
    EXCEPT
        Log    Failed to load checkpoint, file may be corrupted    console=True
        RETURN    ${None}
    END

Save Checkpoint Data
    [Documentation]    Save checkpoint data to JSON file
    [Arguments]    ${checkpoint}
    ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
    Set To Dictionary    ${checkpoint['checkpoint']}    timestamp=${timestamp}
    Save Checkpoint Compact    ${checkpoint}    ${CHECKPOINT_FILE}

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

    &{section_counters}=    Create Dictionary
    ...    used_vehicles=0/0
    ...    new_vehicles=0/0
    ...    showroom=0/0
    ...    models=0/0
    ...    model_trims=0/0

    &{tested_links_dict}=    Create Dictionary
    &{all_pages_covered_dict}=    Create Dictionary
    &{pages_link_tracking}=    Create Dictionary
    ...    tested_links=${tested_links_dict}
    ...    all_pages_covered=${all_pages_covered_dict}

    &{current_site}=    Create Dictionary
    ...    name=${site_name}
    ...    url=${site_url}
    ...    status=in_progress
    ...    section_counters=${section_counters}
    ...    pages_link_tracking=${pages_link_tracking}

    Set To Dictionary    ${checkpoint['checkpoint']}    current_site=${current_site}
    Save Checkpoint Data    ${checkpoint}

Complete Site Processing
    [Documentation]    Mark site as completed and update statistics, preserving link tracking data
    [Arguments]    ${checkpoint}    ${site_name}    ${site_url}    ${results}    ${total_tests}    ${passed}    ${failed}

    # Get current site data to preserve section_counters and pages_link_tracking
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${section_counters}=    Get From Dictionary    ${current_site}    section_counters
    ${pages_link_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking

    &{completed_site}=    Create Dictionary
    ...    name=${site_name}
    ...    url=${site_url}
    ...    status=completed
    ...    results=${results}
    ...    total_tests=${total_tests}
    ...    total_passed=${passed}
    ...    total_failed=${failed}
    ...    section_counters=${section_counters}
    ...    pages_link_tracking=${pages_link_tracking}

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

    # Reset current_site with proper structure
    &{section_counters}=    Create Dictionary
    ...    used_vehicles=0/0
    ...    new_vehicles=0/0
    ...    showroom=0/0
    ...    models=0/0
    ...    model_trims=0/0

    &{tested_links_dict}=    Create Dictionary
    &{all_pages_covered_dict}=    Create Dictionary
    &{pages_link_tracking}=    Create Dictionary
    ...    tested_links=${tested_links_dict}
    ...    all_pages_covered=${all_pages_covered_dict}

    &{current_site}=    Create Dictionary
    ...    name=${EMPTY}
    ...    url=${EMPTY}
    ...    status=not_started
    ...    section_counters=${section_counters}
    ...    pages_link_tracking=${pages_link_tracking}

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

Get Section Counter
    [Documentation]    Get counter for a section (e.g., "4/50")
    [Arguments]    ${checkpoint}    ${section}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${section_counters}=    Get From Dictionary    ${current_site}    section_counters
    ${counter}=    Get From Dictionary    ${section_counters}    ${section}
    RETURN    ${counter}

Set Section Counter
    [Documentation]    Set counter for a section (e.g., "4/50")
    [Arguments]    ${checkpoint}    ${section}    ${tested}    ${total}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${section_counters}=    Get From Dictionary    ${current_site}    section_counters
    ${counter}=    Set Variable    ${tested}/${total}
    Set To Dictionary    ${section_counters}    ${section}=${counter}
    Save Checkpoint Data    ${checkpoint}

Update Section Counter
    [Documentation]    Increment tested count in section counter
    [Arguments]    ${checkpoint}    ${section}
    ${counter}=    Get Section Counter    ${checkpoint}    ${section}
    @{parts}=    Split String    ${counter}    /
    ${tested}=    Get From List    ${parts}    0
    ${total}=    Get From List    ${parts}    1
    ${tested_int}=    Convert To Integer    ${tested}
    ${tested_int}=    Evaluate    ${tested_int} + 1
    Set Section Counter    ${checkpoint}    ${section}    ${tested_int}    ${total}

Should Skip Section
    [Documentation]    Check if section should be skipped based on counter and skip_if_sampled flag
    [Arguments]    ${checkpoint}    ${section}    ${skip_if_sampled}=false
    ${counter}=    Get Section Counter    ${checkpoint}    ${section}
    @{parts}=    Split String    ${counter}    /
    ${tested}=    Get From List    ${parts}    0
    ${total}=    Get From List    ${parts}    1
    ${tested_int}=    Convert To Integer    ${tested}
    ${total_int}=    Convert To Integer    ${total}

    # If section is fully completed, always skip
    IF    ${tested_int} >= ${total_int} and ${total_int} > 0
        Log To Console    Section ${section} already completed (${counter})
        RETURN    ${True}
    END

    # If skip_if_sampled is true and at least one sample was tested, skip
    IF    '${skip_if_sampled}' == 'true' and ${tested_int} > 0
        Log To Console    Section ${section} has samples (${counter}), skipping
        RETURN    ${True}
    END

    RETURN    ${False}

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

Is Link Already Tested
    [Documentation]    Check if a link was already tested with a specific test in the pages section
    [Arguments]    ${checkpoint}    ${link}    ${test_name}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${pages_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

    # Check if link exists in dictionary
    ${link_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${link}
    IF    not ${link_exists}
        RETURN    ${False}
    END

    # Get list of tests for this link
    ${tests_list}=    Get From Dictionary    ${tested_links}    ${link}

    # Check if test_name is in the list
    FOR    ${test}    IN    @{tests_list}
        IF    '${test}' == '${test_name}'
            RETURN    ${True}
        END
    END

    RETURN    ${False}

Add Tested Link
    [Documentation]    Add a link with test name to the tested links dictionary for pages section
    [Arguments]    ${checkpoint}    ${link}    ${test_name}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${pages_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

    # Check if link already exists in dictionary
    ${link_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${link}
    IF    ${link_exists}
        # Get existing list and append test_name if not already present
        ${tests_list}=    Get From Dictionary    ${tested_links}    ${link}
        ${test_in_list}=    Run Keyword And Return Status    List Should Contain Value    ${tests_list}    ${test_name}
        IF    not ${test_in_list}
            Append To List    ${tests_list}    ${test_name}
        END
    ELSE
        # Create new list with test_name
        @{new_tests_list}=    Create List    ${test_name}
        Set To Dictionary    ${tested_links}    ${link}=${new_tests_list}
    END

    Save Checkpoint Data    ${checkpoint}

Get Tested Links Count
    [Documentation]    Get count of tested links for a specific test in pages section
    [Arguments]    ${checkpoint}    ${test_name}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${pages_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

    # Count how many links have this test_name
    ${count}=    Set Variable    0
    FOR    ${link}    ${tests_list}    IN    &{tested_links}
        ${has_test}=    Run Keyword And Return Status    List Should Contain Value    ${tests_list}    ${test_name}
        IF    ${has_test}
            ${count}=    Evaluate    ${count} + 1
        END
    END

    RETURN    ${count}

Are All Pages Covered
    [Documentation]    Check if all pages were covered for a specific test
    [Arguments]    ${checkpoint}    ${test_name}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${pages_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking
    ${all_covered_dict}=    Get From Dictionary    ${pages_tracking}    all_pages_covered

    # Check if test_name exists in dictionary
    ${test_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${all_covered_dict}    ${test_name}
    IF    not ${test_exists}
        RETURN    ${False}
    END

    ${is_covered}=    Get From Dictionary    ${all_covered_dict}    ${test_name}
    RETURN    ${is_covered}

Mark All Pages Covered
    [Documentation]    Mark that all pages have been covered for a specific test
    [Arguments]    ${checkpoint}    ${test_name}
    ${current_site}=    Get From Dictionary    ${checkpoint['checkpoint']}    current_site
    ${pages_tracking}=    Get From Dictionary    ${current_site}    pages_link_tracking
    ${all_covered_dict}=    Get From Dictionary    ${pages_tracking}    all_pages_covered
    Set To Dictionary    ${all_covered_dict}    ${test_name}=${True}
    Save Checkpoint Data    ${checkpoint}
