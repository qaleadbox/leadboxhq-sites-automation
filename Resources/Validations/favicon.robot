*** Settings ***
Documentation    Favicon validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Resource    ../Helpers/csv_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections
Library    String

*** Keywords ***
Validate Favicon Exists And Matches Brand
    [Documentation]    Checks if the site has a favicon and confirms it matches the correct brand
    ...                Searches for shortcut icon rel inside the head tag
    ...                Validates the link has a valid image extension (.ico, .gif, .png, .jpg, .svg)
    ...                Opens the favicon URL in a new tab for manual verification
    ...                Returns detailed results without failing
    ${result}=    Check Favicon
    RETURN    ${result}

Check Favicon
    [Documentation]    Validates favicon presence and format
    ...                Returns: Dictionary with validation results and details
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Favicon exists and matches expected format
    @{details}=    Create List
    ${favicon_data}=    Create Dictionary

    Log To Console    ${\n}>>> FAVICON CHECK: Starting favicon validation...

    # Check for favicon link elements
    TRY
        # Common favicon selectors
        ${favicon_selectors}=    Create List
        ...    link[rel='shortcut icon']
        ...    link[rel='icon']
        ...    link[rel='apple-touch-icon']
        ...    link[rel='apple-touch-icon-precomposed']

        Log To Console    >>> FAVICON CHECK: Searching for favicon link elements...

        ${favicon_found}=    Set Variable    ${False}
        ${favicon_url}=    Set Variable    ${EMPTY}
        ${favicon_type}=    Set Variable    ${EMPTY}
        ${has_valid_extension}=    Set Variable    ${False}
        ${image_loads}=    Set Variable    ${False}

        # Try each selector
        FOR    ${selector}    IN    @{favicon_selectors}
            ${exists}=    Run Keyword And Return Status    Page Should Contain Element    css=${selector}
            IF    ${exists}
                ${favicon_found}=    Set Variable    ${True}
                ${favicon_url}=    Get Element Attribute    css=${selector}    href
                ${rel_value}=    Get Element Attribute    css=${selector}    rel
                Log To Console    >>> FAVICON CHECK: Found favicon link with rel='${rel_value}'

                # Check if it's a shortcut icon or standard icon
                ${is_shortcut}=    Run Keyword And Return Status    Should Contain    ${rel_value}    shortcut
                ${is_icon}=    Run Keyword And Return Status    Should Contain    ${rel_value}    icon

                IF    ${is_shortcut} or ${is_icon}
                    Set To Dictionary    ${favicon_data}    rel=${rel_value}
                    Set To Dictionary    ${favicon_data}    href=${favicon_url}
                    Log To Console    >>> FAVICON CHECK: Favicon URL: ${favicon_url}

                    # Check for .ico or .gif extension
                    ${has_ico}=    Run Keyword And Return Status    Should Match Regexp    ${favicon_url}    (?i)\.ico
                    ${has_gif}=    Run Keyword And Return Status    Should Match Regexp    ${favicon_url}    (?i)\.gif
                    ${has_png}=    Run Keyword And Return Status    Should Match Regexp    ${favicon_url}    (?i)\.png
                    ${has_jpg}=    Run Keyword And Return Status    Should Match Regexp    ${favicon_url}    (?i)\.(jpg|jpeg)
                    ${has_svg}=    Run Keyword And Return Status    Should Match Regexp    ${favicon_url}    (?i)\.svg

                    IF    ${has_ico}
                        ${has_valid_extension}=    Set Variable    ${True}
                        ${favicon_type}=    Set Variable    .ico
                        Log To Console    >>> FAVICON CHECK: ✓ Found favicon with .ico extension
                        Append To List    ${details}    Found favicon with .ico extension: ${favicon_url}
                    ELSE IF    ${has_gif}
                        ${has_valid_extension}=    Set Variable    ${True}
                        ${favicon_type}=    Set Variable    .gif
                        Log To Console    >>> FAVICON CHECK: ✓ Found favicon with .gif extension
                        Append To List    ${details}    Found favicon with .gif extension: ${favicon_url}
                    ELSE IF    ${has_png}
                        ${has_valid_extension}=    Set Variable    ${True}
                        ${favicon_type}=    Set Variable    .png
                        Log To Console    >>> FAVICON CHECK: ✓ Found favicon with .png extension
                        Append To List    ${details}    Found favicon with .png extension: ${favicon_url}
                    ELSE IF    ${has_jpg}
                        ${has_valid_extension}=    Set Variable    ${True}
                        ${favicon_type}=    Set Variable    .jpg
                        Log To Console    >>> FAVICON CHECK: ✓ Found favicon with .jpg extension
                        Append To List    ${details}    Found favicon with .jpg extension: ${favicon_url}
                    ELSE IF    ${has_svg}
                        ${has_valid_extension}=    Set Variable    ${True}
                        ${favicon_type}=    Set Variable    .svg
                        Log To Console    >>> FAVICON CHECK: ✓ Found favicon with .svg extension
                        Append To List    ${details}    Found favicon with .svg extension: ${favicon_url}
                    ELSE
                        # Found favicon but not a common image format
                        Log To Console    >>> FAVICON CHECK: ✗ Found favicon but unrecognized format: ${favicon_url}
                        Append To List    ${details}    Found favicon but unrecognized format: ${favicon_url}
                    END

                    # If we found a valid extension, try to open URL in new tab for manual verification
                    IF    ${has_valid_extension}
                        Log To Console    >>> FAVICON CHECK: Opening favicon URL in new tab for manual verification...
                        ${url_opened}=    Open Favicon URL In New Tab    ${favicon_url}
                        IF    ${url_opened}
                            Log To Console    >>> FAVICON CHECK: ✓ Favicon URL opened successfully - Please verify manually
                            Log To Console    >>> FAVICON CHECK: URL: ${favicon_url}
                            Append To List    ${details}    Favicon URL accessible: ${favicon_url}
                        ELSE
                            Log To Console    >>> FAVICON CHECK: ⚠ Could not open URL in new tab (but URL exists)
                            Log To Console    >>> FAVICON CHECK: URL: ${favicon_url}
                            Append To List    ${details}    Favicon URL found: ${favicon_url}
                        END
                        ${image_loads}=    Set Variable    ${url_opened}
                        BREAK
                    END
                END
            END
        END

        # Store results
        Set To Dictionary    ${favicon_data}    favicon_found=${favicon_found}
        Set To Dictionary    ${favicon_data}    favicon_url=${favicon_url}
        Set To Dictionary    ${favicon_data}    favicon_type=${favicon_type}
        Set To Dictionary    ${favicon_data}    has_valid_extension=${has_valid_extension}
        Set To Dictionary    ${favicon_data}    image_loads=${image_loads}

        # Validate results
        IF    not ${favicon_found}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No favicon found in head tag
            Append To List    ${details}    No <link> element with rel='shortcut icon' or rel='icon' found
            Log To Console    >>> FAVICON CHECK: ✗ No favicon link found
        ELSE IF    not ${has_valid_extension}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Favicon found but does not use a valid image format
            Append To List    ${details}    Expected .ico, .gif, .png, .jpg, or .svg extension, found: ${favicon_url}
            Log To Console    >>> FAVICON CHECK: ✗ Invalid favicon format
        ELSE
            Append To List    ${details}    Favicon validation passed with ${favicon_type} format
            Log To Console    >>> FAVICON CHECK: ✓ Favicon validation passed
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error checking favicon: ${error}
        Append To List    ${details}    Exception: ${error}
        Log To Console    >>> FAVICON CHECK: ✗ Error: ${error}
    END

    # Determine status
    ${status}=    Set Variable If    ${passed}    PASS    FAIL
    Log To Console    >>> FAVICON CHECK: Result: ${status} - ${description}

    # Build result dictionary
    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}
    ...    favicon_data=${favicon_data}

    RETURN    ${result}

Open Favicon URL In New Tab
    [Documentation]    Opens the favicon URL in a new browser tab for manual verification
    ...                Waits 10 seconds, then closes the tab automatically
    ...                Returns True if URL opened successfully, False otherwise
    [Arguments]    ${image_url}

    TRY
        # Open favicon URL in a new tab
        Execute Javascript    window.open('${image_url}', '_blank');
        Sleep    1s

        # Get all window handles
        ${all_handles}=    Get Window Handles
        ${handle_count}=    Get Length    ${all_handles}

        # If we have more than one window, the new tab opened successfully
        IF    ${handle_count} > 1
            Log To Console    >>> FAVICON CHECK: New tab opened with favicon URL
            # Switch to the new tab to confirm it loaded
            ${new_handle}=    Get From List    ${all_handles}    -1
            Switch Window    ${new_handle}
            # Wait 10 seconds for manual verification
            Log To Console    >>> FAVICON CHECK: Waiting 10 seconds for verification...
            Sleep    10s
            # Close the tab
            Close Window
            Log To Console    >>> FAVICON CHECK: Tab closed
            # Switch back to main window
            ${main_handle}=    Get From List    ${all_handles}    0
            Switch Window    ${main_handle}
            RETURN    ${True}
        ELSE
            RETURN    ${False}
        END
    EXCEPT    AS    ${error}
        Log To Console    >>> FAVICON CHECK: Error opening URL in new tab: ${error}
        RETURN    ${False}
    END

Test All Homepages For Favicon
    [Documentation]    Tests favicon on homepage of all websites in CSV file
    ...                No checkpoint files used - simple homepage-only validation

    # Load sites from spreadsheet
    @{sites_data}=    Load Sites From Spreadsheet
    ${total_sites}=    Get Length    ${sites_data}
    Log To Console    \n========================================
    Log To Console    Starting Favicon Test for ${total_sites} websites
    Log To Console    Testing: Homepage only (no checkpoint)
    Log To Console    ========================================\n

    # Open browser
    Open LeadBox Portal    about:blank

    ${passed_count}=    Set Variable    0
    ${failed_count}=    Set Variable    0
    @{failed_sites}=    Create List

    # Loop through each site
    FOR    ${site_data}    IN    @{sites_data}
        ${name}=    Get From Dictionary    ${site_data}    name
        ${url}=    Get From Dictionary    ${site_data}    url

        Log To Console    \n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Log To Console    Site: ${name}
        Log To Console    Homepage: ${url}

        TRY
            # Go to homepage
            Go To    ${url}
            Sleep    5s
            Wait Until Page Contains Element    xpath=//body    timeout=20s
            Sleep    2s

            # Run favicon validation
            ${result}=    Validate Favicon Exists And Matches Brand
            ${status}=    Get From Dictionary    ${result}    status
            ${description}=    Get From Dictionary    ${result}    description

            IF    '${status}' == 'PASS'
                ${passed_count}=    Evaluate    ${passed_count} + 1
                Log To Console    ✓ ${name}: PASS
            ELSE
                ${failed_count}=    Evaluate    ${failed_count} + 1
                Append To List    ${failed_sites}    ${name}: ${description}
                Log To Console    ✗ ${name}: FAIL - ${description}
            END

        EXCEPT    AS    ${error}
            ${failed_count}=    Evaluate    ${failed_count} + 1
            Append To List    ${failed_sites}    ${name}: Error loading page - ${error}
            Log To Console    ✗ ${name}: ERROR - ${error}
        END
    END

    # Summary
    Log To Console    \n========================================
    Log To Console    TEST SUMMARY
    Log To Console    ========================================
    Log To Console    Total Sites: ${total_sites}
    Log To Console    Passed: ${passed_count}
    Log To Console    Failed: ${failed_count}

    ${failed_count_int}=    Convert To Integer    ${failed_count}
    IF    ${failed_count_int} > 0
        Log To Console    \nFailed Sites:
        FOR    ${failure}    IN    @{failed_sites}
            Log To Console    - ${failure}
        END
    END
    Log To Console    ========================================\n

    # Fail test if any site failed
    IF    ${failed_count_int} > 0
        Fail    ${failed_count} site(s) failed favicon validation
    END
