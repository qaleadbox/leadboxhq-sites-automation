** Settings **
Library  SeleniumLibrary
Library    String
Library    RequestsLibrary
Resource    variables.robot
Resource    helpers.robot
Resource    ../Parser/csv_parser.robot
Resource    ../Parser/sitemap_parser.robot

** Keywords **
Open LeadBox Portal
    Open Browser                  ${BASE_URL}                       chrome

Validate Contact Links Are Clickable
    ${elements}=    Get WebElements    xpath=//*/text()[normalize-space()]/parent::*

    FOR    ${el}    IN    @{elements}
        ${txt}=    Get Text    ${el}
        ${converted_txt}=    Convert To String    ${txt}

        ${type}=   Detect Text Type    ${converted_txt}
        ${converted_type}=   Convert To String    ${type}

        IF    '${converted_type}' != 'None'

            ${href}=    Execute Javascript    try { let a = arguments[0]?.closest('a'); return a ? a.href : null; } catch(e) { return null; }    ${el}

            Log To Console    ${txt}${href}
            IF    '${href}' == 'None'
                Fail    ${type} "${txt}" is NOT clickable
            END
        END
    END

Validate Contact Links Matches It HREF
    [Documentation]    Validates that contact link text matches its HREF attribute
    ...                Can be used in any test to validate phone links on the current page
    ...                Example: Navigate to a page, then call this keyword to validate
    Verify Phone Links On Current Page

Parse Sitemap URLs
    [Documentation]    Multi-site validation using sitemap URL sampling
    ...                Loads sites from spreadsheet and tests sampled URLs with specified validation keyword
    ...                Flexible framework: Pass any validation keyword to test different functionality
    [Arguments]    ${validation_keyword}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1
    @{sites}=    Load Sites From Spreadsheet
    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_urls}=    Create List

    Open Browser    about:blank    chrome

    FOR    ${site}    IN    @{sites}
        ${url}=    Get From Dictionary    ${site}    url
        ${name}=    Get From Dictionary    ${site}    name

        IF    '${url}' == ''
            CONTINUE
        END

        Log To Console    \n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Log To Console    Site: ${name}

        ${site_passed}    ${site_failed}    @{site_failed_urls}=    Test Sitemap URLs In Real Time    ${url}    ${name}    ${validation_keyword}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}

        ${passed}=    Evaluate    ${passed} + ${site_passed}
        ${failed}=    Evaluate    ${failed} + ${site_failed}

        FOR    ${failed_url}    IN    @{site_failed_urls}
            Append To List    ${failed_urls}    ${name}: ${failed_url}
        END
    END

    Close Browser

    Log To Console    \nPassed: ${passed} | Failed: ${failed}

    IF    ${failed} > 0
        FOR    ${url}    IN    @{failed_urls}
            Log To Console    Failed: ${url}
        END
        Fail    ${failed} URL(s) failed
    END

Validate Phone Links
    Verify Phone Links On Current Page

Test Sitemap URLs In Real Time
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

Parse Sitemap And Get Test URLs
    [Arguments]    ${url}    ${name}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1
    ${sitemap_url}=    Build Sitemap URL    ${url}
    Go To    ${sitemap_url}
    Sleep    2s

    ${sitemap_source}=    Get Source
    @{test_urls}=    Get Test URLs From Sitemap    ${sitemap_source}    ${pages_samples}    ${used_vehicle_samples}    ${new_vehicle_samples}    ${showroom_samples}    ${models_samples}    ${model_trims_samples}

    ${url_count}=    Get Length    ${test_urls}
    Log To Console    Found ${url_count} URLs (p=${pages_samples} uv=${used_vehicle_samples} nv=${new_vehicle_samples} s=${showroom_samples} m=${models_samples} mt=${model_trims_samples})

    RETURN    @{test_urls}

Cleanup Browser Windows
    [Documentation]    Closes all windows except the main one to prevent memory buildup
    ${all_handles}=    Get Window Handles
    ${main_handle}=    Get From List    ${all_handles}    0

    ${handles_count}=    Get Length    ${all_handles}
    IF    ${handles_count} > 1
        FOR    ${handle}    IN    @{all_handles}
            IF    '${handle}' != '${main_handle}'
                Switch Window    ${handle}
                Close Window
            END
        END
        Switch Window    ${main_handle}
        Log To Console    Closed ${handles_count - 1} extra window(s)
    END

Test URL In New Tab
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

# Verify Sitemap URL
#     [Documentation]    Verifies that a sitemap URL is accessible and returns 200 OK
#     [Arguments]    ${base_url}

#     # Ensure URL ends with /sitemap
#     ${sitemap_url}=    Set Variable    ${base_url}
#     ${has_sitemap}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /sitemap
#     IF    not ${has_sitemap}
#         ${ends_with_slash}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /
#         IF    ${ends_with_slash}
#             ${sitemap_url}=    Set Variable    ${sitemap_url}sitemap
#         ELSE
#             ${sitemap_url}=    Set Variable    ${sitemap_url}/sitemap
#         END
#     END

#     Log To Console    \nChecking: ${sitemap_url}

#     # Create session and make request
#     Create Session    sitemap_check    ${sitemap_url}    verify=True

#     ${response}=    Run Keyword And Ignore Error    GET On Session    sitemap_check    /    expected_status=200    timeout=30

#     IF    '${response[0]}' == 'PASS'
#         Log To Console    ✓ SUCCESS: ${sitemap_url} is accessible
#         RETURN    True
#     ELSE
#         Log To Console    ✗ FAILED: ${sitemap_url} is not accessible - ${response[1]}
#         RETURN    False
#     END

# Verify Sitemap URL In Browser
#     [Documentation]    Opens sitemap URL in Chrome browser and verifies it loads
#     [Arguments]    ${base_url}

#     # Ensure URL ends with /sitemap
#     ${sitemap_url}=    Set Variable    ${base_url}
#     ${has_sitemap}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /sitemap
#     IF    not ${has_sitemap}
#         ${ends_with_slash}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /
#         IF    ${ends_with_slash}
#             ${sitemap_url}=    Set Variable    ${sitemap_url}sitemap
#         ELSE
#             ${sitemap_url}=    Set Variable    ${sitemap_url}/sitemap
#         END
#     END

#     Log To Console    \nOpening in browser: ${sitemap_url}

#     # Navigate to sitemap URL
#     ${status}=    Run Keyword And Return Status    Go To    ${sitemap_url}

#     IF    ${status}
#         # Wait for page to load
#         Sleep    2s

#         # Check if page loaded successfully
#         ${page_source}=    Get Source

#         # Check for common error indicators
#         ${has_404}=    Run Keyword And Return Status    Should Contain    ${page_source}    404 Not Found
#         ${has_error}=    Run Keyword And Return Status    Should Contain    ${page_source}    Error 404
#         ${has_not_found}=    Run Keyword And Return Status    Should Contain    ${page_source}    Page Not Found

#         # Check for sitemap indicators (XML structure)
#         ${has_urlset}=    Run Keyword And Return Status    Should Contain    ${page_source}    <urlset
#         ${has_sitemapindex}=    Run Keyword And Return Status    Should Contain    ${page_source}    <sitemapindex

#         IF    ${has_404} or ${has_error} or ${has_not_found}
#             Log To Console    ✗ FAILED: ${sitemap_url} returned an error page
#             RETURN    False
#         ELSE IF    ${has_urlset} or ${has_sitemapindex}
#             Log To Console    ✓ SUCCESS: ${sitemap_url} loaded successfully (valid sitemap)
#             RETURN    True
#         ELSE
#             # If no error but also no sitemap tags, still consider it success if page loaded
#             Log To Console    ✓ SUCCESS: ${sitemap_url} loaded (content type unknown)
#             RETURN    True
#         END
#     ELSE
#         Log To Console    ✗ FAILED: Could not navigate to ${sitemap_url}
#         RETURN    False
#     END
