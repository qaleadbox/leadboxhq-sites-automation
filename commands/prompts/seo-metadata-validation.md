# SEO Metadata Validation

## Purpose
Validate SEO metadata and text in the head tag, including title and meta tags, to ensure proper formatting and consistency.

## Validation Requirements

### 1. Capitalization Validation
- Verify that all text in `<title>` and `<meta>` tags are properly capitalized
- Use sitemap data to check expected capitalization patterns
- Check meta tags: `name="description"`, `property="og:title"`, `property="og:description"`, etc.

### 2. Template Variable Detection
- Verify that there are NO occurrences of `%%` in any metadata
- `%%` indicates unprocessed template variables like `%%sitename%%` or `%%sitedesc%%`
- Check in:
  - `<title>` tag content
  - All `<meta>` tag content attributes
  - Meta tags with `property` attributes (Open Graph)
  - Meta tags with `name` attributes (standard meta)

### 3. Open Graph Site Name Consistency
- Extract the page title from `<title>` tag
- Extract `og:site_name` value from `<meta property="og:site_name">`
- Verify that `og:site_name` matches the second part of the page title after "%%sitedesc%%"
- Example: If title is "Page Name | Site Name", then `og:site_name` should be "Site Name"

### 4. Sitemap Site Name Consistency
- When the sitemap page is loaded, capture the site name from its title tag
- Store this as the expected reference site name for all pages
- For each page tested, compare its site name (from title tag) with the sitemap reference
- Ensures all pages use the same consistent site name across the entire site

## Implementation Location

### Files
- **Resources/Validations/seo_metadata.robot**
  - `Validate SEO Metadata` - Multi-validation (fails on error)
  - `Validate SEO Metadata Comprehensive` - Standalone (returns dict)
  - `Check Title Tag Capitalization` - Validates title capitalization
  - `Check Meta Tags For Template Variables` - Checks for %% occurrences
  - `Validate OG Site Name Matches Title` - Validates og:site_name consistency
  - `Set Expected Site Name From Current Page` - Captures reference site name from sitemap
  - `Validate Site Name Matches Expected` - Compares page site name with sitemap reference

## Validation Checks

1. **Capitalization**: All metadata text properly capitalized
2. **Template Variables**: No `%%` found in any metadata
3. **OG Consistency**: `og:site_name` matches the site portion of page title
4. **Sitemap Consistency**: Page site name matches the reference site name from sitemap

## Pass/Fail Criteria

### PASS
- All metadata is properly capitalized
- No `%%` template variables found
- `og:site_name` matches the second part of title (after separator)
- Page site name matches the sitemap reference site name

### FAIL
- Improper capitalization detected
- Found `%%` in any metadata field
- `og:site_name` does not match title site name
- Page site name does not match sitemap reference
- Missing required meta tags

## Usage

### Standalone Test
```robot
${result}=    Validate SEO Metadata Comprehensive
${status}=    Get From Dictionary    ${result}    status
Log To Console    Status: ${status}
```

### Multi-Validation Pattern
```robot
Parse Sitemap URLs
    ...    Validate SEO Metadata
    ...    Validate Favicons
    ...    pages_samples=None
```

## Expected Metadata Structure

```html
<head>
    <title>Page Name | Site Name</title>
    <meta name="description" content="Page description here">
    <meta property="og:title" content="Page Name">
    <meta property="og:description" content="Page description here">
    <meta property="og:site_name" content="Site Name">
    <meta property="og:url" content="https://example.com/page">
    <meta property="og:image" content="https://example.com/image.jpg">
</head>
```

## Common Issues

### Template Variables Not Processed
- **Issue**: `%%sitename%%` or `%%sitedesc%%` appears in metadata
- **Fix**: Ensure template processing is working correctly

### Capitalization Mismatch
- **Issue**: Title case not applied consistently
- **Fix**: Verify CMS capitalization settings

### og:site_name Mismatch
- **Issue**: Site name in title differs from og:site_name
- **Fix**: Ensure both use the same source value

### Sitemap Site Name Mismatch
- **Issue**: Page site name differs from the reference captured from sitemap
- **Fix**: Ensure all pages use consistent site name across the entire site
- **Note**: The reference site name is captured from the sitemap page title on first load
