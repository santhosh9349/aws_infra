# GitHub Issue Template: Drift Detection Report

This document defines the structure and content of GitHub Issues created when Terraform drift is detected.

## Issue Metadata

| Field | Value |
|-------|-------|
| **Title** | `🔴 Terraform Drift Detected - {environment} - {date}` |
| **Labels** | `drift`, `infrastructure`, `automated`, `{environment}` |
| **Assignees** | (configurable via workflow input, default: none) |

## Issue Body Template

```markdown
## Drift Detection Report

| Field | Value |
|-------|-------|
| **Environment** | {environment} |
| **Detected At** | {timestamp} |
| **Workflow Run** | [{run_id}]({run_url}) |

---

### Summary

| Metric | Count |
|--------|-------|
| 🆕 Creates | {create_count} |
| 📝 Updates | {update_count} |
| 🗑️ Deletes | {delete_count} |
| 🔄 Replaces | {replace_count} |
| **Total** | **{total_count}** |

---

### Changed Resources

| Resource Address | Change | IAM User | Timestamp |
|-----------------|--------|----------|-----------|
{resource_table_rows}

> ℹ️ **Note**: Attribution shows the most recent CloudTrail event for each resource.
> Events older than 90 days cannot be queried.

---

### Terraform Plan Diff

<details>
<summary>Click to expand full plan output</summary>

```hcl
{terraform_plan_output}
```

</details>

---

### Possible Causes

- ⚠️ **Manual Console Changes**: Someone modified resources via AWS Console
- 🤖 **Automation Drift**: Another tool (Ansible, scripts) modified resources
- 🔧 **AWS Service Changes**: Auto Scaling, RDS maintenance, etc.
- 📅 **Scheduled Operations**: Backup jobs, rotation policies

---

### Remediation Options

#### Option 1: Accept Drift (Update Terraform)

If the drift is intentional, update Terraform code to match:

```bash
cd terraform/{environment}
# Review the plan
terraform plan

# If changes are acceptable, import or update code
```

#### Option 2: Revert Drift (Apply Terraform)

If the drift is unintentional, restore Terraform state:

```bash
cd terraform/{environment}
terraform apply
```

#### Option 3: Investigate Further

1. Review CloudTrail logs for full change history
2. Contact the IAM user(s) listed above
3. Check for other automation tools

---

### Prevention

To prevent future drift:

- 🚫 Avoid manual AWS Console changes
- 📋 Document emergency changes in issues
- 🔒 Restrict IAM permissions for production
- 🔔 Enable CloudTrail alerts for sensitive resources

---

*This issue was automatically created by the [drift detection workflow]({run_url}).*
*Last updated: {timestamp}*
```

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{environment}` | Terraform environment name | `dev` |
| `{timestamp}` | ISO 8601 timestamp of detection | `2026-01-28T09:00:00Z` |
| `{run_id}` | GitHub Actions run ID | `12345678` |
| `{run_url}` | Full URL to workflow run | `https://github.com/owner/repo/actions/runs/12345678` |
| `{create_count}` | Number of resources to create | `0` |
| `{update_count}` | Number of resources to update | `2` |
| `{delete_count}` | Number of resources to delete | `1` |
| `{replace_count}` | Number of resources to replace | `0` |
| `{total_count}` | Total changed resources | `3` |
| `{resource_table_rows}` | Markdown table rows | See format below |
| `{terraform_plan_output}` | Raw terraform plan text | HCL diff output |

## Resource Table Row Format

Each row in `{resource_table_rows}`:

```markdown
| `{resource_address}` | {change_emoji} {change_type} | `{iam_user}` | {event_time} |
```

**Change Emoji Mapping**:
| Change Type | Emoji |
|-------------|-------|
| create | 🆕 |
| update | 📝 |
| delete | 🗑️ |
| replace | 🔄 |

**Example Rows**:
```markdown
| `module.vpc.aws_vpc.main` | 📝 update | `admin@example.com` | 2026-01-27 15:30 UTC |
| `aws_subnet.public[0]` | 🗑️ delete | `automation-role` | 2026-01-27 14:22 UTC |
| `aws_security_group.web` | 📝 update | *(unavailable)* | - |
```

## Handling Missing Attribution

When CloudTrail data is unavailable:

```markdown
| `{resource_address}` | {change_type} | *(unavailable)* | - |
```

**Reasons attribution may be unavailable**:
- Event older than 90 days
- Resource created before CloudTrail was enabled
- AWS service-initiated change without clear attribution
- API call from AWS internal services

## Size Limits

| Element | Limit | Action if Exceeded |
|---------|-------|-------------------|
| Issue body | 65,536 chars | Truncate plan output, link to artifact |
| Title | 256 chars | Use short environment name |
| Label name | 50 chars | N/A (predefined labels) |
| Table rows | ~100 resources | Group by module, show top 50 |

## Labels Definition

Create these labels in the repository:

| Label | Color | Description |
|-------|-------|-------------|
| `drift` | `#d73a4a` (red) | Terraform drift detected |
| `infrastructure` | `#0075ca` (blue) | Infrastructure-related |
| `automated` | `#7057ff` (purple) | Created by automation |
| `dev` | `#bfdadc` (teal) | Development environment |
| `prod` | `#d4c5f9` (lavender) | Production environment |
