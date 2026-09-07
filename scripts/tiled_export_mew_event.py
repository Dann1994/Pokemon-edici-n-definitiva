#!/usr/bin/env python3
"""Build a Tiled workspace that includes the mew_event island map.

`tools/tiled_export.py` only knows the vanilla maps from the ROM cache, so a
mod-registered map like ISLA_SUPREMA never lands in the workspace.  This
wrapper runs the normal export for a handful of nearby reference maps (every
tileset atlas is built regardless), then emits `maps/ISLA_SUPREMA.tmj` from
`mods/mew_event/data/isla_suprema.lua` with `vanilla = false` so the
gen1-mod-export extension writes `mod.content.maps:register` on export.

    python scripts/tiled_export_mew_event.py
    # then open build/tiled/gen1.tiled-project in the tiled_gen1recomp build
    # edit  maps/ISLA_SUPREMA  ->  export as a mod folder / single map
"""

import json
import os
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "tools"))

# tiled_export shells out to `luajit`; make sure it is findable
_LJ = os.path.join(os.environ.get("LOCALAPPDATA", ""),
                   "Programs", "LuaJIT", "bin")
if os.path.isdir(_LJ):
    os.environ["PATH"] = _LJ + os.pathsep + os.environ.get("PATH", "")

import tiled_export as tx

ISLA_LUA = os.path.join(REPO, "mods", "mew_event", "data", "isla_suprema.lua")

# reference maps worth having open around the island (coast, forest, the
# Vermilion dock the sailor sails from, Fuji's town)
REFERENCE_MAPS = [
    "PALLET_TOWN", "ROUTE_1", "ROUTE_21", "CINNABAR_ISLAND",
    "VIRIDIAN_FOREST", "VERMILION_CITY", "LAVENDER_TOWN",
    "POKEMON_MANSION_1F",
]


def dump_lua(path):
    lua = shutil.which("luajit") or shutil.which("lua")
    if not lua:
        sys.exit("need luajit on PATH")
    raw = subprocess.check_output(
        [lua, os.path.join(REPO, "tools", "lua_to_json.lua"), path], cwd=REPO)
    return json.loads(raw)


def main():
    out_dir = os.path.join(REPO, "build", "tiled")

    # 1. the vanilla export (reference maps + all tileset atlases + project)
    sys.argv = ["tiled_export.py", "--maps", ",".join(REFERENCE_MAPS)]
    tx.main()

    # 2. the island, straight from the mod's own map data
    isla = dump_lua(ISLA_LUA)
    tx.write_map(out_dir, isla, isla.get("palette"))

    # 3. flip `vanilla` -> false so export picks maps:register, not :patch
    tmj_path = os.path.join(out_dir, "maps", "ISLA_SUPREMA.tmj")
    with open(tmj_path, encoding="utf-8") as fh:
        tmj = json.load(fh)
    for prop in tmj.get("properties", []):
        if prop.get("name") == "vanilla":
            prop["value"] = False
    with open(tmj_path, "w", encoding="utf-8") as fh:
        json.dump(tmj, fh, indent=1)

    print("\nwrote %s" % tmj_path)
    print("open build/tiled/gen1.tiled-project and edit maps/ISLA_SUPREMA")


if __name__ == "__main__":
    main()
