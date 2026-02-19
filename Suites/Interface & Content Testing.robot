*** Settings ***
Documentation    Interface & Content Testing
...              Validates interface consistency and content quality across pages
...              Checks: header layout, favicons, SEO metadata (title, meta tags, og:site_name)
...              SEO validation includes: capitalization, template variables (%%), og:site_name consistency, sitemap site name consistency
Resource    ../Resources/variables.robot
Resource    ../Resources/Validations/header_layout.robot
Resource    ../Resources/Validations/seo_metadata.robot
Resource    ../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test Interface And Content From Sitemap URLs
    [Documentation]    Validates interface elements and content quality
    ...                Includes: Favicons, SEO metadata validation, Header layout with tab wrapping check
    ...                Tab wrapping settings: CHECK_TAB_WRAPPING, TAB_WRAPPING_TEST_WIDTHS in variables.robot
    Run Test Environment
    ...    Validate Favicons
    ...    Validate SEO Metadata
    ...    Validate Header Layout With Wrapping Check

# Settings can be found on ./Resources/variables.robot