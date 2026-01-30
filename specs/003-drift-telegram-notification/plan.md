# Implementation Plan: Telegram Bot Notifications for Drift Detection

**Branch**: `003-drift-telegram-notification` | **Date**: January 29, 2026 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/003-drift-telegram-notification/spec.md`

## Summary

Replace MS Teams notifications with Telegram bot notifications in the drift detection workflow. The system will send drift alerts to a configured Telegram channel when infrastructure changes are detected, implementing retry logic, message splitting for large reports, and secure credential management through GitHub Actions secrets.

**Technical Approach**: Python script integrated into GitHub Actions workflow, using python-telegram-bot library for API communication, with exponential backoff retry (2s, 4s, 8s) and sequential message splitting for reports exceeding 4096 characters.

## Technical Context

**Language/Version**: Python 3.11+  
**Primary Dependencies**: python-telegram-bot (v20.7+), AWS SDK (boto3 for Terraform state reading), GitHub Actions  
**Storage**: GitHub Actions secrets for credentials (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID)  
**Testing**: pytest, pytest-asyncio for async bot operations  
**Target Platform**: GitHub Actions runner (Ubuntu latest)  
**Project Type**: CI/CD automation script (single Python module)  
**Performance Goals**: Notifications delivered within 30 seconds of drift detection completion  
**Constraints**: Telegram API rate limit (30 msg/sec), message size limit (4096 chars), total retry time <15 seconds  
**Scale/Scope**: Single repository, ~500-1000 LOC, supports unlimited drift events

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. IaC First** | All infra in Terraform, remote state | ✅ PASS | N/A - This feature adds workflow automation, not infrastructure |
| **II. Module-First** | Reusable modules required | ✅ PASS | N/A - This is a Python script for CI/CD, not Terraform module |
| **III. Dynamic Scalability** | No hardcoded counts, use for_each | ✅ PASS | N/A - Notification logic doesn't provision infrastructure |
| **IV. Security & Compliance** | Mandatory tags, private subnets, least privilege | ✅ PASS | Credentials secured in GitHub secrets, sanitized from logs |
| **V. Operational Verification** | terraform plan/validate passes | ✅ PASS | N/A - Python script validated via pytest, not Terraform |

**Assessment**: All gates PASS. This feature implements CI/CD workflow automation without provisioning AWS infrastructure, so IaC principles are not applicable. Security principle is upheld through GitHub Actions secrets management and credential sanitization in logs.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

## Project Structure

### Documentation (this feature)

```text
specs/003-drift-telegram-notification/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (implementation plan)
├── research.md          # Phase 0 output (to be created)
├── data-model.md        # Phase 1 output (to be created)
├── quickstart.md        # Phase 1 output (to be created)
├── contracts/           # Phase 1 output (API schemas, message formats)
│   └── telegram-message-schema.json
├── checklists/          # Quality verification
│   └── requirements.md
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
.github/
└── workflows/
    ├── drift-detection.yml           # Main drift detection workflow (to be created/updated)
    └── drift-detection-scheduled.yml # Scheduled cron trigger (optional)

scripts/
└── drift-detection/
    ├── __init__.py
    ├── detect_drift.py               # Terraform state comparison logic
    ├── notify_telegram.py            # New: Telegram notification module
    ├── notify_teams.py               # To be removed: MS Teams integration
    ├── config.py                     # Configuration loader (env vars, secrets)
    ├── message_formatter.py          # New: Format drift data for Telegram
    ├── retry_handler.py              # New: Exponential backoff retry logic
    └── requirements.txt              # Python dependencies

tests/
├── unit/
│   ├── test_notify_telegram.py      # Unit tests for Telegram notification
│   ├── test_message_formatter.py    # Unit tests for message formatting
│   └── test_retry_handler.py        # Unit tests for retry logic
└── integration/
    └── test_workflow_integration.py  # End-to-end workflow tests

docs/
└── drift-detection/
    └── telegram-setup.md             # New: Telegram bot setup guide
```

**Structure Decision**: Single project structure selected. Python scripts organized under `scripts/drift-detection/` to maintain consistency with existing repository organization. GitHub Actions workflows in `.github/workflows/` follow standard GitHub Actions patterns.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. This feature implements workflow automation within established CI/CD patterns.

---

## Phase 0: Research & Technology Evaluation

**Status**: ✅ Complete  
**Output**: [research.md](research.md)

### Deliverables Completed

1. **Library Selection**: python-telegram-bot v20.7+ selected for async support and reliability
2. **Retry Strategy**: Custom exponential backoff (2s, 4s, 8s) using tenacity library
3. **Message Splitting**: Sequential messages with part indicators for reports >4096 chars
4. **GitHub Actions Integration**: Dedicated notification step after drift detection
5. **Credential Management**: GitHub Actions secrets with environment variable interface
6. **Error Handling**: Three-tier strategy (retry, fail, warn) based on error type

### Key Decisions

| Decision | Rationale |
|----------|-----------|
| python-telegram-bot | Best async support, active maintenance, comprehensive docs |
| Exponential backoff | Balances fast recovery with API respect |
| Message splitting | Ensures complete drift details delivered |
| GitHub Actions | Native secret management, existing infrastructure |

---

## Phase 1: Design & Contracts

**Status**: ✅ Complete  
**Outputs**: [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

### Deliverables Completed

1. **Data Models** (data-model.md):
   - `DriftDetectionEvent`: Drift event with resource changes
   - `TelegramNotification`: Notification tracking with retry state
   - `NotificationConfig`: Configuration with validation
   
2. **API Contracts** (contracts/telegram-message-schema.json):
   - Message schema v1.0.0 with metadata, content, part_info
   - JSON Schema validation for all message fields
   - Example messages for single and multi-part notifications

3. **Quickstart Guide** (quickstart.md):
   - Local development setup instructions
   - Telegram bot configuration steps
   - Testing procedures (unit, integration, manual)
   - GitHub Actions integration guide
   - Troubleshooting common issues

### Entity Relationships

```
DriftDetectionEvent (1) ──< (1) TelegramNotification
                                      │
                                      ├─< (1..N) NotificationPart
                                      │
                                      └── (1) NotificationConfig
```

### State Machine: Notification Status

```
[PENDING] ──(send success)──> [SENT]
    │
    └──(retryable error)──> [RETRYING] ──(retry success)──> [SENT]
                               │
                               └──(max retries)──> [FAILED]
```

### Constitution Re-Check (Post-Design)

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. IaC First** | ✅ PASS | No infrastructure changes |
| **II. Module-First** | ✅ PASS | Python module, not Terraform |
| **III. Dynamic Scalability** | ✅ PASS | Not applicable |
| **IV. Security & Compliance** | ✅ PASS | Credentials in GitHub secrets, sanitized logs |
| **V. Operational Verification** | ✅ PASS | pytest coverage >95% target |

**Assessment**: All gates still PASS after design phase. No constitution violations introduced.

---

## Phase 2: Implementation Planning

**Status**: 🔄 Pending (next phase)  
**Tool**: `/speckit.tasks` command  
**Output**: tasks.md

### Implementation Scope

The implementation phase will create:

1. **Core Modules** (5 files):
   - `notify_telegram.py` - Main notification orchestrator
   - `message_formatter.py` - Markdown formatting and splitting
   - `retry_handler.py` - Exponential backoff logic
   - `config.py` - Configuration loading and validation
   - `requirements.txt` - Dependency specifications

2. **Workflow Integration** (2 files):
   - `.github/workflows/drift-detection.yml` - Updated workflow
   - `docs/drift-detection/telegram-setup.md` - Setup guide

3. **Cleanup** (1 file):
   - Remove `scripts/drift-detection/notify_teams.py`

**Total**: 9 files (8 new/updated, 1 removed)

**Note**: Manual verification procedures documented in quickstart.md replace automated test suite per user simplification request.

### Estimated Complexity

| Component | LOC | Complexity | Priority |
|-----------|-----|------------|----------|
| notify_telegram.py | 150-200 | Medium | P1 |
| message_formatter.py | 100-150 | Medium | P1 |
| retry_handler.py | 50-80 | Low | P2 |
| config.py | 80-100 | Low | P2 |
| Workflow integration | 30-50 | Low | P1 |
| Documentation | 200-300 | Low | P3 |

**Total Estimate**: ~600-900 LOC across 9 files

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Telegram API changes | Low | High | Pin library version, monitor deprecations |
| Message formatting edge cases | Medium | Medium | Comprehensive test suite with edge cases |
| Workflow integration conflicts | Low | Medium | Test in separate workflow first |
| Missing MS Teams code | Medium | Low | Search codebase thoroughly before removal |

### Success Criteria

See [spec.md](spec.md) SC-001 through SC-006 for complete success criteria definitions.

---

## Implementation Roadmap

### Week 1: Core Implementation (P1)

**Days 1-2**: Notification Module
- Implement `notify_telegram.py` with basic send functionality
- Implement `message_formatter.py` with Markdown formatting
- Unit tests for both modules (>90% coverage)

**Days 3-4**: Retry & Configuration
- Implement `retry_handler.py` with exponential backoff
- Implement `config.py` with Pydantic validation
- Unit tests for both modules

**Day 5**: Integration
- Update `.github/workflows/drift-detection.yml`
- Integration tests for end-to-end flow
- Manual testing with test Telegram channel

### Week 2: Testing & Cleanup (P2/P3)

**Days 1-2**: Enhanced Testing
- Edge case tests (large messages, special characters, rate limits)
- Performance tests (latency, throughput)
- Error simulation tests

**Days 3-4**: Cleanup & Documentation
- Remove `notify_teams.py` and dependencies
- Create `docs/drift-detection/telegram-setup.md`
- Update main README.md with Telegram instructions

**Day 5**: Review & Polish
- Code review and refactoring
- Documentation review
- Final integration testing in staging

### Week 3: Deployment & Verification

**Days 1-2**: Staging Deployment
- Deploy to staging environment
- Monitor notifications for 48 hours
- Verify success criteria metrics

**Days 3-4**: Production Deployment
- Merge to main branch
- Deploy to production
- Verify production notifications

**Day 5**: Post-Deployment
- Monitor for 24 hours
- Document any issues
- Create runbook for on-call team

---

## Dependencies & Blockers

### External Dependencies

1. **Telegram Bot Setup**: Required before development begins
   - Create bot via BotFather
   - Create test channel
   - Add bot to channel with post permissions
   - **ETA**: 15 minutes

2. **GitHub Secrets Configuration**: Required for workflow testing
   - Add TELEGRAM_BOT_TOKEN secret
   - Add TELEGRAM_CHANNEL_ID secret
   - **ETA**: 5 minutes

### Internal Dependencies

1. **Drift Detection Logic**: Must understand existing implementation
   - Locate drift detection script
   - Understand output format
   - Identify MS Teams integration points
   - **Status**: Research needed (Phase 0 finding)

2. **Development Environment**: Python 3.11+ with pip
   - **Status**: Available on GitHub Actions runners

### Potential Blockers

1. **Missing Drift Detection Code**: If drift detection doesn't exist yet
   - **Mitigation**: Create minimal drift detection script
   - **Impact**: +2-3 days to timeline

2. **Telegram API Restrictions**: If corporate network blocks Telegram
   - **Mitigation**: Request firewall exception for api.telegram.org
   - **Impact**: Variable (depends on security approval process)

3. **GitHub Actions Permissions**: If secrets access restricted
   - **Mitigation**: Request permissions from repository admin
   - **Impact**: 1-2 days for approval

---

## Monitoring & Observability

### Metrics to Track

1. **Notification Delivery Rate**: % of notifications successfully sent
   - **Target**: ≥99% (SC-002)
   - **Source**: GitHub Actions workflow logs

2. **Delivery Latency**: Time from drift detection to notification
   - **Target**: <30 seconds (SC-001)
   - **Source**: Workflow timestamp analysis

3. **Retry Success Rate**: % of failed notifications recovered via retry
   - **Target**: ≥95% (SC-003)
   - **Source**: Retry handler logs

4. **Error Rate by Type**: Distribution of error types
   - **Target**: >80% transient errors (retryable)
   - **Source**: Error categorization logs

### Logging Strategy

**Log Levels**:
- **DEBUG**: Detailed message formatting steps
- **INFO**: Notification sent successfully
- **WARNING**: Retrying after failure (includes retry count)
- **ERROR**: Max retries exhausted or non-retryable error

**Log Format** (JSON):
```json
{
  "timestamp": "2026-01-29T14:30:00Z",
  "level": "INFO",
  "notification_id": "drift_20260129_143000",
  "channel_id": "@devops_alerts",
  "status": "sent",
  "retry_count": 0,
  "latency_ms": 1234,
  "message_parts": 1
}
```

### Alerting

**Alert Conditions**:
1. Notification delivery rate <95% over 24 hours → Page on-call
2. Delivery latency >60 seconds → Warning notification
3. 3 consecutive failures → Page on-call
4. Telegram API rate limit hit → Warning notification

---

## Rollback Plan

### If Issues Arise in Production

**Step 1**: Disable Telegram Notifications
```yaml
# In .github/workflows/drift-detection.yml
- name: Send Telegram Notification
  if: false  # Disable temporarily
```

**Step 2**: Monitor Drift Detection
- Verify drift detection still runs successfully
- Check logs for any workflow failures

**Step 3**: Investigate & Fix
- Review error logs in GitHub Actions
- Test fix in staging environment
- Re-enable with phased rollout

### Rollback Criteria

Trigger rollback if any of these occur:
- Notification delivery rate <80% for 6 hours
- Workflow failures caused by notification step
- Telegram API unavailable >4 hours

### Recovery Time Objective (RTO)

- **Detection**: <15 minutes (monitoring alerts)
- **Diagnosis**: <30 minutes (review logs, identify root cause)
- **Rollback**: <5 minutes (disable notification step)
- **Total RTO**: <1 hour from issue to rollback

---

## Next Steps

1. **Run `/speckit.tasks`** to generate task breakdown in tasks.md
2. **Begin Phase 2 implementation** following tasks.md
3. **Update this plan** if design decisions change during implementation

**Branch**: `003-drift-telegram-notification`  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md) (this document)  
**Research**: [research.md](research.md)  
**Data Model**: [data-model.md](data-model.md)  
**Quickstart**: [quickstart.md](quickstart.md)  
**Contracts**: [contracts/telegram-message-schema.json](contracts/telegram-message-schema.json)
