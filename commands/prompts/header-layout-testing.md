# Header Layout Consistency Testing

## Purpose
Validate header structure consistency across page types on dealership sites.

## Implementation

### Files
- **Resources/Validations/header_layout.robot**
  - `Validate Header Layout` - Multi-validation (fails on error)
  - `Validate Header Layout Consistency` - Standalone (returns dict)
  - `Compare Header Layouts` - Captures header structure
  - `Compare Header Between Pages` - Homepage vs internal comparison

- **Suites/.../Test header layout consistency.robot**
  - Standalone test suite with checkpoint/resume

### Validation Checks
1. **Structure**: `<header>` element, navigation, logo presence
2. **Navigation**: Nav items count, `ul#menu-header-menu` component
3. **CTAs**: Button count consistency
4. **Styling**: Background color consistency

## Usage

### Standalone
```bash
robot "Suites/Functional & Accessibility Testing/Test header layout consistency.robot"
```

### Multi-Validation
```robot
Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    Validate Header Layout
    ...    pages_samples=2
```

### Checkpoint
- Progress: `./checkpoints/checkpoint.json`
- Issues: `./checkpoints/issues.json`
- Reset: Delete checkpoint files
- Disable: `use_checkpoint=false`

## Configuration

### Sample Sizes
```robot
Parse Sitemap URLs
    ...    pages_samples=5           # Test 5 pages
    ...    pages_samples=None         # Test ALL pages
    ...    skip_pages_if_sampled=true # Skip if sampled
```

## Pass/Fail
- **PASS**: Header, logo, nav exist; counts consistent; styling matches
- **FAIL**: Missing elements, inconsistent counts/styling

## Common Issues
- **Missing nav**: Check if using `<ul>` directly instead of `<nav>`
- **No logo**: Verify alt text/class contains "logo"
- **Inconsistent counts**: May be intentional (dynamic menus)
- **Menu component missing**: Check id attribute on `<ul>` element
