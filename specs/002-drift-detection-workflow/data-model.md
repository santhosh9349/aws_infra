# Data Model: Terraform Drift Detection Workflow

**Feature Branch**: `002-drift-detection-workflow`  
**Date**: 2026-01-28

## Overview

This document defines the data structures used throughout the drift detection workflow, from Terraform plan parsing through GitHub Issue creation and Teams notification.

---

## Core Entities

### 1. DriftEvent

Represents a single detected drift on a Terraform-managed resource.

```typescript
interface DriftEvent {
  resourceAddress: string;    // e.g., "module.vpc.aws_vpc.main"
  resourceType: string;       // e.g., "aws_vpc"
  resourceId: string;         // AWS resource ID (e.g., "vpc-12345678")
  changeType: ChangeAction;   // Type of change detected
  beforeValue: object | null; // State before change
  afterValue: object | null;  // State after change (from plan)
  diffSnippet: string;        // Human-readable diff excerpt
}

type ChangeAction = 
  | "create"    // Resource exists in config but not in state
  | "update"    // Resource attributes differ
  | "delete"    // Resource exists in state but not in config
  | "replace";  // Resource must be destroyed and recreated
```

**Field Constraints**:
| Field | Constraint |
|-------|------------|
| `resourceAddress` | Max 256 chars, format: `[module.name.]resource_type.name[index]` |
| `resourceType` | AWS provider resource type (e.g., `aws_vpc`) |
| `resourceId` | AWS resource identifier, may be null for creates |
| `diffSnippet` | Truncated to 500 chars max |

**Source**: Extracted from `terraform show -json` output → `resource_changes[]`

---

### 2. ChangeAttribution

Information about who made a change, derived from AWS CloudTrail.

```typescript
interface ChangeAttribution {
  userArn: string;           // Full IAM ARN
  userType: UserType;        // Type of identity
  userName: string;          // Human-readable name
  eventTime: string;         // ISO 8601 timestamp
  eventName: string;         // CloudTrail event name (e.g., "ModifyVpcAttribute")
  sourceIp: string | null;   // Source IP if available
  userAgent: string | null;  // AWS CLI, Console, SDK, etc.
}

type UserType = 
  | "IAMUser"        // Direct IAM user
  | "AssumedRole"    // Role assumed via STS
  | "Root"           // Account root user
  | "FederatedUser"  // Federated identity
  | "AWSService";    // AWS service (e.g., Auto Scaling)
```

**Field Constraints**:
| Field | Constraint |
|-------|------------|
| `userArn` | Valid IAM ARN format |
| `eventTime` | ISO 8601 format (e.g., `2026-01-27T15:30:00Z`) |
| `eventName` | CloudTrail API event name |

**Source**: Extracted from `aws cloudtrail lookup-events` → `CloudTrailEvent.userIdentity`

---

### 3. DriftReport

Aggregated report of all drift events from a single workflow run.

```typescript
interface DriftReport {
  environment: string;       // "dev" | "prod"
  detectedAt: string;        // ISO 8601 timestamp
  workflowRunId: string;     // GitHub Actions run ID
  workflowRunUrl: string;    // Full URL to workflow run
  summary: DriftSummary;     // Aggregated statistics
  events: DriftEventWithAttribution[];
}

interface DriftSummary {
  totalChanges: number;
  createCount: number;
  updateCount: number;
  deleteCount: number;
  replaceCount: number;
  uniqueUsers: string[];     // List of unique IAM ARNs
}

interface DriftEventWithAttribution extends DriftEvent {
  attribution: ChangeAttribution | null;  // null if CloudTrail unavailable
}
```

**Source**: Composed from DriftEvent[] and ChangeAttribution[]

---

## API/Message Schemas

### 4. TerraformPlanJson (Input)

Structure of `terraform show -json` output (relevant subset).

```typescript
interface TerraformPlanJson {
  format_version: string;     // e.g., "1.0"
  terraform_version: string;  // e.g., "1.5.7"
  resource_changes: ResourceChange[];
  resource_drift?: ResourceChange[];  // Resources changed outside Terraform
}

interface ResourceChange {
  address: string;
  module_address?: string;
  mode: "managed" | "data";
  type: string;
  name: string;
  index?: number | string;
  change: {
    actions: ("no-op" | "create" | "read" | "update" | "delete")[];
    before: object | null;
    after: object | null;
    after_unknown?: object;
  };
  action_reason?: string;
}
```

---

### 5. CloudTrailEvent (Input)

Structure of CloudTrail LookupEvents response (relevant subset).

```typescript
interface CloudTrailLookupResponse {
  Events: CloudTrailEventRecord[];
  NextToken?: string;
}

interface CloudTrailEventRecord {
  EventId: string;
  EventName: string;
  EventTime: string;       // ISO 8601
  EventSource: string;     // e.g., "ec2.amazonaws.com"
  Username: string;
  Resources: {
    ResourceType: string;
    ResourceName: string;
  }[];
  CloudTrailEvent: string; // JSON string containing userIdentity
}

// Parsed from CloudTrailEvent JSON string
interface CloudTrailEventDetail {
  userIdentity: {
    type: string;
    principalId: string;
    arn: string;
    accountId: string;
    userName?: string;
    sessionContext?: {
      sessionIssuer: {
        type: string;
        arn: string;
        userName: string;
      };
    };
  };
  sourceIPAddress: string;
  userAgent: string;
  eventTime: string;
  eventName: string;
  requestParameters: object;
  responseElements: object;
}
```

---

## Output Schemas

### 6. GitHubIssueBody

Markdown structure for the created GitHub issue.

```markdown
## Drift Detection Report

**Environment:** {environment}
**Detected At:** {detectedAt}
**Workflow Run:** [{workflowRunId}]({workflowRunUrl})

### Summary

| Metric | Count |
|--------|-------|
| Total Changes | {totalChanges} |
| Creates | {createCount} |
| Updates | {updateCount} |
| Deletes | {deleteCount} |
| Replaces | {replaceCount} |

### Changed Resources

| Resource Address | Change Type | IAM User | Timestamp |
|-----------------|-------------|----------|-----------|
{{#each events}}
| `{resourceAddress}` | {changeType} | {attribution.userName} | {attribution.eventTime} |
{{/each}}

### Terraform Plan Output

```hcl
{{#each events}}
# {resourceAddress} will be {changeType}
{diffSnippet}

{{/each}}
```

### Remediation

To reconcile drift:
```bash
cd terraform/{environment}
terraform apply
```

---
*This issue was automatically created by the drift detection workflow.*
```

---

### 7. TeamsAdaptiveCard (Output)

See [contracts/teams-webhook.json](contracts/teams-webhook.json) for full schema.

```typescript
interface TeamsWebhookPayload {
  type: "message";
  attachments: [{
    contentType: "application/vnd.microsoft.card.adaptive";
    content: AdaptiveCard;
  }];
}

interface AdaptiveCard {
  $schema: string;
  type: "AdaptiveCard";
  version: "1.4";
  body: (TextBlock | FactSet | Container)[];
  actions: ActionOpenUrl[];
}
```

---

## State Transitions

### Workflow State Machine

```
┌─────────────┐     trigger      ┌──────────────┐
│  SCHEDULED  │ ───────────────► │  RUNNING     │
└─────────────┘                  └──────┬───────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            ┌───────────┐       ┌───────────┐       ┌───────────┐
            │ exit=0    │       │ exit=1    │       │ exit=2    │
            │ NO_DRIFT  │       │ ERROR     │       │ DRIFT     │
            └─────┬─────┘       └─────┬─────┘       └─────┬─────┘
                  │                   │                   │
                  ▼                   ▼                   ▼
            ┌───────────┐       ┌───────────┐       ┌───────────┐
            │ Success   │       │ Alert     │       │ Query     │
            │ (no-op)   │       │ (error)   │       │ CloudTrail│
            └───────────┘       └───────────┘       └─────┬─────┘
                                                          │
                                                          ▼
                                                   ┌───────────┐
                                                   │ Create    │
                                                   │ Issue     │
                                                   └─────┬─────┘
                                                          │
                                                          ▼
                                                   ┌───────────┐
                                                   │ Send      │
                                                   │ Teams     │
                                                   └───────────┘
```

---

## Validation Rules

### DriftEvent Validation

| Field | Rule |
|-------|------|
| `resourceAddress` | Required, non-empty, matches pattern `^[a-z_][a-z0-9_\.]*$` |
| `changeType` | Required, one of: create, update, delete, replace |
| `resourceType` | Required, starts with `aws_` |
| `diffSnippet` | Max 500 characters, truncate with `...` if longer |

### ChangeAttribution Validation

| Field | Rule |
|-------|------|
| `userArn` | Required, valid ARN format `^arn:aws:` |
| `eventTime` | Required, valid ISO 8601 |
| `userType` | Required, one of: IAMUser, AssumedRole, Root, FederatedUser, AWSService |

### DriftReport Validation

| Field | Rule |
|-------|------|
| `environment` | Required, one of: dev, prod |
| `events` | At least 1 event (report only created when drift exists) |
| `workflowRunUrl` | Valid GitHub URL format |
