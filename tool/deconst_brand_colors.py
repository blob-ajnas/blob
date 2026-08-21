#!/usr/bin/env python3
"""Remove `const` from expressions that now embed a mutable brand colour.

`AppColors.primary` and friends became mutable statics so the app can switch
palettes per track (see app_colors.dart). Any `const` expression containing one
is no longer a valid constant, so the enclosing `const` keyword has to go.

Rather than guess which line to edit, this reads the analyzer's own error
locations, walks *up* the expression from the offending token to find the
`const` keyword that actually governs it, and removes only that keyword. It
loops until the analyzer stops reporting, because removing an outer `const`
can reveal a nested one.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ERROR_RE = re.compile(
    r"error • .*? • (lib/[^ :]+):(\d+):(\d+) • "
    r"(invalid_constant|const_with_non_constant_argument)"
)
OPENERS, CLOSERS = "([{", ")]}"


def analyze():
    out = subprocess.run(
        ["flutter", "analyze", "--no-pub"],
        cwd=ROOT, capture_output=True, text=True,
    ).stdout
    hits = []
    for m in ERROR_RE.finditer(out):
        hits.append((m.group(1), int(m.group(2)), int(m.group(3))))
    return hits


def offset_of(text, line, col):
    lines = text.splitlines(keepends=True)
    return sum(len(x) for x in lines[: line - 1]) + (col - 1)


def find_governing_const(text, offset):
    """Walk backwards/up the expression, returning the index of the `const`
    keyword that makes this expression constant, or None."""
    i = offset
    depth = 0
    while i > 0:
        i -= 1
        ch = text[i]
        if ch in CLOSERS:
            depth += 1
        elif ch in OPENERS:
            if depth:
                depth -= 1
                continue
            # Moved up one level. Read the token run just before this opener,
            # skipping an identifier (the constructor/type name) if present.
            j = i
            while j > 0 and text[j - 1].isspace():
                j -= 1
            k = j
            while k > 0 and (text[k - 1].isalnum() or text[k - 1] in "_.<>"):
                k -= 1
            word_start = k
            while word_start > 0 and text[word_start - 1].isspace():
                word_start -= 1
            # `const X(` -> keyword sits before the identifier.
            if text[:word_start].endswith("const"):
                return word_start - 5
            # `const [` / `const {` -> keyword sits directly before.
            if text[:j].endswith("const"):
                return j - 5
    return None


def main():
    total = 0
    for _ in range(12):
        hits = analyze()
        if not hits:
            print(f"clean after removing {total} const keyword(s)")
            return 0
        # Group by file, apply from the end so earlier offsets stay valid.
        by_file = {}
        for path, line, col in hits:
            by_file.setdefault(path, []).append((line, col))
        changed = 0
        for path, spots in by_file.items():
            p = ROOT / path
            text = p.read_text()
            cuts = set()
            for line, col in spots:
                idx = find_governing_const(text, offset_of(text, line, col))
                if idx is not None:
                    cuts.add(idx)
            for idx in sorted(cuts, reverse=True):
                end = idx + 5
                while end < len(text) and text[end] == " ":
                    end += 1
                text = text[:idx] + text[end:]
                changed += 1
            if cuts:
                p.write_text(text)
        if not changed:
            print("could not resolve remaining sites:", hits[:5],
                  file=sys.stderr)
            return 1
        total += changed
        print(f"pass: removed {changed}")
    print("hit iteration cap", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
