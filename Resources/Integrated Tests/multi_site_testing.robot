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
Run Test Environment
    [Documentation]    Runs tests based on TEST_MODE variable
    ...    - sitemap: Tests all sites from spreadsheet (with checkpoint/resume)
    ...    - unitary: Tests single page from UNITARY_PAGE_URL
    [Arguments]    @{validation_keywords}

    IF    '${TEST_MODE}' == 'unitary'
        Log To Console    \n🧪 TEST MODE: UNITARY PAGE
        Open Unitary Page    @{validation_keywords}
    ELSE IF    '${TEST_MODE}' == 'sitemap'
        Log To Console    \n🧪 TEST MODE: SITEMAP (Multiple Sites)
        Parse Sitemap URLs    @{validation_keywords}
    ELSE
        Fail    Invalid TEST_MODE: ${TEST_MODE}. Must be 'sitemap' or 'unitary'
    END

Open Unitary Page
    [Documentation]    Tests a single page with specified validations
    [Arguments]    @{validation_keywords}

    # Install signal handler
    Install Signal Handler

    Log To Console    🔍 Testing: ${UNITARY_PAGE_URL}
    Log To Console    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver

    # Stability options
    Call Method    ${chrome_options}    add_argument    --no-sandbox
    Call Method    ${chrome_options}    add_argument    --disable-dev-shm-usage
    Call Method    ${chrome_options}    add_argument    --disable-gpu

    # Headless mode if enabled
    IF    '${HEADLESS}' == 'true'
        Call Method    ${chrome_options}    add_argument    headless
        ${window_size_arg}=    Set Variable    --window-size=1920,1080
        Call Method    ${chrome_options}    add_argument    ${window_size_arg}
    END

    Open Browser    about:blank    chrome    options=${chrome_options}
    Set Selenium Timeout    30 seconds
    Set Selenium Implicit Wait    10 seconds
    Set Selenium Page Load Timeout    30 seconds

    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0

    # Navigate to page
    TRY
        Go To    ${UNITARY_PAGE_URL}
        Sleep    3s
        Log To Console    ✓ Page loaded
    EXCEPT    AS    ${error}
        Log To Console    ✗ Failed to load page: ${error}
        Close Browser Safely
        Fail    Could not load page: ${UNITARY_PAGE_URL}
    END

    # Run all validations
    Log To Console    \n📋 Running ${validation_keywords.__len__()} validation(s)...\n

    @{failed_validations}=    Create List

    FOR    ${validation_keyword}    IN    @{validation_keywords}
        Log To Console    ▶ ${validation_keyword}
        TRY
            Run Keyword    ${validation_keyword}
            Log To Console    ✓ PASSED\n
            ${passed}=    Evaluate    ${passed} + 1
        EXCEPT    AS    ${error}
            Log To Console    ✗ FAILED: ${error}\n
            ${failed}=    Evaluate    ${failed} + 1
            Append To List    ${failed_validations}    ${validation_keyword}: ${error}
        END
    END

    # Summary
    ${total}=    Evaluate    ${passed} + ${failed}
    Log To Console    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Log To Console    📊 Results: ${passed}/${total} PASSED, ${failed}/${total} FAILED
    Log To Console    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    # Fail the test if any validations failed
    IF    ${failed} > 0
        ${failed_list}=    Catenate    SEPARATOR=\n    @{failed_validations}
        Fail    ${failed} validation(s) failed:\n${failed_list}
    END

Parse Sitemap URLs
    [Documentation]    Multi-site validation using sitemap URL sampling with checkpoint/resume support
    ...                Loads sites from spreadsheet and tests sampled URLs with specified validation keywords
    ...                Automatically saves progress and can resume from last checkpoint
    ...                Flexible framework: Pass validation keywords as a list to test different functionality
    ...                skip_*_if_sampled: Set to 'true' to skip section if at least one sample was already tested
    [Arguments]    @{validation_keywords}    ${pages_samples}=${PAGES_SAMPLES}    ${used_vehicle_samples}=${USED_VEHICLE_SAMPLES}    ${new_vehicle_samples}=${NEW_VEHICLE_SAMPLES}    ${showroom_samples}=${SHOWROOM_SAMPLES}    ${models_samples}=${MODELS_SAMPLES}    ${model_trims_samples}=${MODEL_TRIMS_SAMPLES}    ${use_checkpoint}=${USE_CHECKPOINT}    ${skip_pages_if_sampled}=${SKIP_PAGES_IF_SAMPLED}    ${skip_used_vehicles_if_sampled}=${SKIP_USED_VEHICLES_IF_SAMPLED}    ${skip_new_vehicles_if_sampled}=${SKIP_NEW_VEHICLES_IF_SAMPLED}    ${skip_showroom_if_sampled}=${SKIP_SHOWROOM_IF_SAMPLED}    ${skip_models_if_sampled}=${SKIP_MODELS_IF_SAMPLED}    ${skip_model_trims_if_sampled}=${SKIP_MODEL_TRIMS_IF_SAMPLED}

    # Install signal handler for graceful interrupts
    Install Signal Handler

    # Validation keywords must be a list
    @{validation_list}=    Set Variable    ${validation_keywords}

    @{sites}=    Load Sites From Spreadsheet
    ${sites_count}=    Get Length    ${sites}

    # Initialize checkpoint and issue logger
    ${checkpoint}=    Initialize Checkpoint    ${sites_count}
    ${issues_data}=    Initialize Issue Log

    # Set expected validations for this test run
    Set Expected Validations    ${checkpoint}    @{validation_list}

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
            ${site_passed}    ${site_failed}    @{site_failed_data}=    Test Sitemap URLs In Real Time With Details    ${checkpoint}    ${url}    ${name}    ${validation_list}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}    ${skip_pages_if_sampled}    ${skip_used_vehicles_if_sampled}    ${skip_new_vehicles_if_sampled}    ${skip_showroom_if_sampled}    ${skip_models_if_sampled}    ${skip_model_trims_if_sampled}
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
            ${site_passed}    ${site_failed}    @{site_failed_data}=    Test Sitemap URLs In Real Time With Details    ${checkpoint}    ${url}    ${name}    ${validation_list}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}    ${skip_pages_if_sampled}    ${skip_used_vehicles_if_sampled}    ${skip_new_vehicles_if_sampled}    ${skip_showroom_if_sampled}    ${skip_models_if_sampled}    ${skip_model_trims_if_sampled}
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

Test URL With Multiple Validations
    [Documentation]    Opens URL once and runs multiple validations, returns dictionary with results per validation
    [Arguments]    ${url}    ${validation_keywords}
    &{all_results}=    Create Dictionary

    # In headless mode, navigate directly
    IF    '${HEADLESS}' == 'true'
        TRY
            Go To    ${url}
            Sleep    3s
            Wait Until Page Contains Element    xpath=//body    timeout=10s
            Execute Javascript    return document.readyState === 'complete'

            # Run each validation
            FOR    ${validation_keyword}    IN    @{validation_keywords}
                TRY
                    Run Keyword    ${validation_keyword}
                    &{result}=    Create Dictionary    status=PASS    description=${EMPTY}    details=${EMPTY}    parent_span=${EMPTY}
                EXCEPT    AS    ${error}
                    &{result}=    Create Dictionary    status=FAIL    description=${validation_keyword} failed: ${error}    details=${error}    parent_span=${EMPTY}
                END
                Set To Dictionary    ${all_results}    ${validation_keyword}=${result}
            END
        EXCEPT    AS    ${error}
            Log To Console    ⚠️ Failed to load ${url}: ${error}
            FOR    ${validation_keyword}    IN    @{validation_keywords}
                &{result}=    Create Dictionary    status=FAIL    description=Page load failed    details=${error}    parent_span=${EMPTY}
                Set To Dictionary    ${all_results}    ${validation_keyword}=${result}
            END
        END
        RETURN    ${all_results}
    END

    # In headed mode, use tabs
    ${main_handle}=    Get Window Handles
    ${main_handle}=    Get From List    ${main_handle}    0
    Execute Javascript    window.open('${url}', '_blank');
    Sleep    1s
    ${all_handles}=    Get Window Handles
    ${new_handle}=    Get From List    ${all_handles}    -1
    Switch Window    ${new_handle}
    Sleep    0.5s
    Sleep    2s

    # Run each validation in the same tab
    FOR    ${validation_keyword}    IN    @{validation_keywords}
        TRY
            Run Keyword    ${validation_keyword}
            &{result}=    Create Dictionary    status=PASS    description=${EMPTY}    details=${EMPTY}    parent_span=${EMPTY}
        EXCEPT    AS    ${error}
            &{result}=    Create Dictionary    status=FAIL    description=${validation_keyword} failed: ${error}    details=${error}    parent_span=${EMPTY}
        END
        Set To Dictionary    ${all_results}    ${validation_keyword}=${result}
    END

    Close Window
    Sleep    0.3s
    Switch Window    ${main_handle}
    Sleep    0.5s
    RETURN    ${all_results}

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
    [Arguments]    ${checkpoint}    ${url}    ${name}    ${validation_keywords}    ${pages_samples}=${PAGES_SAMPLES}    ${used_vehicle_samples}=${USED_VEHICLE_SAMPLES}    ${new_vehicle_samples}=${NEW_VEHICLE_SAMPLES}    ${showroom_samples}=${SHOWROOM_SAMPLES}    ${models_samples}=${MODELS_SAMPLES}    ${model_trims_samples}=${MODEL_TRIMS_SAMPLES}    ${skip_pages_if_sampled}=${SKIP_PAGES_IF_SAMPLED}    ${skip_used_vehicles_if_sampled}=${SKIP_USED_VEHICLES_IF_SAMPLED}    ${skip_new_vehicles_if_sampled}=${SKIP_NEW_VEHICLES_IF_SAMPLED}    ${skip_showroom_if_sampled}=${SKIP_SHOWROOM_IF_SAMPLED}    ${skip_models_if_sampled}=${SKIP_MODELS_IF_SAMPLED}    ${skip_model_trims_if_sampled}=${SKIP_MODEL_TRIMS_IF_SAMPLED}
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

    # Test pages (using link tracking with multiple validations)
    ${passed}    ${failed}=    Test Pages Section With Link Tracking    ${checkpoint}    ${pages_list}    ${pages_samples}    ${skip_pages_if_sampled}    Pages    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    # Test used vehicles
    @{used_vehicles_list}=    Get From Dictionary    ${sections}    used_vehicles
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Used Vehicles    used_vehicles    ${used_vehicles_list}    ${used_vehicle_samples}    ${skip_used_vehicles_if_sampled}    Used Vehicle    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    # Test new vehicles
    @{new_vehicles_list}=    Get From Dictionary    ${sections}    new_vehicles
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    New Vehicles    new_vehicles    ${new_vehicles_list}    ${new_vehicle_samples}    ${skip_new_vehicles_if_sampled}    New Vehicle    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    # Test showroom
    @{showroom_list}=    Get From Dictionary    ${sections}    showroom
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Showroom    showroom    ${showroom_list}    ${showroom_samples}    ${skip_showroom_if_sampled}    Showroom    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    # Test models
    @{models_list}=    Get From Dictionary    ${sections}    models
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Models    models    ${models_list}    ${models_samples}    ${skip_models_if_sampled}    Model    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    # Test model trims
    @{model_trims_list}=    Get From Dictionary    ${sections}    model_trims
    ${passed}    ${failed}=    Test Section With Counter    ${checkpoint}    Model Trims    model_trims    ${model_trims_list}    ${model_trims_samples}    ${skip_model_trims_if_sampled}    Model Trim    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${name}

    ${total_tests}=    Evaluate    ${passed} + ${failed}
    Log To Console    Site summary: ${passed}/${total_tests} passed, ${failed}/${total_tests} failed

    RETURN    ${passed}    ${failed}    @{failed_data}

Test Section With Counter
    [Documentation]    Tests a section with counter-based checkpoint tracking
    ...    Also tracks which validations have been completed per URL
    ...    Skips URLs that have logged issues in issues.json
    [Arguments]    ${checkpoint}    ${section_name}    ${section_key}    ${url_list}    ${samples_param}    ${skip_if_sampled}    ${category_label}    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${site_name}

    # Map section keys to tested_links keys
    &{section_key_map}=    Create Dictionary
    ...    used_vehicles=used
    ...    new_vehicles=new
    ...    showroom=showroom
    ...    models=model
    ...    model_trims=model_trim
    ${link_key}=    Get From Dictionary    ${section_key_map}    ${section_key}

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
            # Sample from all URLs (DO NOT filter URLs with issues - they need to be tracked)
            ${actual_samples}=    Evaluate    min(${remaining}, ${url_count})
            @{random_urls}=    Evaluate    random.sample(${url_list}, ${actual_samples})    random
            IF    ${actual_samples} > 0
                Log To Console    [${section_name}] Sampling ${actual_samples} URLs (counter: ${counter})...
                FOR    ${test_url}    IN    @{random_urls}
                    # Check for interrupt before testing each URL
                    Check For Interrupt

                    Log To Console    [${category_label}] ${test_url}

                    # Test URL with all validations once
                    ${all_results}=    Test URL With Multiple Validations    ${test_url}    ${validation_keywords}

                    # Process results for each validation
                    FOR    ${validation_keyword}    IN    @{validation_keywords}
                        ${result}=    Get From Dictionary    ${all_results}    ${validation_keyword}
                        ${status}=    Get From Dictionary    ${result}    status

                        # Mark this validation as complete (use link_key for sections, not URL)
                        Mark Section Validation Complete    ${checkpoint}    ${site_name}    ${section_key}    ${link_key}    ${validation_keyword}

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
                    END

                    Update Section Counter    ${checkpoint}    ${section_key}
                    Sleep    0.5s
                END
                Log To Console    ${section_name} section complete. Cleaning up...
                Cleanup Browser Windows
            END
        END
    END

    RETURN    ${passed}    ${failed}

Test Pages Section With Link Tracking
    [Documentation]    Tests pages section using link tracking instead of counters, runs multiple validations per page
    ...    Skips pages where ALL validations have been tested
    [Arguments]    ${checkpoint}    ${url_list}    ${samples_param}    ${skip_if_sampled}    ${category_label}    ${validation_keywords}    ${passed}    ${failed}    ${failed_data}    ${site_name}
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

    # Check for each validation if all pages are covered
    @{validations_to_run}=    Create List
    FOR    ${validation_keyword}    IN    @{validation_keywords}
        ${all_covered}=    Are All Pages Covered    ${checkpoint}    ${validation_keyword}    ${site_name}
        IF    not ${all_covered}
            # Check skip_if_sampled for this validation
            ${should_skip}=    Set Variable    ${False}
            IF    '${skip_if_sampled}' == 'true'
                ${tested_count}=    Get Tested Links Count    ${checkpoint}    ${validation_keyword}    ${site_name}
                IF    ${tested_count} > 0
                    ${should_skip}=    Set Variable    ${True}
                    Log To Console    [Pages] Skipping ${validation_keyword}: sampled (${tested_count} tested)
                END
            END
            IF    not ${should_skip}
                Append To List    ${validations_to_run}    ${validation_keyword}
            END
        ELSE
            Log To Console    [Pages] Skipping ${validation_keyword}: all pages covered
        END
    END

    ${validations_count}=    Get Length    ${validations_to_run}
    IF    ${validations_count} == 0
        Log To Console    [Pages] All validations complete or skipped
        RETURN    ${passed}    ${failed}
    END

    # Find pages that need testing for ANY of the remaining validations
    @{pages_needing_tests}=    Create List
    FOR    ${page_url}    IN    @{url_list}
        ${needs_test}=    Set Variable    ${False}
        FOR    ${validation_keyword}    IN    @{validations_to_run}
            ${is_tested}=    Is Link Already Tested    ${checkpoint}    ${page_url}    ${validation_keyword}    ${site_name}
            IF    not ${is_tested}
                ${needs_test}=    Set Variable    ${True}
                BREAK
            END
        END
        IF    ${needs_test}
            Append To List    ${pages_needing_tests}    ${page_url}
        END
    END

    ${pages_to_test_count}=    Get Length    ${pages_needing_tests}
    IF    ${pages_to_test_count} == 0
        Log To Console    [Pages] All pages tested for remaining validations
        FOR    ${validation_keyword}    IN    @{validations_to_run}
            Mark All Pages Covered    ${checkpoint}    ${validation_keyword}    ${site_name}
        END
        RETURN    ${passed}    ${failed}
    END

    # Determine how many samples to test and select pages
    IF    '${samples_param}' == 'None'
        ${samples_to_test}=    Set Variable    ${pages_to_test_count}
        @{pages_to_test}=    Evaluate    sorted(${pages_needing_tests})
        Log To Console    [Pages] Testing all ${samples_to_test} pages (${url_count} total) with ${validations_count} validation(s)...
    ELSE
        ${samples_int}=    Convert To Integer    ${samples_param}
        ${samples_to_test}=    Evaluate    min(${samples_int}, ${pages_to_test_count})
        @{pages_to_test}=    Evaluate    random.sample(${pages_needing_tests}, ${samples_to_test})    random
        Log To Console    [Pages] Testing ${samples_to_test} page(s) with ${validations_count} validation(s)...
    END

    FOR    ${test_url}    IN    @{pages_to_test}
        Check For Interrupt
        Log To Console    [${category_label}] ${test_url}

        # Run all validations that are needed for this URL
        @{validations_for_url}=    Create List
        FOR    ${validation_keyword}    IN    @{validations_to_run}
            ${is_tested}=    Is Link Already Tested    ${checkpoint}    ${test_url}    ${validation_keyword}    ${site_name}
            IF    not ${is_tested}
                Append To List    ${validations_for_url}    ${validation_keyword}
            END
        END

        ${validations_for_url_count}=    Get Length    ${validations_for_url}
        IF    ${validations_for_url_count} == 0
            Log To Console    ✓ All validations already done for this URL
            CONTINUE
        END

        # Test URL with all needed validations
        TRY
            ${results}=    Test URL With Multiple Validations    ${test_url}    ${validations_for_url}
        EXCEPT    AS    ${error}
            Log To Console    ⚠️ Error testing page: ${error}
            ${is_browser_error}=    Run Keyword And Return Status
            ...    Should Contain Any    ${error}    Connection refused    Broken pipe    Session not found
            IF    ${is_browser_error}
                Fail    ${error}
            END
            # Create failed result for all validations
            &{results}=    Create Dictionary
            FOR    ${validation_keyword}    IN    @{validations_for_url}
                &{result}=    Create Dictionary    status=FAIL    description=Test failed: ${error}    details=${error}    parent_span=${EMPTY}
                Set To Dictionary    ${results}    ${validation_keyword}=${result}
            END
        END

        # Process results for each validation
        FOR    ${validation_keyword}    IN    @{validations_for_url}
            ${result}=    Get From Dictionary    ${results}    ${validation_keyword}
            ${status}=    Get From Dictionary    ${result}    status

            # Mark as tested
            Add Tested Link    ${checkpoint}    ${test_url}    ${validation_keyword}    ${site_name}

            IF    '${status}' == 'PASS'
                ${passed}=    Evaluate    ${passed} + 1
            ELSE
                ${failed}=    Evaluate    ${failed} + 1
                ${description}=    Get From Dictionary    ${result}    description
                ${details}=    Get From Dictionary    ${result}    details
                ${has_parent_span}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${result}    parent_span
                IF    ${has_parent_span}
                    ${parent_span}=    Get From Dictionary    ${result}    parent_span
                    &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}    parent_span=${parent_span}
                ELSE
                    &{fail_info}=    Create Dictionary    url=${test_url}    category=${category_label}    description=${description}    details=${details}
                END
                Append To List    ${failed_data}    ${fail_info}
            END
        END

        # Update pages counter once per URL
        Update Section Counter    ${checkpoint}    pages

        IF    '${HEADLESS}' == 'true'
            Sleep    1s
        ELSE
            Sleep    0.5s
        END
    END

    # Check if all pages are covered for each validation
    FOR    ${validation_keyword}    IN    @{validations_to_run}
        ${tested_count}=    Get Tested Links Count    ${checkpoint}    ${validation_keyword}    ${site_name}
        IF    ${tested_count} >= ${url_count}
            Mark All Pages Covered    ${checkpoint}    ${validation_keyword}    ${site_name}
            Log To Console    [Pages] All pages covered for: ${validation_keyword}
        END
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
