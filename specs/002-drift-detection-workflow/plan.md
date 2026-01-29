# Implementation Plan: Terraform Drift Detection Workflow

**Branch**: `002-drift-detection-workflow` | **Date**: 2026-01-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-drift-detection-workflow/spec.md`

## Summary

Implement a GitHub Actions workflow that runs daily at 9:00 AM BST to detect Terraform infrastructure drift using `terraform plan -detailed-exitcode`. When drift is detected (exit code 2), the workflow queries AWS CloudTrail to identify the IAM user responsible for changes, creates a GitHub Issue with detailed attribution information (resource address, IAM user, timestamp, diff snippet), and sends a Microsoft Teams notification via incoming webhook with an Adaptive Card format. The workflow uses OIDC authentication for AWS and reads Terraform state from Terraform Cloud.

## Technical Context

**Language/Version**: YAML (GitHub Actions), Bash (scripts), Terraform v1.5.x  
**Primary Dependencies**: GitHub Actions, AWS CLI v2, Terraform CLI, gh CLI, jq  
**Storage**: Terraform Cloud (remote state), AWS CloudTrail (logs)  
**Testing**: Manual workflow trigger (`workflow_dispatch`), terraform plan validation  
**Target Platform**: GitHub Actions runner (ubuntu-latest)
**Project Type**: CI/CD Workflow (GitHub Actions)  
**Performance Goals**: Complete drift detection within 15 minutes of scheduled time  
**Constraints**: Workflow runs at 9:00 AM BST (8:00 AM UTC / 9:00 AM UTC depending on DST)  
**Scale/Scope**: Single environment (dev) initially, extensible to prod

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Infrastructure as Code First | ✅ PASS | Workflow detects drift FROM IaC state; reinforces IaC compliance |
| II. Module-First Architecture | ✅ N/A | No Terraform modules created; this is a CI/CD workflow |
| III. Dynamic Scalability | ✅ PASS | Workflow can be parameterized to run against multiple environments |
| IV. Security & Compliance | ✅ PASS | Uses OIDC for AWS auth (no long-lived credentials); read-only access |
| V. Operational Verification | ✅ PASS | Workflow validates via `terraform plan` - core to its purpose |

**Additional Gates (Constitution Governance)**:
- Module structure: N/A (no Terraform modules)
- Mandatory tagging: N/A (no AWS resources created)
- Dynamic scalability: ✅ Environment parameterized via workflow input
- Terraform v1.5.x compatibility: ✅ Uses Terraform Cloud backend
- `terraform plan` validation: ✅ Core workflow step

## Project Structure

### Documentation (this feature)

```text
specs/002-drift-detection-workflow/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - AWS/GitHub Actions research
├── data-model.md        # Phase 1 output - Drift event data structures
├── quickstart.md        # Phase 1 output - Setup and testing guide
├── contracts/           # Phase 1 output - Webhook payload schemas
│   ├── teams-webhook.json    # Microsoft Teams Adaptive Card schema
│   └── github-issue.md       # GitHub Issue template
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
.github/
└── workflows/
    └── drift-detection.yml     # Main workflow file

scripts/
└── drift-detection/
    ├── parse-terraform-plan.sh # Extract drifted resources from plan output
    ├── query-cloudtrail.sh     # Query CloudTrail for change attribution
    └── format-teams-card.sh    # Generate Teams Adaptive Card JSON
```

**Structure Decision**: CI/CD workflow pattern - workflow YAML in `.github/workflows/`, supporting scripts in `scripts/drift-detection/`. No Terraform modules required as this feature is purely CI/CD automation.

## Complexity Tracking

> No Constitution violations requiring justification. All gates passed.
---

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion (2026-01-28)*

| Principle | Status | Design Validation |
|-----------|--------|-------------------|
| I. Infrastructure as Code First | ✅ PASS | Workflow reinforces IaC by detecting drift from state |
| II. Module-First Architecture | ✅ N/A | Scripts are simple bash, not Terraform modules |
| III. Dynamic Scalability | ✅ PASS | Environment matrix allows `dev` → `prod` without code changes |
| IV. Security & Compliance | ✅ PASS | OIDC auth, read-only permissions, no secrets in logs |
| V. Operational Verification | ✅ PASS | `terraform plan` is the core verification mechanism |

**Design Artifacts Produced**:
- [research.md](research.md) - All technical decisions documented
- [data-model.md](data-model.md) - DriftEvent, ChangeAttribution, DriftReport structures
- [contracts/teams-webhook.json](contracts/teams-webhook.json) - Adaptive Card JSON schema
- [contracts/github-issue.md](contracts/github-issue.md) - Issue template specification
- [quickstart.md](quickstart.md) - Setup prerequisites and verification steps

---

## Implementation Phases (Summary)

### Phase 0 ✅ Complete
- Researched OIDC authentication, Terraform plan parsing, CloudTrail API, Teams webhooks

### Phase 1 ✅ Complete
- Defined data models for drift events and attribution
- Created contracts for Teams webhook payload and GitHub Issue
- Documented setup requirements in quickstart guide

### Phase 2 (Next: `/speckit.tasks`)
- Create implementation tasks from this plan
- Build workflow YAML and supporting scripts
- Test and validate end-to-end functionality