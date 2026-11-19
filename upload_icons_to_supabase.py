#!/usr/bin/env python3
"""
Uploads all icons in supabase_icons/ to Supabase Storage in one go.

Usage:
  export SUPABASE_URL="https://<your-project-id>.supabase.co"
  export SUPABASE_SERVICE_KEY="<your-service-role-key-or-admin-key>"
  python3 upload_icons_to_supabase.py

Or pass them interactively when prompted.
"""

import os
import sys
import glob
import mimetypes
import urllib.request
import urllib.error

BUCKET_NAME = "service-images"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ICONS_DIR = os.path.join(BASE_DIR, "supabase_icons")


def get_credentials():
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_KEY", "").strip() or os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip() or os.environ.get("SUPABASE_ANON_KEY", "").strip()

    if not url:
        url = input("Enter your Supabase URL (e.g. https://xyz.supabase.co): ").strip().rstrip("/")
    if not key:
        key = input("Enter your Supabase Service Role Key (or Admin Key): ").strip()

    if not url or not key:
        print("Error: Supabase URL and Key are required.")
        sys.exit(1)

    return url, key


def upload_file(supabase_url, api_key, local_path, storage_path):
    mime_type, _ = mimetypes.guess_type(local_path)
    mime_type = mime_type or "image/png"

    endpoint = f"{supabase_url}/storage/v1/object/{BUCKET_NAME}/{storage_path}"

    with open(local_path, "rb") as f:
        file_bytes = f.read()

    req = urllib.request.Request(
        endpoint,
        data=file_bytes,
        headers={
            "Authorization": f"Bearer {api_key}",
            "apikey": api_key,
            "Content-Type": mime_type,
            "x-upsert": "true",  # Overwrite if exists
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            return True, None
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8", errors="ignore")
        return False, f"HTTP {e.code}: {err_msg}"
    except Exception as e:
        return False, str(e)


def main():
    if not os.path.isdir(ICONS_DIR):
        print(f"Error: Directory not found: {ICONS_DIR}")
        sys.exit(1)

    print("==================================================")
    print(" ALLCURO — Supabase Bulk Icon Uploader")
    print(f" Target Bucket: '{BUCKET_NAME}'")
    print("==================================================")

    url, key = get_credentials()

    # Find all PNGs in categories/ and services/
    pattern = os.path.join(ICONS_DIR, "**", "*.png")
    all_files = sorted(glob.glob(pattern, recursive=True))

    if not all_files:
        print(f"No PNG files found in {ICONS_DIR}")
        sys.exit(0)

    print(f"\nFound {len(all_files)} icons to upload...\n")

    success_count = 0
    fail_count = 0

    for idx, filepath in enumerate(all_files, 1):
        rel_path = os.path.relpath(filepath, ICONS_DIR)
        print(f"[{idx}/{len(all_files)}] Uploading {rel_path}...", end=" ", flush=True)

        ok, err = upload_file(url, key, filepath, rel_path)
        if ok:
            print("OK")
            success_count += 1
        else:
            print(f"FAILED ({err})")
            fail_count += 1

    print("\n--------------------------------------------------")
    print(f"Upload Complete: {success_count} succeeded, {fail_count} failed.")
    print(f"Public Base URL:")
    print(f"  {url}/storage/v1/object/public/{BUCKET_NAME}/<category_or_service>/<name>.png")
    print("--------------------------------------------------")


if __name__ == "__main__":
    main()
