
*** Settings ***
Documentation    SEO metadata validation keywords
Resource    ../variables.robot
Resource    ../Helpers/browser_helpers.robot
Library    SeleniumLibrary    run_on_failure=Nothing
Library    Collections
Library    String

*** Variables ***
${EXPECTED_SITE_NAME}    ${EMPTY}

*** Keywords ***
Validate SEO Metadata
    [Documentation]    Validates SEO metadata for multi-validation pattern
    ...                Fails if metadata issues found, passes silently on success
    ...                Use this keyword in Parse Sitemap URLs for multi-site testing
    ${result}=    Validate SEO Metadata Comprehensive
    ${status}=    Get From Dictionary    ${result}    status
    IF    '${status}' == 'FAIL'
        ${description}=    Get From Dictionary    ${result}    description
        Fail    ${description}
    END

Validate SEO Metadata Comprehensive
    [Documentation]    Validates SEO metadata in head tag
    ...                Checks: capitalization, template variables (%%), og:site_name consistency
    ...                Returns detailed results without failing
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    SEO metadata is valid
    @{details}=    Create List
    ${metadata}=    Create Dictionary
    @{passed_checks}=    Create List
    @{failed_checks}=    Create List

    # Get current URL for unique_id
    ${current_url}=    Get Location
    ${unique_id}=    Catenate    SEPARATOR=::    ${current_url}    Validate SEO Metadata

    Log To Console    ${\n}>>> SEO METADATA: Checking [capitalization, template variables, og:site_name consistency, sitemap consistency]...

    TRY
        # 1. CAPITALIZATION CHECK
        ${cap_result}=    Check Title Tag Capitalization
        ${cap_status}=    Get From Dictionary    ${cap_result}    status
        ${cap_desc}=    Get From Dictionary    ${cap_result}    description
        @{cap_details}=    Get From Dictionary    ${cap_result}    details

        IF    '${cap_status}' == 'FAIL'
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    ${cap_desc}
            Append To List    ${failed_checks}    capitalization
            FOR    ${detail}    IN    @{cap_details}
                Append To List    ${details}    ${detail}
            END
        ELSE
            Append To List    ${passed_checks}    capitalization
        END

        # 2. TEMPLATE VARIABLES CHECK (%%VARIABLES%%)
        ${template_result}=    Check Meta Tags For Template Variables
        ${template_status}=    Get From Dictionary    ${template_result}    status
        ${template_desc}=    Get From Dictionary    ${template_result}    description
        @{template_details}=    Get From Dictionary    ${template_result}    details

        IF    '${template_status}' == 'FAIL'
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    ${template_desc}
            Append To List    ${failed_checks}    template variables
            FOR    ${detail}    IN    @{template_details}
                Append To List    ${details}    ${detail}
            END
        ELSE
            Append To List    ${passed_checks}    template variables
        END

        # 3. OG:SITE_NAME CONSISTENCY CHECK
        ${og_result}=    Validate OG Site Name Matches Title
        ${og_status}=    Get From Dictionary    ${og_result}    status
        ${og_desc}=    Get From Dictionary    ${og_result}    description
        @{og_details}=    Get From Dictionary    ${og_result}    details

        IF    '${og_status}' == 'FAIL'
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    ${og_desc}
            Append To List    ${failed_checks}    og:site_name consistency
            FOR    ${detail}    IN    @{og_details}
                Append To List    ${details}    ${detail}
            END
        ELSE
            Append To List    ${passed_checks}    og:site_name consistency
        END

        # 4. SITEMAP SITE NAME CONSISTENCY CHECK
        ${sitemap_result}=    Validate Site Name Matches Expected
        ${sitemap_status}=    Get From Dictionary    ${sitemap_result}    status
        ${sitemap_desc}=    Get From Dictionary    ${sitemap_result}    description
        @{sitemap_details}=    Get From Dictionary    ${sitemap_result}    details

        IF    '${sitemap_status}' == 'FAIL'
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    ${sitemap_desc}
            Append To List    ${failed_checks}    sitemap consistency
            FOR    ${detail}    IN    @{sitemap_details}
                Append To List    ${details}    ${detail}
            END
        ELSE IF    '${sitemap_status}' == 'SKIP'
            Append To List    ${passed_checks}    sitemap consistency (skipped)
        ELSE
            Append To List    ${passed_checks}    sitemap consistency
        END

        # Store all metadata results
        Set To Dictionary    ${metadata}    capitalization=${cap_result}
        Set To Dictionary    ${metadata}    template_variables=${template_result}
        Set To Dictionary    ${metadata}    og_site_name=${og_result}
        Set To Dictionary    ${metadata}    sitemap_consistency=${sitemap_result}

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error validating SEO metadata: ${error}
        Append To List    ${details}    Exception: ${error}
        Log To Console    >>> SEO METADATA: ✗ FAIL - Error: ${error}
    END

    # Determine overall status
    ${status}=    Set Variable If    ${passed}    PASS    FAIL
    IF    '${status}' == 'PASS'
        ${passed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{passed_checks}
        Log To Console    >>> SEO METADATA: ✓ PASS - All checks passed [${passed_list}]
    ELSE
        ${failed_list}=    Catenate    SEPARATOR=, ${SPACE}   @{failed_checks}
        Log To Console    >>> SEO METADATA: ✗ FAIL - Failed checks: [${failed_list}]
        # Log detailed comparison if available
        ${details_count}=    Get Length    ${details}
        IF    ${details_count} > 0
            FOR    ${detail}    IN    @{details}
                ${detail_stripped}=    Strip String    ${detail}
                ${detail_length}=    Get Length    ${detail_stripped}
                IF    ${detail_length} > 0
                    ${log_msg}=    Catenate    SEPARATOR=${EMPTY}    >>> SEO METADATA:${SPACE}${SPACE}${SPACE}    ${detail_stripped}
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
    ...    metadata=${metadata}
    ...    unique_id=${unique_id}

    RETURN    ${result}

Check Title Tag Capitalization
    [Documentation]    Validates that title and meta tags are properly capitalized
    ...                Returns: Dictionary with validation results
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    All metadata is properly capitalized
    @{details}=    Create List
    @{issues}=    Create List

    TRY
        # Check title tag
        ${title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//title
        IF    ${title_exists}
            ${title_text}=    Get Title

            # Check if title is all lowercase (likely not properly capitalized)
            ${title_lower}=    Convert To Lower Case    ${title_text}
            ${is_all_lowercase}=    Run Keyword And Return Status    Should Be Equal    ${title_text}    ${title_lower}

            IF    ${is_all_lowercase}
                ${passed}=    Set Variable    ${False}
                Append To List    ${issues}    Title tag - Expected: Proper capitalization, Found: All lowercase ("${title_text}")
            END
        ELSE
            ${passed}=    Set Variable    ${False}
            Append To List    ${issues}    Title tag - Expected: Present, Found: Missing
        END

        # Check meta description
        ${meta_desc_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//meta[@name='description']
        IF    ${meta_desc_exists}
            ${meta_desc}=    Get Element Attribute    xpath=//meta[@name='description']    content

            # Check first character is capitalized
            ${first_char}=    Get Substring    ${meta_desc}    0    1
            ${first_char_upper}=    Convert To Upper Case    ${first_char}
            ${starts_with_capital}=    Run Keyword And Return Status    Should Be Equal    ${first_char}    ${first_char_upper}

            IF    not ${starts_with_capital}
                Append To List    ${issues}    Meta description - Expected: Start with capital letter, Found: Starts with lowercase ("${meta_desc}")
            END
        END

        # Check og:title
        ${og_title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//meta[@property='og:title']
        IF    ${og_title_exists}
            ${og_title}=    Get Element Attribute    xpath=//meta[@property='og:title']    content

            # Check if all lowercase
            ${og_lower}=    Convert To Lower Case    ${og_title}
            ${is_og_lowercase}=    Run Keyword And Return Status    Should Be Equal    ${og_title}    ${og_lower}

            IF    ${is_og_lowercase}
                ${passed}=    Set Variable    ${False}
                Append To List    ${issues}    og:title - Expected: Proper capitalization, Found: All lowercase ("${og_title}")
            END
        END

        # Check og:description
        ${og_desc_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//meta[@property='og:description']
        IF    ${og_desc_exists}
            ${og_desc}=    Get Element Attribute    xpath=//meta[@property='og:description']    content

            # Check first character is capitalized
            ${first_char}=    Get Substring    ${og_desc}    0    1
            ${first_char_upper}=    Convert To Upper Case    ${first_char}
            ${starts_with_capital}=    Run Keyword And Return Status    Should Be Equal    ${first_char}    ${first_char_upper}

            IF    not ${starts_with_capital}
                Append To List    ${issues}    og:description - Expected: Start with capital letter, Found: Starts with lowercase ("${og_desc}")
            END
        END

        # Build description from issues
        ${issues_count}=    Get Length    ${issues}
        IF    ${issues_count} > 0
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Found ${issues_count} capitalization issue(s)
            FOR    ${issue}    IN    @{issues}
                Append To List    ${details}    ${issue}
            END
        ELSE
            Append To List    ${details}    All checked metadata appears properly capitalized
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error checking capitalization: ${error}
        Append To List    ${details}    Exception: ${error}
    END

    ${status}=    Set Variable If    ${passed}    PASS    FAIL

    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}

    RETURN    ${result}

Check Meta Tags For Template Variables
    [Documentation]    Checks for unprocessed template variables (%%) in metadata
    ...                Returns: Dictionary with validation results
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    No template variables found
    @{details}=    Create List
    @{issues}=    Create List

    TRY
        # Check title tag
        ${title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//title
        IF    ${title_exists}
            ${title_text}=    Get Title
            ${has_percent}=    Run Keyword And Return Status    Should Contain    ${title_text}    %%
            IF    ${has_percent}
                ${passed}=    Set Variable    ${False}
                Append To List    ${issues}    Title tag - Expected: Processed text, Found: Template variable (%%) in "${title_text}"
            END
        END

        # Check all meta tags with 'content' attribute
        @{meta_tags}=    Get WebElements    xpath=//meta[@content]

        FOR    ${meta}    IN    @{meta_tags}
            ${content}=    Get Element Attribute    ${meta}    content
            ${has_percent}=    Run Keyword And Return Status    Should Contain    ${content}    %%

            IF    ${has_percent}
                ${passed}=    Set Variable    ${False}

                # Get name or property attribute for better error message
                TRY
                    ${name_attr}=    Get Element Attribute    ${meta}    name
                    ${has_name}=    Set Variable    ${True}
                EXCEPT
                    ${has_name}=    Set Variable    ${False}
                END
                TRY
                    ${prop_attr}=    Get Element Attribute    ${meta}    property
                    ${has_property}=    Set Variable    ${True}
                EXCEPT
                    ${has_property}=    Set Variable    ${False}
                END

                IF    ${has_name}
                    Append To List    ${issues}    Meta[name="${name_attr}"] - Expected: Processed text, Found: Template variable (%%) in "${content}"
                ELSE IF    ${has_property}
                    Append To List    ${issues}    Meta[property="${prop_attr}"] - Expected: Processed text, Found: Template variable (%%) in "${content}"
                ELSE
                    Append To List    ${issues}    Meta tag - Expected: Processed text, Found: Template variable (%%) in "${content}"
                END
            END
        END

        # Build description from issues
        ${issues_count}=    Get Length    ${issues}
        IF    ${issues_count} > 0
            ${description}=    Set Variable    Found ${issues_count} template variable(s) (%%) in metadata
            FOR    ${issue}    IN    @{issues}
                Append To List    ${details}    ${issue}
            END
        ELSE
            Append To List    ${details}    No template variables (%%) found in any metadata
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error checking template variables: ${error}
        Append To List    ${details}    Exception: ${error}
    END

    ${status}=    Set Variable If    ${passed}    PASS    FAIL

    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}

    RETURN    ${result}

Validate OG Site Name Matches Title
    [Documentation]    Validates that og:site_name matches the second part of the page title
    ...                Example: Title "Page Name | Site Name" should match og:site_name "Site Name"
    ...                Returns: Dictionary with validation results
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    og:site_name matches page title
    @{details}=    Create List

    TRY
        # Get title tag
        ${title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//title
        IF    not ${title_exists}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No title tag found to compare
            Append To List    ${details}    Missing title tag
            ${status}=    Set Variable    FAIL
            ${result}=    Create Dictionary
            ...    status=${status}
            ...    description=${description}
            ...    details=${details}
            RETURN    ${result}
        END

        ${title_text}=    Get Title

        # Get og:site_name
        ${og_site_name_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//meta[@property='og:site_name']
        IF    not ${og_site_name_exists}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No og:site_name meta tag found
            Append To List    ${details}    Missing meta tag: og:site_name
            ${status}=    Set Variable    FAIL
            ${result}=    Create Dictionary
            ...    status=${status}
            ...    description=${description}
            ...    details=${details}
            RETURN    ${result}
        END

        ${og_site_name}=    Get Element Attribute    xpath=//meta[@property='og:site_name']    content

        # Extract site name from title (second part after separator)
        # Common separators: |, -, –, —, :
        ${has_pipe}=    Run Keyword And Return Status    Should Contain    ${title_text}    |
        ${has_dash}=    Run Keyword And Return Status    Should Contain    ${title_text}    -
        ${has_endash}=    Run Keyword And Return Status    Should Contain    ${title_text}    –
        ${has_emdash}=    Run Keyword And Return Status    Should Contain    ${title_text}    —
        ${has_colon}=    Run Keyword And Return Status    Should Contain    ${title_text}    :

        ${separator}=    Set Variable    ${EMPTY}
        IF    ${has_pipe}
            ${separator}=    Set Variable    |
        ELSE IF    ${has_emdash}
            ${separator}=    Set Variable    —
        ELSE IF    ${has_endash}
            ${separator}=    Set Variable    –
        ELSE IF    ${has_dash}
            ${separator}=    Set Variable    -
        ELSE IF    ${has_colon}
            ${separator}=    Set Variable    :
        END

        IF    $separator == ''
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Title does not contain a separator to extract site name
            Append To List    ${details}    Expected: Title format "Page Name - Site Name" | Found: "${title_text}" (no separator)
        ELSE
            @{title_parts}=    Split String    ${title_text}    ${separator}
            ${parts_count}=    Get Length    ${title_parts}

            IF    ${parts_count} < 2
                ${passed}=    Set Variable    ${False}
                ${description}=    Set Variable    Title does not have a site name part
                Append To List    ${details}    Expected: Format "Page Name ${separator} Site Name" | Found: "${title_text}" (missing site name after separator)
            ELSE
                # Get second part (site name) and strip whitespace
                ${title_site_name}=    Get From List    ${title_parts}    -1
                ${title_site_name}=    Strip String    ${title_site_name}

                # Compare with og:site_name
                ${og_site_name_stripped}=    Strip String    ${og_site_name}
                ${matches}=    Run Keyword And Return Status    Should Be Equal    ${title_site_name}    ${og_site_name_stripped}

                IF    not ${matches}
                    ${passed}=    Set Variable    ${False}
                    ${description}=    Set Variable    og:site_name does not match title site name
                    Append To List    ${details}    Expected (from title): "${title_site_name}" | Found (og:site_name): "${og_site_name_stripped}"
                ELSE
                    Append To List    ${details}    og:site_name matches title: "${og_site_name_stripped}"
                END
            END
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error validating og:site_name: ${error}
        Append To List    ${details}    Exception: ${error}
    END

    ${status}=    Set Variable If    ${passed}    PASS    FAIL

    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}

    RETURN    ${result}

Set Expected Site Name From Current Page
    [Documentation]    Extracts and stores the site name from the current page's title
    ...                This should be called when on the sitemap or homepage to set the reference
    ...                Returns: The extracted site name

    TRY
        # Get title tag
        ${title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//title
        IF    not ${title_exists}
            Set Suite Variable    ${EXPECTED_SITE_NAME}    ${EMPTY}
            RETURN    ${EMPTY}
        END

        ${title_text}=    Get Title

        # Extract site name from title (second part after separator)
        ${has_pipe}=    Run Keyword And Return Status    Should Contain    ${title_text}    |
        ${has_dash}=    Run Keyword And Return Status    Should Contain    ${title_text}    -
        ${has_endash}=    Run Keyword And Return Status    Should Contain    ${title_text}    –
        ${has_emdash}=    Run Keyword And Return Status    Should Contain    ${title_text}    —
        ${has_colon}=    Run Keyword And Return Status    Should Contain    ${title_text}    :

        ${separator}=    Set Variable    ${EMPTY}
        IF    ${has_pipe}
            ${separator}=    Set Variable    |
        ELSE IF    ${has_emdash}
            ${separator}=    Set Variable    —
        ELSE IF    ${has_endash}
            ${separator}=    Set Variable    –
        ELSE IF    ${has_dash}
            ${separator}=    Set Variable    -
        ELSE IF    ${has_colon}
            ${separator}=    Set Variable    :
        END

        IF    $separator == ''
            # If no separator, use the entire title as site name
            ${site_name}=    Strip String    ${title_text}
        ELSE
            @{title_parts}=    Split String    ${title_text}    ${separator}
            ${parts_count}=    Get Length    ${title_parts}

            IF    ${parts_count} >= 2
                # Get last part (site name) and strip whitespace
                ${site_name}=    Get From List    ${title_parts}    -1
                ${site_name}=    Strip String    ${site_name}
            ELSE
                ${site_name}=    Strip String    ${title_text}
            END
        END

        # Store as suite variable
        Set Suite Variable    ${EXPECTED_SITE_NAME}    ${site_name}

        RETURN    ${site_name}

    EXCEPT    AS    ${error}
        Set Suite Variable    ${EXPECTED_SITE_NAME}    ${EMPTY}
        RETURN    ${EMPTY}
    END

Validate Site Name Matches Expected
    [Documentation]    Validates that the current page's site name matches the expected site name from sitemap
    ...                Returns: Dictionary with validation results
    ${passed}=    Set Variable    ${True}
    ${description}=    Set Variable    Site name matches expected reference
    @{details}=    Create List

    # Check if expected site name is set
    IF    $EXPECTED_SITE_NAME == ''
        ${status}=    Set Variable    SKIP
        ${description}=    Set Variable    No expected site name reference set
        Append To List    ${details}    Expected site name not initialized - call 'Set Expected Site Name From Current Page' first

        ${result}=    Create Dictionary
        ...    status=${status}
        ...    description=${description}
        ...    details=${details}

        RETURN    ${result}
    END

    TRY
        # Get title tag
        ${title_exists}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//title
        IF    not ${title_exists}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    No title tag found
            Append To List    ${details}    Missing title tag
            ${status}=    Set Variable    FAIL
            ${result}=    Create Dictionary
            ...    status=${status}
            ...    description=${description}
            ...    details=${details}
            RETURN    ${result}
        END

        ${title_text}=    Get Title

        # Extract site name from current page title
        ${has_pipe}=    Run Keyword And Return Status    Should Contain    ${title_text}    |
        ${has_dash}=    Run Keyword And Return Status    Should Contain    ${title_text}    -
        ${has_endash}=    Run Keyword And Return Status    Should Contain    ${title_text}    –
        ${has_emdash}=    Run Keyword And Return Status    Should Contain    ${title_text}    —
        ${has_colon}=    Run Keyword And Return Status    Should Contain    ${title_text}    :

        ${separator}=    Set Variable    ${EMPTY}
        IF    ${has_pipe}
            ${separator}=    Set Variable    |
        ELSE IF    ${has_emdash}
            ${separator}=    Set Variable    —
        ELSE IF    ${has_endash}
            ${separator}=    Set Variable    –
        ELSE IF    ${has_dash}
            ${separator}=    Set Variable    -
        ELSE IF    ${has_colon}
            ${separator}=    Set Variable    :
        END

        IF    $separator == ''
            # If no separator, use the entire title
            ${current_site_name}=    Strip String    ${title_text}
        ELSE
            @{title_parts}=    Split String    ${title_text}    ${separator}
            ${parts_count}=    Get Length    ${title_parts}

            IF    ${parts_count} >= 2
                # Get last part (site name)
                ${current_site_name}=    Get From List    ${title_parts}    -1
                ${current_site_name}=    Strip String    ${current_site_name}
            ELSE
                ${current_site_name}=    Strip String    ${title_text}
            END
        END

        # Compare with expected site name
        ${matches}=    Run Keyword And Return Status    Should Be Equal    ${current_site_name}    ${EXPECTED_SITE_NAME}

        IF    not ${matches}
            ${passed}=    Set Variable    ${False}
            ${description}=    Set Variable    Site name does not match sitemap reference
            Append To List    ${details}    Expected (from sitemap): "${EXPECTED_SITE_NAME}" | Found (on page): "${current_site_name}"
        ELSE
            Append To List    ${details}    Site name matches: "${current_site_name}"
        END

    EXCEPT    AS    ${error}
        ${passed}=    Set Variable    ${False}
        ${description}=    Set Variable    Error validating site name: ${error}
        Append To List    ${details}    Exception: ${error}
    END

    ${status}=    Set Variable If    ${passed}    PASS    FAIL

    ${result}=    Create Dictionary
    ...    status=${status}
    ...    description=${description}
    ...    details=${details}

    RETURN    ${result}
