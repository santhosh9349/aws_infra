# Quickstart: Telegram Bot Notifications for Drift Detection

**Last Updated**: January 29, 2026  
**Target Audience**: Developers and DevOps engineers  
**Prerequisites**: Python 3.11+, GitHub repository access, Telegram account

## Table of Contents

1. [Local Development Setup](#local-development-setup)
2. [Telegram Bot Configuration](#telegram-bot-configuration)
3. [Running Tests](#running-tests)
4. [Manual Testing](#manual-testing)
5. [GitHub Actions Integration](#github-actions-integration)
6. [Troubleshooting](#troubleshooting)

---

## Local Development Setup

### 1. Clone Repository and Create Feature Branch

```bash
git clone https://github.com/org/aws_infra.git
cd aws_infra
git checkout 003-drift-telegram-notification
```

### 2. Install Python Dependencies

```bash
cd scripts/drift-detection
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

pip install -r requirements.txt
```

**requirements.txt**:
```txt
python-telegram-bot==20.7
tenacity==8.2.3
pydantic==2.5.0
python-dotenv==1.0.0

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-mock==3.12.0
pytest-cov==4.1.0
```

### 3. Configure Environment Variables

Create `.env` file in `scripts/drift-detection/`:

```bash
# Telegram Configuration
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHANNEL_ID=@your_test_channel

# Optional: Retry Configuration
TELEGRAM_MAX_RETRIES=3
TELEGRAM_NOTIFY_NO_DRIFT=false
```

⚠️ **Security**: Never commit `.env` file. Add to `.gitignore`.

---

## Telegram Bot Configuration

### Step 1: Create Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` command
3. Follow prompts to choose bot name and username
4. Copy the bot token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Step 2: Create Test Channel

1. Create a new Telegram channel (public or private)
2. Note the channel username (e.g., `@devops_test_alerts`)
3. For private channels/groups, you'll need the numeric channel ID

**Get Channel ID for Private Channels**:
```bash
# Add bot to channel first, then run:
python -c "from telegram import Bot; import os; \
bot = Bot(os.getenv('TELEGRAM_BOT_TOKEN')); \
print(bot.get_updates()[-1].message.chat.id)"
```

### Step 3: Add Bot to Channel

1. Go to your channel settings
2. Select "Administrators" → "Add Administrator"
3. Search for your bot username
4. Grant "Post Messages" permission
5. Save

### Step 4: Verify Bot Access

```bash
cd scripts/drift-detection
python -c "
from telegram import Bot
import os
from dotenv import load_dotenv

load_dotenv()
bot = Bot(os.getenv('TELEGRAM_BOT_TOKEN'))
print('Bot Username:', bot.get_me().username)
print('Bot ID:', bot.get_me().id)
"
```

Expected output:
```
Bot Username: your_bot_username
Bot ID: 1234567890
```

---

## Running Tests

### Unit Tests

```bash
cd scripts/drift-detection
pytest tests/unit/ -v --cov=. --cov-report=html
```

**Expected Output**:
```
tests/unit/test_notify_telegram.py::test_create_notification PASSED
tests/unit/test_message_formatter.py::test_format_single_message PASSED
tests/unit/test_message_formatter.py::test_split_large_message PASSED
tests/unit/test_retry_handler.py::test_exponential_backoff PASSED
===================== 12 passed in 2.34s =====================
Coverage: 95%
```

### Integration Tests (Sends Real Messages)

⚠️ **Warning**: This will send actual messages to your test channel.

```bash
pytest tests/integration/ -v -s
```

**What it tests**:
- Bot can authenticate with Telegram API
- Messages are delivered to configured channel
- Retry logic works with simulated failures
- Large messages are split correctly

---

## Manual Testing

### Test 1: Send Simple Drift Notification

```bash
cd scripts/drift-detection
python notify_telegram.py --test
```

**Sample Test Data** (auto-generated):
```json
{
  "environment": "dev",
  "branch": "main",
  "workflow_run_url": "https://github.com/org/aws_infra/actions/runs/test",
  "drift_detected": true,
  "resource_changes": [
    {
      "resource_type": "aws_instance",
      "resource_name": "web_server",
      "action": "update",
      "before": {"instance_type": "t2.micro"},
      "after": {"instance_type": "t2.small"}
    }
  ]
}
```

**Expected Result**: Message appears in Telegram channel within 2 seconds.

### Test 2: Test Message Splitting

```bash
python notify_telegram.py --test --large-message
```

Generates drift report with 50+ resource changes to test message splitting.

**Expected Result**: Multiple messages (Part 1/N, 2/N, etc.) appear in sequence.

### Test 3: Test Retry Logic

```bash
python notify_telegram.py --test --simulate-failure
```

Simulates Telegram API timeout to test retry behavior.

**Expected Result**: Console shows retry attempts with 2s, 4s, 8s delays, then success.

---

## GitHub Actions Integration

### Step 1: Configure Repository Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `TELEGRAM_BOT_TOKEN`: Your bot token from BotFather
   - `TELEGRAM_CHANNEL_ID`: Your channel username or ID

### Step 2: Update Drift Detection Workflow

Edit `.github/workflows/drift-detection.yml`:

```yaml
name: Infrastructure Drift Detection

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:  # Manual trigger

jobs:
  detect-drift:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install Dependencies
        run: |
          cd scripts/drift-detection
          pip install -r requirements.txt
      
      - name: Detect Infrastructure Drift
        id: drift
        run: |
          # Your existing drift detection logic
          # Output: drift_detected=true/false, drift_report=path/to/report.json
          echo "drift_detected=true" >> $GITHUB_OUTPUT
          echo "drift_report=./drift_report.json" >> $GITHUB_OUTPUT
      
      - name: Send Telegram Notification
        if: steps.drift.outputs.drift_detected == 'true'
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHANNEL_ID: ${{ secrets.TELEGRAM_CHANNEL_ID }}
        run: |
          cd scripts/drift-detection
          python notify_telegram.py \
            --report ${{ steps.drift.outputs.drift_report }} \
            --environment ${{ github.ref_name }} \
            --workflow-run-url ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

### Step 3: Test Workflow

```bash
# Trigger manual workflow run
gh workflow run drift-detection.yml
```

Monitor workflow: https://github.com/org/aws_infra/actions

---

## Troubleshooting

### Issue: "Invalid bot token" error

**Symptoms**:
```
telegram.error.InvalidToken: Invalid token
```

**Solutions**:
1. Verify token format contains `:` (e.g., `1234567890:ABC...`)
2. Check for extra spaces or newlines in `.env` file
3. Regenerate token via BotFather if necessary

---

### Issue: "Chat not found" error

**Symptoms**:
```
telegram.error.BadRequest: Chat not found
```

**Solutions**:
1. Verify bot is added to channel as administrator
2. For public channels: use `@username` format
3. For private channels: use numeric ID (negative number for groups)
4. Test bot access: `bot.get_chat(channel_id)`

---

### Issue: Messages not appearing in channel

**Symptoms**: No error, but no message in channel

**Solutions**:
1. Check bot has "Post Messages" permission
2. Verify correct channel ID (not chat ID)
3. Check channel isn't muted or archived
4. Review workflow logs for rate limit warnings

---

### Issue: Message splitting broken

**Symptoms**: Partial messages or encoding errors

**Solutions**:
1. Check Markdown escaping (use `\\` for literal backslash)
2. Verify UTF-8 encoding for special characters
3. Test with `parse_mode='MarkdownV2'` parameter
4. Use text-only format if Markdown fails

---

### Issue: Retry logic not working

**Symptoms**: Immediate failure without retries

**Solutions**:
1. Check error type is retryable (NetworkError, TimedOut)
2. Verify retry configuration in `.env`
3. Review logs for "Non-retryable error" messages
4. Test with `--simulate-failure` flag

---

## Development Workflow

### Typical Development Cycle

1. **Make Code Changes**
   ```bash
   vim scripts/drift-detection/notify_telegram.py
   ```

2. **Run Unit Tests**
   ```bash
   pytest tests/unit/ -v
   ```

3. **Manual Test (Optional)**
   ```bash
   python notify_telegram.py --test
   ```

4. **Run Integration Tests**
   ```bash
   pytest tests/integration/ -v
   ```

5. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat: add telegram notification for drift detection"
   git push origin 003-drift-telegram-notification
   ```

6. **Create Pull Request**
   - GitHub Actions runs automated tests
   - Review test results and coverage report
   - Merge when tests pass

---

## Next Steps

After local development and testing:

1. **Phase 2**: Create `tasks.md` with implementation task breakdown
2. **Implementation**: Build notification module following `plan.md`
3. **Testing**: Achieve 95%+ test coverage
4. **Documentation**: Update main README with Telegram setup instructions
5. **Deployment**: Merge to main and verify production notifications

---

## Additional Resources

- [python-telegram-bot Documentation](https://docs.python-telegram-bot.org/)
- [Telegram Bot API Reference](https://core.telegram.org/bots/api)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS Infrastructure Repository](https://github.com/org/aws_infra)

## Support

For questions or issues:
- Create GitHub issue: [aws_infra/issues](https://github.com/org/aws_infra/issues)
- Tag: `drift-detection`, `telegram-notifications`
- Include logs and error messages
