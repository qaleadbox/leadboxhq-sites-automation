*** Settings ***
Documentation    Favicon Testing
...              Validates that the site has a favicon and confirms it matches the correct brand
...              Checks: shortcut icon rel in head tag, valid image extension, and opens URL in new tab for manual verification
Resource    ../../Resources/variables.robot
Resource    ../../Resources/Validations/favicon.robot
Resource    ../../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test favicon on all homepages
    # This test validates that each website homepage has a proper favicon
    # It checks for shortcut icon or icon link elements in the head tag
    # Verifies the favicon uses a valid image format (.ico, .gif, .png, .jpg, .svg)
    # and opens the favicon URL in a new tab for manual verification
    #
    # NO checkpoints used - simple homepage-only validation
    Test All Homepages For Favicon
