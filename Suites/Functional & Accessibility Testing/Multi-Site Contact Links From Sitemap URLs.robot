** Settings **
Resource    ../../Shared resources/keywords.robot
Resource    ../../Shared resources/variables.robot

** Test Cases **
Test contact links from sitemap URLs
    Parse Sitemap URLs
    ...    validation_keyword=Validate Contact Links Matches It HREF
    ...    pages_samples=1
    ...    used_vehicle_samples=1
    ...    new_vehicle_samples=1
    ...    showroom_samples=1
    ...    models_samples=1
    ...    model_trims_samples=1
