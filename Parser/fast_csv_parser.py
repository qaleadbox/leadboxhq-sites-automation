"""
Fast CSV Parser using Python's built-in csv module
Much faster than Robot Framework's string operations
"""

import csv
import re


class FastCSVParser:
    """Efficient CSV parsing for site data"""

    @staticmethod
    def parse_sites_from_csv(csv_path):
        """
        Parses CSV file and returns list of site dictionaries
        Skips summary rows and finds the header row automatically
        Args:
            csv_path: Path to CSV file
        Returns:
            List of dictionaries with keys: name, url, version, status, theme
        """
        sites = []

        with open(csv_path, 'r', encoding='utf-8') as f:
            # Read all lines
            lines = f.readlines()

            # Find the header row (contains "Dealer Name")
            header_index = None
            for i, line in enumerate(lines):
                if 'Dealer Name' in line:
                    header_index = i
                    break

            if header_index is None:
                return sites  # No header found

            # Create DictReader starting from header row
            from io import StringIO
            csv_content = ''.join(lines[header_index:])
            reader = csv.DictReader(StringIO(csv_content))

            for row in reader:
                # Get values with default empty strings
                name = row.get('Dealer Name', '').strip()
                url = row.get('URL', '').strip()
                version = row.get('Website Version', '').strip()
                status = row.get('Status', '').strip()
                theme = row.get('Theme', '').strip()

                # Validate URL format
                if url and re.match(r'^https?://', url):
                    site = {
                        'name': name,
                        'url': url,
                        'version': version,
                        'status': status,
                        'theme': theme
                    }
                    sites.append(site)

        return sites

    @staticmethod
    def get_urls_from_sites(sites):
        """
        Extracts just the URLs from a list of site dictionaries
        Args:
            sites: List of site dictionaries
        Returns:
            List of URLs
        """
        return [site['url'] for site in sites if site.get('url')]

    @staticmethod
    def filter_sites_by_status(sites, status):
        """
        Filters sites by status
        Args:
            sites: List of site dictionaries
            status: Status to filter by (e.g., "Published")
        Returns:
            Filtered list of sites
        """
        return [site for site in sites if site.get('status') == status]

    @staticmethod
    def filter_sites_by_version(sites, version):
        """
        Filters sites by version
        Args:
            sites: List of site dictionaries
            version: Version to filter by (e.g., "V5", "V6")
        Returns:
            Filtered list of sites
        """
        return [site for site in sites if site.get('version') == version]
