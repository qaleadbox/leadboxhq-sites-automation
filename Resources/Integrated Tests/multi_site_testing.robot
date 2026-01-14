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
Library    ${CURDIR}${/}..${/}Helpers${/}signal_checker.py

*** Keywords ***
Parse Sitemap URLs
    [Documentation]    Multi-site validation using sitemap URL sampling with checkpoint/resume support
    ...                Loads sites from spreadsheet and tests sampled URLs with specified validation keyword
    ...                Automatically saves progress and can resume from last checkpoint
    ...                Flexible framework: Pass any validation keyword to test different functionality
    ...                skip_*_if_sampled: Set to 'true' to skip section if at least one sample was already tested
    [Arguments]    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1    ${use_checkpoint}=true    ${skip_pages_if_sampled}=false    ${skip_used_vehicles_if_sampled}=false    ${skip_new_vehicles_if_sampled}=false    ${skip_showroom_if_sampled}=false    ${skip_models_if_sampled}=false    ${skip_model_trims_if_sampled}=false

    # Install signal handler for graceful interrupts
    Install Signal Handler

    @{sites}=    Load Sites From Spreadsheet
    ${sites_count}=    Get Length    ${sites}

    # Initialize checkpoint and issue logger
    ${checkpoint}=    Initialize Checkpoint    ${sites_count}
    ${issues_data}=    Initialize Issue Log

    # DISABLED: This was incorrectly "fixing" counters with total=0 back to tested/tested
    # Update Completed Sites Pages Counters    ${checkpoint}

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_urls}=    Create List

    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver

    # Stability options (always enabled)
    Call Method    ${chrome_options}    add_argument    --no-sandbox
    Call Method    ${chrome_options}    add_argument    --disable-dev-shm-usage
    Call Method    ${chrome_options}    add_argument    --disable-gpu
    Call Method    ${chrome_options}    add_argument    --disable-software-rasterizer
    Call Method    ${chrome_options}    add_argument    --disable-extensions
    Call Method    ${chrome_options}    add_argument    --disable-background-networking
    Call Method    ${chrome_options}    add_argument    --disable-sync
    Call Method    ${chrome_options}    add_argument    --disable-translate
    Call Method    ${chrome_options}    add_argument    --disable-web-security
    Call Method    ${chrome_options}    add_argument    --metrics-recording-only
    Call Method    ${chrome_options}    add_argument    --mute-audio
    Call Method    ${chrome_options}    add_argument    --no-first-run
    Call Method    ${chrome_options}    add_argument    --safebrowsing-disable-auto-update
    Call Method    ${chrome_options}    add_argument    --disable-breakpad
    Call Method    ${chrome_options}    add_argument    --disable-component-update
    Call Method    ${chrome_options}    add_argument    --disable-domain-reliability
    Call Method    ${chrome_options}    add_argument    --disable-notifications
    Call Method    ${chrome_options}    add_argument    --disable-popup-blocking
    ${blink_features_arg}=    Set Variable    --disable-blink-features=AutomationControlled
    Call Method    ${chrome_options}    add_argument    ${blink_features_arg}
    ${disable_features_arg}=    Set Variable    --disable-features=TranslateUI,BlinkGenPropertyTrees,VizDisplayCompositor
    Call Method    ${chrome_options}    add_argument    ${disable_features_arg}

    # Memory management
    ${js_flags_arg}=    Set Variable    --js-flags=--max-old-space-size=4096
    Call Method    ${chrome_options}    add_argument    ${js_flags_arg}
    Call Method    ${chrome_options}    add_argument    --disable-renderer-backgrounding

    # Headless mode if enabled (using old headless for stability)
    IF    '${HEADLESS}' == 'true'
        Call Method    ${chrome_options}    add_argument    headless
        # Window size for headless (helps with rendering)
        ${window_size_arg}=    Set Variable    --window-size=1920,1080
        Call Method    ${chrome_options}    add_argument    ${window_size_arg}
        Call Method    ${chrome_options}    add_argument    --start-maximized
        Call Method    ${chrome_options}    add_argument    --disable-crash-reporter
    END

    # Page load strategy
    Call Method    ${chrome_options}    set_capability    pageLoadStrategy    normal

    Open Browser    about:blank    chrome    options=${chrome_options}

    # Set timeouts to prevent hanging
    Set Selenium Timeout    30 seconds
    Set Selenium Implicit Wait    10 seconds
    Set Selenium Page Load Timeout    30 seconds

    FOR    ${site}    IN    @{sites}
        # Check for interrupt signal at start of each site
        Check For Interrupt

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

        # Test site with error recovery
        TRY
            ${site_passed}    ${site_failed}    @{site_failed_data}=    Test Sitemap URLs In Real Time With Details    ${checkpoint}    ${url}    ${name}    ${validation_keyword}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}    ${skip_pages_if_sampled}    ${skip_used_vehicles_if_sampled}    ${skip_new_vehicles_if_sampled}    ${skip_showroom_if_sampled}    ${skip_models_if_sampled}    ${skip_model_trims_if_sampled}
        EXCEPT    AS    ${error}
            Log To Console    Error occurred: ${error}
            Log To Console    Browser may have crashed! Restarting browser...
            Close Browser Safely
            Sleep    2s
            Open Browser    about:blank    chrome    options=${chrome_options}
            Set Selenium Timeout    30 seconds
            Set Selenium Implicit Wait    10 seconds
            Set Selenium Page Load Timeout    30 seconds
            Sleep    2s
            # Try again with the same site
            Log To Console    Retrying site: ${name}
            ${site_passed}    ${site_failed}    @{site_failed_data}=    Test Sitemap URLs In Real Time With Details    ${checkpoint}    ${url}    ${name}    ${validation_keyword}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}    ${skip_pages_if_sampled}    ${skip_used_vehicles_if_sampled}    ${skip_new_vehicles_if_sampled}    ${skip_showroom_if_sampled}    ${skip_models_if_sampled}    ${skip_model_trims_if_sampled}
        END

        # Log issues for failed URLs
        FOR    ${failed_data}    IN    @{site_failed_data}
            ${failed_url}=    Get From Dictionary    ${failed_data}    url
            ${category}=    Get From Dictionary    ${failed_data}    category
            ${description}=    Get From Dictionary    ${failed_data}    description
            ${details}=    Get From Dictionary    ${failed_data}    details

            # Check if parent_span exists in failed_data
            ${has_parent_span}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${failed_data}    parent_span
            IF    ${has_parent_span}
                ${parent_span}=    Get From Dictionary    ${failed_data}    parent_span

                # Check if issue with same parent_span already exists
                ${has_duplicate}=    Has Issue With Parent Span    ${issues_data}    ${name}    ${parent_span}    ${description}
                IF    not ${has_duplicate}
                    Log Issue    ${issues_data}    ${name}    ${failed_url}    ${description}    ${category}    details=${details}    parent_span=${parent_span}
                    Append To List    ${failed_urls}    ${name}: ${failed_url}
                ELSE
                    Log To Console    Skipping duplicate issue with same parent_span: ${parent_span}
                END
            ELSE
                # No parent_span, log as usual
                Log Issue    ${issues_data}    ${name}    ${failed_url}    ${description}    ${category}    details=${details}
                Append To List    ${failed_urls}    ${name}: ${failed_url}
            END
        END

        ${passed}=    Evaluate    ${passed} + ${site_passed}
        ${failed}=    Evaluate    ${failed} + ${site_failed}

        # Mark site as completed and save checkpoint
        ${total_tests}=    Evaluate    ${site_passed} + ${site_failed}
        &{results}=    Create Dictionary    passed=${site_passed}    failed=${site_failed}
        Complete Site Processing    ${checkpoint}    ${name}    ${url}    ${results}    ${total_tests}    ${site_passed}    ${site_failed}
    END

    # Always close browser, even on errors
    Close Browser Safely

    Log To Console    \nPassed: ${passed} | Failed: ${failed}
    Log To Console    Total sites tested: ${sites_count}

    # Display checkpoint summary
    ${summary}=    Get From Dictionary    ${checkpoint}    summary
    ${sites_pending}=    Get From Dictionary    ${summary}    sites_pending
    Log To Console    Sites pending: ${sites_pending}

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
    [Documentation]    Opens URL in new tab (or navigates directly in headless), runs detailed validation, returns results with error details
    [Arguments]    ${url}

    # In headless mode, navigate directly to avoid Chrome crashes with many tabs
    IF    '${HEADLESS}' == 'true'
        TRY
            Go To    ${url}
            Sleep    3s

            # Wait for page to be ready
            Wait Until Page Contains Element    xpath=//body    timeout=10s
            Execute Javascript    return document.readyState === 'complete'

            ${result}=    Validate Contact Links With Details
            RETURN    ${result}
        EXCEPT    AS    ${error}
            Log To Console    ⚠️ Failed to load/validate ${url}: ${error}
            # Return FAIL result
            &{result}=    Create Dictionary
            ...    status=FAIL
            ...    error_count=1
            ...    errors=Failed to load page
            ...    description=Page load failed: ${error}
            ...    details=${error}
            ...    parent_span=${EMPTY}
            RETURN    ${result}
        END
    END

    # In headed mode, use tabs as normal
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
    [Documentation]    Tests sampled URLs from sitemap sections with detailed error tracking and counter-based checkpoint support
    [Arguments]    ${checkpoint}    ${url}    ${name}    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1    ${skip_pages_if_sampled}=false    ${skip_used_vehicles_if_sampled}=false    ${skip_new_vehicles_if_sampled}=false    ${skip_showroom_if_sampled}=false    ${skip_models_if_sampled}=false    ${skip_model_trims_if_sampled}=false
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Log To Console    Loading sitemap: ${sitemap_url}

    TRY
        Go To    ${sitemap_url}
        Sleep    2s
        Log To Console    ✓ Sitemap loaded successfully
    EXCEPT    AS    ${error}
        Log To Console    ✗ Failed to load sitemap: ${error}
        Fail    Could not load sitemap for ${name}: ${error}
    END

    ${sitemap_source}=    Get Source
    &{sections}=    Extract Sitemap Sections    ${sitemap_source}

    # IMPORTANT: Get pages list and immediately set the pages counter with total count
    @{pages_list}=    Get From Dictionary    ${sections}    pages
    ${total_pages}=    Get Length    ${pages_list}

    # Set pages counter immediately after fetching sitemap (before testing)
    ${site}=    Get In Progress Site    ${checkpoint}
    ${section_counters}=    Get From Dictionary    ${site}    section_counters
    ${pages_tracking}=    Get From Dictionary    ${site}    pages_link_tracking
    ${tested_links}=    Get From Dictionary    ${pages_tracking}    tested_links
    ${tested_count}=    Get Length    ${tested_links}

    # Initialize pages counter with actual sitemap count
    ${has_pages}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    pages
    IF    not ${has_pages}
        Set To Dictionary    ${section_counters}    pages=${tested_count}/${total_pages}
        Save Checkpoint Data    ${checkpoint}
        Log To Console    [Sitemap] Initialized pages counter: ${tested_count}/${total_pages}
    ELSE
        ${pages_counter}=    Get From Dictionary    ${section_counters}    pages
        @{parts}=    Split String    ${pages_counter}    /
        ${current_total}=    Get From List    ${parts}    1
        ${current_total_int}=    Convert To Integer    ${current_total}

        # Update if total doesn't match sitemap
        IF    ${current_total_int} != ${total_pages}
            Set To Dictionary    ${section_counters}    pages=${tested_count}/${total_pages}
            Save Checkpoint Data    ${checkpoint}
            Log To Console    [Sitemap] Updated pages counter: ${tested_count}/${total_pages} (was ${pages_counter})
        END
    END

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_data}=    Create List

    # Test pages (using link tracking)
    ${passed}    ${failed}=    Test Pages Section With Link Tracking    ${checkpoint}    ${pages_list}    ${pages_samples}    ${skip_pages_if_sampled}    Pages    ${validation_keyword}    ${passed}    ${failed}    ${failed_data}

    # Test used vehicles
    @{used_vehicles_list}=    Get From Dictionary    ${sections}    used_vehicles
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Used Vehicles    used_vehicles    ${used_vehicles_list}    ${used_vehicle_samples}    ${skip_used_vehicles_if_sampled}    Used Vehicle    ${passed}    ${failed}    ${failed_data}

    # Test new vehicles
    @{new_vehicles_list}=    Get From Dictionary    ${sections}    new_vehicles
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    New Vehicles    new_vehicles    ${new_vehicles_list}    ${new_vehicle_samples}    ${skip_new_vehicles_if_sampled}    New Vehicle    ${passed}    ${failed}    ${failed_data}

    # Test showroom
    @{showroom_list}=    Get From Dictionary    ${sections}    showroom
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Showroom    showroom    ${showroom_list}    ${showroom_samples}    ${skip_showroom_if_sampled}    Showroom    ${passed}    ${failed}    ${failed_data}

    # Test models
    @{models_list}=    Get From Dictionary    ${sections}    models
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Models    models    ${models_list}    ${models_samples}    ${skip_models_if_sampled}    Model    ${passed}    ${failed}    ${failed_data}

    # Test model trims
    @{model_trims_list}=    Get From Dictionary    ${sections}    model_trims
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Model Trims    model_trims    ${model_trims_list}    ${model_trims_samples}    ${skip_model_trims_if_sampled}    Model Trim    ${passed}    ${failed}    ${failed_data}

    ${total_tests}=    Evaluate    ${passed} + ${failed}
    Log To Console    Site summary: ${passed}/${total_tests} passed, ${failed}/${total_tests} failed

    RETURN    ${passed}    ${failed}    @{failed_data}

Test Section With Counter
    [Documentation]    Tests a section with counter-based checkpoint tracking
    ...    Also skips URLs that have logged issues in issues.json
    [Arguments]    ${checkpoint}    ${section_name}    ${section_key}    ${url_list}    ${samples_param}    ${skip_if_sampled}    ${category_label}    ${passed}    ${failed}    ${failed_data}
    ${url_count}=    Get Length    ${url_list}

    # Initialize counter if not set
    ${current_counter}=    Get Section Counter    ${checkpoint}    ${section_key}
    IF    '${current_counter}' == '0/0' and ${url_count} > 0
        IF    '${samples_param}' == 'None'
            Set Section Counter    ${checkpoint}    ${section_key}    0    ${url_count}
        ELSE
            ${samples_int}=    Convert To Integer    ${samples_param}
            ${target_samples}=    Evaluate    min(${samples_int}, ${url_count})
            Set Section Counter    ${checkpoint}    ${section_key}    0    ${target_samples}
        END
    END

    # Check if should skip this section
    ${should_skip}=    Should Skip Section    ${checkpoint}    ${section_key}    ${skip_if_sampled}
    IF    not ${should_skip}
        ${counter}=    Get Section Counter    ${checkpoint}    ${section_key}
        @{counter_parts}=    Split String    ${counter}    /
        ${tested_count}=    Get From List    ${counter_parts}    0
        ${target_count}=    Get From List    ${counter_parts}    1
        ${tested_int}=    Convert To Integer    ${tested_count}
        ${target_int}=    Convert To Integer    ${target_count}
        ${remaining}=    Evaluate    ${target_int} - ${tested_int}

        IF    ${remaining} > 0 and ${url_count} > 0
            # Load issues data to filter out URLs with logged issues
            ${issues_data}=    Load Issues

            # Filter out URLs with logged issues
            @{urls_without_issues}=    Create List
            FOR    ${url}    IN    @{url_list}
                ${has_issue}=    Has Issue For URL    ${issues_data}    ${url}
                IF    not ${has_issue}
                    Append To List    ${urls_without_issues}    ${url}
                END
            END

            ${filtered_count}=    Get Length    ${urls_without_issues}
            IF    ${filtered_count} > 0
                ${actual_samples}=    Evaluate    min(${remaining}, ${filtered_count})
                @{random_urls}=    Evaluate    random.sample(${urls_without_issues}, ${actual_samples})    random
                Log To Console    [${section_name}] Sampling ${actual_samples} URLs (counter: ${counter})...
                FOR    ${test_url}    IN    @{random_urls}
                    # Check for interrupt before testing each URL
                    Check For Interrupt

                    Log To Console    [${category_label}] ${test_url}
                    ${result}=    Test URL In New Tab With Details    ${test_url}
                    ${status}=    Get From Dictionary    ${result}    status
                    Update Section Counter    ${checkpoint}    ${section_key}
                    IF    '${status}' == 'PASS'
                        ${passed}=    Evaluate    ${passed} + 1
                    ELSE
                        ${failed}=    Evaluate    ${failed} + 1
                        ${description}=    Get From Dictionary    ${result}    description
                        ${details}=    Get From Dictionary    ${result}    details

                        # Extract parent_span if available
                        ${has_parent_span}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${result}    parent_span
                        IF    ${has_parent_span}
                            ${parent_span}=    Get From Dictionary    ${result}    parent_span
                            &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}    parent_span=${parent_span}
                        ELSE
                            &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}
                        END

                        Append To List    ${failed_data}    ${fail_info}
                    END
                    Sleep    0.5s
                END
                Log To Console    ${section_name} section complete. Cleaning up...
                Cleanup Browser Windows
            ELSE
                Log To Console    [${section_name}] All URLs have logged issues, skipping section
            END
        END
    END

    RETURN    ${passed}    ${failed}

Test Pages Section With Link Tracking
    [Documentation]    Tests pages section using link tracking instead of counters, skipping pages already tested with this specific test
    ...    Also skips pages that have logged issues in issues.json
    [Arguments]    ${checkpoint}    ${url_list}    ${samples_param}    ${skip_if_sampled}    ${category_label}    ${test_name}    ${passed}    ${failed}    ${failed_data}
    ${url_count}=    Get Length    ${url_list}

    # Pages counter should already be set when sitemap was opened
    # Just verify it exists (shouldn't need this, but safety check)
    ${site}=    Get In Progress Site    ${checkpoint}
    ${section_counters}=    Get From Dictionary    ${site}    section_counters
    ${has_pages}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${section_counters}    pages
    IF    not ${has_pages}
        # This shouldn't happen, but add as fallback
        Set To Dictionary    ${section_counters}    pages=0/${url_count}
        Log To Console    [Pages] WARNING: Counter was not initialized, setting to 0/${url_count}
    END

    # Check if we should skip based on all_pages_covered flag for this test
    ${all_covered}=    Are All Pages Covered    ${checkpoint}    ${test_name}
    IF    ${all_covered}
        Log To Console    [Pages] All pages already covered for test: ${test_name}, skipping
        RETURN    ${passed}    ${failed}
    END

    # Check if skip_if_sampled is true and at least one page was tested with this test
    IF    '${skip_if_sampled}' == 'true'
        ${tested_count}=    Get Tested Links Count    ${checkpoint}    ${test_name}
        IF    ${tested_count} > 0
            Log To Console    [Pages] At least one page sampled for test: ${test_name} (${tested_count} tested), skipping
            RETURN    ${passed}    ${failed}
        END
    END

    # Load issues data to check for URLs with logged issues
    ${issues_data}=    Load Issues

    # Filter out pages already tested with this specific test OR that have logged issues
    @{untested_pages}=    Create List
    FOR    ${page_url}    IN    @{url_list}
        ${is_tested}=    Is Link Already Tested    ${checkpoint}    ${page_url}    ${test_name}
        ${has_issue}=    Has Issue For URL    ${issues_data}    ${page_url}
        IF    not ${is_tested} and not ${has_issue}
            Append To List    ${untested_pages}    ${page_url}
        END
    END

    ${untested_count}=    Get Length    ${untested_pages}
    ${tested_count}=    Get Tested Links Count    ${checkpoint}    ${test_name}

    IF    ${untested_count} == 0
        Log To Console    [Pages] All ${url_count} pages already tested for: ${test_name}
        Mark All Pages Covered    ${checkpoint}    ${test_name}
        RETURN    ${passed}    ${failed}
    END

    # Determine how many samples to test and select pages
    IF    '${samples_param}' == 'None'
        # Test all pages in alphabetical order (no sampling)
        ${samples_to_test}=    Set Variable    ${untested_count}
        @{pages_to_test}=    Evaluate    sorted(${untested_pages})    # Sort alphabetically
        Log To Console    [Pages] Testing all ${samples_to_test} untested pages in alphabetical order (${tested_count} already tested, ${url_count} total)...
    ELSE
        # Random sampling
        ${samples_int}=    Convert To Integer    ${samples_param}
        ${samples_to_test}=    Evaluate    min(${samples_int}, ${untested_count})
        @{pages_to_test}=    Evaluate    random.sample(${untested_pages}, ${samples_to_test})    random
        Log To Console    [Pages] Testing ${samples_to_test} random samples from ${untested_count} untested pages for ${test_name} (${tested_count} already tested, ${url_count} total)...
    END

    FOR    ${test_url}    IN    @{pages_to_test}
        # Check for interrupt before testing each page
        Check For Interrupt

        Log To Console    [${category_label}] ${test_url}

        # Try to test the URL, catch any browser errors
        TRY
            ${result}=    Test URL In New Tab With Details    ${test_url}
        EXCEPT    AS    ${error}
            Log To Console    ⚠️ Error testing page: ${error}

            # Check if it's a browser crash (will trigger site-level retry)
            ${is_browser_error}=    Run Keyword And Return Status
            ...    Should Contain Any    ${error}    Connection refused    Broken pipe    Session not found

            IF    ${is_browser_error}
                # Re-raise error to trigger site-level browser restart
                Fail    ${error}
            END

            # Not a browser error, just mark this page as failed
            &{result}=    Create Dictionary
            ...    status=FAIL
            ...    error_count=1
            ...    errors=${error}
            ...    description=Test failed: ${error}
            ...    details=${error}
            ...    parent_span=${EMPTY}
        END

        ${status}=    Get From Dictionary    ${result}    status

        # Add to tested links with test name, regardless of pass/fail
        Add Tested Link    ${checkpoint}    ${test_url}    ${test_name}

        # Update pages counter
        Update Section Counter    ${checkpoint}    pages

        IF    '${status}' == 'PASS'
            ${passed}=    Evaluate    ${passed} + 1
        ELSE
            ${failed}=    Evaluate    ${failed} + 1
            ${description}=    Get From Dictionary    ${result}    description
            ${details}=    Get From Dictionary    ${result}    details

            # Extract parent_span if available
            ${has_parent_span}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${result}    parent_span
            IF    ${has_parent_span}
                ${parent_span}=    Get From Dictionary    ${result}    parent_span
                &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}    parent_span=${parent_span}
            ELSE
                &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}
            END

            Append To List    ${failed_data}    ${fail_info}
        END

        # Longer sleep in headless mode for stability
        IF    '${HEADLESS}' == 'true'
            Sleep    1s
        ELSE
            Sleep    0.5s
        END
    END

    # Check if all pages are now covered for this test
    ${new_tested_count}=    Get Tested Links Count    ${checkpoint}    ${test_name}
    IF    ${new_tested_count} >= ${url_count}
        Mark All Pages Covered    ${checkpoint}    ${test_name}
        Log To Console    [Pages] All pages now covered for: ${test_name}
    END

    Log To Console    Pages section complete. Cleaning up...
    Cleanup Browser Windows

    RETURN    ${passed}    ${failed}

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
