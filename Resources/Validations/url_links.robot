*** Settings ***
Documentation    URL link validation keywords
Resource    ../variables.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    String
Library    BuiltIn

*** Keywords ***
Validate URL Links Matches It HREF
    [Documentation]    Validates that URL text (http:// or https://) matches href attribute
    ...                Can be used in any test to validate URL links on the current page
    Verify URL Links On Current Page

Verify URL Links On Current Page
    [Documentation]    Verifies that URL link text matches href attribute
    ...    Finds all text containing http:// or https:// and validates they are clickable with matching href

    # Find all <a> tags with href starting with http:// or https://
    ${http_links}=    Get WebElements    xpath=//a[starts-with(@href, 'http://') or starts-with(@href, 'https://')]
    ${count}=    Get Length    ${http_links}
    Log To Console    Found ${count} URL links

    ${failed_count}=    Set Variable    0
    @{errors}=    Create List

    FOR    ${link}    IN    @{http_links}
        ${txt_raw}=    Get Element Attribute    ${link}    textContent
        ${href_raw}=    Get Element Attribute    ${link}    href

        # Skip empty text
        ${txt_stripped}=    Strip String    ${txt_raw}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${txt_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        # Check if text contains http:// or https://
        ${has_http}=    Run Keyword And Return Status    Should Contain    ${txt_stripped}    http://
        ${has_https}=    Run Keyword And Return Status    Should Contain    ${txt_stripped}    https://

        IF    not ${has_http} and not ${has_https}
            # Text doesn't contain URL, skip (e.g., "Click here", "Learn more")
            CONTINUE
        END

        # Normalize both text and href for comparison
        ${text_normalized}=    Normalize URL    ${txt_stripped}
        ${href_normalized}=    Normalize URL    ${href_raw}

        ${matches}=    Run Keyword And Return Status    Should Be Equal    ${text_normalized}    ${href_normalized}

        IF    not ${matches}
            ${failed_count}=    Evaluate    ${failed_count} + 1
            ${error_msg}=    Set Variable    URL text "${txt_stripped}" (${text_normalized}) != href "${href_raw}" (${href_normalized})
            Append To List    ${errors}    ${error_msg}
            Log To Console    ✗ ${error_msg}
        ELSE
            Log To Console    ✓ URL "${text_normalized}" matches href
        END
    END

    # Also check for non-clickable URLs (text with http:// not inside <a> tag)
    ${all_elements}=    Get WebElements    xpath=//*[contains(text(), 'http://') or contains(text(), 'https://')]
    FOR    ${element}    IN    @{all_elements}
        ${tag}=    Get Element Attribute    ${element}    tagName
        ${tag_lower}=    Convert To Lower Case    ${tag}

        # Skip if element is already an <a> tag (already checked above)
        IF    '${tag_lower}' == 'a'
            CONTINUE
        END

        ${text}=    Get Text    ${element}
        ${text_stripped}=    Strip String    ${text}

        # Check if text contains URL pattern
        ${has_http}=    Run Keyword And Return Status    Should Contain    ${text_stripped}    http://
        ${has_https}=    Run Keyword And Return Status    Should Contain    ${text_stripped}    https://

        IF    ${has_http} or ${has_https}
            # Check if this element is inside an <a> tag
            ${closest_link}=    Execute Javascript
            ...    return arguments[0].closest('a');
            ...    ARGUMENTS    ${element}

            ${is_clickable}=    Run Keyword And Return Status    Should Not Be Equal    ${closest_link}    ${None}

            IF    not ${is_clickable}
                ${failed_count}=    Evaluate    ${failed_count} + 1
                ${error_msg}=    Set Variable    URL text "${text_stripped}" is NOT clickable (not inside <a> tag)
                Append To List    ${errors}    ${error_msg}
                Log To Console    ✗ ${error_msg}
            END
        END
    END

    IF    ${failed_count} > 0
        FOR    ${error}    IN    @{errors}
            Log    ${error}
        END
        Fail    ${failed_count} URL link(s) failed verification
    END

Verify URL Links With Details
    [Documentation]    Verifies URL links and returns detailed results without failing
    ...    Returns: Dictionary with status (PASS/FAIL), error_count, errors list, description, and unique_id

    # Find all <a> tags with href starting with http:// or https://
    ${http_links}=    Get WebElements    xpath=//a[starts-with(@href, 'http://') or starts-with(@href, 'https://')]
    ${count}=    Get Length    ${http_links}
    Log To Console    Found ${count} URL links

    ${failed_count}=    Set Variable    0
    @{errors}=    Create List
    ${unique_id}=    Set Variable    ${EMPTY}

    FOR    ${link}    IN    @{http_links}
        ${txt_raw}=    Get Element Attribute    ${link}    textContent
        ${href_raw}=    Get Element Attribute    ${link}    href

        # Skip empty text
        ${txt_stripped}=    Strip String    ${txt_raw}
        ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${txt_stripped}
        IF    ${is_empty}
            CONTINUE
        END

        # Check if text contains http:// or https://
        ${has_http}=    Run Keyword And Return Status    Should Contain    ${txt_stripped}    http://
        ${has_https}=    Run Keyword And Return Status    Should Contain    ${txt_stripped}    https://

        IF    not ${has_http} and not ${has_https}
            CONTINUE
        END

        # Normalize both text and href for comparison
        ${text_normalized}=    Normalize URL    ${txt_stripped}
        ${href_normalized}=    Normalize URL    ${href_raw}

        ${matches}=    Run Keyword And Return Status    Should Be Equal    ${text_normalized}    ${href_normalized}

        IF    not ${matches}
            ${failed_count}=    Evaluate    ${failed_count} + 1
            ${error_msg}=    Set Variable    URL text "${txt_stripped}" (${text_normalized}) != href "${href_raw}" (${href_normalized})
            Append To List    ${errors}    ${error_msg}
            Log To Console    ✗ ${error_msg}

            # Extract unique identifier (only for the first error to avoid duplicates)
            IF    '${unique_id}' == '${EMPTY}'
                ${unique_id}=    Get Parent Span Identifier    ${link}
            END
        ELSE
            Log To Console    ✓ URL "${text_normalized}" matches href
        END
    END

    # Check for non-clickable URLs
    ${all_elements}=    Get WebElements    xpath=//*[contains(text(), 'http://') or contains(text(), 'https://')]
    FOR    ${element}    IN    @{all_elements}
        ${tag}=    Get Element Attribute    ${element}    tagName
        ${tag_lower}=    Convert To Lower Case    ${tag}

        IF    '${tag_lower}' == 'a'
            CONTINUE
        END

        ${text}=    Get Text    ${element}
        ${text_stripped}=    Strip String    ${text}

        ${has_http}=    Run Keyword And Return Status    Should Contain    ${text_stripped}    http://
        ${has_https}=    Run Keyword And Return Status    Should Contain    ${text_stripped}    https://

        IF    ${has_http} or ${has_https}
            ${closest_link}=    Execute Javascript
            ...    return arguments[0].closest('a');
            ...    ARGUMENTS    ${element}

            ${is_clickable}=    Run Keyword And Return Status    Should Not Be Equal    ${closest_link}    ${None}

            IF    not ${is_clickable}
                ${failed_count}=    Evaluate    ${failed_count} + 1
                ${error_msg}=    Set Variable    URL text "${text_stripped}" is NOT clickable (not inside <a> tag)
                Append To List    ${errors}    ${error_msg}
                Log To Console    ✗ ${error_msg}

                IF    '${unique_id}' == '${EMPTY}'
                    ${unique_id}=    Get Parent Span Identifier    ${element}
                END
            END
        END
    END

    IF    ${failed_count} > 0
        ${status}=    Set Variable    FAIL
        ${description}=    Set Variable    ${failed_count} URL link(s) text does not match href or not clickable
        ${details}=    Catenate    SEPARATOR=\n    @{errors}
    ELSE
        ${status}=    Set Variable    PASS
        ${description}=    Set Variable    All URL links validated successfully
        ${details}=    Set Variable    ${EMPTY}
    END

    &{result}=    Create Dictionary
    ...    status=${status}
    ...    error_count=${failed_count}
    ...    errors=${errors}
    ...    description=${description}
    ...    details=${details}
    ...    unique_id=${unique_id}

    RETURN    ${result}

Normalize URL
    [Documentation]    Normalizes a URL for comparison (lowercase, remove trailing slash, etc.)
    [Arguments]    ${url}

    # Convert to lowercase for case-insensitive comparison
    ${normalized}=    Convert To Lower Case    ${url}

    # Remove trailing slash
    ${normalized}=    Remove String    ${normalized}    /    -1

    # Remove common URL parameters that might differ
    ${normalized}=    Replace String Using Regexp    ${normalized}    [?#].*$    ${EMPTY}

    # Strip whitespace
    ${normalized}=    Strip String    ${normalized}

    RETURN    ${normalized}

Get Parent Span Identifier
    [Documentation]    Extracts a unique identifier for the parent container of a link
    ...    Returns a combination of parent tag, class, and id to uniquely identify the parent element
    [Arguments]    ${link}

    ${parent_id}=    Execute Javascript
    ...    const link = arguments[0];
    ...    let parent = link.parentElement;
    ...    while (parent && parent !== document.body) {
    ...        if (parent.id) return 'id:' + parent.id;
    ...        if (parent.className && typeof parent.className === 'string') {
    ...            const classes = parent.className.trim();
    ...            if (classes) return 'class:' + classes;
    ...        }
    ...        parent = parent.parentElement;
    ...    }
    ...    // Fallback: use tag name + text content hash
    ...    const tag = link.parentElement?.tagName || 'unknown';
    ...    const text = link.parentElement?.textContent?.substring(0, 50) || '';
    ...    return 'tag:' + tag + ':text:' + text.replace(/[^a-zA-Z0-9]/g, '').substring(0, 20);
    ...    ARGUMENTS    ${link}

    RETURN    ${parent_id}
