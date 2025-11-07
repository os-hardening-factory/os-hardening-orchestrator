# Metrics and Reporting

## Key Metrics
| Metric | Source | Purpose |
|---------|---------|----------|
| CIS Score | Lynis | Evaluate OS compliance |
| Critical CVEs | Trivy | Track highest severity |
| High CVEs | Trivy | Security trend |
| Compliance Status | Derived | COMPLIANT / NON-COMPLIANT |
| Build Date | GitHub Actions | Audit reference |
| Vendor | Workflow Env | Dashboard filter |

## Data Flow
1. Reports → S3 → Glue Crawler.
2. Glue Catalog → Athena DB.
3. Athena → OpenSearch Dashboards.

## Dashboard Panels
- **CIS Hardening Trend:** Avg `cis_score` over time.  
- **CVE Breakdown:** Pie chart by severity.  
- **Compliance Status:** Bar chart by vendor.  
- **Drilldown View:** Filter by date/version/vendor.
