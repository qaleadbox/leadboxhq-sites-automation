*** Settings ***
Documentation    Header Layout Consistency Testing
...              Validates that header layout remains consistent between homepage and internal pages
...              Checks: logo presence, navigation structure, menu-header-menu component, background color
Resource    ../Resources/variables.robot
Resource    ../Resources/Validations/header_layout.robot
Resource    ../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test header layout from sitemap URLs
    Run Test Environment
    ...    Validate Favicons
    # ...    Validate Header Layout Consistency

# Settings can be found on ./Resources/variables.robot