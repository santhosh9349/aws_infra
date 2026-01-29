# Research: Terraform Drift Detection Workflow

**Feature Branch**: `002-drift-detection-workflow`  
**Date**: 2026-01-28  
**Status**: Complete

## Research Questions

### Q1: How to configure OIDC authentication between GitHub Actions and AWS?

**Decision**: Use `aws-actions/configure-aws-credentials@v5` with OIDC role assumption

**Rationale**: OIDC eliminates long-lived credentials stored in GitHub Secrets. AWS creates short-lived session credentials (1 hour default) that are automatically rotated per workflow run. This aligns with AWS security best practices.

**Implementation Requirements**:
1. Create IAM OIDC Identity Provider for `token.actions.githubusercontent.com`
2. Create IAM Role with trust policy scoped to this repository
3. Add `id-token: write` permission to workflow
4. Use `role-to-assume` parameter instead of access keys

**Trust Policy Example**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::017373135945:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:OWNER/aws_infra:*"
      }
    }
  }]
}
```

**Alternatives Considered**:
- Static IAM credentials in GitHub Secrets: Rejected - long-lived credentials violate security best practices
- AWS Access Key rotation via Secrets Manager: Rejected - adds complexity, OIDC is native to GitHub

---

### Q2: How does `terraform plan -detailed-exitcode` work and how to parse output?

**Decision**: Use exit code 2 to detect drift, `terraform show -json` for structured parsing

**Rationale**: The `-detailed-exitcode` flag provides clear signals: 0=no changes, 1=error, 2=changes detected. JSON output via `terraform show -json` provides machine-parseable structure with exact resource addresses and change actions.

**Exit Code Semantics**:
| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | No changes (infrastructure matches state) | No notification |
| 1 | Error during planning | Alert on error |
| 2 | Changes detected (drift) | Create issue + notify |

**JSON Parsing Strategy**:
```bash
# Extract changed resources from plan JSON
jq -r '.resource_changes[] | 
  select(.change.actions != ["no-op"]) | 
  "\(.address)|\(.change.actions | join(","))|\(.type)"' plan.json
```

**Key JSON Fields**:
- `resource_changes[].address`: Full resource path (e.g., `module.vpc.aws_vpc.main`)
- `resource_changes[].change.actions`: Array of actions (`["update"]`, `["delete"]`, etc.)
- `resource_changes[].type`: AWS resource type (e.g., `aws_vpc`)
- `resource_drift[]`: Resources that changed outside Terraform

**Alternatives Considered**:
- Parse text output with regex: Rejected - fragile, format may change between Terraform versions
- Use `terraform-json` Go library: Rejected - adds build complexity for simple jq parsing

---

### Q3: How to query CloudTrail for change attribution?

**Decision**: Use `aws cloudtrail lookup-events` with ResourceName filter, parse userIdentity from event JSON

**Rationale**: CloudTrail's LookupEvents API provides direct access to recent events by resource. The nested `CloudTrailEvent` JSON contains full user identity including IAM ARN, timestamp, and source IP.

**Query Strategy**:
1. Extract resource IDs from Terraform state (VPC ID, subnet ID, etc.)
2. Query CloudTrail for each changed resource
3. Parse `userIdentity.arn` from CloudTrailEvent JSON
4. Deduplicate users across multiple resources

**CLI Example**:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$RESOURCE_ID \
  --start-time "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --query 'Events[0].CloudTrailEvent' --output text | \
  jq -r '.userIdentity.arn'
```

**Limitations Addressed**:
| Limitation | Mitigation |
|------------|------------|
| 90-day retention | Query recent 7 days for practical purposes |
| Rate limit (2/sec) | Add 0.5s sleep between queries |
| Eventual consistency (15min delay) | Workflow runs daily, not real-time |
| Single attribute per query | Loop over changed resources |

**Resource Mapping**:
| Terraform Type | CloudTrail ResourceType | CloudTrail Events |
|----------------|------------------------|-------------------|
| `aws_vpc` | `AWS::EC2::VPC` | ModifyVpcAttribute |
| `aws_subnet` | `AWS::EC2::Subnet` | ModifySubnetAttribute |
| `aws_security_group` | `AWS::EC2::SecurityGroup` | AuthorizeSecurityGroupIngress |
| `aws_instance` | `AWS::EC2::Instance` | ModifyInstanceAttribute |

**Alternatives Considered**:
- AWS Config: Rejected - requires additional setup, overkill for daily checks
- CloudWatch Events: Rejected - real-time streaming, not historical queries
- Athena on CloudTrail logs: Rejected - requires S3 export setup, adds complexity

---

### Q4: How to send Microsoft Teams notifications via incoming webhook?

**Decision**: Use Adaptive Cards wrapped in message envelope, POST via curl

**Rationale**: Adaptive Cards provide rich formatting with tables, colored text, and action buttons. The incoming webhook is simpler than bot registration and sufficient for one-way notifications.

**Payload Structure**:
```json
{
  "type": "message",
  "attachments": [{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
      "type": "AdaptiveCard",
      "version": "1.4",
      "body": [...],
      "actions": [{"type": "Action.OpenUrl", "title": "View Issue", "url": "..."}]
    }
  }]
}
```

**Best Practices Implemented**:
- Color-coded header: 🔴 red for attention
- FactSet for structured data (environment, count, timestamp)
- Action buttons linking to GitHub Issue and Workflow Run
- Message kept under 28KB limit
- Retry logic for 429 rate limit errors

**Alternatives Considered**:
- Power Automate flow: Rejected - adds external dependency and maintenance
- Microsoft Graph API: Rejected - requires app registration and OAuth
- Plain text webhook: Rejected - poor formatting, no action buttons

---

### Q5: How to create GitHub Issues programmatically with rich formatting?

**Decision**: Use `gh issue create` CLI with `--body-file` for complex markdown

**Rationale**: The GitHub CLI is pre-installed on GitHub Actions runners, integrates seamlessly with GITHUB_TOKEN, and returns the issue URL to stdout for use in subsequent steps.

**Issue Template Structure**:
```markdown
## Drift Detection Report

**Environment:** {env}
**Detected At:** {timestamp}
**Workflow Run:** {run_url}

### Changed Resources

| Resource Address | Change Type | IAM User | Timestamp |
|-----------------|-------------|----------|-----------|
| `aws_vpc.main` | update | arn:aws:iam::123:user/admin | 2026-01-27T15:30Z |

### Terraform Plan Diff

```hcl
{plan_output}
```

### Remediation
Run `terraform apply` to reconcile or investigate manual changes.
```

**URL Capture**:
```bash
ISSUE_URL=$(gh issue create --title "..." --body-file report.md)
echo "issue_url=$ISSUE_URL" >> $GITHUB_OUTPUT
```

**Alternatives Considered**:
- GitHub REST API via curl: Rejected - gh CLI is simpler and handles auth
- actions/github-script: Rejected - JavaScript adds complexity for simple create

---

## Technology Decisions Summary

| Component | Technology | Rationale |
|-----------|------------|-----------|
| AWS Authentication | OIDC via configure-aws-credentials@v5 | No long-lived credentials |
| Drift Detection | terraform plan -detailed-exitcode | Native exit code signals |
| Plan Parsing | terraform show -json + jq | Structured, stable format |
| Change Attribution | CloudTrail LookupEvents API | Direct query by resource |
| Teams Notification | Incoming Webhook + Adaptive Card | Rich formatting, action buttons |
| Issue Creation | gh CLI | Pre-installed, URL capture |

## Required GitHub Secrets

| Secret Name | Purpose |
|-------------|---------|
| `AWS_ROLE_ARN` | OIDC role ARN for AWS authentication |
| `TF_API_TOKEN` | Terraform Cloud API token (for state access) |
| `TEAMS_WEBHOOK_URL` | Microsoft Teams incoming webhook URL |

Note: `GITHUB_TOKEN` is automatically provided by Actions.

## Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformPlanReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "autoscaling:Describe*",
        "s3:GetBucket*",
        "s3:ListBucket*",
        "iam:Get*",
        "iam:List*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudTrailLookup",
      "Effect": "Allow",
      "Action": ["cloudtrail:LookupEvents"],
      "Resource": "*"
    }
  ]
}
```

## Edge Case Handling

| Edge Case | Handling Strategy |
|-----------|-------------------|
| CloudTrail data unavailable | Issue includes "Attribution unavailable" |
| State locked | Workflow waits 5min, retries once |
| Teams webhook failure | Workflow continues, logs error |
| GitHub API rate limit | Use built-in gh CLI retry |
| AWS service change (not human) | Show service principal, flag as automated |
| Multiple users changed same resource | Show most recent change |
