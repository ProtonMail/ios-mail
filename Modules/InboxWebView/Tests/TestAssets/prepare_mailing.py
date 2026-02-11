#!/usr/bin/env python3
"""
The script only downloads assets based on URLs found in the HTML file.

Usage:
    ./prepare_mailing.py path/to/mailing-index.html mailing-name

This script will:
1. Parse the HTML to find all remote resources (images, CSS, JS, fonts)
2. Download all resources locally (using https:// URLs from the HTML file)
3. HTML processing (https:// -> proton-https:// with filenames only) is done by Swift's processedHTML function (this is temporary step, it will be part of exposed Rust function).

The mailing-name-index.html file should be added manually.
"""

import argparse
import hashlib
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse
import urllib.request

def extract_urls_from_html(html_content):
    """Extract all resource URLs from HTML."""
    urls = set()

    urls.update(re.findall(r'src=["\']([^"\']+)["\']', html_content))
    urls.update(re.findall(r'background=["\']([^"\']+)["\']', html_content))
    urls.update(re.findall(r'url\(["\']?([^"\')]+)["\']?\)', html_content))
    urls.update(re.findall(r'<link[^>]+rel=["\']stylesheet["\'][^>]+href=["\']([^"\']+)["\']', html_content, re.IGNORECASE))
    urls.update(re.findall(r'<link[^>]+href=["\']([^"\']+)["\'][^>]+rel=["\']stylesheet["\']', html_content, re.IGNORECASE))

    extensions = ('.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico', '.bmp',
                  '.css', '.js', '.woff', '.woff2', '.ttf', '.eot', '.otf')

    remote_urls = set()
    for url in urls:
        if url.startswith(('http://', 'https://')):
            url_path = url.split('?')[0]
            if any(url_path.lower().endswith(ext) for ext in extensions):
                remote_urls.add(url)

    return remote_urls

def get_filename_from_url(url):
    """Extract filename from URL."""
    filename = os.path.basename(urlparse(url).path)

    if not filename or '.' not in filename:
        url_hash = hashlib.md5(url.encode()).hexdigest()[:8]
        filename = f"resource_{url_hash}.dat"

    return filename

def download_resource(url, output_path):
    """Download a resource from URL to local path."""
    try:
        print(f"  {os.path.basename(output_path)}")

        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req, timeout=30) as response:
            data = response.read()

        with open(output_path, 'wb') as f:
            f.write(data)

        return True
    except Exception:
        print(f"  Failed: {os.path.basename(output_path)}")
        return False

def prepare_mailing(input_html_path, mailing_name):
    """Main function to prepare mailing for testing."""
    input_path = Path(input_html_path)
    
    if not input_path.exists():
        print(f"❌ Error: File not found: {input_html_path}")
        return False
    
    print(f"📖 Reading HTML from: {input_path}")
    with open(input_path, 'r', encoding='utf-8') as f:
        html_content = f.read()
    
    print("🔍 Extracting resource URLs...")
    resource_urls = extract_urls_from_html(html_content)
    print(f"   Found {len(resource_urls)} resources")
    
    script_dir = Path(__file__).parent
    output_dir = script_dir / "Mailings" / mailing_name
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"📁 Output directory: {output_dir}")
    
    print(f"⬇️  Downloading {len(resource_urls)} resources...")
    successful = 0
    
    for url in sorted(resource_urls):
        filename = get_filename_from_url(url)
        output_path = output_dir / filename
        
        if download_resource(url, output_path):
            successful += 1
    
    print(f"✅ Downloaded {successful}/{len(resource_urls)} resources")

    total_size = sum(f.stat().st_size for f in output_dir.glob('*') if f.is_file()) / 1024 / 1024
    print(f"\n✅ Done! {successful} resources ({total_size:.2f} MB)")

    return True

def main():
    parser = argparse.ArgumentParser(
        description='Download all assets from mailing HTML for offline snapshot testing',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example:
  ./prepare_mailing.py Mailings/google-dec-2025/google-dec-2025-index.html google-dec-2025
        """
    )
    parser.add_argument('html_file', help='Path to the mailing HTML file')
    parser.add_argument('mailing_name', help='Name for the mailing (e.g., google-dec-2025)')
    
    args = parser.parse_args()
    
    success = prepare_mailing(args.html_file, args.mailing_name)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
