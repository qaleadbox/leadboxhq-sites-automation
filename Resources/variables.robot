*** Variables ***
# ${BASE_URL}    https://drummondmotors.ca/
${SPREADSHEET_LINK}    https://docs.google.com/spreadsheets/d/1PwGF8nXgqCV9gVY0Ewj4ZrEmvBP-ATBp5ddtzcvZMRU/edit?gid=0#gid=0
${HEADLESS}    false

# Checkpoint/Resume Configuration
${CHECKPOINT_DIR}    ${CURDIR}${/}..${/}checkpoints
${CHECKPOINT_FILE}    ${CHECKPOINT_DIR}${/}checkpoint.json
${ISSUES_LOG_FILE}    ${CHECKPOINT_DIR}${/}issues.json
${USE_CHECKPOINT}    true