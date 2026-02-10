# Favicon Testing

## Purpose
Validate favicon presence and format across dealership sites.

## Implementation

### Files
- **Resources/Validations/favicon.robot**
  - `Validate Favicons` - Multi-validation (fails on error)
  - `Validate Favicon Exists And Matches Brand` - Standalone (returns dict)
  - `Check Favicon` - Internal logic

- **Suites/.../Test check if the site has a Favicon...robot**
  - Standalone test suite with checkpoint/resume

### Validation Logic
Checks favicon selectors: `link[rel='shortcut icon']`, `link[rel='icon']`, `link[rel='apple-touch-icon']`, `link[rel='apple-touch-icon-precomposed']`

Valid extensions: `.ico`, `.gif`, `.png`, `.jpg`, `.svg`

## Usage

### Standalone
```bash
robot "Suites/Functional & Accessibility Testing/Test check if the site has a Favicon and confirm it matches the correct brand.robot"
```

### Multi-Validation
```robot
Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    Validate Favicons
    ...    pages_samples=2
```

## Pass/Fail
- **PASS**: Valid favicon with supported extension found
- **FAIL**: No favicon or unsupported format
