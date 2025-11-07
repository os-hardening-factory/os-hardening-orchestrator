import os
import json
from datetime import datetime, timezone
from opensearchpy import OpenSearch, exceptions

# =========================================================
# CONFIGURATION
# =========================================================
OPENSEARCH_URL = os.getenv(
    "OPENSEARCH_URL",
    "https://search-infraos-dev-wsa2t3ill565rhqbgrw4gmk6zu.ap-south-1.es.amazonaws.com"
)
INDEX = "os-compliance-summary"
USERNAME = os.getenv("OS_USERNAME", "admin")
PASSWORD = os.getenv("OS_PASSWORD", "SecurePass#2025!")

# =========================================================
# METADATA (INJECTED FROM GITHUB ACTIONS ENV)
# =========================================================
vendor = os.getenv("OS_NAME", "unknown").lower()           # ubuntu, rhel, amazonlinux
os_version = os.getenv("OS_VERSION", "unknown")
cis_version = os.getenv("CIS_VERSION", "unknown")
build_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
build_id = os.getenv("GITHUB_RUN_ID", "local-test")
commit = os.getenv("GITHUB_SHA", "manual")
status = os.getenv("STATUS", "COMPLIANT")
critical_cves = int(os.getenv("CRITICAL_CVES", 0))
high_cves = int(os.getenv("HIGH_CVES", 0))
cis_score = int(os.getenv("CIS_SCORE", 85))

# =========================================================
# PREPARE DOCUMENT
# =========================================================
doc = {
    "vendor": vendor,
    "os": vendor,  # keep 'os' for backward compatibility
    "version": os_version,
    "cis_version": cis_version,
    "build_date": build_date,
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "status": status,
    "cis_score": cis_score,
    "critical_cves": critical_cves,
    "high_cves": high_cves,
    "build_id": build_id,
    "commit": commit,
}

# =========================================================
# CONNECT TO OPENSEARCH
# =========================================================
try:
    client = OpenSearch(
        hosts=[OPENSEARCH_URL],
        http_auth=(USERNAME, PASSWORD),
        use_ssl=True,
        verify_certs=False,
        ssl_show_warn=False
    )
    print(f"✅ Connected to OpenSearch at {OPENSEARCH_URL}")
except Exception as e:
    print(f"❌ Failed to connect to OpenSearch: {e}")
    exit(1)

# =========================================================
# PUSH DOCUMENT
# =========================================================
try:
    doc_id = f"{vendor}-{build_id}"
    resp = client.index(index=INDEX, id=doc_id, body=doc)
    print(f"✅ Pushed compliance summary for vendor: {vendor}, build: {build_id}")
    print(json.dumps(resp, indent=2))
except exceptions.AuthorizationException:
    print("❌ Authorization error — check OpenSearch credentials or index permissions.")
    exit(1)
except Exception as e:
    print(f"❌ Failed to index document: {e}")
    exit(1)

# =========================================================
# VERIFY INGESTION
# =========================================================
try:
    query = {"query": {"term": {"build_id": build_id}}}
    verify = client.search(index=INDEX, body=query)
    hits = verify["hits"]["total"]["value"]
    if hits > 0:
        print(f"🔍 Verification: document successfully indexed (hits={hits})")
    else:
        print("⚠️ Verification: document not found after indexing.")
except Exception as e:
    print(f"⚠️ Verification step failed: {e}")
