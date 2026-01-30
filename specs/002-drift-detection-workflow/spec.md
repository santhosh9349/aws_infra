# Feature Specification: Terraform Drift Detection Workflow

**Feature Branch**: `002-drift-detection-workflow`  
**Created**: January 26, 2026  
**Status**: Draft  
**Input**: User description: "Trigger GitHub workflow every day at 9AM BST to check for Terraform drift. If any drift is detected, it should create GitHub issue in the same repo with which IAM user made changes, what changes, and what time the changes was made. Also send Microsoft Teams notification to Drift_notification_tf teams channel"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scheduled Drift Detection (Priority: P1)

As a DevOps engineer, I want the system to automatically check for infrastructure drift every day at 9AM BST so that I can be proactively alerted to any unauthorized or unintended changes to our AWS infrastructure before they cause issues.

**Why this priority**: This is the core functionality - without scheduled drift detection, the entire feature has no value. It enables proactive infrastructure monitoring without manual intervention.

**Independent Test**: Can be fully tested by triggering the scheduled workflow manually and verifying it runs `terraform plan` against the current state and completes successfully.

**Acceptance Scenarios**:

1. **Given** the GitHub workflow is configured, **When** the clock reaches 9:00 AM BST on any day, **Then** the workflow triggers automatically and runs Terraform plan to detect drift
2. **Given** the workflow is triggered, **When** AWS credentials are valid and Terraform state is accessible, **Then** the drift detection completes within 15 minutes
3. **Given** the workflow is triggered, **When** no drift is detected, **Then** no GitHub issue is created and no Teams notification is sent

---

### User Story 2 - GitHub Issue Creation on Drift (Priority: P1)

As a DevOps engineer, when infrastructure drift is detected, I want a GitHub issue automatically created in the repository containing details about who made the change, what changed, and when, so I can investigate and remediate the drift.

**Why this priority**: Equal priority with drift detection - this is the primary alerting mechanism. Without issue creation, detected drift would not be actionable.

**Independent Test**: Can be tested by introducing manual drift (e.g., modifying a security group via AWS Console) and verifying an issue is created with correct details.

**Acceptance Scenarios**:

1. **Given** drift is detected by Terraform plan, **When** the workflow processes the drift results, **Then** a GitHub issue is created in the aws_infra repository
2. **Given** a drift issue is created, **When** the issue content is viewed, **Then** it includes the IAM user/role that made the change
3. **Given** a drift issue is created, **When** the issue content is viewed, **Then** it includes a summary of what resources changed and how
4. **Given** a drift issue is created, **When** the issue content is viewed, **Then** it includes the timestamp when the change was made
5. **Given** multiple drifted resources are detected, **When** the issue is created, **Then** all drifted resources are listed in a single issue

---

### User Story 3 - Microsoft Teams Notification (Priority: P2)

As a DevOps engineer, when infrastructure drift is detected, I want to receive a Microsoft Teams notification in the "Drift_notification_tf" channel so that I am immediately aware of the drift without needing to check GitHub.

**Why this priority**: Secondary alerting mechanism - provides faster notification but GitHub issue contains the detailed information for investigation.

**Independent Test**: Can be tested by triggering a drift detection that finds changes and verifying a message appears in the specified Teams channel.

**Acceptance Scenarios**:

1. **Given** drift is detected and a GitHub issue is created, **When** the notification step runs, **Then** a message is sent to the "Drift_notification_tf" Teams channel
2. **Given** a Teams notification is sent, **When** the message is viewed, **Then** it includes a link to the GitHub issue for detailed investigation
3. **Given** a Teams notification is sent, **When** the message is viewed, **Then** it includes a brief summary of the drift (number of resources affected)
4. **Given** no drift is detected, **When** the workflow completes, **Then** no Teams notification is sent

---

### Edge Cases

- What happens when AWS CloudTrail logs are not available or incomplete for change attribution?
- What happens when the Terraform state is locked during drift detection?
- What happens when the Microsoft Teams webhook is unavailable or returns an error?
- What happens when GitHub API rate limits are exceeded during issue creation?
- What happens when multiple IAM users made changes to the same resource?
- What happens when changes were made by an AWS service (not a human user)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST run a GitHub Actions workflow on a daily schedule at 9:00 AM BST
- **FR-002**: System MUST execute `terraform plan` against the current AWS infrastructure state
- **FR-003**: System MUST parse Terraform plan output to identify any detected drift (resource additions, modifications, or deletions)
- **FR-004**: System MUST query AWS CloudTrail to identify who made infrastructure changes
- **FR-005**: System MUST create a GitHub issue in the repository when drift is detected
- **FR-006**: GitHub issue MUST include the IAM user or role that made the change
- **FR-007**: GitHub issue MUST include a description of what resources changed
- **FR-008**: GitHub issue MUST include the timestamp of when changes were made
- **FR-009**: System MUST send a notification to Microsoft Teams channel "Drift_notification_tf" when drift is detected
- **FR-010**: Teams notification MUST include a link to the created GitHub issue
- **FR-011**: System MUST NOT create issues or send notifications when no drift is detected
- **FR-012**: System MUST have access to Terraform Cloud for state management
- **FR-013**: System MUST have appropriate AWS credentials to run Terraform plan and query CloudTrail

### Key Entities

- **Drift Event**: A detected difference between the Terraform state and actual AWS infrastructure; includes affected resources, change type (add/modify/delete), and detection timestamp
- **Change Attribution**: Information about who made a change; includes IAM user/role ARN, timestamp, and source IP (if available from CloudTrail)
- **Drift Report**: Aggregated information about all detected drift in a single workflow run; used to populate the GitHub issue body

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Drift detection workflow runs automatically at 9:00 AM BST every day (±5 minutes tolerance)
- **SC-002**: DevOps team is notified of any infrastructure drift within 30 minutes of the 9 AM scheduled time
- **SC-003**: 100% of detected drift events result in a GitHub issue being created
- **SC-004**: 100% of created GitHub issues include IAM attribution when CloudTrail data is available
- **SC-005**: Teams notification is delivered within 2 minutes of issue creation
- **SC-006**: Zero false positive notifications (no notifications when infrastructure matches Terraform state)

## Assumptions

- AWS CloudTrail is enabled and logging API calls for the monitored AWS accounts
- CloudTrail logs are retained for at least 90 days to support change attribution
- The GitHub repository has Actions enabled and sufficient workflow minutes
- A Microsoft Teams incoming webhook is configured for the "Drift_notification_tf" channel
- Terraform Cloud workspace credentials are available as GitHub secrets
- AWS IAM credentials with read-only access for Terraform plan and CloudTrail queries are available as GitHub secrets
- The workflow will run against the `dev` environment initially (can be extended to `prod` later)
