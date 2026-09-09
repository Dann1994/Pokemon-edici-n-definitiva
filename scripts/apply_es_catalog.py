#!/usr/bin/env python3
"""Merge translated entries into a mods/es_es/lang/*.lua catalog.

    python scripts/apply_es_catalog.py <lang/file.lua> <batch.tsv> [batch2.tsv ...]

TSV: one entry per line,  "key"<TAB>"spanish value"  (outer quotes optional).
The value is dropped verbatim into  ["key"] = "..."  -- keep \\n \\v \\12 and
%s / %d / {TOKENS} identical to the key.  Only non-empty values are applied.
Keys are matched literally, so a key containing " or \\ must be given exactly
as it appears in the .lua file (with the \\ escapes).
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def parse(path):
    out = {}
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            raw = raw.rstrip("\r\n")
            if not raw or raw.lstrip().startswith("#"):
                continue
            if "\t" not in raw:
                sys.exit("no tab:\n" + raw)
            key, val = raw.split("\t", 1)
            if key[:1] == '"' and key[-1:] == '"':
                key = key[1:-1]
            if val[:1] == '"' and val[-1:] == '"':
                val = val[1:-1]
            if val.strip():
                out[key] = val
    return out


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    lua = os.path.join(REPO, sys.argv[1]) if not os.path.isabs(sys.argv[1]) \
        else sys.argv[1]
    trans = {}
    for p in sys.argv[2:]:
        trans.update(parse(p))

    with open(lua, encoding="utf-8") as fh:
        src = fh.read()

    applied, missing = 0, []
    for key, val in trans.items():
        esc = val.replace("\\", "\\\\").replace('"', '\\"') \
            if False else val.replace('"', '\\"')
        pat = re.compile(
            r'(\[' + re.escape('"' + key + '"') + r'\]\s*=\s*)"(?:\\.|[^"\\])*"')
        src, n = pat.subn(lambda m: m.group(1) + '"' + esc + '"', src, count=1)
        if n:
            applied += 1
        else:
            missing.append(key)

    with open(lua, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(src)

    print("applied %d" % applied)
    if missing:
        print("  %d keys not found:" % len(missing))
        for k in missing[:20]:
            print("   ", repr(k))
    print("  %d still untranslated" % len(re.findall(r'=\s*"",', src)))


if __name__ == "__main__":
    main()
