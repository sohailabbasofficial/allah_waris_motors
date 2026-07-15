"""Convert UTF-16 / UTF-16LE Dart sources under lib/ to UTF-8."""
from __future__ import annotations

import sys
from pathlib import Path


def looks_utf16(data: bytes) -> bool:
    if data.startswith(b"\xff\xfe") or data.startswith(b"\xfe\xff"):
        return True
    # Heuristic: many NUL bytes in even positions (UTF-16LE ASCII)
    if len(data) >= 8:
        sample = data[:200]
        nulls = sample[1::2].count(0)
        if nulls >= len(sample) // 4:
            return True
    return False


def decode_best(data: bytes) -> str:
    if data.startswith(b"\xff\xfe"):
        return data.decode("utf-16-le")
    if data.startswith(b"\xfe\xff"):
        return data.decode("utf-16-be")
    try:
        return data.decode("utf-16-le")
    except UnicodeDecodeError:
        return data.decode("utf-8")


def main() -> int:
    root = Path(__file__).resolve().parents[1] / "lib"
    fixed: list[str] = []
    for path in root.rglob("*.dart"):
        data = path.read_bytes()
        if not looks_utf16(data):
            continue
        text = decode_best(data)
        # Normalize newlines
        text = text.replace("\r\n", "\n").replace("\r", "\n")
        path.write_text(text, encoding="utf-8", newline="\n")
        fixed.append(str(path.relative_to(root.parent)))
    print(f"fixed={len(fixed)}")
    for item in fixed:
        print(item)
    return 0


if __name__ == "__main__":
    sys.exit(main())
