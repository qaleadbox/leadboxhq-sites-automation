*** Variables ***

${SPREADSHEET_LINK}    https://docs.google.com/spreadsheets/d/1PwGF8nXgqCV9gVY0Ewj4ZrEmvBP-ATBp5ddtzcvZMRU/edit?gid=0#gid=0
${HEADLESS}    false    # true, to run without interface (to future CI/CD runnings) | false, to run with interface

# Test Environment Mode
${TEST_MODE}             unitary    # sitemap = test multiple sites from spreadsheet | unitary = test single website via sitemap
${UNITARY_PAGE_URL}      https://addisononeglinton.com/   # URL to test when TEST_MODE=unitary

# Sampling Configuration (0 = test all links, None = test all, N = test N samples)
${PAGES_SAMPLES}             0
${USED_VEHICLE_SAMPLES}      1
${NEW_VEHICLE_SAMPLES}       1
${SHOWROOM_SAMPLES}          1
${MODELS_SAMPLES}            1
${MODEL_TRIMS_SAMPLES}       1

# Skip Configuration (Set to 'true' to skip section if at least one sample was already tested)
${SKIP_PAGES_IF_SAMPLED}            false
${SKIP_USED_VEHICLES_IF_SAMPLED}    false
${SKIP_NEW_VEHICLES_IF_SAMPLED}     false
${SKIP_SHOWROOM_IF_SAMPLED}         false
${SKIP_MODELS_IF_SAMPLED}           false
${SKIP_MODEL_TRIMS_IF_SAMPLED}      false

# Checkpoint/Resume Configuration
${USE_CHECKPOINT}    true
${CHECKPOINT_DIR}    ${CURDIR}${/}..${/}checkpoints
${CHECKPOINT_FILE}    ${CHECKPOINT_DIR}${/}checkpoint.json
${ISSUES_LOG_FILE}    ${CHECKPOINT_DIR}${/}issues.json

# Spreadsheet Data Caching
${FORCE_SPREADSHEET_DATA_FETCH}    false    # true = fetch from Google Spreadsheet (slow) | false = use local CSV cache (fast)
${SPREADSHEET_CSV_CACHE}           ${EXECDIR}${/}sites.csv    # Use existing sites.csv in project root

# Header Tab Wrapping Configuration
${CHECK_TAB_WRAPPING}              true     # true = check for tab wrapping at specific breakpoints | false = skip wrapping check
${TAB_WRAPPING_TEST_WIDTHS}        1366,1440,1520    # Comma-separated list of widths to test (common problematic breakpoints)
${TAB_WRAPPING_HEIGHT}             1024     # Height to use when testing tab wrapping
${TAB_WRAPPING_TOLERANCE}          5        # Y-position tolerance in pixels (default: 5px)