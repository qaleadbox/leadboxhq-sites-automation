import json
import io


class CompactJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder that keeps simple arrays on single lines."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.current_indent = 0
        self.indent_str = "  "

    def encode(self, obj):
        """Encode obj with custom formatting."""
        if isinstance(obj, dict):
            return self._encode_dict(obj, 0)
        elif isinstance(obj, list):
            return self._encode_list(obj, 0)
        else:
            return json.dumps(obj, ensure_ascii=False)

    def _encode_dict(self, obj, level):
        """Encode dictionary with proper indentation."""
        if not obj:
            return "{}"

        indent = self.indent_str * level
        next_indent = self.indent_str * (level + 1)
        items = []

        for key, value in obj.items():
            encoded_key = json.dumps(key, ensure_ascii=False)

            # Special handling for "tested_links" dictionary values
            if key == "tested_links" and isinstance(value, dict):
                items.append(f'{next_indent}{encoded_key}: {self._encode_tested_links(value, level + 1)}')
            elif isinstance(value, dict):
                items.append(f'{next_indent}{encoded_key}: {self._encode_dict(value, level + 1)}')
            elif isinstance(value, list):
                # Check if it's a simple list (for compact formatting)
                if self._is_simple_list(value):
                    items.append(f'{next_indent}{encoded_key}: {self._encode_list_compact(value)}')
                else:
                    items.append(f'{next_indent}{encoded_key}: {self._encode_list(value, level + 1)}')
            else:
                items.append(f'{next_indent}{encoded_key}: {json.dumps(value, ensure_ascii=False)}')

        return "{\n" + ",\n".join(items) + f"\n{indent}}}"

    def _encode_tested_links(self, obj, level):
        """Special encoding for tested_links dictionary - keep URL and tests on same line."""
        if not obj:
            return "{}"

        indent = self.indent_str * level
        next_indent = self.indent_str * (level + 1)
        items = []

        for key, value in obj.items():
            encoded_key = json.dumps(key, ensure_ascii=False)
            # Keep the URL and its test array on the same line
            encoded_value = json.dumps(value, ensure_ascii=False)
            items.append(f'{next_indent}{encoded_key}: {encoded_value}')

        return "{\n" + ",\n".join(items) + f"\n{indent}}}"

    def _encode_list(self, obj, level):
        """Encode list with proper indentation."""
        if not obj:
            return "[]"

        indent = self.indent_str * level
        next_indent = self.indent_str * (level + 1)
        items = []

        for item in obj:
            if isinstance(item, dict):
                items.append(f'{next_indent}{self._encode_dict(item, level + 1)}')
            elif isinstance(item, list):
                items.append(f'{next_indent}{self._encode_list(item, level + 1)}')
            else:
                items.append(f'{next_indent}{json.dumps(item, ensure_ascii=False)}')

        return "[\n" + ",\n".join(items) + f"\n{indent}]"

    def _encode_list_compact(self, obj):
        """Encode list on a single line."""
        return "[" + ", ".join(json.dumps(item, ensure_ascii=False) for item in obj) + "]"

    def _is_simple_list(self, obj):
        """Check if list contains only simple types (strings, numbers, booleans)."""
        return all(isinstance(item, (str, int, float, bool, type(None))) for item in obj)


def save_checkpoint_compact(checkpoint, file_path):
    """Save checkpoint with compact formatting for tested_links."""
    encoder = CompactJSONEncoder(ensure_ascii=False)
    json_string = encoder.encode(checkpoint)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(json_string)
