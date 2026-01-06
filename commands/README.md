# Commands & Configuration

This folder contains configuration files and pre-prompts to provide rich context for working with the LeadBox Sites Automation project.

## Purpose

The `commands/` folder serves as a knowledge base that helps AI assistants (like Claude Code) understand:
- Project structure and purpose
- Common patterns and conventions
- Testing focus areas for IMS/Concesionary websites
- Reusable prompt templates for common tasks

## Structure

```
commands/
├── config.json                      # Project configuration and metadata
├── prompts/                         # Pre-written prompts with variables
│   ├── test-creation.md            # Create new test suites
│   ├── keyword-creation.md         # Create reusable keywords
│   ├── debugging.md                # Debug failing tests
│   ├── refactor.md                 # Refactor existing code
│   └── site-analysis.md            # Analyze new dealership websites
├── templates/                       # Code templates
│   ├── test-suite-template.robot   # Template for new test files
│   └── keyword-template.robot      # Template for new keywords
└── README.md                        # This file
```

## How to Use

### 1. Share Context with AI

When starting a new conversation with Claude Code or another AI assistant, reference the config:

```
"Read commands/config.json to understand this project's structure and purpose"
```

### 2. Use Pre-Prompts with Variables

Select a prompt template from `commands/prompts/` and replace the variables:

Example using `test-creation.md`:
```
Use commands/prompts/test-creation.md with these variables:
- TEST_NAME: "Test Header Navigation Links"
- BASE_URL: "https://dealership.example.com"
- FEATURE: "Header Navigation"
- DESCRIPTION: "Verify all navigation links in header are functional"
```

### 3. Use Templates for New Files

Copy templates and fill in the placeholders:
```
Use commands/templates/test-suite-template.robot to create a new test for form validation
```

## Available Prompts

### test-creation.md
Creates new Robot Framework test suites for dealership website features.

**Variables:**
- `{{TEST_NAME}}`: Name of test suite
- `{{BASE_URL}}`: Target website
- `{{FEATURE}}`: Feature being tested
- `{{DESCRIPTION}}`: Test purpose

### keyword-creation.md
Creates reusable keywords for common testing operations.

**Variables:**
- `{{KEYWORD_NAME}}`: Keyword name
- `{{PURPOSE}}`: What it does
- `{{INPUTS}}`: Arguments
- `{{RETURNS}}`: Return value

### debugging.md
Helps debug failing tests with project context.

**Variables:**
- `{{TEST_FILE}}`: Failing test path
- `{{ERROR_MESSAGE}}`: Error from test
- `{{EXPECTED_BEHAVIOR}}`: What should happen
- `{{ACTUAL_BEHAVIOR}}`: What actually happens

### refactor.md
Guides code refactoring while maintaining project standards.

**Variables:**
- `{{TARGET}}`: What to refactor
- `{{REASON}}`: Why refactor
- `{{GOAL}}`: Desired outcome

### site-analysis.md
Analyzes new dealership websites for test planning.

**Variables:**
- `{{SITE_URL}}`: Website URL
- `{{DEALERSHIP_NAME}}`: Dealership name
- `{{FOCUS_AREAS}}`: What to analyze

## Configuration (config.json)

The configuration file contains:

- **Project metadata**: Name, type, purpose
- **Structure**: Folder organization
- **Common variables**: BASE_URL, browser settings
- **Testing focus**: Functional, accessibility, content areas
- **Patterns**: Regex patterns for phone, email, postal codes
- **Libraries**: Robot Framework libraries used

## Example Workflow

### Creating a New Test for a New Dealership

1. **Analyze the site:**
   ```
   Use commands/prompts/site-analysis.md for https://newdealer.com
   ```

2. **Update BASE_URL:**
   ```
   Update Shared resources/variables.robot with new URL
   ```

3. **Create test suite:**
   ```
   Use commands/prompts/test-creation.md to create contact link tests
   ```

4. **Create keywords if needed:**
   ```
   Use commands/prompts/keyword-creation.md for any new validation logic
   ```

5. **Run and debug:**
   ```
   If tests fail, use commands/prompts/debugging.md
   ```

## Maintenance

When you add new patterns or conventions to the project:

1. Update `config.json` with new patterns or variables
2. Create new prompt templates for recurring tasks
3. Update templates to reflect current best practices
4. Document changes in this README

## Benefits

- **Consistency**: Ensures all tests follow the same patterns
- **Speed**: Pre-written prompts reduce setup time
- **Knowledge preservation**: Documents project conventions
- **Onboarding**: New team members can quickly understand the project
- **AI assistance**: Provides rich context for AI-powered development
