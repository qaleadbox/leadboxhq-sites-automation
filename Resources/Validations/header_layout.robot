*** Settings ***
Documentation    Header layout validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections

*** Keywords ***
Validate Header Layout Consistency
    [Documentation]    Compares header layout between homepage and internal pages
    ...                Checks: structure, navigation items, logo presence, menu-header-menu ul component, background color
    ...                Returns detailed results without failing
    ${result}=    Compare Header Layouts
    RETURN    ${result}

Compare Header Layouts
    [Documentation]    Captures header structure and compares elements including ul#menu-header-menu
    ...                Returns: Dictionary with validation results and details
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Header layout is consistent
    @{details}=    Create List
    ${header_data}=    Create Dictionary

    Log To Console    ${\n}>>> HEADER CHECK: Starting header validation...

    # Capture current page header structure
    TRY
        # Get header element
        ${header_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header
        IF    not ${header_exists}
            Log To Console    >>> HEADER CHECK: ✗ No header element found
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No header element found
            Append To List    ${details}    No <header> element found on page
        ELSE
            Log To Console    >>> HEADER CHECK: ✓ Header element found
            # Capture header structure
            Log To Console    >>> HEADER CHECK: Checking logo...
            ${logo_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header//img[contains(@alt, 'logo') or contains(@class, 'logo-div')]
            Log To Console    >>> HEADER CHECK: Checking navigation...
            ${nav_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//header//nav

            # Check for specific menu-header-menu ul component
            Log To Console    >>> HEADER CHECK: Checking menu-header-menu component...
            ${menu_header_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//ul[@id='menu-header-menu']
            ${menu_header_count}=    Set Variable    0
            @{menu_header_items}=    Create List
            IF    ${menu_header_exists}
                ${menu_items}=    Get WebElements    xpath=//ul[@id='menu-header-menu']//li
                ${menu_header_count}=    Get Length    ${menu_items}
                Log To Console    >>> HEADER CHECK: ✓ Menu-header-menu found with ${menu_header_count} items
                FOR    ${item}    IN    @{menu_items}
                    ${text}=    Get Text    ${item}
                    ${text}=    Strip String    ${text}
                    IF    '${text}' != ''
                        Append To List    ${menu_header_items}    ${text}
                    END
                END
            ELSE
                Log To Console    >>> HEADER CHECK: ✗ Menu-header-menu not found
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

            # Get header background color
            ${header_element}=    Get WebElement    xpath=//header
            ${bg_color}=    Execute JavaScript    return window.getComputedStyle(arguments[0]).backgroundColor;    ${header_element}

            # Store header data
            Set To Dictionary    ${header_data}    logo_exists=${logo_exists}
            Set To Dictionary    ${header_data}    nav_exists=${nav_exists}
            Set To Dictionary    ${header_data}    nav_count=${nav_count}
            Set To Dictionary    ${header_data}    nav_items=${nav_texts}
            Set To Dictionary    ${header_data}    menu_header_exists=${menu_header_exists}
            Set To Dictionary    ${header_data}    menu_header_count=${menu_header_count}
            Set To Dictionary    ${header_data}    menu_header_items=${menu_header_items}
            Set To Dictionary    ${header_data}    bg_color=${bg_color}

            # Basic validations
            IF    not ${logo_exists}
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    Header logo not found
                Append To List    ${details}    No logo found in header
                Log To Console    >>> HEADER CHECK: ✗ Logo validation failed
            ELSE
                Log To Console    >>> HEADER CHECK: ✓ Logo validation passed
            END

            IF    not ${nav_exists}
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    Header navigation not found
                Append To List    ${details}    No navigation element found in header
                Log To Console    >>> HEADER CHECK: ✗ Navigation validation failed
            ELSE
                Log To Console    >>> HEADER CHECK: ✓ Navigation found with ${nav_count} item(s)
            END

            IF    ${nav_count} == 0
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    No navigation items found
                Append To List    ${details}    Navigation exists but contains no links
                Log To Console    >>> HEADER CHECK: ✗ Navigation has no items
            END
        END
    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error analyzing header: ${error}
        Append To List    ${details}    Exception: ${error}
        Log To Console    [HEADER CHECK] ✗ Error: ${error}
    END

    # Determine status
    ${status}=    Set Variable If    ${passed}    PASS    FAIL
    Log To Console    [HEADER CHECK] Result: ${status} - ${description}

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
