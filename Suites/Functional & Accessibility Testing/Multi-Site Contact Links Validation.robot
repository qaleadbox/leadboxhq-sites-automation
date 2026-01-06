** Settings **
Resource    ../../Shared resources/keywords.robot
Resource    ../../Shared resources/variables.robot

** Test Cases **
Test contact links (address, phone number, social media)
    Validate Contact Links Matches It HREF    multi_site=True
