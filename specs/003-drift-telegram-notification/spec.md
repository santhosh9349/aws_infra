# Feature Specification: Telegram Bot Notifications for Drift Detection

**Feature Branch**: `003-drift-telegram-notification`  
**Created**: January 29, 2026  
**Status**: Draft  
**Input**: User description: "remove ms teams notification during drift and add in telegram bot notification"

## Clarifications

### Session 2026-01-29

- Q: When drift detection finds no drift, should the system send a notification? → A: Only notify when drift is detected (no message for clean runs)
- Q: For the exponential backoff retry logic, what should the initial delay and backoff multiplier be? → A: 2s initial, double each time (2s, 4s, 8s)
- Q: Should the system classify drift by severity levels (e.g., critical, warning, info)? → A: No severity classification, treat all drift equally
- Q: When drift details exceed 4096 characters, how should the system handle it? → A: Split into multiple sequential messages (Message 1/3, 2/3, 3/3)
- Q: Where does the drift detection workflow run? → A: GitHub Actions workflow (scheduled via cron)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - DevOps Team Receives Drift Alerts via Telegram (Priority: P1)

When infrastructure drift is detected in the AWS environment, the DevOps team receives immediate notifications through Telegram, allowing them to respond quickly to configuration changes. This replaces the existing MS Teams notification system with a more accessible and mobile-friendly platform.

**Why this priority**: Real-time drift notifications are critical for maintaining infrastructure security and compliance. Telegram provides faster mobile access and better notification reliability compared to MS Teams, enabling quicker response times.

**Independent Test**: Can be fully tested by triggering a drift detection (either actual drift or test scenario), verifying Telegram message is received with drift details, and confirming MS Teams notifications are no longer sent.

**Acceptance Scenarios**:

1. **Given** drift detection workflow runs and finds infrastructure drift, **When** the notification phase executes, **Then** a Telegram message is sent to the configured channel with drift details (affected resources, changes detected, timestamp)
2. **Given** drift detection workflow runs and finds no drift, **When** the notification phase executes, **Then** no Telegram notification is sent
3. **Given** drift detection workflow completes, **When** reviewing notification logs, **Then** no MS Teams notifications are present and MS Teams integration code has been removed
4. **Given** Telegram API is temporarily unavailable, **When** drift notification attempts to send, **Then** the system retries up to 3 times and logs the failure without breaking the workflow

---

### User Story 2 - Configure Telegram Bot Credentials (Priority: P2)

DevOps engineers can configure Telegram bot credentials (bot token and channel ID) through environment variables or configuration files, enabling secure and flexible notification setup without hardcoding sensitive data.

**Why this priority**: Essential for deployment but lower priority than core notification functionality. Credentials must be configurable before the feature can be used in production, but the mechanism is straightforward.

**Independent Test**: Can be tested by providing valid Telegram credentials through configuration, running drift detection, and verifying notifications are successfully delivered to the correct channel.

**Acceptance Scenarios**:

1. **Given** Telegram bot token and channel ID are configured, **When** drift detection runs, **Then** notifications are sent to the specified Telegram channel
2. **Given** Telegram credentials are missing or invalid, **When** drift detection runs, **Then** the workflow logs a clear error message and continues without crashing
3. **Given** credentials are stored in environment variables, **When** the drift detection script initializes, **Then** credentials are securely loaded without appearing in logs ("simple" setup defined as: ≤3 steps, <5 minutes total configuration time)

---

### User Story 3 - View Notification History and Status (Priority: P3)

DevOps team can review notification delivery history and status through workflow logs, confirming that drift alerts were successfully delivered or identifying delivery failures that need attention.

**Why this priority**: Helpful for troubleshooting and auditing but not critical for core functionality. The primary value is delivered through P1 and P2.

**Independent Test**: Can be tested by running drift detection multiple times, then reviewing logs to see notification timestamps, delivery status, and any error messages.

**Acceptance Scenarios**:

1. **Given** drift notifications have been sent, **When** reviewing workflow logs, **Then** each notification attempt shows timestamp, channel ID, and delivery status (success/failure)
2. **Given** a notification fails after all retry attempts, **When** reviewing logs, **Then** the failure is clearly documented with error details
3. **Given** multiple drift detection runs, **When** reviewing notification history, **Then** each run's notifications are clearly separated and identifiable

---

### Edge Cases

- What happens when Telegram bot token expires or is revoked during a drift detection run?
- How does the system handle Telegram rate limits if multiple drift detections trigger simultaneously?
- What happens if the configured Telegram channel is deleted or the bot is removed from the channel?
- How does the system handle extremely large drift reports that exceed Telegram message size limits?
- What happens when running drift detection in environments where Telegram is blocked or restricted?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST send Telegram notifications only when infrastructure drift is detected (no notifications for clean runs)
- **FR-002**: System MUST include the following information in drift notifications: affected resources, type of changes detected, environment name, timestamp, and link to detailed drift report (if available)
- **FR-003**: System MUST remove all MS Teams notification code and dependencies from the drift detection workflow
- **FR-004**: System MUST support configuration of Telegram bot token and channel ID through environment variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID)
- **FR-005**: System MUST implement retry logic for failed Telegram notifications (3 retry attempts with exponential backoff: 2s, 4s, 8s delays)
- **FR-006**: System MUST log all notification attempts including timestamp, delivery status, and error details (if failed)
- **FR-007**: System MUST handle missing or invalid Telegram credentials gracefully by logging an error and continuing the drift detection workflow without crashing
- **FR-008**: System MUST sanitize log output to prevent Telegram bot token from appearing in logs or error messages
- **FR-009**: System MUST support formatting drift details as readable Telegram messages using Markdown formatting
- **FR-010**: System MUST handle messages exceeding Telegram's 4096 character limit by splitting into multiple sequential messages with clear part indicators (e.g., "Message 1/3", "Message 2/3")

### Key Entities

- **Drift Detection Event**: Represents an infrastructure drift detection run with timestamp, environment, affected resources, and detected changes
- **Telegram Notification**: Represents a notification attempt with target channel, message content, delivery status, retry count, and error details (if failed)
- **Configuration**: Contains Telegram bot credentials (token, channel ID) and notification settings (retry count, timeout, formatting options)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: DevOps team receives Telegram notifications within 30 seconds of drift detection completion
- **SC-002**: 99% of drift notifications are successfully delivered to Telegram on first attempt (excluding API outages), measured over 30-day window with minimum 10 drift events
- **SC-003**: Failed notification attempts are successfully delivered within 3 retry attempts in 95% of cases
- **SC-004**: Zero MS Teams notification code or dependencies remain in the codebase after migration
- **SC-005**: Notification setup time is reduced by 50% compared to MS Teams setup (measured from credential creation to first successful notification)
- **SC-006**: 100% of notification delivery failures are logged with clear error messages for troubleshooting

## Assumptions

1. **Telegram Bot Access**: The organization has the ability to create and use Telegram bots for notifications
2. **Network Connectivity**: Infrastructure where drift detection runs has outbound internet access to Telegram API (api.telegram.org)
3. **Channel Configuration**: A Telegram channel or group has been created and the bot has been added with appropriate permissions
4. **Existing Drift Detection**: A functional drift detection workflow already exists that currently uses MS Teams for notifications
5. **Credential Management**: GitHub Actions secrets are used to securely store Telegram bot credentials (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_ID)
6. **Message Format**: Drift reports can be summarized into text format suitable for Telegram messages (under 4096 characters with truncation or splitting as needed)
7. **Python Runtime**: The drift detection workflow runs in a GitHub Actions runner with Python environment where python-telegram-bot library can be installed via pip

## Constraints

- Telegram API rate limits: 30 messages per second per bot (must be respected to avoid API throttling)
- Telegram message size limit: 4096 characters per message (longer content must be split or truncated)
- Notification delivery is dependent on Telegram service availability
- Telegram bot requires one-time setup (bot creation via BotFather, obtaining token, adding to channel)

## Out of Scope

- Two-way communication (responding to notifications, acknowledging alerts)
- Multi-channel support (notifications to multiple Telegram channels simultaneously)
- Custom notification templates or user-configurable message formats
- Integration with Telegram bot commands or interactive features
- SMS or email fallback notifications when Telegram is unavailable
- Historical notification analytics dashboard or reporting
- Migration tooling for existing MS Teams notification history
