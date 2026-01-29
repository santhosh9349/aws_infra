# Implementation Tasks: Telegram Bot Notifications for Drift Detection

**Feature**: Telegram Bot Notifications for Drift Detection  
**Branch**: `003-drift-telegram-notification`  
**Date**: January 29, 2026  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Task Summary

**Total Tasks**: 25  
**Estimated Timeline**: 1 week  
**Tech Stack**: Python 3.11+, python-telegram-bot v20.7+, GitHub Actions

## Phase 1: Setup (Project Initialization)

**Goal**: Initialize project structure and dependencies

**Tasks**:

- [ ] T001 Create scripts/drift-detection/ directory structure
- [ ] T002 Create scripts/drift-detection/requirements.txt with dependencies (python-telegram-bot==20.7, tenacity==8.2.3, pydantic==2.5.0, python-dotenv==1.0.0) - verify exactly 4 core dependencies for minimal dependency principle
- [ ] T003 Create scripts/drift-detection/__init__.py
- [ ] T004 Create .gitignore entry for scripts/drift-detection/.env
- [ ] T005 Create scripts/drift-detection/.env.example with template variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID)

**Checkpoint**: Project structure created, ready for implementation

---

## Phase 2: Core Implementation

**Goal**: Build data models and notification functionality

## Phase 2: Core Implementation

**Goal**: Build data models and notification functionality

**Tasks**:

- [ ] T006 Implement DriftDetectionEvent, ResourceChange, TelegramNotification, and NotificationConfig models in scripts/drift-detection/models.py (from data-model.md)
- [ ] T007 Implement config.py with NotificationConfig.from_env() method in scripts/drift-detection/config.py
- [ ] T008 Implement format_drift_message() and escape_markdown() in scripts/drift-detection/message_formatter.py
- [ ] T009 Implement split_message() in scripts/drift-detection/message_formatter.py (split on resource boundaries, add part indicators)
- [ ] T010 Implement RetryHandler class in scripts/drift-detection/retry_handler.py (exponential backoff 2s, 4s, 8s)
- [ ] T011 Implement TelegramNotifier class in scripts/drift-detection/notify_telegram.py (bot initialization, send logic)
- [ ] T012 Add logging with sanitized credentials in scripts/drift-detection/notify_telegram.py (implement sanitize_for_logging() to show only first/last 4 chars, configure structured logging with JSON format: drift_run_id, timestamp, status, action, error_type)

**Checkpoint**: All core modules implemented

---

## Phase 3: Integration & Cleanup

**Goal**: Integrate with GitHub Actions and remove MS Teams code

## Phase 3: Integration & Cleanup

**Goal**: Integrate with GitHub Actions and remove MS Teams code

**Tasks**:

- [ ] T013 Locate and remove scripts/drift-detection/notify_teams.py (or equivalent MS Teams integration)
- [ ] T014 Remove MS Teams dependencies from requirements.txt if present
- [ ] T015 Search codebase for MS Teams references and remove (grep -r "teams" "msteams" "microsoft teams")
- [ ] T016 Create/update .github/workflows/drift-detection.yml with Telegram notification step
- [ ] T017 Add conditional check (if: steps.drift.outputs.drift_detected == 'true') to notification step
- [ ] T018 Configure environment variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID from secrets)

**Checkpoint**: GitHub Actions integration complete, MS Teams removed

---

## Phase 4: Documentation

**Goal**: Setup guide and basic documentation

**Tasks**:

- [ ] T019 Create docs/drift-detection/telegram-setup.md with Telegram bot setup guide (BotFather, channel setup, GitHub secrets)
- [ ] T020 Update main README.md with Telegram notification section
- [ ] T021 Add basic troubleshooting section (common errors: invalid token, bot not in channel, rate limits)

**Checkpoint**: Documentation complete

---

## Phase 5: Manual Verification

**Goal**: Test the implementation manually

**Tasks**:

- [ ] T022 Create Telegram bot via BotFather and add to test channel
- [ ] T023 Configure GitHub secrets (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID)
- [ ] T024 Trigger drift detection manually and verify notification received
- [ ] T025 Verify message format (Markdown, emojis, timestamps) and MS Teams code completely removed, validate all error paths (timeout, rate limit, auth failure) produce log entries with error message and context

**Checkpoint**: Feature working end-to-end, ready for production

---

## Dependencies

### Task Dependencies (blocking relationships)

```
Setup (T001-T005) → Core Implementation (T006-T012) → Integration (T013-T018) → Documentation (T019-T021) → Verification (T022-T025)
```

### Parallel Execution Opportunities

**Phase 2**: T006-T012 can be worked on in parallel (different files)  
**Phase 3**: T013-T015 (cleanup) can run while T016-T018 (workflow) is being done  
**Phase 4**: T019-T021 can all run in parallel

---

## Implementation Strategy

### Week 1: Complete Implementation

**Days 1-2**: Setup + Core Implementation (T001-T012)
- Set up project structure
- Implement all core modules (models, config, formatter, retry, notifier)

**Days 3-4**: Integration + Cleanup (T013-T018)
- Remove MS Teams code
- Integrate with GitHub Actions workflow
- Configure secrets

**Day 5**: Documentation + Verification (T019-T025)
- Write setup guide
- Manual testing with real Telegram bot
- Verify end-to-end functionality

---

## Success Metrics (from spec.md)

Verify these manually after implementation:

- **SC-001**: Notifications delivered <30 seconds
- **SC-002**: Messages successfully sent on first attempt
- **SC-003**: Retry logic works when API temporarily fails
- **SC-004**: MS Teams code completely removed
- **SC-005**: Setup time faster than MS Teams
- **SC-006**: Failed notifications logged clearly

---

## Notes

- **Message format**: Follow contracts/telegram-message-schema.json for consistency
- **Credential security**: NEVER log full bot token (use sanitize_for_logging())
- **Error handling**: All Telegram API calls must handle exceptions gracefully
- **Markdown escaping**: Critical for Telegram MarkdownV2 parsing

**Next Step**: Begin implementation with Phase 1 (Setup) tasks T001-T005
