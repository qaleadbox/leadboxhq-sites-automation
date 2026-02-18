*** Settings ***
Documentation    CSV Parser - Fast CSV parsing using Python
Library    OperatingSystem
Library    String
Library    Collections

*** Keywords ***
Parse Sites From CSV
    [Documentation]    Parses CSV file and returns list of site dictionaries (FAST Python version)
    ...                Each site dict contains: name, url, version, status, etc.
    [Arguments]    ${csv_path}

    # Add Parser directory to Python path and call the function
    @{sites}=    Evaluate    sys.path.insert(0, r'${EXECDIR}/Parser') or __import__('fast_csv_parser').FastCSVParser.parse_sites_from_csv(r'${csv_path}')    sys
    RETURN    @{sites}

Get URLs From Sites
    [Documentation]    Extracts just the URLs from a list of site dictionaries (FAST Python version)
    [Arguments]    @{sites}
    @{urls}=    Evaluate    sys.path.insert(0, r'${EXECDIR}/Parser') or __import__('fast_csv_parser').FastCSVParser.get_urls_from_sites(${sites})    sys
    RETURN    @{urls}

Filter Sites By Status
    [Documentation]    Filters sites by status (FAST Python version)
    [Arguments]    ${status}    @{sites}
    @{filtered}=    Evaluate    sys.path.insert(0, r'${EXECDIR}/Parser') or __import__('fast_csv_parser').FastCSVParser.filter_sites_by_status(${sites}, '${status}')    sys
    RETURN    @{filtered}

Filter Sites By Version
    [Documentation]    Filters sites by version (FAST Python version)
    [Arguments]    ${version}    @{sites}
    @{filtered}=    Evaluate    sys.path.insert(0, r'${EXECDIR}/Parser') or __import__('fast_csv_parser').FastCSVParser.filter_sites_by_version(${sites}, '${version}')    sys
    RETURN    @{filtered}
