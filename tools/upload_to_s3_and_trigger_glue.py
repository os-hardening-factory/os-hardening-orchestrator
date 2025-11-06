#!/usr/bin/env python3
import boto3, os, json, datetime

def upload_to_s3_and_trigger_glue(bucket, crawler, path="./reports", region="ap-south-1"):
    s3 = boto3.client("s3", region_name=region)
    glue = boto3.client("glue", region_name=region)
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S")

    uploaded_files = []
    for filename in os.listdir(path):
        if filename.endswith(".json"):
            file_path = os.path.join(path, filename)
            key = f"reports/raw/os/{filename.replace('.json','')}-{timestamp}.json"
            s3.upload_file(file_path, bucket, key)
            uploaded_files.append(key)
            print(f"✅ Uploaded {filename} → s3://{bucket}/{key}")

    if uploaded_files:
        try:
            glue.start_crawler(Name=crawler)
            print(f"🚀 Glue crawler '{crawler}' triggered successfully.")
        except glue.exceptions.CrawlerRunningException:
            print("⚙️  Crawler already running; skipping trigger.")
        except Exception as e:
            print(f"❌ Failed to trigger crawler: {e}")

if __name__ == "__main__":
    BUCKET = os.getenv("METADATA_BUCKET")
    CRAWLER = os.getenv("GLUE_CRAWLER_NAME")
    REGION = os.getenv("AWS_REGION", "ap-south-1")
    REPORTS_PATH = os.getenv("REPORTS_PATH", "./reports")

    if not BUCKET or not CRAWLER:
        raise Exception("❌ METADATA_BUCKET and GLUE_CRAWLER_NAME environment variables must be set.")

    upload_to_s3_and_trigger_glue(BUCKET, CRAWLER, REPORTS_PATH, REGION)
