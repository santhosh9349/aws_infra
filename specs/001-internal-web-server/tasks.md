# Tasks: Internal Web Server for Client Dashboard

**Input**: Design documents from `/specs/001-internal-web-server/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: Not requested in specification - focusing on operational validation via Terraform and AWS testing

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Terraform module structure and development environment setup

- [ ] T001 Verify existing EC2 module structure in terraform/modules/ec2/ (main.tf, variables.tf, outputs.tf exist)
- [ ] T002 Review current Dev VPC infrastructure in terraform/dev/ (VPC ID, subnet IDs, Transit Gateway)
- [ ] T003 [P] Create user data script at specs/001-internal-web-server/contracts/user-data.sh (already exists - validate)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core module enhancements that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Add AWS AMI data source for Amazon Linux 2023 in terraform/modules/ec2/main.tf
- [ ] T005 [P] Create IAM role for SSM access in terraform/modules/ec2/main.tf (aws_iam_role.ssm_role)
- [ ] T006 [P] Create IAM role policy attachment for SSM in terraform/modules/ec2/main.tf (aws_iam_role_policy_attachment.ssm_policy)
- [ ] T007 [P] Create IAM instance profile in terraform/modules/ec2/main.tf (aws_iam_instance_profile.ssm_instance)
- [ ] T008 Create security group resource in terraform/modules/ec2/main.tf (aws_security_group.web_server with dynamic ingress)
- [ ] T009 Update EC2 instance resource in terraform/modules/ec2/main.tf (add IAM profile, security group, encrypted EBS)
- [ ] T010 [P] Add security group variables in terraform/modules/ec2/variables.tf (ingress_cidrs list)
- [ ] T011 [P] Add IAM and security group outputs in terraform/modules/ec2/outputs.tf
- [ ] T012 Run terraform fmt on terraform/modules/ec2/ directory

**Checkpoint**: EC2 module enhanced with SSM, security groups, and encryption - ready for instantiation

---

## Phase 3: User Story 1 - Deploy Secure Internal Server (Priority: P1) 🎯 MVP

**Goal**: Provision an EC2 instance in Dev VPC private subnet with no public internet access

**Independent Test**: Instance is running, has no public IP, cannot be accessed from internet, reachable via SSM Session Manager

### Implementation for User Story 1

- [ ] T013 [US1] Create/update terraform/dev/ec2.tf with internal_web_server module instantiation
- [ ] T014 [US1] Set instance name to "dev-internal-web-server" in terraform/dev/ec2.tf
- [ ] T015 [US1] Configure instance to use priv_sub1 subnet in Dev VPC in terraform/dev/ec2.tf
- [ ] T016 [US1] Set instance_type to t3.small in terraform/dev/ec2.tf
- [ ] T017 [US1] Reference user-data.sh script from contracts/ directory in terraform/dev/ec2.tf
- [ ] T018 [US1] Apply mandatory tags (Environment, Project, ManagedBy, Owner, CostCenter, VPC) in terraform/dev/ec2.tf
- [ ] T019 [US1] Add instance outputs to terraform/dev/outputs.tf (instance_id, private_ip, security_group_id)
- [ ] T020 [US1] Run terraform fmt, terraform validate in terraform/dev/
- [ ] T021 [US1] Run terraform plan in terraform/dev/ and verify 5 resources to be added
- [ ] T022 [US1] Run terraform apply in terraform/dev/ to deploy instance
- [ ] T023 [US1] Verify instance state is "running" via AWS CLI (aws ec2 describe-instances)
- [ ] T024 [US1] Verify instance has NO public IP address via AWS CLI
- [ ] T025 [US1] Verify SSM Session Manager connectivity (aws ssm start-session --target <instance-id>)
- [ ] T026 [US1] Verify SSH connection fails (connection refused or timeout)

**Checkpoint**: User Story 1 complete - secure internal server deployed and verified

---

## Phase 4: User Story 2 - Enable Internal HTTPS Connectivity (Priority: P2)

**Goal**: Configure security group to accept HTTPS traffic from all internal VPCs (Inspection, Dev, Prod)

**Independent Test**: HTTPS requests from instances in other VPCs (192.0.0.0/16, 10.0.0.0/16) successfully reach the web server

### Implementation for User Story 2

- [ ] T027 [US2] Verify ingress_cidrs variable includes all internal VPC CIDRs in terraform/dev/ec2.tf (192.0.0.0/16, 172.0.0.0/16, 10.0.0.0/16)
- [ ] T028 [US2] Run terraform plan to verify security group rules are correct (HTTPS port 443 from internal CIDRs)
- [ ] T029 [US2] Verify security group has NO port 22 (SSH) ingress rules via AWS CLI
- [ ] T030 [US2] Verify security group has NO 0.0.0.0/0 ingress rules via AWS CLI
- [ ] T031 [US2] Test HTTPS connectivity from Dev VPC instance (curl -k https://<private-ip>/)
- [ ] T032 [US2] Test HTTPS connectivity from another internal VPC if available (Inspection or Prod VPC instance)
- [ ] T033 [US2] Verify nginx health endpoint responds (curl -k https://<private-ip>/health)
- [ ] T034 [US2] Verify HTTP port 80 returns info message (curl http://<private-ip>/)

**Checkpoint**: User Story 2 complete - HTTPS connectivity from all internal VPCs verified

---

## Phase 5: User Story 3 - Optimize Resource Footprint (Priority: P3)

**Goal**: Ensure instance uses minimal computing resources (t3.small) appropriate for development

**Independent Test**: Instance type is t3.small, EBS volume is 20GB gp3, resource utilization is appropriate for dev workload

### Implementation for User Story 3

- [ ] T035 [US3] Verify instance_type is set to t3.small in terraform/dev/ec2.tf (already set in US1)
- [ ] T036 [US3] Verify root_block_device volume_size is 20 GB in terraform/modules/ec2/main.tf (already set in Phase 2)
- [ ] T037 [US3] Verify root_block_device volume_type is gp3 in terraform/modules/ec2/main.tf (already set in Phase 2)
- [ ] T038 [US3] Check instance details via AWS CLI (aws ec2 describe-instances) to confirm t3.small
- [ ] T039 [US3] Check EBS volume details via AWS CLI (aws ec2 describe-volumes) to confirm 20GB gp3 encrypted
- [ ] T040 [US3] Connect via SSM and check system resources (free -h, df -h)
- [ ] T041 [US3] Monitor CPU and memory usage via CloudWatch for 10-15 minutes to verify no over-provisioning
- [ ] T042 [US3] Calculate estimated monthly cost (~$15/month for t3.small 24/7 + EBS)

**Checkpoint**: User Story 3 complete - resource footprint optimized and verified

---

## Phase 6: User Story 4 - Ensure Resource Identification (Priority: P3)

**Goal**: All infrastructure resources have mandatory tags for cost tracking and ownership

**Independent Test**: Query instance tags via AWS CLI and verify all 7 mandatory tags are present with correct values

### Implementation for User Story 4

- [ ] T043 [US4] Verify all mandatory tags are present in terraform/dev/ec2.tf module call (already set in US1)
- [ ] T044 [US4] Query instance tags via AWS CLI (aws ec2 describe-tags --filters "Name=resource-id,Values=<instance-id>")
- [ ] T045 [US4] Verify Environment tag = "dev"
- [ ] T046 [US4] Verify Project tag = "AWS Infrastructure"
- [ ] T047 [US4] Verify ManagedBy tag = "Terraform"
- [ ] T048 [US4] Verify Owner tag = "DevOps Team"
- [ ] T049 [US4] Verify CostCenter tag = "dev"
- [ ] T050 [US4] Verify VPC tag = "dev"
- [ ] T051 [US4] Verify Name tag = "dev-internal-web-server"
- [ ] T052 [US4] Query security group tags and verify same mandatory tags
- [ ] T053 [US4] Query IAM role tags and verify same mandatory tags
- [ ] T054 [US4] Generate AWS Cost Explorer report filtered by Environment=dev tag
- [ ] T055 [US4] Verify server costs are correctly attributed to development budget

**Checkpoint**: User Story 4 complete - all resources properly tagged and trackable

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, cleanup, and final validation

- [ ] T056 [P] Update terraform/dev/README.md with internal web server deployment instructions (if exists)
- [ ] T057 [P] Add internal web server section to main README.md with architecture overview
- [ ] T058 Validate all success criteria from spec.md are met (SC-001 through SC-010)
- [ ] T059 Run complete quickstart.md validation from another AWS account/region (if feasible)
- [ ] T060 [P] Create architectural diagram showing web server in Dev VPC with TGW connectivity
- [ ] T061 Document known limitations (self-signed certificate, single instance, no HA)
- [ ] T062 [P] Update .github/copilot-instructions.md with web server deployment patterns (already done)
- [ ] T063 Create handoff documentation for application team (how to deploy dashboard app)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (Phase 3): Foundation → Deploy server
  - User Story 2 (Phase 4): User Story 1 complete → Enable HTTPS connectivity
  - User Story 3 (Phase 5): User Story 1 complete (can run in parallel with US2)
  - User Story 4 (Phase 6): User Story 1 complete (can run in parallel with US2/US3)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Requires Foundational phase - Fully independent MVP
- **User Story 2 (P2)**: Requires User Story 1 (server must exist to test connectivity)
- **User Story 3 (P3)**: Requires User Story 1 (server must exist to verify resources) - Can run parallel to US2/US4
- **User Story 4 (P3)**: Requires User Story 1 (resources must exist to verify tags) - Can run parallel to US2/US3

### Within Each User Story

- User Story 1: Terraform configuration → plan → apply → verify (sequential)
- User Story 2: Verify config → test connectivity (sequential)
- User Story 3: Check configuration → monitor resources (sequential)
- User Story 4: Query tags → verify values → test cost reporting (sequential)

### Parallel Opportunities

**Phase 1 (Setup)**:
- T001, T002, T003 can all run in parallel (different review/validation tasks)

**Phase 2 (Foundational)**:
- T005, T006, T007 (IAM resources) can run in parallel - different resources in same file
- T010, T011 can run in parallel with IAM tasks - different files

**Phase 7 (Polish)**:
- T056, T057, T060, T062 (documentation tasks) can all run in parallel - different files

**User Stories After US1**:
- Once User Story 1 is complete, User Stories 2, 3, and 4 can run in parallel (different validation/testing activities)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# These tasks can be launched together as they modify different resources:
T005: Create IAM role (aws_iam_role.ssm_role)
T006: Create IAM policy attachment (aws_iam_role_policy_attachment.ssm_policy)
T007: Create IAM instance profile (aws_iam_instance_profile.ssm_instance)
T010: Add variables in variables.tf
T011: Add outputs in outputs.tf
```

## Parallel Example: User Stories 2, 3, 4

```bash
# After User Story 1 completes, these can run in parallel:
Phase 4 (US2): Test HTTPS connectivity from other VPCs
Phase 5 (US3): Verify resource footprint and monitor usage
Phase 6 (US4): Query and verify all tags
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (validate existing infrastructure)
2. Complete Phase 2: Foundational (enhance EC2 module) - **CRITICAL**
3. Complete Phase 3: User Story 1 (deploy secure server)
4. **STOP and VALIDATE**: 
   - Instance running ✅
   - No public IP ✅
   - SSM access works ✅
   - SSH blocked ✅
5. Deploy/Demo MVP → Secure internal server operational

### Incremental Delivery

1. **Setup + Foundational** → Enhanced EC2 module ready
2. **Add User Story 1** → Deploy server → Test independently → **Demo: Secure internal server** 🎯
3. **Add User Story 2** → Enable HTTPS → Test connectivity → **Demo: Cross-VPC communication**
4. **Add User Story 3** → Verify resources → Monitor usage → **Demo: Cost-optimized deployment**
5. **Add User Story 4** → Verify tags → Cost reports → **Demo: Full compliance & tracking**
6. Each story adds value without breaking previous functionality

### Parallel Team Strategy (if multiple team members available)

With 2-3 infrastructure engineers:

1. **Together**: Complete Setup + Foundational phases (everyone needs the enhanced module)
2. **Once Foundational is done**:
   - **Engineer A**: User Story 1 (deploy server) - **Must complete first**
3. **After User Story 1 completes**:
   - **Engineer A**: User Story 2 (HTTPS connectivity testing)
   - **Engineer B**: User Story 3 (resource optimization validation)
   - **Engineer C**: User Story 4 (tagging compliance verification)
4. **Polish**: Team reviews documentation and creates handoff materials

---

## Success Criteria Checklist

Track completion against specification requirements:

### User Story 1 - Deploy Secure Internal Server
- [ ] SC-001: Server provisioned and operational within 5 minutes ✅
- [ ] SC-002: Zero public internet accessibility (100% blocked) ✅
- [ ] SC-004: SSH completely disabled (0% success rate) ✅
- [ ] SC-010: Deployment without manual intervention ✅

### User Story 2 - Enable Internal HTTPS Connectivity
- [ ] SC-003: Accepts 100% of valid HTTPS connections from internal VPCs ✅
- [ ] SC-008: Internal services from all VPCs can establish HTTPS connections ✅
- [ ] SC-009: Non-HTTPS traffic blocked (100% rejection rate) ✅

### User Story 3 - Optimize Resource Footprint
- [ ] SC-005: Minimal cost footprint (t3.small, smallest suitable size) ✅

### User Story 4 - Ensure Resource Identification
- [ ] SC-006: 100% of costs attributed to dev environment ✅
- [ ] SC-007: All mandatory tags present in metadata ✅

### All Requirements Met
- [ ] FR-001 through FR-010: All functional requirements satisfied ✅
- [ ] Constitution compliance: All 5 principles validated ✅
- [ ] Deployment documentation complete ✅

---

## Notes

- **No automated tests**: Infrastructure validation relies on Terraform plan/apply and AWS CLI verification
- **[P] markers**: Tasks that operate on different files or resources (can run in parallel)
- **[Story] labels**: Map each task to its user story for traceability (US1, US2, US3, US4)
- **Sequential nature**: Terraform apply operations must be sequential (cannot apply multiple conflicting changes)
- **Independent stories**: Each user story can be tested independently after US1 establishes the foundation
- **Commit strategy**: Commit after each completed user story phase for rollback capability
- **Stop at checkpoints**: Validate each user story independently before proceeding
- **Cost tracking**: Monitor AWS costs throughout deployment to ensure budget compliance

---

## Risk Mitigation

### Infrastructure Risks
- **Instance capacity**: If t3.small unavailable in AZ, T035 allows instance_type override
- **SSM connectivity**: Ensure VPC has route to SSM endpoints (via NAT Gateway or VPC endpoints)
- **Security group conflicts**: Verify no existing rules conflict with HTTPS requirements

### Operational Risks
- **Terraform state**: Always use Terraform Cloud remote state (never local state)
- **Concurrent applies**: Coordinate team to avoid simultaneous terraform apply operations
- **Rollback**: Keep git commits small (per user story) for easy rollback if needed

---

## Total Task Count: 63 tasks

- **Setup**: 3 tasks (validation and review)
- **Foundational**: 9 tasks (module enhancement - BLOCKS all stories)
- **User Story 1**: 14 tasks (deploy and verify secure server) - **MVP**
- **User Story 2**: 8 tasks (enable and test HTTPS connectivity)
- **User Story 3**: 8 tasks (optimize and verify resource footprint)
- **User Story 4**: 13 tasks (verify tagging compliance and cost tracking)
- **Polish**: 8 tasks (documentation and handoff)

**Estimated Timeline**:
- MVP (Phases 1-3): 4-6 hours
- Full Feature (All Phases): 8-12 hours
- With parallel execution: 6-8 hours

---

## Quick Reference

### File Paths
- Module: `terraform/modules/ec2/` (main.tf, variables.tf, outputs.tf)
- Environment: `terraform/dev/ec2.tf`, `terraform/dev/outputs.tf`
- Contracts: `specs/001-internal-web-server/contracts/`
- Documentation: `specs/001-internal-web-server/` (plan.md, quickstart.md, etc.)

### Key Commands
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Review changes
terraform plan

# Apply changes
terraform apply

# Test SSM access
aws ssm start-session --target <instance-id>

# Test HTTPS
curl -k https://<private-ip>/
```
