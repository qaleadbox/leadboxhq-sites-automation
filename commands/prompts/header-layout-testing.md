# Header Layout Consistency Testing Prompt

## Context
This prompt is for testing header layout consistency across different page types on automotive dealership websites. Headers should maintain consistent structure, navigation, and styling across homepage and internal pages.

## Test Overview
**Feature**: Header Layout Consistency
**Target**: Multi-site validation via sitemap URLs
**Purpose**: Ensure header elements remain consistent across different page types

## What This Test Validates

### 1. Header Structure
- Presence of `<header>` element
- Header contains navigation element
- Logo placement and visibility
- Specific menu component with id `menu-header-menu` on `<ul>` element

### 2. Navigation Elements
- Navigation menu exists
- Number of navigation items is consistent
- Navigation items are accessible
- Menu-header-menu ul component presence and consistency

### 3. Call-to-Action (CTA) Buttons
- CTA buttons in header
- Consistent CTA count across pages
- Proper styling classes applied

### 4. Visual Styling
- Background color consistency
- Overall header styling matches

### 5. Menu-Header-Menu Component (ul#menu-header-menu)
- Checks existence of the specific menu component
- Validates menu item count consistency
- Captures menu items text for comparison

## Files Involved

### Test Suite
`Suites/Functional & Accessibility Testing/Test header layout consistency.robot`
- Main test suite file
- Uses checkpoint/resume for multi-site testing
- Samples from different URL categories

### Validation Keywords
`Resources/Validations/header_layout.robot`
- `Validate Header Layout Consistency` - Main validation keyword
- `Compare Header Layouts` - Captures and analyzes header structure
- `Compare Header Between Pages` - Compares homepage vs internal page headers

## Usage

### Running the Test
```bash
robot "Suites/Functional & Accessibility Testing/Test header layout consistency.robot"
```

### Sample Configuration
The test samples URLs from different categories:
- **Pages**: 2 samples (homepage, about, contact, etc.)
- **Used Vehicles**: 1 sample
- **New Vehicles**: 1 sample
- **Showroom**: 1 sample
- **Models**: 1 sample
- **Model Trims**: 1 sample

### Checkpoint/Resume
- Progress saved to: `./checkpoints/checkpoint.json`
- Issues logged to: `./checkpoints/issues.json`
- Delete checkpoint files to start fresh
- Use `use_checkpoint=false` to disable

## Expected Results

### Pass Criteria
- Header element exists on all pages
- Logo is present and visible
- Navigation menu exists with items
- Navigation item count is consistent
- Menu-header-menu ul component presence is consistent
- Menu-header-menu item count matches across pages
- CTA button count is consistent
- Background color matches across pages

### Fail Criteria
- Missing header element
- No logo found
- Navigation missing or empty
- Inconsistent navigation item count
- Menu-header-menu component exists on one page but not another
- Menu-header-menu item count differs between pages
- Inconsistent CTA button count
- Different background colors

## Common Issues

### Issue: Missing Navigation
**Symptoms**: No `<nav>` element in header
**Resolution**: Check if navigation is structured differently (e.g., using `<ul>` directly)

### Issue: Logo Not Found
**Symptoms**: No logo image detected
**Resolution**: Verify logo uses proper alt text or class names (should contain "logo")

### Issue: Inconsistent Nav Count
**Symptoms**: Different number of navigation items on different pages
**Resolution**: May indicate dynamic navigation or page-specific menus - verify if intentional

### Issue: Menu-Header-Menu Component Missing
**Symptoms**: ul#menu-header-menu not found on page
**Resolution**: Verify the navigation menu uses the correct id attribute. This specific component may only be present on certain page templates.

### Issue: Menu-Header-Menu Item Count Differs
**Symptoms**: Different number of menu items in ul#menu-header-menu between pages
**Resolution**: Check if certain pages show/hide menu items dynamically based on context (e.g., user login state, page type). This may be intentional.

## Customization

### Adjusting Sample Sizes
To test more pages, modify the sample parameters:
```robot
Parse Sitemap URLs
    ...    pages_samples=5        # Test 5 pages instead of 2
    ...    used_vehicle_samples=2 # Test 2 used vehicle pages
```

### Testing All Pages
To test all pages in a category, use `None`:
```robot
Parse Sitemap URLs
    ...    pages_samples=None  # Test ALL pages
```

### Skip Already Sampled Sections
To skip sections where at least one URL was tested:
```robot
Parse Sitemap URLs
    ...    skip_pages_if_sampled=true
    ...    skip_models_if_sampled=true
```

## Integration with Other Tests

This test uses the same multi-site testing framework as:
- Contact links validation
- Phone number validation
- Other functional tests

You can run multiple validations by changing the `validation_keyword` parameter.

## Future Enhancements

Potential additions:
1. Header height consistency check
2. Mobile responsive header validation
3. Sticky header behavior testing
4. Header z-index and overlay testing
5. Header animation/transition validation
