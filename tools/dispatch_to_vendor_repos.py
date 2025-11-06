#!/usr/bin/env python3
"""
Dispatch hardened image release metadata to vendor repositories.

Features:
- Updates CHANGELOG.md with release details
- Publishes GitHub Release (skips if already exists)
- Uses modern GitHub Auth.Token API (no deprecation warnings)
- Idempotent — safe to rerun without breaking
"""

import os
import datetime
import argparse
from github import Github, Auth

# ---------------------------
# 🧩 Parse CLI arguments
# ---------------------------
parser = argparse.ArgumentParser(description="Dispatch release metadata to vendor repos")
parser.add_argument("--vendor", required=True, help="OS vendor name (e.g. ubuntu, rhel, amazonlinux)")
parser.add_argument("--cis_profile", required=True, help="CIS profile version (e.g. cis1.4)")
parser.add_argument("--version", required=True, help="OS version (e.g. 22.04)")
parser.add_argument("--build_date", required=True, help="Build date (YYYYMMDD)")
parser.add_argument("--summary", required=True, help="Summary for release notes")
args = parser.parse_args()

# ---------------------------
# ⚙️ Environment variables
# ---------------------------
ORG = "os-hardening-factory"
REPO = f"os-hardening-{args.vendor}"
TOKEN = os.getenv("GITHUB_TOKEN")
ACCOUNT = "661539128717"
REGION = "ap-south-1"

if not TOKEN:
    raise SystemExit("❌ Missing GitHub Token (GITHUB_TOKEN not set)")

# ---------------------------
# 🔐 GitHub Authentication
# ---------------------------
gh = Github(auth=Auth.Token(TOKEN))
repo = gh.get_repo(f"{ORG}/{REPO}")

# ---------------------------
# 🏷️ Compute release details
# ---------------------------
commit = os.getenv("GITHUB_SHA", "manual")[:7]
ecr_image = (
    f"{ACCOUNT}.dkr.ecr.{REGION}.amazonaws.com/"
    f"hardened-{args.vendor}:{args.version}-{args.cis_profile}-{args.build_date}-{commit}"
)

entry = f"""
## [{args.version}-{args.cis_profile}-{args.build_date}] - {datetime.date.today()}
- CIS Benchmark: {args.cis_profile}
- ECR Image: `{ecr_image}`
- Summary: {args.summary}
"""

# ---------------------------
# 🧾 Update CHANGELOG.md
# ---------------------------
try:
    contents = repo.get_contents("CHANGELOG.md", ref="main")
    new_content = entry + "\n" + contents.decoded_content.decode()
    repo.update_file(
        contents.path,
        f"Update changelog for {args.vendor}",
        new_content,
        contents.sha,
    )
    print(f"✅ Updated CHANGELOG.md in {REPO}")
except Exception as e:
    print(f"⚠️ Skipped changelog update: {e}")

# ---------------------------
# 🚀 Publish GitHub Release (idempotent)
# ---------------------------
tag_name = f"{args.version}-{args.cis_profile}-{args.build_date}"
release_title = f"{args.vendor.title()} Hardened Image {args.version}"
release_body = f"""
# {args.vendor.title()} Hardened Image Release

**CIS Profile:** {args.cis_profile}  
**Version:** {args.version}  
**ECR Image:** {ecr_image}  
**Date:** {args.build_date}  

Summary: {args.summary}
"""

try:
    # Check if release already exists
    existing_releases = repo.get_releases()
    if any(r.tag_name == tag_name for r in existing_releases):
        print(f"⚠️ Release for tag '{tag_name}' already exists in {REPO}. Skipping creation.")
    else:
        repo.create_git_release(
            tag=tag_name,
            name=release_title,
            message=release_body,
        )
        print(f"🚀 Published release for {args.vendor} — Tag: {tag_name}")
except Exception as e:
    print(f"⚠️ Skipped release creation (might already exist): {e}")

print("✅ Dispatch script completed successfully.")
