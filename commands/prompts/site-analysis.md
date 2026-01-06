# Site Analysis Pre-Prompt

## Context
This is the LeadBox Sites Automation project. We analyze IMS/Concesionary dealership websites to create comprehensive test suites.

## Variables
- `{{SITE_URL}}`: Target dealership website URL
- `{{DEALERSHIP_NAME}}`: Name of the dealership
- `{{FOCUS_AREAS}}`: Specific areas to analyze (e.g., "Contact info", "Inventory", "Forms")

## Prompt Template

```
Analyze a new IMS/Concesionary dealership website for automated testing.

Site URL: {{SITE_URL}}
Dealership: {{DEALERSHIP_NAME}}
Focus Areas: {{FOCUS_AREAS}}

Analysis Objectives:
1. Identify all testable elements and features
2. Map contact information locations (phone, email, address)
3. Find all forms and submission flows
4. Catalog navigation structure
5. Locate social media links
6. Identify dynamic content areas
7. Note any accessibility concerns

Common Dealership Website Patterns:
- Header: Logo, navigation, phone, hours
- Hero Section: Main CTA, inventory search
- Inventory: Vehicle listings, filters, details
- About: Dealership info, history, team
- Contact: Form, map, address, phone, hours, directions
- Footer: Quick links, social media, legal, contact info

What to Look For:
1. Contact Information:
   - Phone numbers (sales, service, parts)
   - Email addresses
   - Physical address with postal code
   - Business hours
   - Department-specific contacts

2. Links and Navigation:
   - All clickable elements
   - External vs internal links
   - Social media links
   - CTA buttons
   - Navigation menus (main, mobile, footer)

3. Forms:
   - Contact forms
   - Service appointment forms
   - Test drive forms
   - Trade-in valuation forms
   - Finance application forms

4. Accessibility:
   - Non-clickable labels
   - Alt text for images
   - ARIA labels
   - Keyboard navigation

Deliverables:
1. Comprehensive element inventory
2. Test priority recommendations
3. Potential issues identified
4. Suggested test suite structure
5. Updated variables.robot with new BASE_URL
6. Initial test cases to implement

Please provide:
1. Site structure overview
2. Element categorization
3. Testing recommendations
4. Risk areas to watch
```

## Example Usage
Replace variables:
- SITE_URL: "https://newdealership.com"
- DEALERSHIP_NAME: "New Motors Ltd"
- FOCUS_AREAS: "Contact information, Service forms, Social media"
