import os, datetime, argparse
from github import Github

parser = argparse.ArgumentParser()
parser.add_argument("--vendor", required=True)
parser.add_argument("--cis_profile", required=True)
parser.add_argument("--version", required=True)
parser.add_argument("--build_date", required=True)
parser.add_argument("--summary", required=True)
args = parser.parse_args()

ORG = "os-hardening-factory"
REPO = f"os-hardening-{args.vendor}"
TOKEN = os.getenv("GITHUB_TOKEN")
ACCOUNT = "661539128717"
REGION = "ap-south-1"

if not TOKEN:
    raise SystemExit("❌ Missing GitHub Token (PERSONAL_ACCESS_TOKEN not set)")

gh = Github(TOKEN)
repo = gh.get_repo(f"{ORG}/{REPO}")

commit = os.getenv("GITHUB_SHA", "manual")[:7]
ecr_image = f"{ACCOUNT}.dkr.ecr.{REGION}.amazonaws.com/hardened-{args.vendor}:{args.version}-{args.cis_profile}-{args.build_date}-{commit}"

entry = f"""
## [{args.version}-{args.cis_profile}-{args.build_date}] - {datetime.date.today()}
- CIS Benchmark: {args.cis_profile}
- ECR Image: `{ecr_image}`
- Summary: {args.summary}
"""

try:
    contents = repo.get_contents("CHANGELOG.md", ref="main")
    new_content = entry + "\n" + contents.decoded_content.decode()
    repo.update_file(contents.path, f"Update changelog for {args.vendor}", new_content, contents.sha)
    print(f"✅ Updated CHANGELOG.md in {REPO}")
except Exception as e:
    print(f"⚠️ Skipped changelog update: {e}")

repo.create_git_release(
    tag=f"{args.version}-{args.cis_profile}-{args.build_date}",
    name=f"{args.vendor.title()} Hardened Image {args.version}",
    message=f"""
# {args.vendor.title()} Hardened Image Release

**CIS Profile:** {args.cis_profile}  
**Version:** {args.version}  
**ECR Image:** {ecr_image}  
**Date:** {args.build_date}

Summary: {args.summary}
""",
)
print(f"🚀 Published release for {args.vendor}")
