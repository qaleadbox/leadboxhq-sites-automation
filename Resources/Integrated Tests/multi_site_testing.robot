*** Settings ***
Documentation    Integrated multi-site testing orchestration keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Resource    ../Helpers/csv_helpers.robot
Resource    ../Helpers/checkpoint_helpers.robot
Resource    ../Helpers/issue_logger.robot
Resource    ../Validations/contact_links.robot
Resource    ../../Parser/sitemap_parser.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    String
Library    Collections

*** Keywords ***
Parse Sitemap URLs
    [Documentation]    Multi-site validation using sitemap URL sampling with checkpoint/resume support
    ...                Loads sites from spreadsheet and tests sampled URLs with specified validation keyword
    ...                Automatically saves progress and can resume from last checkpoint
    ...                Flexible framework: Pass any validation keyword to test different functionality
    [Arguments]    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1    ${use_checkpoint}=true
    @{sites}=    Load Sites From Spreadsheet
    ${sites_count}=    Get Length    ${sites}

    # Initialize checkpoint and issue logger
    ${checkpoint}=    Initialize Checkpoint    ${sites_count}
    ${issues_data}=    Initialize Issue Log

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_urls}=    Create List

    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    IF    '${HEADLESS}' == 'true'
        Call Method    ${chrome_options}    add_argument    headless
        Call Method    ${chrome_options}    add_argument    no-sandbox
        Call Method    ${chrome_options}    add_argument    disable-dev-shm-usage
        Call Method    ${chrome_options}    add_argument    disable-gpu
    END
    Open Browser    about:blank    chrome    options=${chrome_options}

    FOR    ${site}    IN    @{sites}
        ${url}=    Get From Dictionary    ${site}    url
        ${name}=    Get From Dictionary    ${site}    name

        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${url}
        IF    ${is_empty}
            CONTINUE
        END

        # Check if site should be skipped (already completed)
        IF    '${use_checkpoint}' == 'true'
            ${should_skip}=    Should Skip Site    ${name}    ${checkpoint}
            IF    ${should_skip}
                Log To Console    ⏭️  Skipping already completed site: ${name}
                CONTINUE
            END

            # Check if site should be resumed (was in progress)
            ${should_resume}=    Should Resume Site    ${name}    ${checkpoint}
            IF    not ${should_resume}
                # Start fresh for this site
                Start Site Processing    ${checkpoint}    ${name}    ${url}
            END
        ELSE
            # Checkpoint disabled, start fresh
            Start Site Processing    ${checkpoint}    ${name}    ${url}
        END

        Log To Console    \n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Log To Console    Site: ${name}

        ${site_passed}    ${site_failed}    @{site_failed_data}=    Test Sitemap URLs In Real Time With Details    ${checkpoint}    ${url}    ${name}    ${validation_keyword}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}

        # Log issues for failed URLs
        FOR    ${failed_data}    IN    @{site_failed_data}
            ${failed_url}=    Get From Dictionary    ${failed_data}    url
            ${category}=    Get From Dictionary    ${failed_data}    category
            ${description}=    Get From Dictionary    ${failed_data}    description
            ${details}=    Get From Dictionary    ${failed_data}    details

            Log Issue    ${issues_data}    ${name}    ${failed_url}    ${description}    ${category}    details=${details}
            Append To List    ${failed_urls}    ${name}: ${failed_url}
        END

        ${passed}=    Evaluate    ${passed} + ${site_passed}
        ${failed}=    Evaluate    ${failed} + ${site_failed}

        # Mark site as completed and save checkpoint
        ${total_tests}=    Evaluate    ${site_passed} + ${site_failed}
        &{results}=    Create Dictionary    passed=${site_passed}    failed=${site_failed}
        Complete Site Processing    ${checkpoint}    ${name}    ${url}    ${results}    ${total_tests}    ${site_passed}    ${site_failed}
    END

    Close Browser

    Log To Console    \nPassed: ${passed} | Failed: ${failed}

    IF    ${failed} > 0
        FOR    ${url}    IN    @{failed_urls}
            Log To Console    Failed: ${url}
        END
        Fail    ${failed} URL(s) failed
    END

Test Sitemap URLs In Real Time
    [Documentation]    Tests sampled URLs from sitemap sections with specified validation keyword
    [Arguments]    ${url}    ${name}    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Go To    ${sitemap_url}
    Sleep    2s

    ${sitemap_source}=    Get Source
    &{sections}=    Extract Sitemap Sections    ${sitemap_source}

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_urls}=    Create List
    ${total_urls}=    Set Variable    0

    # Test pages
    @{pages_list}=    Get From Dictionary    ${sections}    pages
    ${pages_count}=    Get Length    ${pages_list}
    IF    '${pages_samples}' == 'None'
        ${total_urls}=    Evaluate    ${total_urls} + ${pages_count}
        Log To Console    Testing all ${pages_count} detected page URLs...
        FOR    ${test_url}    IN    @{pages_list}
            Log To Console    [Page] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
    ELSE
        ${pages_samples_int}=    Convert To Integer    ${pages_samples}
        ${actual_samples}=    Evaluate    min(${pages_samples_int}, ${pages_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_pages}=    Evaluate    random.sample(${pages_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${pages_count} detected page URLs...
        FOR    ${test_url}    IN    @{random_pages}
            Log To Console    [Page] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
    END
    Log To Console    Pages section complete. Cleaning up...
    Cleanup Browser Windows

    # Test used vehicles
    @{used_vehicles_list}=    Get From Dictionary    ${sections}    used_vehicles
    ${used_vehicles_count}=    Get Length    ${used_vehicles_list}
    ${used_samples_int}=    Convert To Integer    ${used_vehicle_samples}
    IF    ${used_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${used_samples_int}, ${used_vehicles_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_used}=    Evaluate    random.sample(${used_vehicles_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${used_vehicles_count} detected used vehicle URLs...
        FOR    ${test_url}    IN    @{random_used}
            Log To Console    [Used Vehicle] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
        Log To Console    Used vehicles section complete.
        Cleanup Browser Windows
    END

    # Test new vehicles
    @{new_vehicles_list}=    Get From Dictionary    ${sections}    new_vehicles
    ${new_vehicles_count}=    Get Length    ${new_vehicles_list}
    ${new_samples_int}=    Convert To Integer    ${new_vehicle_samples}
    IF    ${new_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${new_samples_int}, ${new_vehicles_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_new}=    Evaluate    random.sample(${new_vehicles_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${new_vehicles_count} detected new vehicle URLs...
        FOR    ${test_url}    IN    @{random_new}
            Log To Console    [New Vehicle] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
        Log To Console    New vehicles section complete.
        Cleanup Browser Windows
    END

    # Test showroom
    @{showroom_list}=    Get From Dictionary    ${sections}    showroom
    ${showroom_count}=    Get Length    ${showroom_list}
    ${showroom_samples_int}=    Convert To Integer    ${showroom_samples}
    IF    ${showroom_count} > 0
        ${actual_samples}=    Evaluate    min(${showroom_samples_int}, ${showroom_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_showroom}=    Evaluate    random.sample(${showroom_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${showroom_count} detected showroom URLs...
        FOR    ${test_url}    IN    @{random_showroom}
            Log To Console    [Showroom] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
        Log To Console    Showroom section complete.
        Cleanup Browser Windows
    END

    # Test models
    @{models_list}=    Get From Dictionary    ${sections}    models
    ${models_count}=    Get Length    ${models_list}
    ${models_samples_int}=    Convert To Integer    ${models_samples}
    IF    ${models_count} > 0
        ${actual_samples}=    Evaluate    min(${models_samples_int}, ${models_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_models}=    Evaluate    random.sample(${models_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${models_count} detected model URLs...
        FOR    ${test_url}    IN    @{random_models}
            Log To Console    [Model] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
        Log To Console    Models section complete.
        Cleanup Browser Windows
    END

    # Test model trims
    @{model_trims_list}=    Get From Dictionary    ${sections}    model_trims
    ${trims_count}=    Get Length    ${model_trims_list}
    ${trims_samples_int}=    Convert To Integer    ${model_trims_samples}
    IF    ${trims_count} > 0
        ${actual_samples}=    Evaluate    min(${trims_samples_int}, ${trims_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_trims}=    Evaluate    random.sample(${model_trims_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${trims_count} detected model trim URLs...
        FOR    ${test_url}    IN    @{random_trims}
            Log To Console    [Model Trim] ${test_url}
            ${result}=    Test URL In New Tab    ${test_url}    ${validation_keyword}
            IF    ${result}
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                Append To List    ${failed_urls}    ${test_url}
            END
            Sleep    0.5s
        END
        Log To Console    Model trims section complete.
        Cleanup Browser Windows
    END

    Log To Console    Site summary: ${passed}/${total_urls} passed, ${failed}/${total_urls} failed

    RETURN    ${passed}    ${failed}    @{failed_urls}

Test URL In New Tab
    [Documentation]    Opens URL in new tab, runs validation keyword, closes tab and returns to main window
    [Arguments]    ${url}    ${validation_keyword}
    ${main_handle}=    Get Window Handles
    ${main_handle}=    Get From List    ${main_handle}    0

    Execute Javascript    window.open('${url}', '_blank');
    Sleep    1s

    ${all_handles}=    Get Window Handles
    ${new_handle}=    Get From List    ${all_handles}    -1
    Switch Window    ${new_handle}
    Sleep    0.5s

    Sleep    2s
    ${result}=    Run Keyword And Return Status    ${validation_keyword}

    Close Window
    Sleep    0.3s
    Switch Window    ${main_handle}
    Sleep    0.5s

    RETURN    ${result}

Test URL In New Tab With Details
    [Documentation]    Opens URL in new tab, runs detailed validation, returns results with error details
    [Arguments]    ${url}
    ${main_handle}=    Get Window Handles
    ${main_handle}=    Get From List    ${main_handle}    0

    Execute Javascript    window.open('${url}', '_blank');
    Sleep    1s

    ${all_handles}=    Get Window Handles
    ${new_handle}=    Get From List    ${all_handles}    -1
    Switch Window    ${new_handle}
    Sleep    0.5s

    Sleep    2s
    ${result}=    Validate Contact Links With Details

    Close Window
    Sleep    0.3s
    Switch Window    ${main_handle}
    Sleep    0.5s

    RETURN    ${result}

Test Sitemap URLs In Real Time With Details
    [Documentation]    Tests sampled URLs from sitemap sections with detailed error tracking and checkpoint support
    [Arguments]    ${checkpoint}    ${url}    ${name}    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Go To    ${sitemap_url}
    Sleep    2s

    ${sitemap_source}=    Get Source
    &{sections}=    Extract Sitemap Sections    ${sitemap_source}

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_data}=    Create List
    ${total_urls}=    Set Variable    0

    # Test pages
    @{pages_list}=    Get From Dictionary    ${sections}    pages
    @{already_tested_pages}=    Get Tested URLs For Site    ${checkpoint}    pages
    @{pages_list}=    Filter Already Tested URLs    ${pages_list}    ${already_tested_pages}
    ${pages_count}=    Get Length    ${pages_list}

    IF    ${pages_count} > 0
        IF    '${pages_samples}' == 'None'
            ${total_urls}=    Evaluate    ${total_urls} + ${pages_count}
            Log To Console    Testing ${pages_count} page URLs (${pages_count} new)...
            FOR    ${test_url}    IN    @{pages_list}
                Log To Console    [Page] ${test_url}
                ${result}=    Test URL In New Tab With Details    ${test_url}
                ${status}=    Get From Dictionary    ${result}    status
                Record Tested URL    ${checkpoint}    pages    ${test_url}
                IF    '${status}' == 'PASS'
                    ${passed}=    Evaluate    ${passed} + 1
                ELSE
                    ${failed}=    Evaluate    ${failed} + 1
                    ${description}=    Get From Dictionary    ${result}    description
                    ${details}=    Get From Dictionary    ${result}    details
                    &{fail_info}=    Create Dictionary    url=${test_url}    category=Pages    description=${description}    details=${details}
                    Append To List    ${failed_data}    ${fail_info}
                END
                Sleep    0.5s
            END
        ELSE
            ${pages_samples_int}=    Convert To Integer    ${pages_samples}
            ${actual_samples}=    Evaluate    min(${pages_samples_int}, ${pages_count})
            ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
            @{random_pages}=    Evaluate    random.sample(${pages_list}, ${actual_samples})    random
            Log To Console    Sampling ${actual_samples} from ${pages_count} new page URLs...
            FOR    ${test_url}    IN    @{random_pages}
                Log To Console    [Page] ${test_url}
                ${result}=    Test URL In New Tab With Details    ${test_url}
                ${status}=    Get From Dictionary    ${result}    status
                Record Tested URL    ${checkpoint}    pages    ${test_url}
                IF    '${status}' == 'PASS'
                    ${passed}=    Evaluate    ${passed} + 1
                ELSE
                    ${failed}=    Evaluate    ${failed} + 1
                    ${description}=    Get From Dictionary    ${result}    description
                    ${details}=    Get From Dictionary    ${result}    details
                    &{fail_info}=    Create Dictionary    url=${test_url}    category=Pages    description=${description}    details=${details}
                    Append To List    ${failed_data}    ${fail_info}
                END
                Sleep    0.5s
            END
        END
        Log To Console    Pages section complete. Cleaning up...
        Cleanup Browser Windows
    ELSE
        Log To Console    No new pages to test (all already completed)
    END

    # Test used vehicles
    @{used_vehicles_list}=    Get From Dictionary    ${sections}    used_vehicles
    @{already_tested_used}=    Get Tested URLs For Site    ${checkpoint}    used_vehicles
    @{used_vehicles_list}=    Filter Already Tested URLs    ${used_vehicles_list}    ${already_tested_used}
    ${used_vehicles_count}=    Get Length    ${used_vehicles_list}
    ${used_samples_int}=    Convert To Integer    ${used_vehicle_samples}
    IF    ${used_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${used_samples_int}, ${used_vehicles_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_used}=    Evaluate    random.sample(${used_vehicles_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${used_vehicles_count} new used vehicle URLs...
        FOR    ${test_url}    IN    @{random_used}
            Log To Console    [Used Vehicle] ${test_url}
            ${result}=    Test URL In New Tab With Details    ${test_url}
            ${status}=    Get From Dictionary    ${result}    status
            Record Tested URL    ${checkpoint}    used_vehicles    ${test_url}
            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                &{fail_info}=    Create Dictionary    url=${test_url}    category=Used Vehicle    description=${description}    details=${details}
                Append To List    ${failed_data}    ${fail_info}
            END
            Sleep    0.5s
        END
        Log To Console    Used vehicles section complete.
        Cleanup Browser Windows
    END

    # Test new vehicles
    @{new_vehicles_list}=    Get From Dictionary    ${sections}    new_vehicles
    @{already_tested_new}=    Get Tested URLs For Site    ${checkpoint}    new_vehicles
    @{new_vehicles_list}=    Filter Already Tested URLs    ${new_vehicles_list}    ${already_tested_new}
    ${new_vehicles_count}=    Get Length    ${new_vehicles_list}
    ${new_samples_int}=    Convert To Integer    ${new_vehicle_samples}
    IF    ${new_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${new_samples_int}, ${new_vehicles_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_new}=    Evaluate    random.sample(${new_vehicles_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${new_vehicles_count} new new vehicle URLs...
        FOR    ${test_url}    IN    @{random_new}
            Log To Console    [New Vehicle] ${test_url}
            ${result}=    Test URL In New Tab With Details    ${test_url}
            ${status}=    Get From Dictionary    ${result}    status
            Record Tested URL    ${checkpoint}    new_vehicles    ${test_url}
            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                &{fail_info}=    Create Dictionary    url=${test_url}    category=New Vehicle    description=${description}    details=${details}
                Append To List    ${failed_data}    ${fail_info}
            END
            Sleep    0.5s
        END
        Log To Console    New vehicles section complete.
        Cleanup Browser Windows
    END

    # Test showroom
    @{showroom_list}=    Get From Dictionary    ${sections}    showroom
    @{already_tested_showroom}=    Get Tested URLs For Site    ${checkpoint}    showroom
    @{showroom_list}=    Filter Already Tested URLs    ${showroom_list}    ${already_tested_showroom}
    ${showroom_count}=    Get Length    ${showroom_list}
    ${showroom_samples_int}=    Convert To Integer    ${showroom_samples}
    IF    ${showroom_count} > 0
        ${actual_samples}=    Evaluate    min(${showroom_samples_int}, ${showroom_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_showroom}=    Evaluate    random.sample(${showroom_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${showroom_count} new showroom URLs...
        FOR    ${test_url}    IN    @{random_showroom}
            Log To Console    [Showroom] ${test_url}
            ${result}=    Test URL In New Tab With Details    ${test_url}
            ${status}=    Get From Dictionary    ${result}    status
            Record Tested URL    ${checkpoint}    showroom    ${test_url}
            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                &{fail_info}=    Create Dictionary    url=${test_url}    category=Showroom    description=${description}    details=${details}
                Append To List    ${failed_data}    ${fail_info}
            END
            Sleep    0.5s
        END
        Log To Console    Showroom section complete.
        Cleanup Browser Windows
    END

    # Test models
    @{models_list}=    Get From Dictionary    ${sections}    models
    @{already_tested_models}=    Get Tested URLs For Site    ${checkpoint}    models
    @{models_list}=    Filter Already Tested URLs    ${models_list}    ${already_tested_models}
    ${models_count}=    Get Length    ${models_list}
    ${models_samples_int}=    Convert To Integer    ${models_samples}
    IF    ${models_count} > 0
        ${actual_samples}=    Evaluate    min(${models_samples_int}, ${models_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_models}=    Evaluate    random.sample(${models_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${models_count} new model URLs...
        FOR    ${test_url}    IN    @{random_models}
            Log To Console    [Model] ${test_url}
            ${result}=    Test URL In New Tab With Details    ${test_url}
            ${status}=    Get From Dictionary    ${result}    status
            Record Tested URL    ${checkpoint}    models    ${test_url}
            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                &{fail_info}=    Create Dictionary    url=${test_url}    category=Model    description=${description}    details=${details}
                Append To List    ${failed_data}    ${fail_info}
            END
            Sleep    0.5s
        END
        Log To Console    Models section complete.
        Cleanup Browser Windows
    END

    # Test model trims
    @{model_trims_list}=    Get From Dictionary    ${sections}    model_trims
    @{already_tested_trims}=    Get Tested URLs For Site    ${checkpoint}    model_trims
    @{model_trims_list}=    Filter Already Tested URLs    ${model_trims_list}    ${already_tested_trims}
    ${trims_count}=    Get Length    ${model_trims_list}
    ${trims_samples_int}=    Convert To Integer    ${model_trims_samples}
    IF    ${trims_count} > 0
        ${actual_samples}=    Evaluate    min(${trims_samples_int}, ${trims_count})
        ${total_urls}=    Evaluate    ${total_urls} + ${actual_samples}
        @{random_trims}=    Evaluate    random.sample(${model_trims_list}, ${actual_samples})    random
        Log To Console    Sampling ${actual_samples} from ${trims_count} new model trim URLs...
        FOR    ${test_url}    IN    @{random_trims}
            Log To Console    [Model Trim] ${test_url}
            ${result}=    Test URL In New Tab With Details    ${test_url}
            ${status}=    Get From Dictionary    ${result}    status
            Record Tested URL    ${checkpoint}    model_trims    ${test_url}
            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                &{fail_info}=    Create Dictionary    url=${test_url}    category=Model Trim    description=${description}    details=${details}
                Append To List    ${failed_data}    ${fail_info}
            END
            Sleep    0.5s
        END
        Log To Console    Model trims section complete.
        Cleanup Browser Windows
    END

    Log To Console    Site summary: ${passed}/${total_urls} passed, ${failed}/${total_urls} failed

    RETURN    ${passed}    ${failed}    @{failed_data}

Parse Sitemap And Get Test URLs
    [Documentation]    Parses sitemap and returns list of URLs for testing (without running validations)
    [Arguments]    ${url}    ${name}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Go To    ${sitemap_url}
    Sleep    2s

    ${sitemap_source}=    Get Source
    @{test_urls}=    Get Test URLs From Sitemap    ${sitemap_source}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}

    ${url_count}=    Get Length    ${test_urls}
    Log To Console    Found ${url_count} URLs (p=${pages_samples} uv=${used_vehicle_samples} nv=${new_vehicle_samples} s=${showroom_samples} m=${models_samples} mt=${model_trims_samples})

    RETURN    @{test_urls}
