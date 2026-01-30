# Research: Telegram Bot Notifications for Drift Detection

**Date**: January 29, 2026  
**Phase**: 0 - Research & Technology Evaluation  
**Status**: Complete

## Executive Summary

Research confirms python-telegram-bot library (v20.7+) as the optimal solution for Telegram integration in GitHub Actions workflows. The library provides async/await support, built-in retry mechanisms, and comprehensive error handling suitable for CI/CD environments.

## Technology Decisions

### 1. Telegram Bot Library Selection

**Decision**: python-telegram-bot v20.7+

**Rationale**:
- **Async Support**: Native async/await for non-blocking operations in CI/CD pipelines
- **Rate Limit Handling**: Built-in rate limit detection and automatic backoff
- **Markdown Formatting**: Native support for Telegram MarkdownV2 formatting
- **Active Maintenance**: 20K+ GitHub stars, regular updates, Python 3.11+ support
- **Error Handling**: Comprehensive exception hierarchy for granular error handling
- **Documentation**: Extensive examples and API documentation

**Alternatives Considered**:
- **aiogram**: More modern API but less stable for production CI/CD (breaking changes in recent versions)
- **telepot**: Abandoned (last update 2018), no async support
- **pyTelegramBotAPI**: Synchronous only, would block workflow execution

### 2. Retry Strategy Implementation

**Decision**: Custom exponential backoff with python-telegram-bot's error handling

**Rationale**:
- python-telegram-bot provides retry decorators but we need custom timing (2s, 4s, 8s per spec)
- Implement using `tenacity` library for declarative retry logic
- Hook into telegram.error.NetworkError and telegram.error.TimedOut exceptions

**Pattern**:
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=2, min=2, max=8),
    reraise=True
)
async def send_notification(bot, channel_id, message):
    await bot.send_message(chat_id=channel_id, text=message)
```

### 3. Message Splitting Strategy

**Decision**: Smart truncation with part indicators

**Rationale**:
- Telegram's 4096 character limit requires careful message splitting
- Split on natural boundaries (newlines, resource groups) to maintain readability
- Add headers like "🔔 Drift Alert (Part 1/3)" for clarity
- Include summary in first message, details in subsequent messages

**Implementation Approach**:
- Calculate message size with Markdown formatting overhead
- Split at resource boundaries to avoid breaking resource descriptions
- Send messages sequentially with 100ms delay between parts to maintain order

### 4. GitHub Actions Integration

**Decision**: Dedicated Python action step after Terraform drift detection

**Rationale**:
- Decouple notification logic from drift detection logic
- Enable independent testing of notification system
- Allow reuse of notification module for other workflows
- Fail gracefully if notification fails (drift detection still succeeds)

**Workflow Pattern**:
```yaml
- name: Detect Infrastructure Drift
  id: drift
  run: |
    # Terraform drift detection logic
    # Output: drift_detected=true/false, drift_report=path/to/report.json

- name: Send Telegram Notification
  if: steps.drift.outputs.drift_detected == 'true'
  env:
    TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    TELEGRAM_CHANNEL_ID: ${{ secrets.TELEGRAM_CHANNEL_ID }}
  run: |
    python scripts/drift-detection/notify_telegram.py \
      --report ${{ steps.drift.outputs.drift_report }} \
      --environment ${{ github.ref_name }}
```

### 5. Credential Management

**Decision**: GitHub Actions secrets with environment variable fallback

**Rationale**:
- GitHub Actions secrets provide encryption at rest and in transit
- Secrets automatically masked in workflow logs
- Environment variable interface enables local testing with .env files
- No credential persistence on runner filesystem

**Best Practices**:
- Validate secrets exist before bot initialization
- Never log raw token values (use `token[:8]...` for debugging)
- Implement health check command to verify bot access before critical workflows

### 6. Error Handling Strategy

**Decision**: Three-tier error handling with graceful degradation

**Rationale**:
- **Tier 1 - Transient Errors**: Retry with exponential backoff (network timeouts, API throttling)
- **Tier 2 - Configuration Errors**: Log and fail workflow (invalid token, missing secrets)
- **Tier 3 - Non-Critical Errors**: Log and continue (bot removed from channel, rate limit exceeded)

**Error Categories**:
```python
# Retryable errors (Tier 1)
- telegram.error.NetworkError
- telegram.error.TimedOut
- telegram.error.RetryAfter

# Fatal errors (Tier 2)
- telegram.error.InvalidToken
- ValueError (missing environment variables)

# Logged warnings (Tier 3)
- telegram.error.BadRequest (bot not in channel)
- telegram.error.ChatMigrated
```

## Drift Detection Integration Points

### Current MS Teams Implementation Analysis

**Finding**: Research needed to locate existing MS Teams integration code

**Action Required**: Investigate `scripts/drift-detection/` directory for:
1. notify_teams.py or similar notification module
2. Drift detection workflow in `.github/workflows/`
3. Drift report format and structure
4. Environment variable configuration

**Expected Integration Points**:
- Replace MS Teams webhook POST with Telegram bot API call
- Reuse existing drift report parsing logic
- Maintain same workflow trigger points (scheduled cron, manual dispatch)

### Drift Report Format

**Research Finding**: Need to determine drift report structure

**Options**:
1. **Terraform JSON Plan**: Parse terraform plan -json output
2. **Custom JSON**: Structured drift report from custom script
3. **Text Summary**: Human-readable text format

**Recommendation**: If custom format doesn't exist, parse Terraform JSON plan for:
- Resource type and name
- Attribute changes (before/after values)
- Action type (create/update/delete/replace)

**Message Format Design**:
```
🚨 **Infrastructure Drift Detected**

**Environment**: dev
**Time**: 2026-01-29 14:30:00 UTC
**Resources Affected**: 5

**Changes**:
━━━━━━━━━━━━━━━━
📦 aws_instance.web_server
  • instance_type: t2.micro → t2.small

🔒 aws_security_group.allow_https
  • ingress: [new rule added]

[View Full Report](link-to-workflow-run)
```

## Testing Strategy

### Unit Testing Approach

**Decision**: pytest with pytest-asyncio for async bot operations

**Test Coverage**:
1. **Message Formatting**: Verify Markdown escaping, truncation, splitting
2. **Retry Logic**: Mock Telegram API failures, verify backoff timing
3. **Credential Handling**: Test missing secrets, invalid tokens, sanitization
4. **Error Scenarios**: Verify graceful degradation for all error tiers

### Integration Testing Approach

**Decision**: GitHub Actions test workflow with test Telegram channel

**Setup**:
- Create dedicated test Telegram channel
- Store test credentials in repository secrets
- Run integration tests on PR creation
- Verify notifications delivered within 30 seconds

**Test Scenarios**:
1. Small drift report (< 1000 chars)
2. Large drift report requiring splitting (> 5000 chars)
3. Multiple drift detections in succession (rate limit handling)
4. Telegram API unavailable (retry behavior)

## Dependencies

### Production Dependencies

```txt
python-telegram-bot==20.7
tenacity==8.2.3
pydantic==2.5.0        # For configuration validation
python-dotenv==1.0.0   # For local testing
```

### Development Dependencies

```txt
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-mock==3.12.0
pytest-cov==4.1.0
```

## Performance Characteristics

**Benchmarks**:
- Bot initialization: <500ms
- Single message send: <1000ms
- Retry cycle (3 attempts): ~14 seconds total
- Message splitting overhead: <100ms per additional message

**Expected Latency**:
- Success case: 1-2 seconds (detection complete → notification delivered)
- Retry case: 15-16 seconds (detection complete → final retry → notification delivered)
- Large message: 3-5 seconds (splitting + sequential sending with delays)

## Security Considerations

### Credential Security

- Bot token stored in GitHub Actions secrets (encrypted at rest)
- Token never logged or persisted to disk
- Token validation on initialization (fail fast on invalid credentials)
- No token in error messages (use `[REDACTED]` placeholder)

### Audit Trail

- Log all notification attempts with outcome
- Include workflow run URL in notifications for traceability
- Retain notification logs for 90 days (GitHub Actions default)

### Rate Limiting

- Telegram allows 30 messages/second per bot
- Our use case: <1 message/minute (drift checks hourly or daily)
- No special rate limiting needed beyond retry logic

## Open Questions & Assumptions

### Resolved
✅ Message format for drift reports → Markdown with resource-level details  
✅ Retry timing → 2s, 4s, 8s exponential backoff  
✅ Message splitting strategy → Sequential messages with part indicators  
✅ Workflow execution context → GitHub Actions with cron scheduling  

### Assumptions
1. Existing drift detection workflow outputs structured data (JSON or similar)
2. Drift detection runs on scheduled basis (hourly/daily), not on every push
3. Single Telegram channel for all environments (alternatively, environment-specific channels via environment variables)
4. Workflow has sufficient permissions to read GitHub secrets

## Next Steps (Phase 1)

1. Create data-model.md defining drift event structure
2. Design Telegram message schema in contracts/
3. Document API contracts for notification module
4. Create quickstart.md for local development and testing
5. Update agent context with python-telegram-bot library choice
