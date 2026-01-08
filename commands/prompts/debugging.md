# Debugging Pre-Prompt

## Context
This is the LeadBox Sites Automation project. When tests fail, we need to debug Robot Framework test execution.

## Variables
- `{{TEST_FILE}}`: Path to the failing test
- `{{ERROR_MESSAGE}}`: The error message from the test
- `{{EXPECTED_BEHAVIOR}}`: What should happen
- `{{ACTUAL_BEHAVIOR}}`: What actually happened

## Prompt Template

```
Debug a failing Robot Framework test in the LeadBox Sites Automation project.

Test File: {{TEST_FILE}}
Error Message: {{ERROR_MESSAGE}}

Expected Behavior: {{EXPECTED_BEHAVIOR}}
Actual Behavior: {{ACTUAL_BEHAVIOR}}

Project Context:
- Framework: Robot Framework with SeleniumLibrary
- Target: IMS/Concesionary (automotive dealership) websites
- Browser: Chrome
- Base URL: See Shared resources/variables.robot

Common Issues in this Project:
1. Dynamic content loading - elements may not be immediately available
2. Phone number format variations (xxx-xxx-xxxx, (xxx) xxx-xxxx, 1-xxx-xxx-xxxx)
3. Href normalization issues (tel: links with different formats)
4. Xpath selector brittleness due to changing DOM structure
5. Text content including non-breaking spaces or hidden characters

Debugging Steps:
1. Check if element exists with "Element Should Be Visible"
2. Add waits with "Wait Until Element Is Visible"
3. Verify xpath selector with browser DevTools
4. Check for pattern matching issues in text normalization
5. Review log.html report for detailed execution flow
6. Test phone/email/address pattern regex separately

Available Resources:
- Shared keywords in "Shared resources/keywords.robot"
- Helper functions in "Shared resources/helpers.robot"
- Existing working tests in "Suites/" folder for reference

Please:
1. Identify the root cause
2. Suggest a fix with code changes
3. Explain why the issue occurred
4. Recommend prevention strategies
```

## Example Usage
Replace variables:
- TEST_FILE: "Suites/Functional & Accessibility Testing/Test contact links.robot"
- ERROR_MESSAGE: "Phone '(555) 123-4567' is NOT clickable"
- EXPECTED_BEHAVIOR: "Phone number should be wrapped in <a href='tel:...'>"
- ACTUAL_BEHAVIOR: "Phone number is plain text without link"
