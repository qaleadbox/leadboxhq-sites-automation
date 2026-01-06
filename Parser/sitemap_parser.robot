*** Settings ***
Documentation    Sitemap Parser - Handles sitemap URL construction and navigation
Library    SeleniumLibrary
Library    String

*** Keywords ***
Build Sitemap URL
    [Documentation]    Constructs a sitemap URL from a base URL
    ...                Returns the full sitemap URL (e.g., https://example.com/sitemap)
    [Arguments]    ${base_url}

    ${sitemap_url}=    Set Variable    ${base_url}

    # Check if already has /sitemap suffix
    ${has_sitemap}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /sitemap
    IF    ${has_sitemap}
        RETURN    ${sitemap_url}
    END

    # Add /sitemap with proper slash handling
    ${ends_with_slash}=    Run Keyword And Return Status    Should End With    ${sitemap_url}    /
    IF    ${ends_with_slash}
        ${sitemap_url}=    Set Variable    ${sitemap_url}sitemap
    ELSE
        ${sitemap_url}=    Set Variable    ${sitemap_url}/sitemap
    END

    RETURN    ${sitemap_url}

Navigate To Sitemap
    [Documentation]    Navigates to a sitemap URL in the current browser
    ...                Returns True if successful, False otherwise
    [Arguments]    ${base_url}

    ${sitemap_url}=    Build Sitemap URL    ${base_url}

    ${status}=    Run Keyword And Return Status    Go To    ${sitemap_url}

    RETURN    ${status}

Verify Sitemap Loaded
    [Documentation]    Checks if the current page is a valid sitemap
    ...                Returns status dictionary with: success, has_xml, error_type
    [Arguments]    ${url}

    &{result}=    Create Dictionary
    ...    success=False
    ...    has_xml=False
    ...    error_type=None
    ...    url=${url}

    ${page_source}=    Get Source

    # Check for error pages
    ${has_404}=    Run Keyword And Return Status    Should Contain    ${page_source}    404 Not Found
    ${has_error}=    Run Keyword And Return Status    Should Contain    ${page_source}    Error 404
    ${has_not_found}=    Run Keyword And Return Status    Should Contain    ${page_source}    Page Not Found

    IF    ${has_404} or ${has_error} or ${has_not_found}
        Set To Dictionary    ${result}    error_type=404
        RETURN    &{result}
    END

    # Check for valid sitemap XML
    ${has_urlset}=    Run Keyword And Return Status    Should Contain    ${page_source}    <urlset
    ${has_sitemapindex}=    Run Keyword And Return Status    Should Contain    ${page_source}    <sitemapindex

    IF    ${has_urlset} or ${has_sitemapindex}
        Set To Dictionary    ${result}    success=True    has_xml=True
    ELSE
        # Page loaded but not XML sitemap
        Set To Dictionary    ${result}    success=True    has_xml=False
    END

    RETURN    &{result}

Extract Sitemap URLs
    [Documentation]    Parses sitemap XML and extracts all URLs
    ...                Returns list of URLs found in the sitemap
    [Arguments]    ${sitemap_source}

    @{urls}=    Create List

    # Extract URLs from <loc> tags
    @{matches}=    Get Regexp Matches    ${sitemap_source}    <loc>(.+?)</loc>    1

    FOR    ${url}    IN    @{matches}
        ${url_clean}=    Strip String    ${url}
        Append To List    ${urls}    ${url_clean}
    END

    RETURN    @{urls}

Count Sitemap URLs
    [Documentation]    Counts the number of URLs in a sitemap
    [Arguments]    ${sitemap_source}

    @{urls}=    Extract Sitemap URLs    ${sitemap_source}
    ${count}=    Get Length    ${urls}

    RETURN    ${count}
