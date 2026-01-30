import signal
import sys

# Track if interrupt was requested
_interrupt_requested = False


def _signal_handler(signum, frame):
    """Handle interrupt signals by setting flag."""
    global _interrupt_requested
    _interrupt_requested = True
    print("\n⚠️  Interrupt received! Stopping after current test...", flush=True)


def install_signal_handler():
    """Install signal handler for graceful interrupts."""
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)


def check_for_interrupt():
    """Check if interrupt was requested. Raises exception to stop Robot Framework."""
    if _interrupt_requested:
        print("⛔ Stopping test execution due to interrupt", flush=True)
        # Raise exception that Robot Framework will catch
        raise KeyboardInterrupt("Test execution interrupted by user")


def was_interrupted():
    """Return True if interrupt was requested (for status checks without raising)."""
    return _interrupt_requested
