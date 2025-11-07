#!/usr/bin/env python3
import boto3
import os
import sys
import argparse
import datetime

# ──────────────────────────────────────────────
# Parse command-line arguments
# ──────────────────────────────────────────────
parser = argparse.ArgumentParser(description="Upload compliance reports to S3 and trigger Glue crawler.")
parser.add_argument("--bucket", required=True, help="S3 bucket name")
parser.add_argument("--region", required=True, help="AWS region")
parser.add_argument("--os", required=True, help="Operating system (ubuntu/rhel/amazonlinux)")
parser.add_argument("--build_date", required=True, help="Build date (YYYYMMDD)")
args = parser.parse_args()

BUCKET = args.bucket
REGION = args.region
OS_NAME = args.os
BUILD_DATE = args.build_date
REPORTS_PATH = "./reports"
CRAWLER = "cloud-secure-infra-dev-compliance-crawler"

# ──────────────────────────────────────────────
# Initialize clients
# ──────────────────────────────────────────────
s3 = boto3.client("s3", region_name=REGION)
glue = boto3.client("glue", region_name=REGION)

print(f"🧾 Using bucket: {BUCKET}")
print(f"🧩 OS: {OS_NAME}")
print(f"📅 Build date: {BUILD_DATE}")
print(f"📂 Local path: {REPORTS_PATH}")

# ──────────────────────────────────────────────
# Upload all report files (JSON/TXT/XML)
# ──────────────────────────────────────────────
uploaded = 0
timestamp = datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S")

for root, _, files in os.walk(REPORTS_PATH):
    for f in files:
        if f.endswith((".json", ".txt", ".xml")):
            file_path = os.path.join(root, f)
            # Structured S3 key: <os>/<date>/<filename>
            key = f"{OS_NAME}/{BUILD_DATE}/{f}"
            print(f"📤 Uploading {file_path} → s3://{BUCKET}/{key}")
            s3.upload_file(file_path, BUCKET, key)
            uploaded += 1

if uploaded == 0:
    print("⚠️ No report files found in ./reports — nothing to upload.")
else:
    print(f"✅ Uploaded {uploaded} report file(s) to s3://{BUCKET}/{OS_NAME}/{BUILD_DATE}/")

# ──────────────────────────────────────────────
# Trigger Glue Crawler
# ──────────────────────────────────────────────
try:
    print(f"🚀 Triggering Glue Crawler: {CRAWLER}")
    glue.start_crawler(Name=CRAWLER)
    print("✅ Glue crawler triggered successfully.")
except Exception as e:
    print(f"❌ Failed to trigger Glue Crawler: {e}")
    sys.exit(1)
