# Refactoring Pre-Prompt

## Context
This is the LeadBox Sites Automation project. Refactoring improves code quality while maintaining test functionality.

## Variables
- `{{TARGET}}`: What to refactor (test file, keyword, or entire suite)
- `{{REASON}}`: Why refactoring is needed
- `{{GOAL}}`: Desired outcome

## Prompt Template

```
Refactor code in the LeadBox Sites Automation project.

Target: {{TARGET}}
Reason: {{REASON}}
Goal: {{GOAL}}

Project Standards:
1. DRY (Don't Repeat Yourself) - Extract common logic to keywords
2. Clear naming - Use descriptive names for keywords and variables
3. Proper structure:
   - Variables in "Shared resources/variables.robot"
   - Keywords in "Shared resources/keywords.robot"
   - Helpers in "Shared resources/helpers.robot"
   - Tests in "Suites/" organized by category
4. Consistent patterns for IMS/Concesionary website testing
5. Proper error messages that help identify issues quickly

Refactoring Guidelines:
- Keep test intent clear and readable
- Extract repeated xpath selectors to variables
- Create reusable keywords for common operations
- Improve pattern matching for phone/email/address
- Add meaningful comments for complex logic
- Maintain backward compatibility with existing tests

Before Refactoring:
1. Read the current implementation
2. Identify duplication and complexity
3. Check dependencies (what uses this code?)
4. Plan the changes

After Refactoring:
1. Ensure all tests still pass
2. Update documentation if needed
3. Verify log output is still useful for debugging

Please provide:
1. Analysis of current code issues
2. Refactored code with explanations
3. Migration guide if breaking changes
4. Test plan to verify refactoring
```

## Example Usage
Replace variables:
- TARGET: "Phone validation logic across multiple test files"
- REASON: "Same phone normalization code duplicated in 5 different tests"
- GOAL: "Create a single reusable keyword for phone validation"
