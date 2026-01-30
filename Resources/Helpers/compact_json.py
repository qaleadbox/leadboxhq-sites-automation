import json
import re


def save_checkpoint_compact(checkpoint, file_path):
    """Save checkpoint with compact array formatting.

    Arrays are formatted horizontally on one line.
    Takes ~1ms per write.
    """
    try:
        # First, dump with standard formatting
        json_str = json.dumps(checkpoint, indent=2, ensure_ascii=False)

        # Compact arrays: convert multi-line arrays to single-line
        # Pattern matches:   [\n      "item1",\n      "item2"\n    ]
        # Replaces with:     ["item1", "item2"]
        json_str = re.sub(
            r'\[\n\s+("(?:[^"\\]|\\.)*?"(?:,\s*\n\s+"(?:[^"\\]|\\.)*?")*)\n\s+\]',
            lambda m: '[' + ', '.join(re.findall(r'"(?:[^"\\]|\\.)*?"', m.group(0))) + ']',
            json_str
        )

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(json_str)
    except Exception as e:
        print(f"Error writing checkpoint: {e}")


def flush_all_pending_writes():
    """No-op for compatibility. Writes happen immediately."""
    pass
