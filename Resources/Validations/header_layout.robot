*** Settings ***
Documentation    Header layout validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections

*** Keywords ***
Validate Header Layout With Wrapping Check
    [Documentation]    Validates header layout with optional tab wrapping checks at multiple breakpoints
    ...                Uses configuration from variables.robot: CHECK_TAB_WRAPPING, TAB_WRAPPING_TEST_WIDTHS
    ...                Fails if header issues or tab wrapping detected at configured breakpoints

    IF    '${CHECK_TAB_WRAPPING}' == 'true'
        # Parse the width list
        @{widths}=    Split String    ${TAB_WRAPPING_TEST_WIDTHS}    ,

        FOR    ${width_str}    IN    @{widths}
            ${width}=    Strip String    ${width_str}

            Set Window Size For Testing    ${width}    ${TAB_WRAPPING_HEIGHT}
            Sleep    1s

            ${result}=    Compare Header Layouts
            ${status}=    Get From Dictionary    ${result}    status

            IF    '${status}' == 'FAIL'
                ${description}=    Get From Dictionary    ${result}    description
                Fail    Header validation failed at ${width}px: ${description}
            END
        END

        # Reset to full desktop size after testing
        Set Window Size For Testing    1920    1080
        Sleep    0.5s
    ELSE
        Validate Header Layout
    END

Validate Header Layout
    [Documentation]    Validates header layout for multi-validation pattern
    ...                Fails if header layout issues found, passes silently on success
    ...                Use this keyword in Parse Sitemap URLs for multi-site testing
    ...                Note: Set window size before calling this if testing specific breakpoints
    ${result}=    Compare Header Layouts
    ${status}=    Get From Dictionary    ${result}    status
    IF    '${status}' == 'FAIL'
        ${description}=    Get From Dictionary    ${result}    description
        Fail    ${description}
    END

Validate Header Layout Consistency
    [Documentation]    Compares header layout between homepage and internal pages
    ...                Checks: structure, navigation items, logo presence, menu-header-menu ul component, background color
    ...                Returns detailed results without failing
    ...                Note: Set window size before calling this if testing specific breakpoints
    ${result}=    Compare Header Layouts
    RETURN    ${result}

Compare Header Layouts
    [Documentation]    Captures header structure and compares elements including ul#menu-header-menu
    ...                Returns: Dictionary with validation results and details
    ...                Note: Set window size before calling this if testing specific breakpoints
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Header layout is consistent
    @{details}=    Create List
    ${header_data}=    Create Dictionary
    @{passed_checks}=    Create List
    @{failed_checks}=    Create List

    Log To Console    ${\n}>>> HEADER LAYOUT: Checking [structure, navigation, tab wrapping]...

    # Capture current page header structure
    TRY
        # Get header element
        ${header_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header
        IF    not ${header_exists}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No header element found
            Append To List    ${details}    No <header> element found on page
            Append To List    ${failed_checks}    structure
        ELSE
            Append To List    ${passed_checks}    structure
            # Capture header structure

            # Check for logo using multiple patterns:
            # 1. SVG elements (logos are often SVG)
            # 2. Images in header
            # 3. Links with logo in title/aria-label
            ${logo_svg_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header//svg
            ${logo_img_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header//img
            ${logo_link_exists}=    Run Keyword And Return Status    Page Should Contain Element
            ...    xpath=//header//a[contains(translate(@title, 'LOGO', 'logo'), 'logo') or contains(translate(@aria-label, 'LOGO', 'logo'), 'logo')]

            # Logo exists if any pattern matches
            ${logo_exists}=    Evaluate    ${logo_svg_exists} or ${logo_img_exists} or ${logo_link_exists}
            ${nav_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header//nav

            # Check for specific menu-header-menu ul component
            ${menu_header_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//ul[@id='menu-header-menu']
            ${menu_header_count}=    Set Variable    0
            @{menu_header_items}=    Create List
            IF    ${menu_header_exists}
                ${menu_items}=    Get WebElements    xpath=//ul[@id='menu-header-menu']//li
                ${menu_header_count}=    Get Length    ${menu_items}
                FOR    ${item}    IN    @{menu_items}
                    ${text}=    Get Text    ${item}
                    ${text}=    Strip String    ${text}
                    IF    '${text}' != ''
                        Append To List    ${menu_header_items}    ${text}
                    END
                END
            END

            # Get navigation items
            ${nav_items}=    Get WebElements    xpath=//header//nav//a
            ${nav_count}=    Get Length    ${nav_items}
            @{nav_texts}=    Create List
            FOR    ${item}    IN    @{nav_items}
                ${text}=    Get Text    ${item}
                ${text}=    Strip String    ${text}
                IF    '${text}' != ''
                    Append To List    ${nav_texts}    ${text}
                END
            END

            # Check for tab wrapping (navigation breaking into multiple lines)
            ${wrapping_detected}=    Set Variable    ${False}

            TRY
                # Use pure JavaScript approach to avoid WebElement logging issues
                ${js_check_result}=    Execute JavaScript
                ...    const menuItems = Array.from(document.querySelectorAll('#menu-header-menu li, header nav a'));
                ...    const visible = menuItems.filter(el => {
                ...        const style = window.getComputedStyle(el);
                ...        return style.display !== 'none' && style.visibility !== 'hidden' && el.offsetParent !== null;
                ...    });
                ...    const windowWidth = window.innerWidth;
                ...    if (visible.length <= 1) return {count: visible.length, wrapping: false, message: 'Not enough visible items', windowWidth: windowWidth};
                ...    const firstY = visible[0].getBoundingClientRect().top;
                ...    for (let i = 1; i < visible.length; i++) {
                ...        const y = visible[i].getBoundingClientRect().top;
                ...        const diff = Math.abs(y - firstY);
                ...        if (diff > 5) return {count: visible.length, wrapping: true, diff: diff, windowWidth: windowWidth};
                ...    }
                ...    return {count: visible.length, wrapping: false, message: 'All items aligned', windowWidth: windowWidth};

                ${visible_count}=    Evaluate    $js_check_result.get('count', 0)
                ${wrapping_js}=    Evaluate    $js_check_result.get('wrapping', False)
                ${window_width}=    Evaluate    $js_check_result.get('windowWidth', 0)

                IF    ${visible_count} > 1
                    IF    ${wrapping_js}
                        ${wrapping_detected}=    Set Variable    ${True}
                        ${y_diff}=    Evaluate    $js_check_result.get('diff', 0)
                        ${passed}=    Set Variable    ${False}
                        ${description}=    Set Variable    Navigation tabs are wrapping/breaking into multiple lines
                        Append To List    ${details}    Tabs are not aligned horizontally - overflow detected at window width ${window_width}px (Y-diff: ${y_diff}px)
                        Append To List    ${failed_checks}    tab wrapping
                    ELSE
                        Append To List    ${passed_checks}    tab wrapping
                    END
                END
            EXCEPT    AS    ${wrap_error}
                # Wrapping check failure is not critical - log as warning
                Append To List    ${details}    Warning: Could not check tab wrapping: ${wrap_error}
            END

            # Get header background color
            TRY
                ${bg_color}=    Execute JavaScript
                ...    return window.getComputedStyle(document.querySelector('header')).backgroundColor;
            EXCEPT
                ${bg_color}=    Set Variable    unknown
            END

            # Store header data (convert lists to ensure no WebElements)
            ${nav_texts_str}=    Evaluate    [str(item) for item in $nav_texts]    modules=builtins
            ${menu_items_str}=    Evaluate    [str(item) for item in $menu_header_items]    modules=builtins

            Set To Dictionary    ${header_data}    logo_exists=${logo_exists}
            Set To Dictionary    ${header_data}    nav_exists=${nav_exists}
            Set To Dictionary    ${header_data}    nav_count=${nav_count}
            Set To Dictionary    ${header_data}    nav_items=${nav_texts_str}
            Set To Dictionary    ${header_data}    menu_header_exists=${menu_header_exists}
            Set To Dictionary    ${header_data}    menu_header_count=${menu_header_count}
            Set To Dictionary    ${header_data}    menu_header_items=${menu_items_str}
            Set To Dictionary    ${header_data}    bg_color=${bg_color}
            Set To Dictionary    ${header_data}    tabs_wrapping=${wrapping_detected}

            # Basic validations
            IF    not ${logo_exists}
                # Logo check is a warning only (sites implement logos differently)
                Append To List    ${details}    Warning: No logo detected using standard patterns
            END

            IF    not ${nav_exists}
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    Header navigation not found
                Append To List    ${details}    No navigation element found in header
                Append To List    ${failed_checks}    navigation
            ELSE
                Append To List    ${passed_checks}    navigation
            END

            IF    ${nav_count} == 0
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    No navigation items found
                Append To List    ${details}    Navigation exists but contains no links
                ${nav_in_list}=    Run Keyword And Return Status    List Should Contain Value    ${failed_checks}    navigation
                IF    not ${nav_in_list}
                    Append To List    ${failed_checks}    navigation items
                END
            END
        END
    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${error_str}=    Convert To String    ${error}
        ${description}=    Set Variable    Error analyzing header: ${error_str}
        Append To List    ${details}    Exception: ${error_str}
        Log To Console    >>> HEADER LAYOUT: ✗ FAIL - Error: ${error_str}
    END

    # Determine status and log summary
    ${status}=    Set Variable If    ${passed}    PASS    FAIL
    IF    '${status}' == 'PASS'
        ${passed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{passed_checks}
        Log To Console    >>> HEADER LAYOUT: ✓ PASS - All checks passed [${passed_list}]
    ELSE
        ${failed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{failed_checks}
        Log To Console    >>> HEADER LAYOUT: ✗ FAIL - Failed checks: [${failed_list}]
        # Log detailed comparison if available
        ${details_count}=    Get Length    ${details}
        IF    ${details_count} > 0
            FOR    ${detail}    IN    @{details}
                ${detail_stripped}=    Strip String    ${detail}
                ${detail_length}=    Get Length    ${detail_stripped}
                IF    ${detail_length} > 0
                    ${log_msg}=    Catenate    SEPARATOR=${EMPTY}    >>> HEADER LAYOUT:${SPACE}${SPACE}${SPACE}    ${detail_stripped}
                    Log To Console    ${log_msg}
                END
            END
        END
    END

    # Build result dictionary
    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}
    ...    header_data=${header_data}

    RETURN    ${result}

Compare Header Between Pages
    [Documentation]    Compares header structure between two pages (homepage vs internal)
    ...                Captures homepage header, navigates to internal page, compares
    [Arguments]    ${homepage_url}    ${internal_url}

    # Capture homepage header
    Go To    ${homepage_url}
    Sleep    2s
    ${homepage_result}=    Compare Header Layouts
    ${homepage_data}=    Get From Dictionary    ${homepage_result}    header_data

    # Capture internal page header
    Go To    ${internal_url}
    Sleep    2s
    ${internal_result}=    Compare Header Layouts
    ${internal_data}=    Get From Dictionary    ${internal_result}    header_data

    # Compare the two headers
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Header layout is consistent between homepage and internal pages
    @{details}=    Create List

    # Compare logo
    ${hp_logo}=    Get From Dictionary    ${homepage_data}    logo_exists
    ${int_logo}=    Get From Dictionary    ${internal_data}    logo_exists
    IF    ${hp_logo} != ${int_logo}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Logo presence differs between homepage and internal page
        Append To List    ${details}    Homepage logo: ${hp_logo}, Internal page logo: ${int_logo}
    END

    # Compare menu-header-menu existence
    ${hp_menu_header}=    Get From Dictionary    ${homepage_data}    menu_header_exists
    ${int_menu_header}=    Get From Dictionary    ${internal_data}    menu_header_exists
    IF    ${hp_menu_header} != ${int_menu_header}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Menu-header-menu ul component presence differs
        Append To List    ${details}    Homepage menu-header-menu: ${hp_menu_header}, Internal page: ${int_menu_header}
    END

    # Compare menu-header-menu item count if both exist
    IF    ${hp_menu_header} and ${int_menu_header}
        ${hp_menu_count}=    Get From Dictionary    ${homepage_data}    menu_header_count
        ${int_menu_count}=    Get From Dictionary    ${internal_data}    menu_header_count
        IF    ${hp_menu_count} != ${int_menu_count}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Menu-header-menu item count differs
            Append To List    ${details}    Homepage has ${hp_menu_count} menu items, internal page has ${int_menu_count}
        END
    END

    # Compare nav count
    ${hp_nav_count}=    Get From Dictionary    ${homepage_data}    nav_count
    ${int_nav_count}=    Get From Dictionary    ${internal_data}    nav_count
    IF    ${hp_nav_count} != ${int_nav_count}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Navigation item count differs
        Append To List    ${details}    Homepage has ${hp_nav_count} nav items, internal page has ${int_nav_count}
    END

    # Compare background color
    ${hp_bg}=    Get From Dictionary    ${homepage_data}    bg_color
    ${int_bg}=    Get From Dictionary    ${internal_data}    bg_color
    IF    '${hp_bg}' != '${int_bg}'
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Header background color differs
        Append To List    ${details}    Homepage: ${hp_bg}, Internal: ${int_bg}
    END

    ${status}=    Set Variable If    ${passed}    PASS    FAIL

    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}
    ...    homepage_data=${homepage_data}
    ...    internal_data=${internal_data}

    RETURN    ${result}
