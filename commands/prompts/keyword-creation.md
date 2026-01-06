# Keyword Creation Pre-Prompt

## Context
This is the LeadBox Sites Automation project. Keywords are reusable test functions stored in "Shared resources/keywords.robot".

## Variables
- `{{KEYWORD_NAME}}`: Name of the keyword to create
- `{{PURPOSE}}`: What the keyword should accomplish
- `{{INPUTS}}`: Arguments the keyword should accept
- `{{RETURNS}}`: What the keyword should return (if applicable)

## Prompt Template

```
Create a new Robot Framework keyword for the LeadBox automation project.

Keyword Name: {{KEYWORD_NAME}}
Purpose: {{PURPOSE}}
Arguments: {{INPUTS}}
Returns: {{RETURNS}}

Requirements:
1. Add to "Shared resources/keywords.robot" file
2. Use existing libraries: SeleniumLibrary, String
3. Follow the existing coding patterns in the keywords.robot file
4. Include proper error handling with meaningful failure messages
5. Use "Log To Console" for debugging information
6. Support the testing of IMS/Concesionary dealership websites

Existing keyword patterns to follow:
- Pattern detection (phone, email, address)
- Element validation (clickability, href matching)
- Text normalization (removing spaces, special chars)
- Xpath-based element selection

Integration with existing keywords:
- Can use "Detect Text Type" for pattern matching
- Can use helpers from helpers.robot
- Should work with ${BASE_URL} variable

Please provide:
1. The complete keyword implementation
2. Usage example
3. Any edge cases handled
```

## Example Usage
Replace variables:
- KEYWORD_NAME: "Validate Form Submission"
- PURPOSE: "Submit a contact form and verify success message appears"
- INPUTS: "[Arguments] ${form_selector} ${success_message}"
- RETURNS: "Success status (True/False)"
