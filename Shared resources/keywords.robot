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
    [Arguments]    ${multi_site}=False

    IF    ${multi_site}
        Run Multi Site Validation
    ELSE
        Verify Phone Links On Current Page
    END

Run Multi Site Validation
    @{sites}=    Load Sites From Spreadsheet
    ${passed}=    Set Variable    0
    ${failed}=    Set Variable    0
    @{failed_sites}=    Create List

    Open Browser    about:blank    chrome

    FOR    ${site}    IN    @{sites}
        ${url}=    Get From Dictionary    ${site}    url
        ${name}=    Get From Dictionary    ${site}    name

        IF    '${url}' == ''
            CONTINUE
        END

        Navigate To Site Sitemap    ${url}    ${name}

        ${result}=    Run Keyword And Return Status    Validate Phone Links

        IF    ${result}
            ${passed}=    Evaluate    ${passed} + 1
        ELSE
            ${failed}=    Evaluate    ${failed} + 1
            Append To List    ${failed_sites}    ${name}
        END
    END

    Close Browser

    Log To Console    \nPassed: ${passed} | Failed: ${failed}

    IF    ${failed} > 0
        FOR    ${name}    IN    @{failed_sites}
            Log To Console    Failed: ${name}
        END
        Fail    ${failed} sites failed
    END

Validate Phone Links
    Verify Phone Links On Current Page

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
