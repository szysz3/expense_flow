import asyncio
import logging
from typing import Callable, Any, Optional

class RetryableError(Exception):
    """Base class for errors that should trigger a retry."""
    pass

class ProcessingError(RetryableError):
    """Error during processing that can be retried."""
    pass

async def retry_async(
    func: Callable,
    *args,
    max_retries: int = 3,
    retry_delay: float = 1.0,
    logger: Optional[logging.Logger] = None,
    **kwargs
) -> Any:
    """
    Retry an async function with a fixed delay between retries.
    
    Args:
        func: The async function to retry
        *args: Arguments to pass to the function
        max_retries: Maximum number of retries
        retry_delay: Delay between retries in seconds
        logger: Optional logger for logging retries
        **kwargs: Keyword arguments to pass to the function
        
    Returns:
        The result of the function call
        
    Raises:
        The last exception if all retries fail
    """
    attempt = 0
    last_exception = None
    
    while attempt <= max_retries:
        try:
            return await func(*args, **kwargs)
        except Exception as e:
            attempt += 1
            last_exception = e
            
            is_retryable = isinstance(e, RetryableError)
            
            if logger:
                if is_retryable and attempt <= max_retries:
                    logger.warning(
                        f"Attempt {attempt}/{max_retries} failed: {str(e)}. Retrying in {retry_delay}s..."
                    )
                else:
                    logger.error(
                        f"Attempt {attempt}/{max_retries} failed: {str(e)}"
                    )
            
            if not is_retryable or attempt > max_retries:
                break
                
            await asyncio.sleep(retry_delay)
    
    raise last_exception