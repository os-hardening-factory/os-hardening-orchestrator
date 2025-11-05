#!/bin/bash
set -e

echo "📦 Uploading metadata to S3..."

# Validate environment variables
: "${AWS_REGION:?AWS_REGION not set}"
: "${PROJECT:?PROJECT not set}"
: "${ENVIRONMENT:?ENVIRONMENT not set}"
: "${OS_NAME:?OS_NAME not set}"
: "${MANIFEST_PATH:?MANIFEST_PATH not set}"

echo "🔍 Using manifest file: ${MANIFEST_PATH}"

# Validate manifest exists
if [ ! -f "$MANIFEST_PATH" ]; then
  echo "❌ Manifest file not found at $MANIFEST_PATH"
  exit 1
fi

# Extract latest AMI info using jq
AMI_ID=$(jq -r '.builds[-1].artifact_id' "$MANIFEST_PATH" | awk -F':' '{print $2}')
AMI_NAME="${OS_NAME}-cis-${ENVIRONMENT}-$(date -u +"%Y%m%d-%H%M")"

if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "null" ]; then
  echo "⚠️  No AMI_ID found in manifest, setting to 'unknown'"
  AMI_ID="unknown"
fi

# Prepare metadata JSON
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TEMP_JSON="/tmp/${OS_NAME}-${ENVIRONMENT}-metadata.json"

cat <<EOF > "$TEMP_JSON"
{
  "AMI_ID": "${AMI_ID}",
  "Name": "${AMI_NAME}",
  "Project": "${PROJECT}",
  "Environment": "${ENVIRONMENT}",
  "OS": "${OS_NAME}",
  "Timestamp": "${TIMESTAMP}"
}
EOF

S3_BUCKET="cloud-secure-infra-${ENVIRONMENT}-image-metadata"
S3_KEY="${OS_NAME}/${OS_NAME}-${ENVIRONMENT}-$(date -u +"%Y%m%d-%H%M").json"
S3_PATH="s3://${S3_BUCKET}/${S3_KEY}"

echo "⬆️  Uploading metadata to: ${S3_PATH}"
aws s3 cp "$TEMP_JSON" "$S3_PATH" --region "$AWS_REGION"

echo "✅ Metadata uploaded successfully!"
