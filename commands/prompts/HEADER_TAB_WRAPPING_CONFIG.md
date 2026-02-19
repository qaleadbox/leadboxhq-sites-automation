# Header Tab Wrapping Detection Configuration

## Overview

The header tab wrapping detection automatically checks if navigation tabs break into multiple lines at specific viewport sizes. This is important for ensuring a professional appearance and usability across different screen sizes.

## Configuration Variables

All configuration is in `Resources/variables.robot`:

### `CHECK_TAB_WRAPPING`
- **Type:** Boolean (`true` or `false`)
- **Default:** `true`
- **Description:** Enable/disable tab wrapping checks
- **Usage:**
  ```robot
  ${CHECK_TAB_WRAPPING}    true    # Enable wrapping checks
  ${CHECK_TAB_WRAPPING}    false   # Disable wrapping checks
  ```

### `TAB_WRAPPING_TEST_WIDTHS`
- **Type:** Comma-separated list of integers
- **Default:** `1366,1440,1520`
- **Description:** Viewport widths (in pixels) to test for tab wrapping
- **Recommended values:**
  - `1366` - Common laptop resolution
  - `1440` - Small desktop
  - `1520` - Last width where wrapping typically occurs
- **Usage:**
  ```robot
  ${TAB_WRAPPING_TEST_WIDTHS}    1366,1440,1520    # Test 3 breakpoints
  ${TAB_WRAPPING_TEST_WIDTHS}    1366              # Test only one width
  ${TAB_WRAPPING_TEST_WIDTHS}    1300,1400,1500,1600    # Custom range
  ```

### `TAB_WRAPPING_HEIGHT`
- **Type:** Integer
- **Default:** `1024`
- **Description:** Viewport height (in pixels) to use during testing
- **Usage:**
  ```robot
  ${TAB_WRAPPING_HEIGHT}    1024    # Standard
  ${TAB_WRAPPING_HEIGHT}    768     # Smaller screens
  ```

### `TAB_WRAPPING_TOLERANCE`
- **Type:** Integer
- **Default:** `5`
- **Description:** Y-position tolerance in pixels for alignment detection
- **Usage:**
  ```robot
  ${TAB_WRAPPING_TOLERANCE}    5     # 5px tolerance
  ${TAB_WRAPPING_TOLERANCE}    10    # More lenient
  ```

## How It Works

### Detection Logic

1. **Hamburger Menu Detection:** If navigation items are hidden (e.g., in a mobile hamburger menu), the check is skipped for that width

2. **Y-Coordinate Comparison:** For visible navigation items, the tool compares the Y-position of each tab to the first tab

3. **Wrapping Detection:** If any tab's Y-position differs by more than `TAB_WRAPPING_TOLERANCE` pixels from the first tab, wrapping is detected

4. **Failure:** If wrapping is detected at any configured breakpoint, the test fails with a clear message

### Test Results from addisononeglinton.com

Based on testing, here's what we found:

- **≤1280px:** Hamburger menu (no desktop navigation visible)
- **1300-1520px:** ✗ Tab wrapping detected (80px Y-difference)
- **1540px+:** ✓ No wrapping (all tabs on one line)

## Usage Examples

### Example 1: Test Common Breakpoints (Recommended)

```robot
# In Resources/variables.robot
${CHECK_TAB_WRAPPING}              true
${TAB_WRAPPING_TEST_WIDTHS}        1366,1440,1520
${TAB_WRAPPING_HEIGHT}             1024
```

This tests the three most problematic widths where wrapping typically occurs.

### Example 2: Test Only Laptop Resolution

```robot
${CHECK_TAB_WRAPPING}              true
${TAB_WRAPPING_TEST_WIDTHS}        1366
${TAB_WRAPPING_HEIGHT}             768
```

This tests only the common laptop resolution (1366x768).

### Example 3: Disable Tab Wrapping Checks

```robot
${CHECK_TAB_WRAPPING}              false
```

This completely disables tab wrapping checks (useful if your site intentionally wraps navigation).

### Example 4: Extensive Testing

```robot
${CHECK_TAB_WRAPPING}              true
${TAB_WRAPPING_TEST_WIDTHS}        1280,1300,1366,1400,1440,1500,1520,1600
${TAB_WRAPPING_HEIGHT}             1024
```

This tests many breakpoints to find the exact point where wrapping starts/stops.

## Running Tests

### Main Test Suite (Multi-Site)

```bash
robot "Suites/Interface & Content Testing.robot"
```

This will test all sites from the spreadsheet and check tab wrapping at configured breakpoints.

### Unit Test (Single Site)

```bash
robot "Suites/test_header_with_config.robot"
```

This tests the single site defined in `UNITARY_PAGE_URL` variable.

### Custom Breakpoint Test

```bash
robot "Suites/test_detailed_breakpoints.robot"
```

This tests every 20px from 1280-1600px to find exact breaking points.

## Understanding Results

### Pass Example
```
>>> HEADER CHECK: Testing at 1600px
>>> HEADER CHECK: Found 10 visible navigation items
>>> HEADER CHECK: ✓ No tab wrapping detected
```

### Fail Example (Wrapping Detected)
```
>>> HEADER CHECK: Testing at 1366px
>>> HEADER CHECK: Found 10 visible navigation items
>>> HEADER CHECK: ✗ Tab wrapping detected (Y-diff: 80px)
[HEADER CHECK] Result: FAIL - Navigation tabs are wrapping/breaking into multiple lines
```

### Skip Example (Hamburger Menu)
```
>>> HEADER CHECK: Testing at 1280px
>>> HEADER CHECK: Found 0 visible navigation items
>>> HEADER CHECK: ℹ Skipping wrapping check - navigation may be hidden (hamburger menu)
```

## Troubleshooting

### Issue: Test is too slow
**Solution:** Reduce the number of test widths:
```robot
${TAB_WRAPPING_TEST_WIDTHS}    1366    # Test only one width
```

### Issue: False positives (reporting wrapping when there isn't any)
**Solution:** Increase the tolerance:
```robot
${TAB_WRAPPING_TOLERANCE}    10    # More lenient
```

### Issue: Not detecting wrapping that exists
**Solution:** Decrease the tolerance:
```robot
${TAB_WRAPPING_TOLERANCE}    3    # More strict
```

### Issue: Want to skip this check entirely
**Solution:** Disable it:
```robot
${CHECK_TAB_WRAPPING}    false
```

## Integration with CI/CD

To use in CI/CD pipelines:

1. Set `${HEADLESS}    true` in variables.robot for headless browser mode
2. Configure critical breakpoints only for faster execution:
   ```robot
   ${TAB_WRAPPING_TEST_WIDTHS}    1366,1440
   ```
3. The test will fail if wrapping is detected, preventing deployment of broken layouts

## Best Practices

1. **Test representative breakpoints:** Use widths that match your actual user traffic (check analytics)

2. **Include common resolutions:**
   - 1366x768 (Most common laptop)
   - 1440x900 (MacBook Air)
   - 1920x1080 (Full HD desktop)

3. **Test the "danger zone":** Based on our analysis, 1300-1520px is where wrapping typically occurs

4. **Keep tolerance reasonable:** 5px is usually sufficient to account for minor CSS variations

5. **Review failures visually:** When wrapping is detected, manually verify in a browser to ensure it's a real issue

## Technical Details

### JavaScript Implementation

The detection uses pure JavaScript to avoid Robot Framework WebElement serialization issues:

```javascript
// Gets all visible navigation items
const menuItems = Array.from(document.querySelectorAll('#menu-header-menu li, header nav a'));

// Filters to only visible elements
const visible = menuItems.filter(el => {
    const style = window.getComputedStyle(el);
    return style.display !== 'none' &&
           style.visibility !== 'hidden' &&
           el.offsetParent !== null;
});

// Checks Y-positions for wrapping
const firstY = visible[0].getBoundingClientRect().top;
for (let i = 1; i < visible.length; i++) {
    const y = visible[i].getBoundingClientRect().top;
    const diff = Math.abs(y - firstY);
    if (diff > tolerance) return {wrapping: true, diff: diff};
}
```

This approach is fast, reliable, and works across all browsers.
