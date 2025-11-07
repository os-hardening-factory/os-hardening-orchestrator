# Design Assumptions

1. **AWS Environment**
   - All components (ECR, S3, Glue, OpenSearch) are in `ap-south-1`.
   - IAM role `GitHubActionsFactoryRole` has OIDC trust & limited permissions.

2. **Security Baselines**
   - CIS Benchmarks per OS version.
   - Hardened base images: Ubuntu 22.04, RHEL 9, Amazon Linux 2.

3. **Automation Tools**
   - Packer for image builds. Ansible for CIS enforcement.
   - Trivy for CVE scan, Lynis for CIS score.

4. **Report Storage**
   - Stored in `cloud-secure-infra-dev-image-metadata-ap-south-1` bucket.
   - Glue crawler parses `reports/raw/os/`.

5. **Image Governance**
   - ECR images immutable + signed via KMS `alias/cosign-signing`.
   - Promotion only after security gate pass.

6. **Reporting Stack**
   - OpenSearch for dashboards, Athena for queries.

7. **Future Work**
   - Dynamic CIS score integration. Automated remediation. Container hardening.
