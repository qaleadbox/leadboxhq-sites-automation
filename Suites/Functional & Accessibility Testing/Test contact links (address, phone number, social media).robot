*** Settings ***
Resource    ../../Resources/variables.robot
Resource    ../../Resources/Validations/contact_links.robot
Resource    ../../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test contact links from sitemap URLs
    # Checkpoint/resume is enabled by default with counter-based tracking
    # Progress is saved to: ./checkpoints/checkpoint.json (shows counters like "4/50")
    # Issues are logged to: ./checkpoints/issues.json
    # To start fresh, delete the checkpoint files before running
    # To disable checkpoint, add: use_checkpoint=false
    #
    # Skip parameters: Set to 'true' to skip section if at least one sample was already tested
    # Example: skip_pages_if_sampled=true means skip pages section if counter is "1/50" or higher
    # This is useful when you want to sample all sections at least once, then skip on resume
    Parse Sitemap URLs
    ...    validation_keyword=Validate Contact Links Matches It HREF
    ...    pages_samples=3
    ...    used_vehicle_samples=1
    ...    new_vehicle_samples=1
    ...    showroom_samples=1
    ...    models_samples=1
    ...    model_trims_samples=1
    # ...    skip_pages_if_sampled=true
    # ...    skip_used_vehicles_if_sampled=true
    # ...    skip_new_vehicles_if_sampled=true
    # ...    skip_showroom_if_sampled=true
    # ...    skip_models_if_sampled=true
    # ...    skip_model_trims_if_sampled=true
    # blogs is missing
