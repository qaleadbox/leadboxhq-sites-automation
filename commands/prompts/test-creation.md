# Test Creation Pre-Prompt

## Context
This is the LeadBox Sites Automation project - a Robot Framework test automation tool for IMS/Concesionary (automotive dealership) websites.

## Variables
- `{{TEST_NAME}}`: Name of the test suite
- `{{BASE_URL}}`: Target website URL (default: https://drummondmotors.ca/)
- `{{FEATURE}}`: Feature being tested (e.g., "Contact Links", "Navigation", "Forms")
- `{{DESCRIPTION}}`: Brief description of test purpose

## Prompt Template

```
Create a new Robot Framework test suite for testing {{FEATURE}} on dealership websites.

Test Name: {{TEST_NAME}}
Target URL: {{BASE_URL}}
Description: {{DESCRIPTION}}

Requirements:
1. Use the shared resources from "Shared resources/" folder:
   - variables.robot (contains BASE_URL)
   - keywords.robot (contains reusable keywords)
   - helpers.robot (contains utility functions)

2. Follow the existing project structure in "Suites/" folder

3. Test should validate:
   - Functional correctness
   - Accessibility compliance
   - Data accuracy (phone, email, address formatting)

4. Include proper logging with "Log To Console"

5. Use appropriate xpath selectors and SeleniumLibrary keywords

6. Handle edge cases and provide clear failure messages

Project patterns to follow:
- Phone: North American format (xxx-xxx-xxxx or (xxx) xxx-xxxx)
- Email: Standard email validation
- Postal Code: Canadian format (A1A 1A1)

Please create the test file in: Suites/{{CATEGORY}}/{{TEST_NAME}}.robot
```

## Example Usage
Replace variables:
- TEST_NAME: "Test Footer Social Media Links"
- BASE_URL: "https://dealership-example.com"
- FEATURE: "Social Media Links in Footer"
- DESCRIPTION: "Verify all social media icons in footer are clickable and link to correct platforms"
