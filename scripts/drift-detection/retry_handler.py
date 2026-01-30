"""
Retry Handler for Telegram API Operations

This module provides exponential backoff retry logic for Telegram API calls.
Retry delays: 2s, 4s, 8s (exponential backoff with base 2)
"""

import asyncio
import logging
from functools import wraps
from typing import Callable, Any, Optional, Type, Tuple

from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log,
    RetryError,
)


logger = logging.getLogger(__name__)


# Define retryable exceptions
# These will be imported from telegram when available
RETRYABLE_EXCEPTIONS: Tuple[Type[Exception], ...] = (
    ConnectionError,
    TimeoutError,
)

# Try to import telegram-specific exceptions
try:
    from telegram.error import NetworkError, TimedOut, RetryAfter
    RETRYABLE_EXCEPTIONS = (
        ConnectionError,
        TimeoutError,
        NetworkError,
        TimedOut,
        RetryAfter,
    )
except ImportError:
    pass


class RetryHandler:
    """
    Handles retry logic for Telegram API operations with exponential backoff.
    
    Retry timing: 2s, 4s, 8s (3 attempts total)
    Total retry window: ~14 seconds max
    """
    
    def __init__(
        self,
        max_retries: int = 3,
        initial_delay: int = 2,
        multiplier: int = 2,
        max_delay: int = 8
    ):
        """
        Initialize retry handler.
        
        Args:
            max_retries: Maximum number of retry attempts (default: 3)
            initial_delay: Initial delay in seconds (default: 2)
            multiplier: Exponential backoff multiplier (default: 2)
            max_delay: Maximum delay between retries (default: 8)
        """
        self.max_retries = max_retries
        self.initial_delay = initial_delay
        self.multiplier = multiplier
        self.max_delay = max_delay
    
    def get_retry_decorator(self):
        """
        Get a tenacity retry decorator configured with this handler's settings.
        
        Returns:
            Configured retry decorator
        """
        return retry(
            stop=stop_after_attempt(self.max_retries),
            wait=wait_exponential(
                multiplier=self.initial_delay,
                min=self.initial_delay,
                max=self.max_delay
            ),
            retry=retry_if_exception_type(RETRYABLE_EXCEPTIONS),
            before_sleep=before_sleep_log(logger, logging.WARNING),
            reraise=True,
        )
    
    async def execute_with_retry(
        self,
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        """
        Execute an async function with retry logic.
        
        Args:
            func: Async function to execute
            *args: Positional arguments for the function
            **kwargs: Keyword arguments for the function
            
        Returns:
            Result of the function call
            
        Raises:
            Exception: Re-raises the last exception after all retries exhausted
        """
        last_exception: Optional[Exception] = None
        
        for attempt in range(self.max_retries):
            try:
                return await func(*args, **kwargs)
            except RETRYABLE_EXCEPTIONS as e:
                last_exception = e
                
                if attempt < self.max_retries - 1:
                    delay = min(
                        self.initial_delay * (self.multiplier ** attempt),
                        self.max_delay
                    )
                    logger.warning(
                        f"Attempt {attempt + 1}/{self.max_retries} failed: {e}. "
                        f"Retrying in {delay}s..."
                    )
                    await asyncio.sleep(delay)
                else:
                    logger.error(
                        f"All {self.max_retries} attempts failed. Last error: {e}"
                    )
        
        if last_exception:
            raise last_exception
        
        raise RuntimeError("Unexpected retry handler state")
    
    def calculate_delay(self, attempt: int) -> float:
        """
        Calculate delay for a specific attempt number.
        
        Args:
            attempt: Zero-based attempt number
            
        Returns:
            Delay in seconds
        """
        delay = self.initial_delay * (self.multiplier ** attempt)
        return min(delay, self.max_delay)
    
    @property
    def total_retry_time(self) -> float:
        """
        Calculate total maximum time for all retries.
        
        Returns:
            Total retry window in seconds
        """
        total = 0
        for attempt in range(self.max_retries - 1):
            total += self.calculate_delay(attempt)
        return total


def with_retry(
    max_retries: int = 3,
    initial_delay: int = 2,
    multiplier: int = 2,
    max_delay: int = 8
):
    """
    Decorator for adding retry logic to async functions.
    
    Args:
        max_retries: Maximum number of retry attempts
        initial_delay: Initial delay in seconds
        multiplier: Exponential backoff multiplier
        max_delay: Maximum delay between retries
        
    Returns:
        Decorated function with retry logic
    """
    handler = RetryHandler(max_retries, initial_delay, multiplier, max_delay)
    
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            return await handler.execute_with_retry(func, *args, **kwargs)
        return wrapper
    
    return decorator
