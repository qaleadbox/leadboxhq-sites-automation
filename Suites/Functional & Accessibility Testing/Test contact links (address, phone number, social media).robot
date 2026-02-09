*** Settings ***
Resource    ../../Resources/variables.robot
Resource    ../../Resources/Validations/contact_links.robot
Resource    ../../Resources/Validations/url_links.robot
Resource    ../../Resources/Validations/security.robot
Resource    ../../Resources/Validations/favicon.robot
Resource    ../../Resources/Validations/header_layout.robot
Resource    ../../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test contact links
    Run Test Environment
    ...    Validate Contact Links Matches It HREF
    ...    Validate URL Links Matches It HREF
    ...    Validate Page URL Is Secure HTTPS
    ...    Validate Favicons

# Configuration: Set TEST_MODE in variables.robot
# - sitemap: Tests all sites from spreadsheet
# - unitary: Tests single page from UNITARY_PAGE_URL