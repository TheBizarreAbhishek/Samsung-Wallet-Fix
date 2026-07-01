#!/usr/bin/env python3
"""
Samsung Pay Mini version checker & APK fetcher.
Used by GitHub Actions workflow to check for updates from Samsung servers.
"""

import re
import sys
import os
import requests

SAMSUNG_API = (
    "https://vas.samsungapps.com/stub/stubDownload.as"
    "?appId=com.samsung.android.spaymini"
    "&deviceId=SM-M325F"
    "&mcc=404&mnc=20&csc=INS"
    "&sdkVer=30&pd=0"
    "&systemId=1608665720954"
    "&callerId=com.sec.android.app.samsungapps"
    "&abiType=64&extuk=0191d6627f38685f"
)

def main():
    print("Querying Samsung Galaxy Store API...")
    try:
        resp = requests.get(SAMSUNG_API, timeout=15).text
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    rc = re.search(r"<resultCode>(\d+)</resultCode>", resp)
    if not rc or rc.group(1) != "1":
        msg = re.search(r"<resultMsg>([^<]+)</resultMsg>", resp)
        print(f"Samsung API Error: {msg.group(1) if msg else 'Unknown'}")
        sys.exit(1)

    uri = re.search(r"downloadURI><!\[CDATA\[([^\]]+)\]\]>", resp).group(1)
    vc  = re.search(r"<versionCode>(\d+)</versionCode>", resp).group(1)
    vn  = re.search(r"<versionName>([^<]+)</versionName>", resp).group(1)
    sz  = re.search(r"<contentSize>(\d+)</contentSize>", resp).group(1)

    print(f"Found: Samsung Pay Mini v{vn} (code: {vc}), size: {int(sz)//(1024*1024)} MB")

    # Write to GitHub Actions output
    github_output = os.environ.get("GITHUB_OUTPUT", "")
    if github_output:
        with open(github_output, "a") as f:
            f.write(f"version_code={vc}\n")
            f.write(f"version_name={vn}\n")
            f.write(f"download_url={uri}\n")
            f.write(f"apk_filename=com.samsung.android.spaymini-{vn}.apk\n")
    else:
        # Local run - print to stdout
        print(f"version_code={vc}")
        print(f"version_name={vn}")
        print(f"download_url={uri}")

if __name__ == "__main__":
    main()
