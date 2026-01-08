# Commands & Configuration

Documentation and configuration resources for LeadBox Sites Automation project.

## Overview

The `commands/` directory provides project context, configuration, and reusable templates for efficient test development and AI-assisted workflows.

## Directory Structure

```
commands/
├── config.json              # Project metadata and configuration
├── CHANGELOG.md             # Version history and changes
├── QUICK-CONTEXT.md         # Fast project onboarding for AI assistants
├── DEBUG-COMMANDS.md        # Debugging procedures and commands
├── README.md                # This file
├── prompts/                 # Prompt templates for common tasks
│   ├── test-creation.md
│   ├── keyword-creation.md
│   ├── debugging.md
│   ├── refactor.md
│   ├── site-analysis.md
│   ├── batch-sitemap-testing.md
│   └── sitemap-url-sampling.md
├── templates/               # Code templates
│   ├── test-suite-template.robot
│   └── keyword-template.robot
└── guides/                  # Implementation guides
```

## Quick Start

### For AI Assistants

Start new conversations by referencing context files:

```
"Read commands/QUICK-CONTEXT.md for project overview"
```

For specific tasks:
- **Sitemap sampling**: `commands/prompts/sitemap-url-sampling.md`
- **Full configuration**: `commands/config.json`
- **Debugging issues**: `commands/DEBUG-COMMANDS.md`

### For Developers

1. Review `config.json` for project structure and patterns
2. Use templates in `templates/` for new files
3. Reference prompts in `prompts/` for guided workflows
4. Consult `DEBUG-COMMANDS.md` for troubleshooting

## Key Files

### Configuration

**config.json**
- Project metadata and structure
- Testing focus areas and patterns
- Common variables and settings
- Regex patterns for validation

### Documentation

**CHANGELOG.md**
- Complete version history
- Feature additions and bug fixes
- Breaking changes and migration guides

**QUICK-CONTEXT.md**
- Condensed project overview
- Essential patterns and workflows
- Quick reference for starting new work

**DEBUG-COMMANDS.md**
- Troubleshooting procedures
- Testing and validation commands
- Common issues and solutions
- Performance testing guidance

### Prompts

Reusable templates for common development tasks:

| Prompt | Purpose | Variables |
|--------|---------|-----------|
| `test-creation.md` | Create new test suites | TEST_NAME, BASE_URL, FEATURE, DESCRIPTION |
| `keyword-creation.md` | Define reusable keywords | KEYWORD_NAME, PURPOSE, INPUTS, RETURNS |
| `debugging.md` | Debug failing tests | TEST_FILE, ERROR_MESSAGE, EXPECTED_BEHAVIOR |
| `refactor.md` | Guide refactoring tasks | TARGET, REASON, GOAL |
| `site-analysis.md` | Analyze dealership sites | SITE_URL, DEALERSHIP_NAME, FOCUS_AREAS |
| `batch-sitemap-testing.md` | Multi-site testing | CSV_FILE, URL_COLUMN, ADDITIONAL_CHECKS |
| `sitemap-url-sampling.md` | URL sampling reference | N/A (reference doc) |

## Sitemap Sampling

The framework supports intelligent URL sampling from sitemap sections:

### Parameters
All sampling parameters use the `_samples` suffix:
- `pages_samples` - General pages (None = all, or integer)
- `used_vehicle_samples` - Used vehicle listings
- `new_vehicle_samples` - New vehicle listings
- `showroom_samples` - Showroom/inventory pages
- `models_samples` - Vehicle model pages
- `model_trims_samples` - Model trim variant pages

### Detection Methods
1. **HTML Sitemaps**: Section headers (h2, h3) for precise categorization
2. **XML Sitemaps**: URL pattern matching as fallback
3. **Vehicle Classification**: Automatic used/new detection via URL keywords

### Sample Size Recommendations

| Profile | pages | used | new | showroom | models | trims | Duration |
|---------|-------|------|-----|----------|--------|-------|----------|
| Quick   | 1     | 1    | 1   | 1        | 0      | 0     | ~30s     |
| Standard| 3     | 2    | 2   | 1        | 1      | 1     | ~2min    |
| Full    | None  | 5    | 5   | 2        | 3      | 2     | Variable |

## Common Patterns

### Regular Expressions
```
Phone:       \(?\\d{3}\)?[-\s]?\d{3}[-\s]?\d{4}
Email:       [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}
Postal (CA): [A-Z]\d[A-Z]\s?\d[A-Z]\d
```

### URL Patterns
```
New Vehicles:   /new/, /new-, /view/new-
Used Vehicles:  /used/, /used-, /view/used-
Showroom:       /showroom/
Models:         Section: "Models" (HTML)
Model Trims:    Section: "Models Trims" (HTML)
```

## Development Workflow

### Adding New Test Suite

1. **Analyze target site**
   ```bash
   # Review sitemap structure
   robot debug-sitemap-urls.robot
   ```

2. **Use template**
   ```bash
   cp commands/templates/test-suite-template.robot "Suites/new-test.robot"
   ```

3. **Implement and test**
   ```bash
   robot "Suites/new-test.robot"
   ```

4. **Document changes**
   - Update `CHANGELOG.md` with modifications
   - Add new patterns to `config.json` if applicable

### Debugging Issues

Consult `DEBUG-COMMANDS.md` for:
- URL categorization testing
- Race condition diagnosis
- Sitemap analysis commands
- Performance profiling

## Maintenance

### Update Checklist
- [ ] Add new patterns to `config.json`
- [ ] Document changes in `CHANGELOG.md`
- [ ] Update templates with best practices
- [ ] Create prompts for recurring tasks
- [ ] Update `QUICK-CONTEXT.md` with significant changes

### Version Control
Reference `CHANGELOG.md` for complete history of:
- Feature additions
- Bug fixes
- Breaking changes
- Migration guides

## Benefits

| Benefit | Description |
|---------|-------------|
| **Consistency** | Standardized patterns across all tests |
| **Efficiency** | Pre-built templates reduce development time |
| **Knowledge Preservation** | Documented conventions and patterns |
| **AI Integration** | Optimized context for AI-assisted development |
| **Onboarding** | Rapid team member familiarization |
| **Debuggability** | Comprehensive troubleshooting resources |

## Support

For detailed implementation guidance:
1. Review relevant prompt template in `prompts/`
2. Consult `config.json` for configuration details
3. Check `DEBUG-COMMANDS.md` for troubleshooting
4. Reference `CHANGELOG.md` for recent updates

---

**Version**: 1.0.0
**Last Updated**: 2026-01-06
**Maintained By**: LeadBox QA Team
