*** Settings ***
Documentation    Header Layout Consistency Testing
...              Validates that header layout remains consistent between homepage and internal pages
...              Checks: logo presence, navigation structure, CTA buttons, styling
Resource    ../../Resources/variables.robot
Resource    ../../Resources/Validations/header_layout.robot
Resource    ../../Resources/Integrated Tests/multi_site_testing.robot
Suite Teardown    Close Browser Safely

*** Test Cases ***
Test header layout from sitemap URLs
    # Checkpoint/resume is enabled by default with link tracking for pages
    # Progress is saved to: ./checkpoints/checkpoint.json
    # Issues are logged to: ./checkpoints/issues.json
    # To start fresh, delete the checkpoint files before running
    # To disable checkpoint, add: use_checkpoint=false
    #
    # This test validates header layout consistency across different page types
    # It checks that headers maintain the same structure, navigation items, and styling
    Parse Sitemap URLs
    ...    validation_keyword=Validate Header Layout Consistency
    ...    pages_samples=2
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
