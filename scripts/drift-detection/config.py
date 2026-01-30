"""
Configuration Management for Drift Detection Notifications

This module loads and validates configuration from environment variables.
"""

import os
from typing import Optional

from dotenv import load_dotenv

from .models import NotificationConfig


def load_config(env_file: Optional[str] = None) -> NotificationConfig:
    """
    Load configuration from environment variables.
    
    Args:
        env_file: Optional path to .env file for local development
        
    Returns:
        NotificationConfig: Validated configuration object
        
    Raises:
        ValueError: If required environment variables are missing
    """
    # Load .env file if provided (for local development)
    if env_file:
        load_dotenv(env_file)
    else:
        # Try to load from default location
        load_dotenv()
    
    return NotificationConfig.from_env()


# Add from_env classmethod to NotificationConfig if not present in models
def _from_env() -> NotificationConfig:
    """Load configuration from environment variables"""
    bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
    channel_id = os.getenv("TELEGRAM_CHANNEL_ID")
    
    if not bot_token:
        raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
    if not channel_id:
        raise ValueError("TELEGRAM_CHANNEL_ID environment variable is required")
    
    return NotificationConfig(
        bot_token=bot_token,
        channel_id=channel_id,
        max_retries=int(os.getenv("TELEGRAM_MAX_RETRIES", "3")),
        notify_on_no_drift=os.getenv("TELEGRAM_NOTIFY_NO_DRIFT", "false").lower() == "true",
    )


# Monkey-patch the from_env method onto NotificationConfig
NotificationConfig.from_env = staticmethod(_from_env)
