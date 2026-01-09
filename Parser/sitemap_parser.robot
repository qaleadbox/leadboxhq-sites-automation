*** Settings ***
Documentation    Sitemap Parser - Handles sitemap URL construction and navigation
Resource    ../Resources/variables.robot
Library    SeleniumLibrary    run_on_failure=Nothing
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
    [Documentation]    Parses sitemap and extracts all URLs (supports both XML and HTML)
    ...                Returns list of URLs found in the sitemap
    [Arguments]    ${sitemap_source}

    @{urls}=    Create List

    ${is_xml}=    Run Keyword And Return Status    Should Contain    ${sitemap_source}    <loc>

    IF    ${is_xml}
        @{matches}=    Get Regexp Matches    ${sitemap_source}    <loc>(.+?)</loc>    1
        FOR    ${url}    IN    @{matches}
            ${url_clean}=    Strip String    ${url}
            Append To List    ${urls}    ${url_clean}
        END
    ELSE
        @{links}=    Get WebElements    xpath=//a[@href]
        FOR    ${link}    IN    @{links}
            ${href}=    Get Element Attribute    ${link}    href
            ${href_clean}=    Strip String    ${href}
            ${is_full_url}=    Run Keyword And Return Status    Should Match Regexp    ${href_clean}    ^https?://
            IF    ${is_full_url}
                Append To List    ${urls}    ${href_clean}
            END
        END
    END

    RETURN    @{urls}

Extract Sitemap URLs By Section
    [Documentation]    Extracts URLs from HTML sitemap organized by section headers
    ...                Returns dictionary with section names as keys
    [Arguments]    ${sitemap_source}

    &{sections_dict}=    Create Dictionary

    # Try to find section headers (h2, h3) and their following links
    @{h2_elements}=    Get WebElements    xpath=//h2
    @{h3_elements}=    Get WebElements    xpath=//h3

    FOR    ${header}    IN    @{h2_elements}    @{h3_elements}
        ${section_name}=    Get Text    ${header}
        ${section_name}=    Strip String    ${section_name}

        # Get the next sibling ul element
        ${has_ul}=    Run Keyword And Return Status    Element Should Be Visible    xpath=//h2[text()='${section_name}']/following-sibling::ul[1] | //h3[text()='${section_name}']/following-sibling::ul[1]

        IF    ${has_ul}
            @{section_urls}=    Create List
            @{section_links}=    Get WebElements    xpath=//h2[text()='${section_name}']/following-sibling::ul[1]//a | //h3[text()='${section_name}']/following-sibling::ul[1]//a

            FOR    ${link}    IN    @{section_links}
                ${href}=    Get Element Attribute    ${link}    href
                ${href_clean}=    Strip String    ${href}
                Append To List    ${section_urls}    ${href_clean}
            END

            Set To Dictionary    ${sections_dict}    ${section_name}=${section_urls}
        END
    END

    RETURN    &{sections_dict}

Count Sitemap URLs
    [Documentation]    Counts the number of URLs in a sitemap
    [Arguments]    ${sitemap_source}

    @{urls}=    Extract Sitemap URLs    ${sitemap_source}
    ${count}=    Get Length    ${urls}

    RETURN    ${count}

Extract Sitemap Sections
    [Documentation]    Extracts URLs from sitemap organized by sections
    ...                Returns all Pages URLs and random samples from other sections
    ...                Uses HTML section headers if available, otherwise falls back to URL pattern matching
    [Arguments]    ${sitemap_source}

    &{sections}=    Create Dictionary
    ...    pages=@{EMPTY}
    ...    used_vehicles=@{EMPTY}
    ...    new_vehicles=@{EMPTY}
    ...    showroom=@{EMPTY}
    ...    models=@{EMPTY}
    ...    model_trims=@{EMPTY}

    # Try HTML section-based extraction first
    ${has_sections}=    Run Keyword And Return Status    Get WebElements    xpath=//h2 | //h3

    IF    ${has_sections}
        # HTML sitemap with section headers
        &{html_sections}=    Extract Sitemap URLs By Section    ${sitemap_source}

        @{pages}=    Create List
        @{used_vehicles}=    Create List
        @{new_vehicles}=    Create List
        @{showroom}=    Create List
        @{models}=    Create List
        @{model_trims}=    Create List

        # Map HTML section names to our standard sections
        FOR    ${section_name}    IN    @{html_sections.keys()}
            @{section_urls}=    Get From Dictionary    ${html_sections}    ${section_name}

            IF    '${section_name}' == 'Pages'
                FOR    ${url}    IN    @{section_urls}
                    Append To List    ${pages}    ${url}
                END
            ELSE IF    '${section_name}' == 'Vehicles'
                # Categorize vehicles as used or new
                FOR    ${url}    IN    @{section_urls}
                    ${url_lower}=    Convert To Lower Case    ${url}
                    ${is_used}=    Run Keyword And Return Status    Should Contain    ${url_lower}    used
                    IF    ${is_used}
                        Append To List    ${used_vehicles}    ${url}
                    ELSE
                        Append To List    ${new_vehicles}    ${url}
                    END
                END
            ELSE IF    '${section_name}' == 'Showroom'
                FOR    ${url}    IN    @{section_urls}
                    Append To List    ${showroom}    ${url}
                END
            ELSE IF    '${section_name}' == 'Models'
                FOR    ${url}    IN    @{section_urls}
                    Append To List    ${models}    ${url}
                END
            ELSE IF    '${section_name}' == 'Models Trims'
                FOR    ${url}    IN    @{section_urls}
                    Append To List    ${model_trims}    ${url}
                END
            END
        END

        Set To Dictionary    ${sections}    pages=${pages}
        Set To Dictionary    ${sections}    used_vehicles=${used_vehicles}
        Set To Dictionary    ${sections}    new_vehicles=${new_vehicles}
        Set To Dictionary    ${sections}    showroom=${showroom}
        Set To Dictionary    ${sections}    models=${models}
        Set To Dictionary    ${sections}    model_trims=${model_trims}

    ELSE
        # Fallback to URL pattern matching for XML sitemaps
        @{all_urls}=    Extract Sitemap URLs    ${sitemap_source}

        @{pages}=    Create List
        @{used_vehicles}=    Create List
        @{new_vehicles}=    Create List
        @{showroom}=    Create List
        @{models}=    Create List
        @{model_trims}=    Create List

        FOR    ${url}    IN    @{all_urls}
            ${url_lower}=    Convert To Lower Case    ${url}

            # Check for specific sections
            ${is_showroom}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /showroom/
            ${is_model_trim}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /model-trims/
            ${is_model}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /models/

            # Check for vehicle patterns (multiple URL patterns)
            ${has_vehicle_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /vehicle/
            ${has_view_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /view/
            ${has_new_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /new/
            ${has_used_path}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /used/
            ${has_new_dash}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /new-
            ${has_used_dash}=    Run Keyword And Return Status    Should Contain    ${url_lower}    /used-

            # Determine if this is a vehicle URL
            ${is_vehicle}=    Evaluate    ${has_vehicle_path} or ${has_view_path} or ${has_new_path} or ${has_used_path} or ${has_new_dash} or ${has_used_dash}

            IF    ${is_showroom}
                Append To List    ${showroom}    ${url}
            ELSE IF    ${is_model_trim}
                Append To List    ${model_trims}    ${url}
            ELSE IF    ${is_model}
                Append To List    ${models}    ${url}
            ELSE IF    ${is_vehicle}
                # Check if vehicle is Used or New
                ${is_used}=    Run Keyword And Return Status    Should Contain    ${url_lower}    used
                ${is_new}=    Run Keyword And Return Status    Should Contain    ${url_lower}    new

                IF    ${is_used}
                    Append To List    ${used_vehicles}    ${url}
                ELSE IF    ${is_new}
                    Append To List    ${new_vehicles}    ${url}
                ELSE
                    # If neither keyword found, default to new vehicles
                    Append To List    ${new_vehicles}    ${url}
                END
            ELSE
                Append To List    ${pages}    ${url}
            END
        END

        Set To Dictionary    ${sections}    pages=${pages}
        Set To Dictionary    ${sections}    used_vehicles=${used_vehicles}
        Set To Dictionary    ${sections}    new_vehicles=${new_vehicles}
        Set To Dictionary    ${sections}    showroom=${showroom}
        Set To Dictionary    ${sections}    models=${models}
        Set To Dictionary    ${sections}    model_trims=${model_trims}
    END

    RETURN    &{sections}

Get Test URLs From Sitemap
    [Documentation]    Returns URLs to test from sitemap sections
    [Arguments]    ${sitemap_source}    ${pages_samples}=None    ${used_vehicle_samples}=1    ${new_vehicle_samples}=1    ${showroom_samples}=1    ${models_samples}=1    ${model_trims_samples}=1

    &{sections}=    Extract Sitemap Sections    ${sitemap_source}
    @{test_urls}=    Create List

    @{pages_list}=    Get From Dictionary    ${sections}    pages
    ${pages_count}=    Get Length    ${pages_list}

    IF    '${pages_samples}' == 'None'
        FOR    ${url}    IN    @{pages_list}
            Append To List    ${test_urls}    ${url}
        END
    ELSE
        ${pages_samples_int}=    Convert To Integer    ${pages_samples}
        ${actual_samples}=    Evaluate    min(${pages_samples_int}, ${pages_count})
        @{random_pages}=    Evaluate    random.sample(${pages_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_pages}
            Append To List    ${test_urls}    ${url}
        END
    END

    @{used_vehicles_list}=    Get From Dictionary    ${sections}    used_vehicles
    ${used_vehicles_count}=    Get Length    ${used_vehicles_list}
    ${used_samples_int}=    Convert To Integer    ${used_vehicle_samples}
    IF    ${used_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${used_samples_int}, ${used_vehicles_count})
        @{random_used}=    Evaluate    random.sample(${used_vehicles_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_used}
            Append To List    ${test_urls}    ${url}
        END
    END

    @{new_vehicles_list}=    Get From Dictionary    ${sections}    new_vehicles
    ${new_vehicles_count}=    Get Length    ${new_vehicles_list}
    ${new_samples_int}=    Convert To Integer    ${new_vehicle_samples}
    IF    ${new_vehicles_count} > 0
        ${actual_samples}=    Evaluate    min(${new_samples_int}, ${new_vehicles_count})
        @{random_new}=    Evaluate    random.sample(${new_vehicles_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_new}
            Append To List    ${test_urls}    ${url}
        END
    END

    @{showroom_list}=    Get From Dictionary    ${sections}    showroom
    ${showroom_count}=    Get Length    ${showroom_list}
    ${showroom_samples_int}=    Convert To Integer    ${showroom_samples}
    IF    ${showroom_count} > 0
        ${actual_samples}=    Evaluate    min(${showroom_samples_int}, ${showroom_count})
        @{random_showroom}=    Evaluate    random.sample(${showroom_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_showroom}
            Append To List    ${test_urls}    ${url}
        END
    END

    @{models_list}=    Get From Dictionary    ${sections}    models
    ${models_count}=    Get Length    ${models_list}
    ${models_samples_int}=    Convert To Integer    ${models_samples}
    IF    ${models_count} > 0
        ${actual_samples}=    Evaluate    min(${models_samples_int}, ${models_count})
        @{random_models}=    Evaluate    random.sample(${models_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_models}
            Append To List    ${test_urls}    ${url}
        END
    END

    @{model_trims_list}=    Get From Dictionary    ${sections}    model_trims
    ${trims_count}=    Get Length    ${model_trims_list}
    ${trims_samples_int}=    Convert To Integer    ${model_trims_samples}
    IF    ${trims_count} > 0
        ${actual_samples}=    Evaluate    min(${trims_samples_int}, ${trims_count})
        @{random_trims}=    Evaluate    random.sample(${model_trims_list}, ${actual_samples})    random
        FOR    ${url}    IN    @{random_trims}
            Append To List    ${test_urls}    ${url}
        END
    END

    RETURN    @{test_urls}
