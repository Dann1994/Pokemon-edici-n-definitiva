#!/usr/bin/env python3
"""Derive 16x16 overworld sprites for every species from the mini sprites
in mods/pokered_plus/assets/icons/.

Overworld Pokemon objects (the legendary birds, Mewtwo, Snorlax, and the
decorative pet Pokemon in houses) use a handful of shared sprites
(SPRITE_MONSTER / SPRITE_BIRD / ...).  This takes frame 0 of each mini
sprite and flattens it to the 4 DMG greys the vanilla overworld sheets use
(mode "L", like assets/generated/sprites/snorlax.png) so it renders the
same in every COLORS mode; the mod then points each object at its own.

    python3 tools/pokered_plus_overworld_mons.py

Reads  mods/pokered_plus/assets/icons/*.png
Writes mods/pokered_plus/assets/ow/*.png
"""
import os

from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(REPO, "mods", "pokered_plus", "assets", "icons")
OUT = os.path.join(REPO, "mods", "pokered_plus", "assets", "ow")

# 4 DMG greys, matching the vanilla overworld sheets
LEVELS = [255, 170, 85, 0]


def quantise(v):
    return min(LEVELS, key=lambda l: abs(l - v))


def derive(icon_png):
    im = Image.open(icon_png).convert("RGBA")
    frame0 = im.crop((0, 0, 16, 16))
    out = Image.new("L", (16, 16), 255)
    src = frame0.load()
    dst = out.load()
    for y in range(16):
        for x in range(16):
            r, g, b, a = src[x, y]
            if a == 0 or (r, g, b) == (255, 255, 255):
                dst[x, y] = 255  # background -> white, like the ROM sheets
            else:
                lum = 0.299 * r + 0.587 * g + 0.114 * b
                dst[x, y] = quantise(lum)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for name in sorted(os.listdir(ICONS)):
        if name.endswith(".png"):
            derive(os.path.join(ICONS, name)).save(os.path.join(OUT, name))
            n += 1
    print(f"derived {n} overworld sprites -> {OUT}")


if __name__ == "__main__":
    main()
