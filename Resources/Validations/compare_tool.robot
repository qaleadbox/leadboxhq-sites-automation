*** Settings ***
Documentation    Compare Tool validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections
Library    String

*** Keywords ***
Validate Compare Tool
    [Documentation]    Validates Compare Tool presence for multi-validation pattern
    ...                Fails if compare tool configuration is inconsistent, passes silently on success
    ...                Skips validation if dealer didn't opt in (no icons found on both header and vehicle cards)
    ...                Only runs on homepage (with Featured/Available Vehicles section) or SRP pages
    ...                Validation is re-enabled for each new website
    ...                Use this keyword in Parse Sitemap URLs for multi-site testing
    ${result}=    Check Compare Tool Presence
    ${status}=    Get From Dictionary    ${result}    status
    IF    '${status}' == 'FAIL'
        ${description}=    Get From Dictionary    ${result}    description
        Fail    ${description}
    ELSE IF    '${status}' == 'SKIP'
        # Either dealer didn't opt in, or page doesn't have vehicle cards
        # Skip validation for this page, but check again on next page/website
        ${description}=    Get From Dictionary    ${result}    description
        Log To Console    >>> COMPARE TOOL: ⊘ SKIP - ${description}
    END

Validate Compare Tool Opt In
    [Documentation]    Checks if the dealer opted in for the Compare Tool service
    ...                Validates presence in header (my-garage div with SVG) and vehicle cards (saveFavorites onclick)
    ...                Returns detailed results without failing
    ${result}=    Check Compare Tool Presence
    RETURN    ${result}

Check If Page Has Vehicle Cards Section
    [Documentation]    Checks if the current page has a vehicle cards section
    ...                Looks for filter container div that indicates the Compare Tool is available
    ...                Checks for either:
    ...                1. Filter div with class 'filter filter-4 pr-2'
    ...                2. Filter container div with id 'filter__container' and class 'filter__container'
    ...                3. Vehicle cards div with class 'width-card height-card shadow-cards vehicle-car-1 vehicle-car__section' inside span with class 'contents'
    ...                Returns: True if page has filter section or vehicle cards (indicating vehicle cards), False otherwise

    # Check for filter div option 1: filter filter-4 pr-2
    ${has_filter_1}=    Run Keyword And Return Status
    ...    Page Should Contain Element    css=#inventory > div > div.flex.flex-row.flex-wrap.w-full.xl\\:w-1\\/5.lg\\:pr-2.xl\\:pr-0.xxl\\:pr-4.lbx-filter-section > div > div > div.filter.filter-4.pr-2

    IF    ${has_filter_1}
        # Filter option 1 found
        RETURN    ${True}
    END

    # Check for filter div option 2: filter__container
    ${has_filter_2}=    Run Keyword And Return Status
    ...    Page Should Contain Element    css=#filter__container.filter__container

    IF    ${has_filter_2}
        # Filter option 2 found
        RETURN    ${True}
    END

    # Check for vehicle cards option 3: vehicle cards inside span.contents
    ${has_vehicle_cards}=    Run Keyword And Return Status
    ...    Page Should Contain Element    css=span.contents > div.width-card.height-card.shadow-cards.vehicle-car-1.vehicle-car__section

    IF    ${has_vehicle_cards}
        # Vehicle cards found
        RETURN    ${True}
    END

    # Page doesn't have filter section or vehicle cards
    RETURN    ${False}

Check Compare Tool Presence
    [Documentation]    Validates Compare Tool icon presence in header and vehicle cards
    ...                Only runs on pages with vehicle cards (homepage with Featured/Available Vehicles or SRP)
    ...                Returns: Dictionary with validation results and details
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Compare Tool configuration is consistent
    @{details}=    Create List
    ${compare_data}=    Create Dictionary
    @{passed_checks}=    Create List
    @{failed_checks}=    Create List

    Log To Console    ${\n}>>> COMPARE TOOL: Checking [header icon, vehicle card icons]...

    # First check if this page should have vehicle cards
    ${has_vehicle_cards_section}=    Check If Page Has Vehicle Cards Section

    IF    not ${has_vehicle_cards_section}
        # Skip validation - page doesn't have vehicle cards section
        ${passed}=    Set Variable    SKIP
        ${description}=    Set Variable    Page does not have vehicle cards section
        Append To List    ${details}    Not a homepage with Featured/Available Vehicles or SRP page - validation skipped
        ${status}=    Set Variable    SKIP

        ${result}=    Create Dictionary
        ...    status=${status}
        ...    description=${description}
        ...    details=${details}
        ...    compare_data=${compare_data}

        RETURN    ${result}
    END

    TRY
        # 1. CHECK HEADER ICON (my-garage icon with SVG)
        # Structure: <a href="/my-garage/"><svg>...</svg></a>
        # Use JavaScript to find it since XPath may have timing issues
        Sleep    0.5s    # Wait for dynamic content to load

        ${header_icon_exists}=    Execute JavaScript
        ...    const links = Array.from(document.querySelectorAll('a[href*="my-garage"], a[href*="garage"]'));
        ...    return links.some(link => link.querySelector('svg') !== null);

        Set To Dictionary    ${compare_data}    header_icon_exists=${header_icon_exists}

        IF    ${header_icon_exists}
            Append To List    ${details}    Header icon found: a[href contains 'garage']>svg
            Append To List    ${passed_checks}    header icon present
        ELSE
            Append To List    ${details}    Header icon not found: No a[href contains 'garage']>svg
        END

        # 2. CHECK VEHICLE CARD ICONS (div with onclick containing saveFavorites)
        ${vehicle_card_icons_exist}=    Run Keyword And Return Status
        ...    Page Should Contain Element    xpath=//div[contains(@onclick, 'saveFavorites')]

        ${vehicle_card_count}=    Set Variable    0
        IF    ${vehicle_card_icons_exist}
            @{vehicle_card_icons}=    Get WebElements    xpath=//div[contains(@onclick, 'saveFavorites')]
            ${vehicle_card_count}=    Get Length    ${vehicle_card_icons}
            Append To List    ${details}    Vehicle card icons found: ${vehicle_card_count} div(s) with onclick='saveFavorites'
            Append To List    ${passed_checks}    vehicle card icons present
        ELSE
            Append To List    ${details}    Vehicle card icons not found: No div with onclick='saveFavorites'
        END

        Set To Dictionary    ${compare_data}    vehicle_card_icons_exist=${vehicle_card_icons_exist}
        Set To Dictionary    ${compare_data}    vehicle_card_count=${vehicle_card_count}

        # 3. VALIDATE CONSISTENCY
        # If both are missing: dealer didn't opt in - SKIP validation
        # If both are present: dealer opted in - PASS
        # If only one is present: inconsistent configuration - FAIL

        IF    ${header_icon_exists} and ${vehicle_card_icons_exist}
            # Both present - dealer opted in
            ${description}=    Set Variable    Compare Tool enabled (header and vehicle cards)
            Append To List    ${passed_checks}    consistency
        ELSE IF    not ${header_icon_exists} and not ${vehicle_card_icons_exist}
            # Neither present - dealer did not opt in, skip validation for this website
            ${passed}=    Set Variable    SKIP
            ${description}=    Set Variable    Dealer did not opt in for Compare Tool
            Append To List    ${details}    No Compare Tool icons found - validation skipped for this website
        ELSE IF    not ${header_icon_exists} and ${vehicle_card_icons_exist}
            # Only vehicle cards have the icon - inconsistent but track it
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Compare Tool inconsistent: Present in vehicle cards but missing in header
            Append To List    ${failed_checks}    header icon missing
        ELSE IF    ${header_icon_exists} and not ${vehicle_card_icons_exist}
            # Only header has the icon - inconsistent
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Compare Tool inconsistent: Present in header but missing in vehicle cards
            Append To List    ${failed_checks}    vehicle card icons missing
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error checking Compare Tool: ${error}
        Append To List    ${details}    Exception: ${error}
        Log To Console    >>> COMPARE TOOL: ✗ FAIL - Error: ${error}
    END

    # Determine status and log summary
    IF    '${passed}' == 'SKIP'
        ${status}=    Set Variable    SKIP
        # Don't log here - will be logged by the calling keyword
    ELSE
        ${status}=    Set Variable If    ${passed}    PASS    FAIL
        IF    '${status}' == 'PASS'
            ${passed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{passed_checks}
            Log To Console    >>> COMPARE TOOL: ✓ PASS - All checks passed [${passed_list}]
        ELSE
            ${failed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{failed_checks}
            Log To Console    >>> COMPARE TOOL: ✗ FAIL - Failed checks: [${failed_list}]
            # Log detailed comparison if available
            ${details_count}=    Get Length    ${details}
            IF    ${details_count} > 0
                FOR    ${detail}    IN    @{details}
                    ${detail_stripped}=    Strip String    ${detail}
                    ${detail_length}=    Get Length    ${detail_stripped}
                    IF    ${detail_length} > 0
                        ${log_msg}=    Catenate    SEPARATOR=${EMPTY}    >>> COMPARE TOOL:${SPACE}${SPACE}${SPACE}    ${detail_stripped}
                        Log To Console    ${log_msg}
                    END
                END
            END
        END
    END

    # Build result dictionary
    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}
    ...    compare_data=${compare_data}

    RETURN    ${result}
