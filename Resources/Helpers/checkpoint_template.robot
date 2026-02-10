*** Settings ***
Documentation    Checkpoint template validator - ensures checkpoint structure follows the expected format

*** Keywords ***
Validate And Repair Checkpoint
    [Documentation]    Validates checkpoint structure and repairs any missing parts based on template
    [Arguments]    ${checkpoint}

    Log To Console    🔍 Validating checkpoint structure...

    # Validate root structure
    ${has_checkpoint_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${checkpoint}    checkpoint
    IF    not ${has_checkpoint_key}
        Log To Console    ⚠️  Missing 'checkpoint' key - creating...
        &{checkpoint_data}=    Create Dictionary
        Set To Dictionary    ${checkpoint}    checkpoint=${checkpoint_data}
    END

    ${has_summary_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${checkpoint}    summary
    IF    not ${has_summary_key}
        Log To Console    ⚠️  Missing 'summary' key - creating...
        &{summary}=    Create Dictionary
        Set To Dictionary    ${checkpoint}    summary=${summary}
    END

    # Validate checkpoint data structure
    ${checkpoint_data}=    Get From Dictionary    ${checkpoint}    checkpoint

    # Required fields in checkpoint
    @{required_checkpoint_fields}=    Create List
    ...    timestamp
    ...    test_run_id
    ...    total_sites
    ...    sites_processed
    ...    sites_completed
    ...    expected_validations

    FOR    ${field}    IN    @{required_checkpoint_fields}
        ${has_field}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${checkpoint_data}    ${field}
        IF    not ${has_field}
            Log To Console    ⚠️  Missing checkpoint.${field} - adding default...
            ${default_value}=    Get Default Value For Field    ${field}
            Set To Dictionary    ${checkpoint_data}    ${field}=${default_value}
        END
    END

    # Validate summary structure
    ${summary}=    Get From Dictionary    ${checkpoint}    summary

    @{required_summary_fields}=    Create List
    ...    sites_pending
    ...    total_urls_tested
    ...    total_passed
    ...    total_failed
    ...    failed_sites

    FOR    ${field}    IN    @{required_summary_fields}
        ${has_field}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${summary}    ${field}
        IF    not ${has_field}
            Log To Console    ⚠️  Missing summary.${field} - adding default...
            ${default_value}=    Get Default Value For Field    ${field}
            Set To Dictionary    ${summary}    ${field}=${default_value}
        END
    END

    # Validate sites_completed structure
    ${sites_completed}=    Get From Dictionary    ${checkpoint_data}    sites_completed
    ${sites_count}=    Get Length    ${sites_completed}

    IF    ${sites_count} > 0
        Log To Console    📋 Validating ${sites_count} site(s)...
        FOR    ${site}    IN    @{sites_completed}
            Validate And Repair Site Structure    ${site}
        END
    END

    Log To Console    ✓ Checkpoint structure validated

Validate And Repair Site Structure
    [Documentation]    Validates and repairs a single site structure
    [Arguments]    ${site}

    ${site_name}=    Get From Dictionary    ${site}    name    default=Unknown

    # Required fields in site
    @{required_site_fields}=    Create List
    ...    name
    ...    url
    ...    status
    ...    section_counters
    ...    pages_link_tracking

    FOR    ${field}    IN    @{required_site_fields}
        ${has_field}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${site}    ${field}
        IF    not ${has_field}
            Log To Console    ⚠️  ${site_name}: Missing ${field} - adding default...
            ${default_value}=    Get Default Value For Field    ${field}
            Set To Dictionary    ${site}    ${field}=${default_value}
        END
    END

    # Validate section_counters structure
    ${section_counters}=    Get From Dictionary    ${site}    section_counters
    @{required_sections}=    Create List    pages    used_vehicles    new_vehicles    showroom    models    model_trims

    FOR    ${section}    IN    @{required_sections}
        ${has_section}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    ${section}
        IF    not ${has_section}
            Set To Dictionary    ${section_counters}    ${section}=0/0
        END
    END

    # Validate pages_link_tracking structure
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking

    ${has_tested_links}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${pages_tracking}    tested_links
    IF    not ${has_tested_links}
        &{tested_links}=    Create Dictionary
        Set To Dictionary    ${pages_tracking}    tested_links=${tested_links}
    END

    ${has_all_pages_covered}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${pages_tracking}    all_pages_covered
    IF    not ${has_all_pages_covered}
        &{all_pages_covered}=    Create Dictionary
        Set To Dictionary    ${pages_tracking}    all_pages_covered=${all_pages_covered}
    END

    # Validate tested_links has correct format (URLs + section keys)
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links

    # Ensure section keys exist (if sections have been tested but keys are missing)
    @{section_keys}=    Create List    new    used    showroom    model    model_trim
    @{section_counter_keys}=    Create List    new_vehicles    used_vehicles    showroom    models    model_trims
    ${index}=    Set Variable    0

    FOR    ${section_key}    IN    @{section_keys}
        ${section_counter_key}=    Get From List    ${section_counter_keys}    ${index}
        ${index}=    Evaluate    ${index} + 1

        # Check if section was tested (counter > 0/0)
        ${counter}=    Get From Dictionary    ${section_counters}    ${section_counter_key}
        ${counter_shows_testing}=    Run Keyword And Return Status    Should Not Be Equal    ${counter}    0/0

        # Check if section key exists in tested_links
        ${has_section_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${tested_links}    ${section_key}

        # If section was tested but key is missing, it's an old format - migration needed
        IF    ${counter_shows_testing} and not ${has_section_key}
            Log To Console    ⚠️  ${site_name}: Section ${section_key} tested but missing from tested_links - needs migration
        END
    END

Get Default Value For Field
    [Documentation]    Returns default value for a given field name
    [Arguments]    ${field_name}

    IF    '${field_name}' == 'timestamp'
        ${value}=    Get Current Date    result_format=%Y-%m-%dT%H:%M:%SZ
        RETURN    ${value}
    ELSE IF    '${field_name}' == 'test_run_id'
        RETURN    unknown_test_run
    ELSE IF    '${field_name}' == 'total_sites'
        RETURN    0
    ELSE IF    '${field_name}' == 'sites_processed'
        RETURN    0
    ELSE IF    '${field_name}' == 'sites_completed'
        @{empty_list}=    Create List
        RETURN    ${empty_list}
    ELSE IF    '${field_name}' == 'expected_validations'
        @{empty_list}=    Create List
        RETURN    ${empty_list}
    ELSE IF    '${field_name}' == 'sites_pending'
        RETURN    0
    ELSE IF    '${field_name}' == 'total_urls_tested'
        RETURN    0
    ELSE IF    '${field_name}' == 'total_passed'
        RETURN    0
    ELSE IF    '${field_name}' == 'total_failed'
        RETURN    0
    ELSE IF    '${field_name}' == 'failed_sites'
        @{empty_list}=    Create List
        RETURN    ${empty_list}
    ELSE IF    '${field_name}' == 'name'
        RETURN    Unknown Site
    ELSE IF    '${field_name}' == 'url'
        RETURN    ${EMPTY}
    ELSE IF    '${field_name}' == 'status'
        RETURN    pending
    ELSE IF    '${field_name}' == 'section_counters'
        &{counters}=    Create Dictionary
        ...    pages=0/0
        ...    used_vehicles=0/0
        ...    new_vehicles=0/0
        ...    showroom=0/0
        ...    models=0/0
        ...    model_trims=0/0
        RETURN    ${counters}
    ELSE IF    '${field_name}' == 'pages_link_tracking'
        &{tested_links}=    Create Dictionary
        &{all_pages_covered}=    Create Dictionary
        &{tracking}=    Create Dictionary
        ...    tested_links=${tested_links}
        ...    all_pages_covered=${all_pages_covered}
        RETURN    ${tracking}
    END

    RETURN    ${EMPTY}

Get Checkpoint Template
    [Documentation]    Returns the expected checkpoint structure template as documentation
    ${template}=    Set Variable
    ...    {
    ...      "checkpoint": {
    ...        "timestamp": "2026-02-09T12:00:00Z",
    ...        "test_run_id": "test_contact_links_20260209120000",
    ...        "total_sites": 106,
    ...        "sites_processed": 10,
    ...        "sites_completed": [...],
    ...        "expected_validations": ["Contact Links", "URL Links", "HTTPS", "Favicons"]
    ...      },
    ...      "summary": {
    ...        "sites_pending": 96,
    ...        "total_urls_tested": 500,
    ...        "total_passed": 450,
    ...        "total_failed": 50,
    ...        "failed_sites": []
    ...      }
    ...    }
    ...
    ...    Site structure:
    ...    {
    ...      "name": "Site Name",
    ...      "url": "https://site.com",
    ...      "status": "completed",
    ...      "section_counters": {
    ...        "pages": "10/53",
    ...        "used_vehicles": "1/1",
    ...        "new_vehicles": "1/1",
    ...        "showroom": "1/1",
    ...        "models": "1/1",
    ...        "model_trims": "1/1"
    ...      },
    ...      "pages_link_tracking": {
    ...        "tested_links": {
    ...          "https://site.com/page1": ["Contact Links", "HTTPS"],
    ...          "new": ["Contact Links", "URL Links", "HTTPS", "Favicons"],
    ...          "used": ["Contact Links", "URL Links", "HTTPS", "Favicons"],
    ...          "showroom": ["Contact Links", "URL Links", "HTTPS", "Favicons"],
    ...          "model": ["Contact Links", "URL Links", "HTTPS", "Favicons"],
    ...          "model_trim": ["Contact Links", "URL Links", "HTTPS", "Favicons"]
    ...        },
    ...        "all_pages_covered": {
    ...          "Contact Links": true,
    ...          "URL Links": false,
    ...          "HTTPS": false,
    ...          "Favicons": false
    ...        }
    ...      }
    ...    }

    Log    ${template}
    RETURN    ${template}
