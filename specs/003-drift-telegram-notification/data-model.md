# Data Model: Telegram Bot Notifications for Drift Detection

**Date**: January 29, 2026  
**Phase**: 1 - Design  
**Status**: Complete

## Overview

This document defines the data structures for drift detection events, Telegram notifications, and configuration management. All models use Pydantic for validation and type safety.

## Core Entities

### 1. DriftDetectionEvent

Represents a single infrastructure drift detection run with all detected changes.

```python
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field
from enum import Enum

class ActionType(str, Enum):
    """Terraform action types"""
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    REPLACE = "replace"
    NO_OP = "no-op"

class ResourceChange(BaseModel):
    """Individual resource change detected in drift"""
    resource_type: str = Field(..., description="AWS resource type (e.g., aws_instance)")
    resource_name: str = Field(..., description="Resource name in Terraform")
    action: ActionType = Field(..., description="Type of change detected")
    before: Optional[dict] = Field(None, description="Attribute values before change")
    after: Optional[dict] = Field(None, description="Attribute values after change")
    
    @property
    def display_name(self) -> str:
        """Human-readable resource identifier"""
        return f"{self.resource_type}.{self.resource_name}"
    
    @property
    def change_summary(self) -> List[str]:
        """List of changed attributes with before/after values"""
        if not self.before or not self.after:
            return [f"Action: {self.action.value}"]
        
        changes = []
        for key in self.before.keys() | self.after.keys():
            before_val = self.before.get(key, "[not set]")
            after_val = self.after.get(key, "[not set]")
            if before_val != after_val:
                changes.append(f"{key}: {before_val} → {after_val}")
        return changes

class DriftDetectionEvent(BaseModel):
    """Complete drift detection event"""
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    environment: str = Field(..., description="Target environment (dev/prod)")
    branch: str = Field(..., description="Git branch where detection ran")
    workflow_run_id: str = Field(..., description="GitHub Actions run ID")
    workflow_run_url: str = Field(..., description="URL to view workflow run")
    
    drift_detected: bool = Field(..., description="Whether any drift was found")
    resource_changes: List[ResourceChange] = Field(default_factory=list)
    
    @property
    def total_changes(self) -> int:
        """Total number of resource changes"""
        return len(self.resource_changes)
    
    @property
    def changes_by_action(self) -> dict:
        """Count changes grouped by action type"""
        from collections import Counter
        return dict(Counter(change.action for change in self.resource_changes))
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return self.model_dump(mode='json')
```

**Relationships**:
- One DriftDetectionEvent contains zero or many ResourceChange instances
- Each ResourceChange represents one Terraform resource with detected drift

**Validation Rules**:
- `drift_detected=True` requires at least one ResourceChange
- `drift_detected=False` must have empty resource_changes list
- timestamp is auto-generated in UTC
- workflow_run_url must be valid GitHub Actions URL

---

### 2. TelegramNotification

Represents a notification attempt with delivery tracking.

```python
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field
from enum import Enum

class DeliveryStatus(str, Enum):
    """Notification delivery status"""
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    RETRYING = "retrying"

class NotificationPart(BaseModel):
    """Individual message part for split messages"""
    part_number: int = Field(..., ge=1)
    total_parts: int = Field(..., ge=1)
    content: str = Field(..., max_length=4096)
    telegram_message_id: Optional[int] = Field(None, description="Telegram message ID after sending")

class TelegramNotification(BaseModel):
    """Telegram notification attempt"""
    notification_id: str = Field(..., description="Unique notification identifier")
    drift_event: DriftDetectionEvent = Field(..., description="Associated drift event")
    
    channel_id: str = Field(..., description="Telegram channel/chat ID")
    message_parts: List[NotificationPart] = Field(default_factory=list)
    
    status: DeliveryStatus = Field(default=DeliveryStatus.PENDING)
    retry_count: int = Field(default=0, ge=0, le=3)
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    sent_at: Optional[datetime] = None
    error_message: Optional[str] = None
    error_type: Optional[str] = None
    
    def mark_sent(self, sent_at: datetime = None):
        """Mark notification as successfully sent"""
        self.status = DeliveryStatus.SENT
        self.sent_at = sent_at or datetime.utcnow()
    
    def mark_failed(self, error: Exception):
        """Mark notification as failed"""
        self.status = DeliveryStatus.FAILED
        self.error_message = str(error)
        self.error_type = type(error).__name__
    
    def should_retry(self) -> bool:
        """Check if notification should be retried"""
        return (
            self.status == DeliveryStatus.FAILED and
            self.retry_count < 3 and
            self.is_retryable_error()
        )
    
    def is_retryable_error(self) -> bool:
        """Check if error is retryable (network/timeout)"""
        retryable_types = ["NetworkError", "TimedOut", "RetryAfter"]
        return self.error_type in retryable_types
    
    @property
    def total_message_length(self) -> int:
        """Total character count across all parts"""
        return sum(len(part.content) for part in self.message_parts)
```

**State Transitions**:
```
PENDING → SENT (success on first attempt)
PENDING → RETRYING → SENT (success after retry)
PENDING → RETRYING → FAILED (exhausted retries)
PENDING → FAILED (non-retryable error)
```

**Validation Rules**:
- retry_count must be between 0 and 3
- sent_at is only set when status=SENT
- message_parts cannot be empty for SENT status
- Each NotificationPart.content must be ≤ 4096 characters

---

### 3. NotificationConfig

Application configuration for Telegram notification system.

```python
from pydantic import BaseModel, Field, field_validator
from typing import Optional
import os

class NotificationConfig(BaseModel):
    """Configuration for Telegram notification system"""
    
    # Telegram credentials
    bot_token: str = Field(..., description="Telegram bot token from BotFather")
    channel_id: str = Field(..., description="Target Telegram channel/chat ID")
    
    # Retry configuration
    max_retries: int = Field(default=3, ge=1, le=5)
    initial_retry_delay: int = Field(default=2, ge=1, description="Initial delay in seconds")
    retry_multiplier: int = Field(default=2, ge=1, description="Exponential backoff multiplier")
    
    # Message formatting
    enable_markdown: bool = Field(default=True)
    max_message_length: int = Field(default=4096, ge=1, le=4096)
    split_on_resource_boundary: bool = Field(default=True)
    
    # Notification behavior
    notify_on_no_drift: bool = Field(default=False)
    include_workflow_link: bool = Field(default=True)
    
    @field_validator('bot_token')
    @classmethod
    def validate_bot_token(cls, v: str) -> str:
        """Validate bot token format"""
        if not v or len(v) < 20:
            raise ValueError("Invalid bot token format")
        if ':' not in v:
            raise ValueError("Bot token must contain ':' separator")
        return v
    
    @field_validator('channel_id')
    @classmethod
    def validate_channel_id(cls, v: str) -> str:
        """Validate channel ID format"""
        if not v:
            raise ValueError("Channel ID cannot be empty")
        # Channel IDs start with @ for public channels or - for groups
        if not (v.startswith('@') or v.startswith('-') or v.isdigit()):
            raise ValueError("Invalid channel ID format")
        return v
    
    @classmethod
    def from_env(cls) -> "NotificationConfig":
        """Load configuration from environment variables"""
        bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
        channel_id = os.getenv("TELEGRAM_CHANNEL_ID")
        
        if not bot_token:
            raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
        if not channel_id:
            raise ValueError("TELEGRAM_CHANNEL_ID environment variable is required")
        
        return cls(
            bot_token=bot_token,
            channel_id=channel_id,
            max_retries=int(os.getenv("TELEGRAM_MAX_RETRIES", "3")),
            notify_on_no_drift=os.getenv("TELEGRAM_NOTIFY_NO_DRIFT", "false").lower() == "true",
        )
    
    def sanitize_for_logging(self) -> dict:
        """Return config with sensitive data masked"""
        return {
            "bot_token": f"{self.bot_token[:8]}...[REDACTED]",
            "channel_id": self.channel_id,
            "max_retries": self.max_retries,
            "initial_retry_delay": self.initial_retry_delay,
            "retry_multiplier": self.retry_multiplier,
            "enable_markdown": self.enable_markdown,
        }
```

**Validation Rules**:
- bot_token must be valid Telegram bot token format (contains ':')
- channel_id must start with '@', '-', or be numeric
- max_retries between 1 and 5
- max_message_length must not exceed 4096 (Telegram limit)

---

## Data Flow

### 1. Drift Detection → Notification

```
┌─────────────────────┐
│ Drift Detection     │
│ (Terraform/Script)  │
└──────────┬──────────┘
           │
           │ Outputs drift_report.json
           ▼
┌─────────────────────┐
│ Parse Report        │
│ → DriftDetectionEvent│
└──────────┬──────────┘
           │
           │ drift_detected=false → No notification (per spec clarification)
           │ drift_detected=true  → Continue
           ▼
┌─────────────────────┐
│ Create Notification │
│ → TelegramNotification│
└──────────┬──────────┘
           │
           │ Split if needed
           ▼
┌─────────────────────┐
│ Format Message Parts│
│ → NotificationPart[]│
└──────────┬──────────┘
           │
           │ Send with retry
           ▼
┌─────────────────────┐
│ Update Status       │
│ → SENT/FAILED       │
└─────────────────────┘
```

### 2. Message Splitting Algorithm

```
IF total_message_length <= 4096:
    Send single message
ELSE:
    Split on resource boundaries:
    - Header (timestamp, environment, summary) → Part 1
    - Resource changes → Part 2, 3, ... N
    - Each part ≤ 4000 chars (buffer for headers)
    - Add part indicator: "Message X/N"
```

---

## Persistence & Storage

**Storage Strategy**: Ephemeral (in-memory only)

- DriftDetectionEvent: Parsed from JSON input, not persisted
- TelegramNotification: Created in-memory, logged to workflow output
- NotificationConfig: Loaded from environment variables each run

**Rationale**: GitHub Actions workflows are stateless. All state captured in workflow logs and Telegram message history. No database required.

**Log Format**:
```json
{
  "timestamp": "2026-01-29T14:30:00Z",
  "notification_id": "abc123",
  "status": "sent",
  "retry_count": 0,
  "channel_id": "@devops_alerts",
  "message_parts": 1,
  "delivery_time_ms": 1234
}
```

---

## Usage Examples

### Example 1: Parse Drift Report

```python
# Input: drift_report.json from Terraform
drift_event = DriftDetectionEvent(
    environment="dev",
    branch="main",
    workflow_run_id="12345",
    workflow_run_url="https://github.com/org/repo/actions/runs/12345",
    drift_detected=True,
    resource_changes=[
        ResourceChange(
            resource_type="aws_instance",
            resource_name="web_server",
            action=ActionType.UPDATE,
            before={"instance_type": "t2.micro"},
            after={"instance_type": "t2.small"}
        )
    ]
)

print(drift_event.total_changes)  # 1
print(drift_event.changes_by_action)  # {ActionType.UPDATE: 1}
```

### Example 2: Create and Track Notification

```python
notification = TelegramNotification(
    notification_id="drift_20260129_143000",
    drift_event=drift_event,
    channel_id="@devops_alerts",
    message_parts=[
        NotificationPart(
            part_number=1,
            total_parts=1,
            content="🚨 Infrastructure Drift Detected\\n..."
        )
    ]
)

# After successful send
notification.mark_sent()
print(notification.status)  # DeliveryStatus.SENT

# Or if failed
try:
    send_to_telegram(notification)
except NetworkError as e:
    notification.mark_failed(e)
    if notification.should_retry():
        notification.retry_count += 1
        retry_send(notification)
```

### Example 3: Load Configuration

```python
# From environment variables
config = NotificationConfig.from_env()

# Validate configuration
try:
    config = NotificationConfig(
        bot_token="invalid_token",
        channel_id="@alerts"
    )
except ValueError as e:
    print(e)  # "Bot token must contain ':' separator"

# Safe logging
print(config.sanitize_for_logging())
# {'bot_token': '12345678...[REDACTED]', 'channel_id': '@alerts', ...}
```

---

## Validation & Constraints

### Type Safety
All models use Pydantic for:
- Runtime type checking
- Automatic validation on initialization
- JSON serialization/deserialization
- IDE autocomplete support

### Business Rules
1. **No Notification on Clean Runs**: `drift_detected=False` → skip notification creation
2. **Retry Limit**: Maximum 3 retry attempts with exponential backoff (2s, 4s, 8s)
3. **Message Splitting**: Split at resource boundaries to maintain readability
4. **Token Security**: Never log full bot token (use sanitize_for_logging)

### Error Handling
- Invalid configuration → Fail fast with clear error message
- Malformed drift report → Log warning, skip notification
- Telegram API errors → Retry if transient, fail workflow if auth error

---

## Next Steps

Phase 1 deliverables completed:
- ✅ data-model.md (this document)
- 🔄 contracts/ (message schemas)
- 🔄 quickstart.md (development setup)
- 🔄 Update agent context
