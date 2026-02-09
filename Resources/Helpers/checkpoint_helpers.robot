*** Settings ***
Library    OperatingSystem
Library    Collections
Library    DateTime
Library    String
Resource    checkpoint_template.robot
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
            # Migrate to new format if needed
            Migrate Checkpoint To New Format    ${checkpoint}
            # Validate and repair checkpoint structure
            Validate And Repair Checkpoint    ${checkpoint}
            Log    Checkpoint loaded. Sites processed: ${checkpoint['checkpoint']['sites_processed']}    console=True
            RETURN    ${checkpoint}
        END
    END

    # Create new checkpoint (either file doesn't exist or was corrupted)
    ${timestamp}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
    ${test_run_id}=    Catenate    SEPARATOR=_    test_contact_links    ${timestamp}
    ${test_run_id}=    Replace String    ${test_run_id}    :    ${EMPTY}
    ${test_run_id}=    Replace String    ${test_run_id}    -    ${EMPTY}

    # No current_site needed - sites go directly in sites_completed with status=in_progress
    @{empty_validations}=    Create List
    &{checkpoint_data}=    Create Dictionary
    ...    timestamp=${timestamp}
    ...    test_run_id=${test_run_id}
    ...    total_sites=${total_sites}
    ...    sites_processed=0
    ...    sites_completed=@{EMPTY}
    ...    expected_validations=${empty_validations}

    &{summary}=    Create Dictionary
    ...    sites_pending=${total_sites}
    ...    total_urls_tested=0
    ...    total_passed=0
    ...    total_failed=0
    ...    failed_sites=@{EMPTY}

    &{checkpoint}=    Create Dictionary    checkpoint=${checkpoint_data}    summary=${summary}

    Save Checkpoint Data    ${checkpoint}
    Log    New checkpoint initialized (no current_site field)    console=True
    RETURN    ${checkpoint}

Get Short Validation Name
    [Documentation]    Convert full validation keyword name to short format (horizontal display)
    ...    Examples:
    ...    - "Validate Contact Links Matches It HREF" → "Contact Links"
    ...    - "Validate URL Links Matches It HREF" → "URL Links"
    ...    - "Validate Page URL Is Secure HTTPS" → "HTTPS"
    ...    - "Validate Favicons" → "Favicons"
    [Arguments]    ${validation_keyword}

    # Remove "Validate " prefix
    ${short_name}=    Replace String    ${validation_keyword}    Validate ${EMPTY}    ${EMPTY}

    # Remove common suffixes
    ${short_name}=    Replace String    ${short_name}    Matches It HREF    ${EMPTY}
    ${short_name}=    Replace String    ${short_name}    Is Secure    ${EMPTY}

    # Trim whitespace
    ${short_name}=    Strip String    ${short_name}

    RETURN    ${short_name}

Set Expected Validations
    [Documentation]    Set the expected validations for this test run (uses short names)
    [Arguments]    ${checkpoint}    @{validation_keywords}

    # Convert to short names
    @{short_names}=    Create List
    FOR    ${validation_keyword}    IN    @{validation_keywords}
        ${short_name}=    Get Short Validation Name    ${validation_keyword}
        Append To List    ${short_names}    ${short_name}
    END

    Set To Dictionary    ${checkpoint['checkpoint']}    expected_validations=${short_names}
    Save Checkpoint Data    ${checkpoint}
    Log To Console    Expected validations set: ${short_names}

Migrate Checkpoint To New Format
    [Documentation]    Migrate old checkpoint format to new format (single tested_links with section keys)
    [Arguments]    ${checkpoint}
    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    FOR    ${site}    IN    @{sites_completed}
        ${site_name}=    Get From Dictionary    ${site}    name

        # Get or create pages_link_tracking
        ${has_tracking}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${site}    pages_link_tracking
        IF    not ${has_tracking}
            &{tested_links}=    Create Dictionary
            &{all_pages_covered}=    Create Dictionary
            &{tracking}=    Create Dictionary    tested_links=${tested_links}    all_pages_covered=${all_pages_covered}
            Set To Dictionary    ${site}    pages_link_tracking=${tracking}
        END

        ${tracking}=    Get From Dictionary    ${site}    pages_link_tracking
        ${tested_links}=    Get From Dictionary    ${tracking}    tested_links

        # Migrate old section structures to new format
        &{section_map}=    Create Dictionary
        ...    used_vehicles=used
        ...    new_vehicles=new
        ...    showroom=showroom
        ...    models=model
        ...    model_trims=model_trim

        FOR    ${old_key}    ${new_key}    IN    &{section_map}
            ${has_old_section}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${site}    ${old_key}
            IF    ${has_old_section}
                ${old_section}=    Get From Dictionary    ${site}    ${old_key}
                ${has_old_tested_links}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${old_section}    tested_links
                IF    ${has_old_tested_links}
                    ${old_tested_links}=    Get From Dictionary    ${old_section}    tested_links
                    ${old_links_count}=    Get Length    ${old_tested_links}
                    IF    ${old_links_count} > 0
                        # Get first URL's validations from old structure
                        ${first_url}=    Evaluate    list($old_tested_links.keys())[0]
                        ${validations}=    Get From Dictionary    ${old_tested_links}    ${first_url}
                        # Store in new format using section key
                        Set To Dictionary    ${tested_links}    ${new_key}=${validations}
                        Log To Console    Migrated ${site_name}: ${old_key} → ${new_key} (${validations})
                    END
                END
                # Remove old section structure
                Remove From Dictionary    ${site}    ${old_key}
            END
        END
    END

    Save Checkpoint Data    ${checkpoint}
    Log To Console    ✓ Checkpoint migrated to new format

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

Get In Progress Site
    [Documentation]    Get the site with status=in_progress from sites_completed
    [Arguments]    ${checkpoint}
    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    FOR    ${site}    IN    @{sites_completed}
        ${status}=    Get From Dictionary    ${site}    status
        IF    '${status}' == 'in_progress'
            RETURN    ${site}
        END
    END

    # No in_progress site found
    RETURN    ${None}

Get Site By Name
    [Documentation]    Get site from sites_completed by name
    [Arguments]    ${checkpoint}    ${site_name}
    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    FOR    ${site}    IN    @{sites_completed}
        ${name}=    Get From Dictionary    ${site}    name
        IF    '${name}' == '${site_name}'
            RETURN    ${site}
        END
    END

    # Site not found
    RETURN    ${None}

Should Skip Site
    [Documentation]    Check if site should be skipped - NEVER skip if any section is incomplete
    [Arguments]    ${site_name}    ${checkpoint}

    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    FOR    ${completed_site}    IN    @{sites_completed}
        ${completed_name}=    Get From Dictionary    ${completed_site}    name
        IF    '${completed_name}' == '${site_name}'
            # CRITICAL: Check if section_counters exists
            ${has_counters}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${completed_site}    section_counters
            IF    not ${has_counters}
                # Old checkpoint without counters - needs rebuild, DON'T skip
                Log To Console    ⚠️  ${site_name}: Missing section_counters - WILL TEST
                RETURN    ${False}
            END

            ${section_counters}=    Get From Dictionary    ${completed_site}    section_counters

            # CRITICAL: Check if pages field exists
            ${has_pages}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    pages
            IF    not ${has_pages}
                # Missing pages field - needs rebuild from sitemap, DON'T skip
                Log To Console    ⚠️  ${site_name}: Missing 'pages' field - WILL TEST
                RETURN    ${False}
            END

            # Check pages section validation tracking
            ${has_pages_tracking}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${completed_site}    pages_link_tracking
            IF    ${has_pages_tracking}
                ${pages_tracking}=    Get From Dictionary    ${completed_site}    pages_link_tracking
                ${has_all_pages_covered}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${pages_tracking}    all_pages_covered
                IF    ${has_all_pages_covered}
                    ${all_pages_covered}=    Get From Dictionary    ${pages_tracking}    all_pages_covered

                    # Get expected validations (with backward compatibility)
                    ${has_expected_validations}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${checkpoint['checkpoint']}    expected_validations
                    IF    not ${has_expected_validations}
                        Log To Console    ⚠️  ${site_name}: Missing expected_validations - WILL TEST
                        RETURN    ${False}
                    END
                    ${expected_validations}=    Get From Dictionary    ${checkpoint['checkpoint']}    expected_validations

                    # Check if all expected validations are complete for pages
                    FOR    ${validation}    IN    @{expected_validations}
                        ${is_covered}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${all_pages_covered}    ${validation}
                        IF    not ${is_covered}
                            Log To Console    ⚠️  ${site_name}: Pages missing validation "${validation}" - WILL TEST
                            RETURN    ${False}
                        END
                        ${covered_status}=    Get From Dictionary    ${all_pages_covered}    ${validation}
                        IF    not ${covered_status}
                            Log To Console    ⚠️  ${site_name}: Pages validation "${validation}" incomplete - WILL TEST
                            RETURN    ${False}
                        END
                    END
                ELSE
                    Log To Console    ⚠️  ${site_name}: Missing all_pages_covered - WILL TEST
                    RETURN    ${False}
                END
            ELSE
                Log To Console    ⚠️  ${site_name}: Missing pages_link_tracking - WILL TEST
                RETURN    ${False}
            END

            # Check other sections validation tracking (stored in tested_links with section keys)
            ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

            # Get expected validations (with backward compatibility)
            ${has_expected_validations}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${checkpoint['checkpoint']}    expected_validations
            IF    not ${has_expected_validations}
                Log To Console    ⚠️  ${site_name}: Missing expected_validations - WILL TEST
                RETURN    ${False}
            END
            ${expected_validations}=    Get From Dictionary    ${checkpoint['checkpoint']}    expected_validations

            # Check each non-page section (stored as "new", "used", "showroom", "model", "model_trim")
            @{section_key_names}=    Create List    new    used    showroom    model    model_trim
            @{section_counter_keys}=    Create List    new_vehicles    used_vehicles    showroom    models    model_trims
            ${index}=    Set Variable    0
            FOR    ${section_key_name}    IN    @{section_key_names}
                ${section_counter_key}=    Get From List    ${section_counter_keys}    ${index}
                ${index}=    Evaluate    ${index} + 1

                # Check if section key exists in tested_links
                ${has_section_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${section_key_name}
                IF    ${has_section_key}
                    # Section has been tested - check if all validations are complete
                    ${section_validations}=    Get From Dictionary    ${tested_links}    ${section_key_name}
                    FOR    ${validation}    IN    @{expected_validations}
                        ${has_validation}=    Evaluate    $validation in $section_validations
                        IF    not ${has_validation}
                            Log To Console    ⚠️  ${site_name}: ${section_key_name} missing validation "${validation}" - WILL TEST
                            RETURN    ${False}
                        END
                    END
                ELSE
                    # Section not tested yet - check if section counter shows work needed
                    ${section_counter}=    Get From Dictionary    ${section_counters}    ${section_counter_key}
                    @{sec_parts}=    Split String    ${section_counter}    /
                    ${sec_total}=    Get From List    ${sec_parts}    1
                    ${sec_total_int}=    Convert To Integer    ${sec_total}
                    IF    ${sec_total_int} > 0
                        Log To Console    ⚠️  ${site_name}: ${section_key_name} has URLs but none tested - WILL TEST
                        RETURN    ${False}
                    END
                END
            END

            # All checks passed - can skip
            Log To Console    ⏭️  ${site_name}: All sections complete ${pages_counter} - SKIPPING
            RETURN    ${True}
        END
    END

    # Not in completed list - don't skip
    RETURN    ${False}

Start Site Processing
    [Documentation]    Mark site as in_progress directly in sites_completed (no separate current_site)
    [Arguments]    ${checkpoint}    ${site_name}    ${site_url}

    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed

    # Check if site already exists
    ${existing_site}=    Get Site By Name    ${checkpoint}    ${site_name}

    IF    ${existing_site} != ${None}
        # Site exists - just mark as in_progress
        Set To Dictionary    ${existing_site}    status=in_progress
        Log To Console    ↻ Resuming existing site: ${site_name}
    ELSE
        # Create new site entry
        &{section_counters}=    Create Dictionary
        ...    pages=0/0
        ...    used_vehicles=0/0
        ...    new_vehicles=0/0
        ...    showroom=0/0
        ...    models=0/0
        ...    model_trims=0/0

        # Single tested_links dict for ALL sections (pages use URLs, others use section keys)
        &{tested_links_dict}=    Create Dictionary
        &{all_pages_covered_dict}=    Create Dictionary
        &{pages_link_tracking}=    Create Dictionary
        ...    tested_links=${tested_links_dict}
        ...    all_pages_covered=${all_pages_covered_dict}

        &{new_site}=    Create Dictionary
        ...    name=${site_name}
        ...    url=${site_url}
        ...    status=in_progress
        ...    section_counters=${section_counters}
        ...    pages_link_tracking=${pages_link_tracking}

        Append To List    ${sites_completed}    ${new_site}
        Log To Console    ➕ Added NEW site to list: ${site_name}
    END

    Save Checkpoint Data    ${checkpoint}

Complete Site Processing
    [Documentation]    Mark site as completed directly in sites_completed (no duplicates possible)
    [Arguments]    ${checkpoint}    ${site_name}    ${site_url}    ${results}    ${total_tests}    ${passed}    ${failed}

    # Get site from sites_completed (should already exist with status=in_progress)
    ${site}=    Get Site By Name    ${checkpoint}    ${site_name}

    IF    ${site} == ${None}
        Log To Console    ⚠️  WARNING: Site ${site_name} not found in completed list! Adding it now...
        # Site doesn't exist - create minimal entry
        &{section_counters}=    Create Dictionary    pages=0/0    used_vehicles=0/0    new_vehicles=0/0    showroom=0/0    models=0/0    model_trims=0/0
        &{pages_link_tracking}=    Create Dictionary    tested_links=${{}}    all_pages_covered=${{}}
        &{site}=    Create Dictionary    name=${site_name}    url=${site_url}    section_counters=${section_counters}    pages_link_tracking=${pages_link_tracking}
        ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed
        Append To List    ${sites_completed}    ${site}
    END

    # Update site to completed status
    Set To Dictionary    ${site}    status=completed
    Set To Dictionary    ${site}    results=${results}
    Set To Dictionary    ${site}    total_tests=${total_tests}
    Set To Dictionary    ${site}    total_passed=${passed}
    Set To Dictionary    ${site}    total_failed=${failed}

    Log To Console    ✓ Marked ${site_name} as COMPLETED

    # Update summary (use current sites_processed value)
    ${sites_processed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_processed
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

    Save Checkpoint Data    ${checkpoint}
    Log    Site completed: ${site_name} (${passed}/${total_tests} passed)    console=True

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
    [Documentation]    Get counter for a section (e.g., "4/50") from in_progress site
    [Arguments]    ${checkpoint}    ${section}
    ${site}=    Get In Progress Site    ${checkpoint}
    ${section_counters}=    Get From Dictionary    ${site}    section_counters
    ${counter}=    Get From Dictionary    ${section_counters}    ${section}
    RETURN    ${counter}

Set Section Counter
    [Documentation]    Set counter for a section (e.g., "4/50") in in_progress site
    [Arguments]    ${checkpoint}    ${section}    ${tested}    ${total}
    ${site}=    Get In Progress Site    ${checkpoint}
    ${section_counters}=    Get From Dictionary    ${site}    section_counters
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
    ${site}=    Get In Progress Site    ${checkpoint}

    IF    ${site} == ${None}
        RETURN    ${False}
    END

    ${current_name}=    Get From Dictionary    ${site}    name
    IF    '${current_name}' == '${site_name}'
        Log    Resuming in-progress site: ${site_name}    console=True

        # Check if 'pages' field is missing (for old checkpoints)
        ${section_counters}=    Get From Dictionary    ${site}    section_counters
        ${has_pages}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    pages
        IF    not ${has_pages}
            # Initialize to 0/0 - will be calculated from sitemap when testing starts
            Set To Dictionary    ${section_counters}    pages=0/0
            Log    Added missing 'pages' counter (will be calculated from sitemap)    console=True
        END

        RETURN    ${True}
    END

    RETURN    ${False}

Update Completed Sites Pages Counters
    [Documentation]    Update pages counters for all completed sites from their tested_links
    [Arguments]    ${checkpoint}
    ${sites_completed}=    Get From Dictionary    ${checkpoint['checkpoint']}    sites_completed
    ${updated_count}=    Set Variable    0

    FOR    ${completed_site}    IN    @{sites_completed}
        ${site_name}=    Get From Dictionary    ${completed_site}    name

        # Check if section_counters exists, create if missing
        ${has_counters}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${completed_site}    section_counters
        IF    not ${has_counters}
            Log    ${site_name}: Adding missing section_counters    console=True
            &{section_counters}=    Create Dictionary
            ...    pages=0/0
            ...    used_vehicles=0/0
            ...    new_vehicles=0/0
            ...    showroom=0/0
            ...    models=0/0
            ...    model_trims=0/0
            Set To Dictionary    ${completed_site}    section_counters=${section_counters}
            ${updated_count}=    Evaluate    ${updated_count} + 1
        END

        ${section_counters}=    Get From Dictionary    ${completed_site}    section_counters

        # Check if pages field exists, add if missing
        ${has_pages}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    pages
        IF    not ${has_pages}
            Log    ${site_name}: Adding missing 'pages' field    console=True
            Set To Dictionary    ${section_counters}    pages=0/0
            ${updated_count}=    Evaluate    ${updated_count} + 1
        END

        # Check if pages_link_tracking exists
        ${has_tracking}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${completed_site}    pages_link_tracking
        IF    not ${has_tracking}
            CONTINUE
        END

        ${pages_tracking}=    Get From Dictionary    ${completed_site}    pages_link_tracking
        ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links
        ${tested_count}=    Get Length    ${tested_links}

        # Get current counter
        ${pages_counter}=    Get From Dictionary    ${section_counters}    pages
        @{parts}=    Split String    ${pages_counter}    /
        ${old_tested}=    Get From List    ${parts}    0
        ${current_total}=    Get From List    ${parts}    1
        ${old_tested_int}=    Convert To Integer    ${old_tested}
        ${current_total_int}=    Convert To Integer    ${current_total}

        # Determine best total: use tested_count if current_total is 0 or less than tested_count
        IF    ${current_total_int} == 0 or ${current_total_int} < ${tested_count}
            ${best_total}=    Set Variable    ${tested_count}
        ELSE
            ${best_total}=    Set Variable    ${current_total_int}
        END

        # Update if tested count doesn't match OR total is wrong
        IF    ${tested_count} != ${old_tested_int} or ${current_total_int} != ${best_total}
            ${new_counter}=    Set Variable    ${tested_count}/${best_total}
            Set To Dictionary    ${section_counters}    pages=${new_counter}
            ${updated_count}=    Evaluate    ${updated_count} + 1
            Log    ${site_name}: Updated pages counter from ${pages_counter} to ${new_counter}    console=True
        END
    END

    IF    ${updated_count} > 0
        Save Checkpoint Data    ${checkpoint}
        Log    Updated ${updated_count} completed site(s) with corrected pages counters    console=True
    END

Is Link Already Tested
    [Documentation]    Check if a link was already tested with a specific test in the pages section
    [Arguments]    ${checkpoint}    ${link}    ${test_name}    ${site_name}=${None}
    # Get site by name if provided, otherwise fall back to in_progress site
    IF    '${site_name}' != '${None}'
        ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
        IF    ${site} == ${None}
            Log To Console    WARNING: Site ${site_name} not found, cannot check link
            RETURN    ${False}
        END
    ELSE
        ${site}=    Get In Progress Site    ${checkpoint}
    END
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
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
    [Documentation]    Add a link with test name to tested links dictionary (stores short validation names)
    [Arguments]    ${checkpoint}    ${link}    ${test_name}    ${site_name}=${None}

    # Convert to short name
    ${short_name}=    Get Short Validation Name    ${test_name}

    # Get site by name if provided, otherwise fall back to in_progress site
    IF    '${site_name}' != '${None}'
        ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
        IF    ${site} == ${None}
            Log To Console    ERROR: Site ${site_name} not found, cannot add tested link
            RETURN
        END
    ELSE
        ${site}=    Get In Progress Site    ${checkpoint}
        IF    ${site} == ${None}
            Log To Console    ERROR: No in_progress site found, cannot add tested link
            RETURN
        END
    END
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

    # Check if link already exists in dictionary
    ${link_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${link}
    IF    ${link_exists}
        # Get existing list and append short_name if not already present
        ${tests_list}=    Get From Dictionary    ${tested_links}    ${link}
        ${test_in_list}=    Run Keyword And Return Status    List Should Contain Value    ${tests_list}    ${short_name}
        IF    not ${test_in_list}
            Append To List    ${tests_list}    ${short_name}
        END
    ELSE
        # Create new list with short_name
        @{new_tests_list}=    Create List    ${short_name}
        Set To Dictionary    ${tested_links}    ${link}=${new_tests_list}
    END

    Save Checkpoint Data    ${checkpoint}

Get Tested Links Count
    [Documentation]    Get count of tested links for a specific test in specified site (or in_progress site if not specified)
    [Arguments]    ${checkpoint}    ${test_name}    ${site_name}=${None}
    # Get site by name if provided, otherwise fall back to in_progress site
    IF    '${site_name}' != '${None}'
        ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
        IF    ${site} == ${None}
            Log To Console    WARNING: Site ${site_name} not found, returning 0
            RETURN    0
        END
    ELSE
        ${site}=    Get In Progress Site    ${checkpoint}
    END
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
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
    [Arguments]    ${checkpoint}    ${test_name}    ${site_name}=${None}
    # Get site by name if provided, otherwise fall back to in_progress site
    IF    '${site_name}' != '${None}'
        ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
        IF    ${site} == ${None}
            Log To Console    WARNING: Site ${site_name} not found, returning False
            RETURN    ${False}
        END
    ELSE
        ${site}=    Get In Progress Site    ${checkpoint}
    END
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
    ${all_covered_dict}=    Get From Dictionary    ${pages_tracking}    all_pages_covered

    # Check if test_name exists in dictionary
    ${test_exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${all_covered_dict}    ${test_name}
    IF    not ${test_exists}
        RETURN    ${False}
    END

    ${is_covered}=    Get From Dictionary    ${all_covered_dict}    ${test_name}
    RETURN    ${is_covered}

Mark All Pages Covered
    [Documentation]    Mark that all pages have been covered for a specific test (uses short name)
    [Arguments]    ${checkpoint}    ${test_name}    ${site_name}=${None}

    # Convert to short name
    ${short_name}=    Get Short Validation Name    ${test_name}

    # Get site by name if provided, otherwise fall back to in_progress site
    IF    '${site_name}' != '${None}'
        ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
        IF    ${site} == ${None}
            Log To Console    ERROR: Site ${site_name} not found, cannot mark pages covered
            RETURN
        END
    ELSE
        ${site}=    Get In Progress Site    ${checkpoint}
    END
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
    ${all_covered_dict}=    Get From Dictionary    ${pages_tracking}    all_pages_covered
    Set To Dictionary    ${all_covered_dict}    ${short_name}=${True}
    Save Checkpoint Data    ${checkpoint}

Mark Section Validation Complete
    [Documentation]    Mark a validation as complete in tested_links (uses section_key for non-pages, URL for pages)
    ...    Stores validations using short names (horizontal format)
    [Arguments]    ${checkpoint}    ${site_name}    ${section_key}    ${link_key}    ${validation_keyword}
    ${site}=    Get Site By Name    ${checkpoint}    ${site_name}
    IF    ${site} == ${None}
        Log To Console    WARNING: Site ${site_name} not found, cannot mark validation
        RETURN
    END

    # Convert to short name
    ${short_name}=    Get Short Validation Name    ${validation_keyword}

    # Get pages_link_tracking (contains tested_links for ALL sections)
    ${has_tracking}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${site}    pages_link_tracking
    IF    not ${has_tracking}
        # Create tracking structure
        &{tested_links}=    Create Dictionary
        &{all_pages_covered}=    Create Dictionary
        &{tracking}=    Create Dictionary    tested_links=${tested_links}    all_pages_covered=${all_pages_covered}
        Set To Dictionary    ${site}    pages_link_tracking=${tracking}
    END

    ${tracking}=    Get From Dictionary    ${site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${tracking}    tested_links

    # Check if link_key already exists in tested_links
    ${has_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${link_key}
    IF    ${has_key}
        ${validations_list}=    Get From Dictionary    ${tested_links}    ${link_key}
        ${already_has}=    Run Keyword And Return Status    List Should Contain Value    ${validations_list}    ${short_name}
        IF    not ${already_has}
            Append To List    ${validations_list}    ${short_name}
        END
    ELSE
        @{new_validations_list}=    Create List    ${short_name}
        Set To Dictionary    ${tested_links}    ${link_key}=${new_validations_list}
    END

    Save Checkpoint Data    ${checkpoint}
