# Sitemap URL Sampling

## Purpose
Extract and test random URL samples from dealership sitemaps by category.

## URL Sections
1. **pages** - General website pages (home, about, services)
2. **used_vehicles** - URLs containing "used"
3. **new_vehicles** - URLs containing "new" (or default for /vehicle/)
4. **showroom** - URLs containing "/showroom/"
5. **models** - URLs containing "/models/"
6. **model_trims** - URLs containing "/model-trims/"

## Parameters (all with `_samples` suffix)

| Parameter | Default | Behavior |
|-----------|---------|----------|
| `pages_samples` | None | None=ALL pages, N=random N pages |
| `used_vehicle_samples` | 1 | Test N random used vehicles |
| `new_vehicle_samples` | 1 | Test N random new vehicles |
| `showroom_samples` | 1 | Test N showroom pages |
| `models_samples` | 1 | Test N model pages |
| `model_trims_samples` | 1 | Test N trim pages |

## Usage

### Test Suite
```robot
Parse Sitemap URLs
    ...    Validate Contact Links Matches It HREF
    ...    pages_samples=2
    ...    used_vehicle_samples=1
    ...    new_vehicle_samples=1
    ...    showroom_samples=1
    ...    models_samples=1
    ...    model_trims_samples=1
```

### Direct Keyword
```robot
@{test_urls}=    Get Test URLs From Sitemap
    ...    ${sitemap_source}
    ...    pages_samples=None    # ALL pages
    ...    used_vehicle_samples=3
    ...    models_samples=0      # Skip models
```

## Console Output
```
Found 25 URLs (p=2 uv=1 nv=1 s=1 m=1 mt=1)
```
Legend: p=pages, uv=used_vehicles, nv=new_vehicles, s=showroom, m=models, mt=model_trims

## Files
- **Parser**: `Parser/sitemap_parser.robot`
  - `Extract Sitemap Sections` - Categorizes URLs
  - `Get Test URLs From Sitemap` - Returns samples
- **Multi-Site**: `Resources/Integrated Tests/multi_site_testing.robot`
  - `Parse Sitemap URLs` - Main entry point

## Sample Configurations

**Quick Test**:
```robot
pages_samples=1, used_vehicle_samples=1, new_vehicle_samples=1
models_samples=0, model_trims_samples=0
```

**Standard Test**:
```robot
pages_samples=3, used_vehicle_samples=2, new_vehicle_samples=2
showroom_samples=1, models_samples=1, model_trims_samples=1
```

**Comprehensive**:
```robot
pages_samples=None  # ALL pages
used_vehicle_samples=5, new_vehicle_samples=5
showroom_samples=2, models_samples=3, model_trims_samples=2
```

## Notes
- If section has fewer URLs than requested, all available URLs are tested
- Set sample to 0 to skip a section
- Vehicle detection uses substring matching for "used"/"new"
