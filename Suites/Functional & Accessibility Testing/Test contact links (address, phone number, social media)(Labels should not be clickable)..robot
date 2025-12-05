** Settings **
Library  SeleniumLibrary
# Library  FakerLibrary
Resource    ../../Shared resources/keywords.robot
Resource    ../../Shared resources/variables.robot

** Test Cases **
Test contact links (address, phone number, social media)
    Open LeadBox Portal
    # Validate Contact Links Are Clickable
    Validate Contact Links Matches It HREF