---
description: |
  AI-powered Terraform drift analysis workflow. Analyzes drift detection results
  from Terraform Cloud and CloudTrail attribution data to create comprehensive,
  actionable GitHub issues with intelligent recommendations for remediation.

on:
  repository_dispatch:
    types: [drift-analysis]
  workflow_dispatch:
    inputs:
      drift_report_artifact:
        description: 'Artifact name containing drift report JSON (optional - defaults to latest)'
        required: false
        type: string
      environment:
        description: 'Environment where drift was detected'
        required: false
        default: 'dev'
        type: choice
        options:
          - dev
          - prod

permissions:
  contents: read
  actions: read
  issues: read
  pull-requests: read

network: defaults

tools:
  github:
    toolsets: [default, actions]
  bash: true
  web-fetch:

safe-outputs:
  mentions: false
  allowed-github-references: []
  create-issue:
    title-prefix: "🔴 [Drift Analysis] "
    labels: [drift, infrastructure, ai-analysis, automated]
    max: 1
    close-older-issues: true

engine:
  id: claude
  model: claude-sonnet-4.6

timeout-minutes: 15

steps:
  - name: Setup jq
    run: |
      which jq || sudo apt-get update && sudo apt-get install -y jq

  - name: Download drift artifacts
    env:
      GH_TOKEN: ${{ github.token }}
    run: |
      # Create artifact directory
      mkdir -p /tmp/drift-artifacts

      # Try to download the latest drift artifacts from the drift-detection workflow
      echo "Fetching latest successful drift-detection workflow run..."
      
      # Get the latest successful run from drift-detection workflow
      LATEST_RUN=$(gh api repos/${{ github.repository }}/actions/workflows/drift-detection.yml/runs \
        --jq '.workflow_runs | map(select(.status == "completed" and .conclusion == "success")) | first | .id' 2>/dev/null || echo "")
      
      if [ -n "$LATEST_RUN" ] && [ "$LATEST_RUN" != "null" ]; then
        echo "Found latest run: $LATEST_RUN"
        
        # List and download artifacts
        gh api repos/${{ github.repository }}/actions/runs/$LATEST_RUN/artifacts \
          --jq '.artifacts[] | .name' 2>/dev/null || echo "No artifacts found"
        
        # Download drift-report artifact if available
        gh run download $LATEST_RUN -D /tmp/drift-artifacts --pattern "drift-*" 2>/dev/null || echo "No drift artifacts to download"
      fi
      
      # List what we have
      echo "Available artifacts:"
      ls -la /tmp/drift-artifacts/ 2>/dev/null || echo "No artifacts directory"
      find /tmp/drift-artifacts -type f 2>/dev/null || echo "No files found"

  - name: Prepare drift context
    env:
      INPUT_ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}
      WORKFLOW_RUN_ID: ${{ github.run_id }}
    run: |
      # Create a context file for the AI agent with available drift data
      CONTEXT_FILE="/tmp/drift-context.md"
      
      echo "# Drift Detection Context" > "$CONTEXT_FILE"
      echo "" >> "$CONTEXT_FILE"
      echo "## Environment: ${INPUT_ENVIRONMENT}" >> "$CONTEXT_FILE"
      echo "## Workflow Run: ${WORKFLOW_RUN_ID}" >> "$CONTEXT_FILE"
      echo "## Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$CONTEXT_FILE"
      echo "" >> "$CONTEXT_FILE"
      
      # Add any available drift data
      if [ -f /tmp/drift-artifacts/drift-report/drift_report.json ]; then
        echo "## Drift Report (JSON)" >> "$CONTEXT_FILE"
        echo '```json' >> "$CONTEXT_FILE"
        cat /tmp/drift-artifacts/drift-report/drift_report.json >> "$CONTEXT_FILE"
        echo '```' >> "$CONTEXT_FILE"
      fi
      
      if [ -f /tmp/drift-artifacts/drift-data/drift_resources_attributed.txt ]; then
        echo "## Attributed Resources" >> "$CONTEXT_FILE"
        echo '```' >> "$CONTEXT_FILE"
        cat /tmp/drift-artifacts/drift-data/drift_resources_attributed.txt >> "$CONTEXT_FILE"
        echo '```' >> "$CONTEXT_FILE"
      fi
      
      if [ -f /tmp/drift-artifacts/terraform-plan/plan_output.txt ]; then
        echo "## Terraform Plan Output" >> "$CONTEXT_FILE"
        echo '```hcl' >> "$CONTEXT_FILE"
        head -300 /tmp/drift-artifacts/terraform-plan/plan_output.txt >> "$CONTEXT_FILE"
        echo '```' >> "$CONTEXT_FILE"
      fi
      
      echo "Drift context prepared at: $CONTEXT_FILE"
      cat "$CONTEXT_FILE"
---

# Terraform Drift Analysis Agent

You are an expert DevOps and Infrastructure engineer specializing in AWS and Terraform. Your task is to analyze Terraform drift detection results and create a comprehensive, actionable GitHub issue.

## Your Mission

1. **Analyze the drift data** - Review the Terraform plan output and CloudTrail attribution data
2. **Identify root causes** - Determine why drift occurred (manual changes, automation issues, etc.)
3. **Assess risk levels** - Categorize each drift by severity and impact
4. **Generate recommendations** - Provide clear remediation steps
5. **Create a GitHub issue** - Document everything in a well-structured issue

## Analysis Process

### Step 1: Gather Information

First, check for drift context that was prepared in the setup steps.

**Important**: The workflow setup steps download artifacts and prepare context files. Check these locations:
- `/tmp/drift-context.md` - Summary of drift data prepared by the workflow
- `/tmp/drift-artifacts/` - Directory containing downloaded artifacts:
  - `drift-report/drift_report.json` - Structured drift report
  - `drift-data/drift_resources_attributed.txt` - Attribution data
  - `terraform-plan/plan_output.txt` - Raw Terraform plan

**If files don't exist**: This is normal if no recent drift was detected or artifacts expired.
In this case, use the GitHub MCP tools to search for:
- Recent workflow runs of the `drift-detection.yml` workflow using the actions toolset
- Recent issues with the `drift` label
- The Terraform configuration in `terraform/dev/` or `terraform/prod/`

### Step 2: Analyze the Drift

For each drifted resource, evaluate:

1. **Resource Type & Criticality**
   - Is this a networking resource (VPC, subnet, route table)? → HIGH priority
   - Is this a security resource (security group, IAM)? → CRITICAL priority
   - Is this a compute resource (EC2, ASG)? → MEDIUM priority
   - Is this a tagging or metadata change? → LOW priority

2. **Actor Attribution (from CloudTrail)**
   - Who made the change? (IAM user, assumed role, AWS service)
   - When was the change made?
   - Was this a human operator or automated process?

3. **Change Type**
   - CREATE: Resource exists in Terraform but not in AWS (likely manual deletion)
   - UPDATE: Resource attributes differ between Terraform and AWS
   - DELETE: Resource exists in AWS but not in Terraform (manual creation)
   - REPLACE: Resource needs to be recreated (potentially breaking)

### Step 3: Risk Assessment

Assign a severity level:
- 🔴 **CRITICAL**: Security-related changes, IAM modifications, network security groups
- 🟠 **HIGH**: VPC/subnet changes, route modifications, load balancer configs
- 🟡 **MEDIUM**: EC2 instance changes, tags, scaling configurations
- 🟢 **LOW**: Metadata, descriptions, non-functional changes

### Step 4: Generate Recommendations

For each drift, provide:
1. **Root cause hypothesis** - Why did this likely happen?
2. **Remediation options**:
   - Option A: Accept drift (update Terraform to match AWS)
   - Option B: Revert drift (apply Terraform to match state)
3. **Prevention measures** - How to avoid this in the future

## Issue Format

Create a GitHub issue with this structure:

```markdown
## 📊 Drift Analysis Summary

| Metric | Value |
|--------|-------|
| Environment | {environment} |
| Analysis Time | {timestamp} |
| Total Drifted Resources | {count} |
| Critical Issues | {critical_count} |
| High Priority | {high_count} |

---

## 🎯 Executive Summary

{Brief 2-3 sentence summary of the drift situation and recommended action}

---

## 🔍 Detailed Analysis

### 🔴 Critical Priority

{For each critical resource:}
#### `{resource_address}`
- **Change Type**: {create/update/delete/replace}
- **Actor**: {who made the change}
- **Time**: {when}
- **Root Cause**: {analysis}
- **Risk**: {what could go wrong}
- **Recommendation**: {specific action}

### 🟠 High Priority
{Similar format for high priority items}

### 🟡 Medium Priority
{Similar format for medium priority items}

### 🟢 Low Priority
{Similar format for low priority items}

---

## 📋 Attribution Analysis

| Resource | Actor | Actor Type | Time | Confidence |
|----------|-------|------------|------|------------|
{Table of who changed what}

---

## 🛠️ Remediation Playbook

### Option 1: Accept Drift (Update Terraform)
{Steps to update Terraform configuration to match current AWS state}

### Option 2: Revert Drift (Apply Terraform)
{Steps to apply Terraform and bring AWS back to desired state}

### Option 3: Hybrid Approach
{For cases where some changes should be kept and others reverted}

---

## 🔒 Prevention Recommendations

1. **Process Improvements**
   {Recommendations for preventing future drift}

2. **Tooling Enhancements**
   {Automation or tooling that could help}

3. **Training/Documentation**
   {Any knowledge gaps identified}

---

## 📎 Related Resources

- Workflow Run: {link}
- Terraform Directory: `terraform/{environment}/`
- Previous Drift Issues: {links to related issues}

---

*This analysis was generated by the AI-powered drift analysis workflow.*
*Review the recommendations and consult with the infrastructure team before taking action.*
```

## Important Notes

- If no drift data is available, explain that in the issue and provide general drift prevention guidance
- Always link to the workflow run for context
- Be specific with remediation commands (include actual `terraform` commands)
- If CloudTrail attribution is unavailable for some resources, note this and suggest manual investigation
- Prioritize security-related drift above all else