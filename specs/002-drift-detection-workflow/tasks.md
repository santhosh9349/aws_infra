# Tasks: Terraform Drift Detection Workflow

**Input**: Design documents from `/specs/002-drift-detection-workflow/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: No automated tests requested - manual workflow validation via `workflow_dispatch`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- Workflow: `.github/workflows/`
- Scripts: `scripts/drift-detection/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository configuration and project structure

- [x] T001 Create directory structure `scripts/drift-detection/`
- [x] T002 [P] Create GitHub labels: `drift` (red), `infrastructure` (blue), `automated` (purple), `dev` (teal)
- [ ] T003 [P] Configure repository secret `TEAMS_WEBHOOK_URL` in GitHub Settings *(manual: Settings → Secrets → Actions)*
- [ ] T004 [P] Verify repository secret `TF_API_TOKEN` exists for Terraform Cloud access *(manual: Settings → Secrets → Actions)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Verify AWS IAM role `arn:aws:iam::017373135945:role/github_oidc_drift` has required permissions (EC2:Describe*, CloudTrail:LookupEvents) *(manual: AWS Console)*
- [ ] T006 Verify OIDC Identity Provider exists in AWS account for `token.actions.githubusercontent.com` *(manual: AWS Console)*
- [x] T007 Create workflow skeleton `.github/workflows/drift-detection.yml` with schedule trigger (cron: `0 8 * * *` for 9AM BST)
- [x] T008 [P] Add `workflow_dispatch` trigger for manual testing with environment input

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Scheduled Drift Detection (Priority: P1) 🎯 MVP

**Goal**: Workflow runs daily at 9AM BST and executes `terraform plan -detailed-exitcode`

**Independent Test**: Manually trigger workflow via `workflow_dispatch`, verify Terraform plan runs and exit code is captured correctly (0=no drift, 2=drift detected)

### Implementation for User Story 1

- [x] T009 [US1] Add permissions block to workflow (`id-token: write`, `contents: read`, `issues: write`)
- [x] T010 [US1] Add checkout step using `actions/checkout@v4`
- [x] T011 [US1] Add AWS credentials step using `aws-actions/configure-aws-credentials@v4` with OIDC role `arn:aws:iam::017373135945:role/github_oidc_drift`
- [x] T012 [US1] Add Terraform setup step using `hashicorp/setup-terraform@v3` with Terraform Cloud credentials
- [x] T013 [US1] Add Terraform init step for `terraform/dev/` directory
- [x] T014 [US1] Add Terraform plan step with `-detailed-exitcode -out=tfplan` and capture exit code
- [x] T015 [US1] Add conditional logic: exit 0 = success (no drift), exit 1 = fail workflow, exit 2 = continue to drift processing
- [x] T016 [US1] Add `terraform show -json tfplan > plan.json` step when drift detected

**Checkpoint**: At this point, User Story 1 should be fully functional - workflow detects drift and captures plan output

---

## Phase 4: User Story 2 - GitHub Issue Creation on Drift (Priority: P1)

**Goal**: When drift is detected (exit code 2), create GitHub Issue with IAM attribution, resource changes, and timestamps

**Independent Test**: Introduce manual drift via AWS Console (e.g., add tag to VPC), trigger workflow, verify issue is created with correct content including IAM user ARN

### Implementation for User Story 2

- [x] T017 [P] [US2] Create script `scripts/drift-detection/parse-terraform-plan.sh` to extract changed resources from plan.json using jq
- [x] T018 [P] [US2] Create script `scripts/drift-detection/query-cloudtrail.sh` to lookup IAM user for each resource ID via AWS CLI (return "*(unavailable)*" if no events found)
- [x] T019 [US2] Add workflow step to run `parse-terraform-plan.sh` and output resource list
- [x] T020 [US2] Add workflow step to run `query-cloudtrail.sh` for each drifted resource
- [x] T020a [US2] Add fallback handling in `query-cloudtrail.sh`: return "*(unavailable)*" for IAM user and "-" for timestamp when CloudTrail returns no events (>90 days old, missing logs, or service-initiated changes)
- [x] T021 [US2] Add workflow step to generate issue body markdown from template in `contracts/github-issue.md`
- [x] T022 [US2] Add workflow step to create GitHub Issue using `gh issue create` with labels `drift,infrastructure,automated,dev`
- [x] T023 [US2] Capture created issue URL in workflow output for use by Teams notification

**Checkpoint**: At this point, drift detection creates detailed GitHub Issues with IAM attribution

---

## Phase 5: User Story 3 - Microsoft Teams Notification (Priority: P2)

**Goal**: Send Teams notification with Adaptive Card when drift is detected, including link to GitHub Issue

**Independent Test**: Trigger workflow with drift present, verify Teams message appears in `Drift_notification_tf` channel with correct summary and issue link

### Implementation for User Story 3

- [x] T024 [P] [US3] Create script `scripts/drift-detection/format-teams-card.sh` to generate Adaptive Card JSON per `contracts/teams-webhook.json` schema
- [x] T025 [US3] Add workflow step to run `format-teams-card.sh` with issue URL and drift summary
- [x] T026 [US3] Add workflow step to POST Adaptive Card JSON to `${{ secrets.TEAMS_WEBHOOK_URL }}` using curl
- [x] T027 [US3] Add error handling for webhook failures (continue workflow, log error)

**Checkpoint**: Full notification pipeline complete - drift creates issue AND sends Teams alert

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, documentation, and edge cases

- [x] T028 Add workflow step to handle Terraform state lock errors (wait 5min, retry once)
- [x] T029 Add workflow output summary showing drift count or "No drift detected"
- [x] T030 [P] Update README.md with drift detection workflow documentation
- [ ] T031 Run quickstart.md validation checklist (OIDC auth, manual trigger, drift test, schedule verify) *(manual: see quickstart.md)*
- [x] T032 [P] Add workflow badge to repository README showing drift detection status

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 but US2 depends on US1 outputs (plan.json)
  - US3 depends on US2 (needs issue URL)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1: Setup
    │
    ▼
Phase 2: Foundational
    │
    ▼
Phase 3: US1 - Drift Detection
    │
    ▼
Phase 4: US2 - GitHub Issue (needs plan.json from US1)
    │
    ▼
Phase 5: US3 - Teams Notification (needs issue URL from US2)
    │
    ▼
Phase 6: Polish
```

### Within Each User Story

- Scripts can be developed in parallel [P]
- Workflow steps must be sequential within the YAML
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1** (all parallel):
```bash
T002: Create GitHub labels
T003: Configure TEAMS_WEBHOOK_URL secret
T004: Verify TF_API_TOKEN secret
```

**Phase 2** (T007 first, then T008 parallel):
```bash
T007: Create workflow skeleton (first)
T008: Add workflow_dispatch (parallel after T007)
```

**Phase 4** (scripts parallel, then workflow steps sequential):
```bash
# Parallel script development:
T017: parse-terraform-plan.sh
T018: query-cloudtrail.sh

# Sequential workflow integration:
T019 → T020 → T021 → T022 → T023
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T008)
3. Complete Phase 3: User Story 1 (T009-T016)
4. **STOP and VALIDATE**: Trigger workflow manually, verify Terraform plan runs
5. Deploy to main branch if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test drift detection → **MVP Complete!**
3. Add User Story 2 → Test issue creation → **Alerting Complete!**
4. Add User Story 3 → Test Teams notification → **Full Feature Complete!**

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- AWS role ARN: `arn:aws:iam::017373135945:role/github_oidc_drift`
- Cron schedule: `0 8 * * *` (8:00 UTC = 9:00 BST during summer, adjust for DST)
- Terraform Cloud org: `santhosh9349`, workspace: `aws_infra`
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
