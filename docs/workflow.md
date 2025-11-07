# OS Hardening Factory Workflow

## 1. Trigger
- Manual `workflow_dispatch` in GitHub Actions.
- Each OS (Ubuntu, RHEL, AmazonLinux) has its own workflow file.

## 2. Build Phase
- Checkout repository → Initialize Packer → Validate templates.
- Packer runs with Ansible provisioner → applies CIS baseline roles.

## 3. Scan Phase
- Trivy performs container-level CVE scan.
- Lynis audits system compliance → outputs hardening index.

## 4. Artifact & Versioning
- Immutable tagging based on date + commit + OS metadata.
- Enterprise tag pattern: `<os>-<version>-intuit-<iteration>`.

## 5. Distribution
- Image pushed to AWS ECR.
- Compliance reports (Trivy + Lynis) uploaded to S3 → triggers Glue Crawler.

## 6. Promotion
- `promote-image.yml` handles image promotion with security gating:
  - Blocks if `CRITICAL/HIGH` CVEs exist.
  - Signs verified images using AWS KMS via Cosign.

## 7. Reporting
- S3 → Glue → Athena → OpenSearch → Dashboard.
- Compliance record fields: `vendor`, `os`, `version`, `cis_score`, `critical_cves`, `status`, `timestamp`.
