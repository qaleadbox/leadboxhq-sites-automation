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
Test contact links from sitemap URLs
    Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    Validate URL Links Matches It HREF
    ...    Validate Page URL Is Secure HTTPS

    ...    Validate Favicons

# PS: Now all settings can be found on ./Resources/variables