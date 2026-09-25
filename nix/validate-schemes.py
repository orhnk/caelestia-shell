#!/usr/bin/env python3
"""Validate Caelestia CLI scheme trees.

Each given directory must contain ``<scheme>/<flavour>/<mode>.txt`` files
where every non-empty line parses exactly like the CLI does
(``caelestia.utils.scheme.read_colours_from_file``: ``key value`` split on a
single space, optional ``#`` prefix on the value)::

    base00 1d2021
    primary 83a598

Exits non-zero listing every offending file/line, so user-supplied palettes
fail the nix build instead of breaking `caelestia scheme set` at runtime.
"""

import re
import sys
from pathlib import Path

VALUE_RE = re.compile(r"^#?[0-9a-fA-F]{6}$")
# <scheme>/<flavour>/<mode>.txt, e.g. gruvbox-dark-hard/default/dark.txt
LAYOUT_RE = re.compile(r"^[^/]+/[^/]+/(dark|light)\.txt$")


def check_file(path: Path) -> list[str]:
    errors = []
    for lineno, raw in enumerate(path.read_text().splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        parts = line.split(" ")
        if len(parts) != 2 or not parts[0] or not VALUE_RE.match(parts[1]):
            errors.append(f"{path}:{lineno}: expected `key hex`, got {raw!r}")
    return errors


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: validate-schemes.py <scheme-dir>...", file=sys.stderr)
        return 2
    errors: list[str] = []
    total = 0
    for d in argv:
        root = Path(d)
        files = sorted(root.rglob("*.txt"))
        if not files:
            errors.append(f"{d}: no *.txt scheme files found")
        for f in files:
            total += 1
            rel = f.relative_to(root).as_posix()
            if not LAYOUT_RE.match(rel):
                errors.append(
                    f"{f}: expected <scheme>/<flavour>/<dark|light>.txt, got {rel!r}"
                )
            errors.extend(check_file(f))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"validated {total} scheme files")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
