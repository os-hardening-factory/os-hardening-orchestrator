#!/usr/bin/env python3
import boto3, json, os
from datetime import datetime
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

region = "ap-south-1"
service = "es"
endpoint = os.getenv("OPENSEARCH_ENDPOINT")

credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    service,
    session_token=credentials.token
)

client = OpenSearch(
    hosts=[{"host": endpoint.replace("https://", ""), "port": 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

file_path = "reports/compliance-summary.json"
if not os.path.exists(file_path):
    raise FileNotFoundError(f"{file_path} not found")

with open(file_path) as f:
    doc = json.load(f)

doc["timestamp"] = datetime.utcnow().isoformat()
index = "os-compliance-summary"

resp = client.index(index=index, body=doc)
print(f"✅ Indexed compliance summary into {index}: {resp['_id']}")
