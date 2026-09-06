#!/usr/bin/env python3
"""Render the title-screen version ribbon for pokered-plus
("EDICIÓN DEFINITIVA") as a 1-bit strip, in the style of the vanilla
assets/generated/title/red_version.png.

    python3 tools/pokered_plus_title_ribbon.py

Writes mods/pokered_plus/assets/title/edicion_definitiva.png
The engine colours it with the title's LOGO1 palette (red on the Red
title), and centres it as one continuous ribbon at y=64.
"""
import os

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TTF = os.path.join(REPO, "assets", "fonts", "plainpixel", "PlainPixel-Regular.ttf")
OUT = os.path.join(REPO, "mods", "pokered_plus", "assets", "title")
TEXT = "EDICIÓN DEFINITIVA"

# Plain Pixel rasterises cleanly at multiples of 15; 15 -> ~8px caps.
font = ImageFont.truetype(TTF, 15)
tmp = Image.new("L", (400, 40), 0)
d = ImageDraw.Draw(tmp)
d.text((2, 0), TEXT, fill=255, font=font)
bbox = tmp.getbbox()
glyphs = tmp.crop(bbox)

# 1-bit, black ink on white, +1px margin, capped to the 160px title width
w = min(glyphs.width + 2, 158)
h = glyphs.height
out = Image.new("1", (w, h), 1)
mask = glyphs.point(lambda p: 0 if p > 96 else 255).convert("1")
out.paste(0, (1, 0), Image.eval(glyphs, lambda p: 255 if p > 96 else 0).convert("1"))

os.makedirs(OUT, exist_ok=True)
out.save(os.path.join(OUT, "edicion_definitiva.png"))
print(f"wrote {os.path.join(OUT, 'edicion_definitiva.png')}  ({w}x{h})")
