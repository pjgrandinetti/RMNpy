#!/usr/bin/env python3
"""Test script to verify GitHub release downloads work."""

import platform
import urllib.request
import ssl

def test_github_releases():
    """Test downloading from GitHub releases."""
    
    # Detect platform
    system = platform.system().lower()
    machine = platform.machine().lower()
    
    if system == "darwin":
        platform_suffix = "macos-latest.x64"
    elif system == "linux":
        if machine in ["aarch64", "arm64"]:
            platform_suffix = "ubuntu-latest.arm64"
        else:
            platform_suffix = "ubuntu-latest.x64"
    elif system == "windows":
        platform_suffix = "windows-latest.x64"
    else:
        print(f"Unsupported platform: {system}")
        return False
    
    print(f"Detected platform: {system} {machine} -> {platform_suffix}")
    
    # Test URLs
    test_urls = [
        f"https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.1/libOCTypes-libOCTypes-{platform_suffix}.zip",
        "https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.1/libOCTypes-headers.zip",
        f"https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/libSITypes-libSITypes-{platform_suffix.replace('.x64', '')}.zip",
        "https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/libSITypes-headers.zip",
    ]
    
    # Create SSL context
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE
    
    for url in test_urls:
        try:
            print(f"\nTesting: {url}")
            with urllib.request.urlopen(url, context=ssl_context) as response:
                size = len(response.read())
                print(f"  ✓ Success! Downloaded {size} bytes")
        except Exception as e:
            print(f"  ✗ Failed: {e}")
            
    return True

if __name__ == "__main__":
    test_github_releases()
