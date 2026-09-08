#!/usr/bin/env python3
"""Merge translated script lines into mods/es_es/lang/dialogue.lua.

Input: worksheet format, one entry per line:

    "SomeTextKey"\t"El texto traducido...{DONE}"

The value between the outer quotes is dropped verbatim into the Lua
string -- keep \\n \\11 \\12 and {TOKENS} identical to the English
worksheet (mods/es_ES-worksheet/dialogue.txt). Only non-empty values
are applied; an already-filled key is overwritten.

    python scripts/apply_es_dialogue.py mods/es_ES-worksheet/dialogue_es_*.tsv
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA = os.path.join(REPO, "mods", "es_es", "lang", "dialogue.lua")


def parse(path):
    out = {}
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            raw = raw.rstrip("\n").rstrip("\r")
            if not raw or raw.lstrip().startswith("#"):
                continue
            if "\t" not in raw:
                sys.exit("no tab:\n" + raw)
            key, val = raw.split("\t", 1)
            key = key.strip()
            if key[:1] == '"' and key[-1:] == '"':
                key = key[1:-1]
            if val[:1] == '"' and val[-1:] == '"':
                val = val[1:-1]
            if val.strip():
                out[key] = val
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    trans = {}
    for p in sys.argv[1:]:
        trans.update(parse(p))

    with open(LUA, encoding="utf-8") as fh:
        src = fh.read()

    applied, missing = 0, []
    for key, val in trans.items():
        esc = val.replace('"', '\\"')   # value already carries \n \11 \12
        # replace the whole  ["key"] = "...."  assignment
        pat = re.compile(
            r'(\[' + re.escape('"' + key + '"') + r'\]\s*=\s*)"(?:\\.|[^"\\])*"')
        src, n = pat.subn(lambda m: m.group(1) + '"' + esc + '"', src, count=1)
        if n:
            applied += 1
        else:
            missing.append(key)

    with open(LUA, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(src)

    print("applied %d" % applied)
    if missing:
        print("  %d keys not found:" % len(missing))
        for k in missing[:15]:
            print("   ", k)
    print("  %d still untranslated" % len(re.findall(r'=\s*"",', src)))


if __name__ == "__main__":
    main()
