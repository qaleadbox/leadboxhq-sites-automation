import signal
import sys
import os

# Track if interrupt was requested
_interrupt_requested = False
_original_sigint_handler = None


def _signal_handler(signum, frame):
    """Handle interrupt signals by immediately raising KeyboardInterrupt."""
    global _interrupt_requested
    _interrupt_requested = True
    print("\n⚠️  Interrupt received! Forcing immediate stop...", flush=True)

    # Force immediate termination by raising KeyboardInterrupt in current thread
    # This will interrupt blocking operations like Sleep, page loads, etc.
    raise KeyboardInterrupt("Test execution interrupted by user (Ctrl+C)")


def install_signal_handler():
    """Install signal handler for immediate interrupts."""
    global _original_sigint_handler
    _original_sigint_handler = signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    print("✓ Signal handler installed (Ctrl+C will stop immediately)", flush=True)


def check_for_interrupt():
    """Check if interrupt was requested. Raises exception to stop Robot Framework."""
    if _interrupt_requested:
        print("⛔ Stopping test execution due to interrupt", flush=True)
        raise KeyboardInterrupt("Test execution interrupted by user")


def was_interrupted():
    """Return True if interrupt was requested (for status checks without raising)."""
    return _interrupt_requested
