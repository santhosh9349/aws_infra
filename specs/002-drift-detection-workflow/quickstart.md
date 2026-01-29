# Quickstart: Terraform Drift Detection Workflow

**Feature Branch**: `002-drift-detection-workflow`  
**Date**: 2026-01-28

## Prerequisites

Before implementing this feature, ensure you have:

### AWS Requirements

- [ ] AWS account with CloudTrail enabled
- [ ] IAM OIDC Identity Provider for GitHub Actions (may not exist yet)
- [ ] IAM Role for drift detection with required permissions
- [ ] CloudTrail logs retained for at least 90 days

### GitHub Requirements

- [ ] Repository with GitHub Actions enabled
- [ ] Sufficient Actions minutes quota
- [ ] Repository secrets configured (see below)

### Microsoft Teams Requirements

- [ ] Access to Teams workspace
- [ ] Permission to create Incoming Webhook in `Drift_notification_tf` channel

---

## Setup Steps

### Step 1: Create AWS OIDC Identity Provider

If you don't already have a GitHub Actions OIDC provider in AWS:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

> **Note**: The thumbprint may change. Verify at [GitHub OIDC docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect).

### Step 2: Create IAM Role for Drift Detection

The role `github_oidc_drift` should have the following trust policy:

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
        "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/aws_infra:*"
      }
    }
  }]
}
```

Attach the following permissions policy:

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
        "iam:List*",
        "kms:Describe*",
        "kms:List*",
        "rds:Describe*",
        "lambda:Get*",
        "lambda:List*"
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

### Step 3: Configure Microsoft Teams Webhook

1. Open Microsoft Teams
2. Navigate to the `Drift_notification_tf` channel
3. Click `...` → **Connectors** → **Incoming Webhook**
4. Name it `Terraform Drift Alerts`
5. Copy the webhook URL

### Step 4: Configure GitHub Secrets

Add these secrets to your repository (Settings → Secrets → Actions):

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::017373135945:role/github_oidc_drift` | IAM role ARN for OIDC |
| `TF_API_TOKEN` | `your-terraform-cloud-token` | Terraform Cloud API token |
| `TEAMS_WEBHOOK_URL` | `https://...webhook.office.com/...` | Teams webhook URL |

> **Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions.

### Step 5: Create Repository Labels

Create these labels if they don't exist:

```bash
gh label create drift --color d73a4a --description "Terraform drift detected"
gh label create infrastructure --color 0075ca --description "Infrastructure-related"
gh label create automated --color 7057ff --description "Created by automation"
gh label create dev --color bfdadc --description "Development environment"
gh label create prod --color d4c5f9 --description "Production environment"
```

---

## Verification Checklist

After implementation, verify the following:

### Manual Workflow Trigger Test

1. Navigate to Actions → Drift Detection → Run workflow
2. Verify workflow completes successfully
3. Check exit code handling for no-drift case

### Drift Detection Test

1. Make a manual change via AWS Console (e.g., add a tag to a VPC)
2. Manually trigger the workflow
3. Verify:
   - [ ] GitHub Issue created with correct content
   - [ ] Teams notification received
   - [ ] IAM user attribution is correct
   - [ ] Diff snippet is accurate

### Schedule Verification

1. Wait for 9:00 AM BST trigger
2. Verify workflow runs automatically
3. Check CloudWatch Events (optional) for cron accuracy

---

## File Structure After Implementation

```
aws_infra/
├── .github/
│   └── workflows/
│       └── drift-detection.yml      # Main workflow file
├── scripts/
│   └── drift-detection/
│       ├── parse-terraform-plan.sh  # Extract drifted resources
│       ├── query-cloudtrail.sh      # Query IAM attribution
│       └── format-teams-card.sh     # Generate Teams payload
└── specs/
    └── 002-drift-detection-workflow/
        ├── spec.md                  # Feature specification
        ├── plan.md                  # This implementation plan
        ├── research.md              # Technical research
        ├── data-model.md            # Data structures
        ├── quickstart.md            # This file
        ├── contracts/
        │   ├── teams-webhook.json   # Teams payload schema
        │   └── github-issue.md      # Issue template
        └── tasks.md                 # Implementation tasks (Phase 2)
```

---

## Troubleshooting

### OIDC Authentication Fails

**Symptom**: `Error: Couldn't retrieve credentials`

**Solutions**:
1. Verify IAM role trust policy includes your repository
2. Check `id-token: write` permission is set
3. Ensure OIDC provider exists in AWS account

### Terraform Plan Fails

**Symptom**: Exit code 1 (error)

**Solutions**:
1. Check Terraform Cloud workspace credentials
2. Verify AWS credentials have sufficient read permissions
3. Check for state lock conflicts

### CloudTrail Returns Empty

**Symptom**: No IAM attribution in issue

**Solutions**:
1. CloudTrail events may take 15 minutes to appear
2. Verify CloudTrail is enabled for the region
3. Check if changes are older than 90 days

### Teams Notification Not Received

**Symptom**: Issue created but no Teams message

**Solutions**:
1. Verify webhook URL is correct in secrets
2. Check for rate limiting (100 msgs/hour)
3. Test webhook URL manually with curl

---

## Next Steps

After setup is complete:

1. **Run `/speckit.tasks`** to generate implementation tasks
2. **Implement workflow** following the tasks
3. **Test manually** using `workflow_dispatch`
4. **Monitor** the first few scheduled runs
5. **Extend to prod** by adding environment matrix
