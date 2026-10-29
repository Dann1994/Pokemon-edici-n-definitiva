"""Draws the fork's app icon -- a Poké Ball made of plain shapes -- and writes
every size the builds need. Own drawing, no ROM or third-party art.

    .venv/Scripts/python tools/pokered_plus_pokebola_icon.py

Writes:
  assets/logo/pokebola.png                       1024px, transparent (exe icon
                                                 via scripts/build.sh, window icon)
  installer/pokebola.ico                         16..256px (installer + shortcuts)
  mobile/android/app/src/main/res/drawable-*/ic_launcher_foreground.png
                                                 adaptive-icon foreground, ball
                                                 inside the 66% safe zone
"""
import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
RED = (227, 53, 13, 255)
RED_SHADE = (176, 32, 8, 255)
WHITE = (250, 250, 250, 255)
WHITE_SHADE = (214, 218, 224, 255)
BLACK = (24, 24, 28, 255)
SS = 4  # supersampling factor for smooth edges


def ball(size, margin=0.04):
    """A Poké Ball filling `size` px, `margin` (fraction) of empty border."""
    n = size * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = n * margin
    box = (m, m, n - m, n - m)
    r = (n - 2 * m) / 2
    cx = cy = n / 2
    outline = max(SS, round(r * 0.075))
    band = r * 0.14

    # body: black disc, then the two halves inset by the outline width
    d.ellipse(box, fill=BLACK)
    inner = (m + outline, m + outline, n - m - outline, n - m - outline)
    d.pieslice(inner, 180, 360, fill=RED)
    d.pieslice(inner, 0, 180, fill=WHITE)
    # highlight on the red half
    hl = r * 0.16
    d.ellipse((cx - r * 0.55 - hl, cy - r * 0.58 - hl * 0.7,
               cx - r * 0.55 + hl, cy - r * 0.58 + hl * 0.7), fill=(255, 196, 182, 255))
    # outer ring drawn last so nothing above can nibble at it
    d.ellipse(box, outline=BLACK, width=outline)
    # the black band across the middle
    d.rectangle((m, cy - band / 2, n - m, cy + band / 2), fill=BLACK)
    # the button: black ring, white face, small inner ring
    for rad, col in ((r * 0.34, BLACK), (r * 0.25, WHITE), (r * 0.17, WHITE_SHADE),
                     (r * 0.13, WHITE)):
        d.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), fill=col)
    # clip anything that strayed outside the outer circle
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).ellipse(box, fill=255)
    img.putalpha(Image.composite(img.getchannel("A"), mask, mask))
    return img.resize((size, size), Image.LANCZOS)


def main():
    big = ball(1024)
    (ROOT / "assets/logo").mkdir(parents=True, exist_ok=True)
    big.save(ROOT / "assets/logo/pokebola.png")

    (ROOT / "installer").mkdir(exist_ok=True)
    ball(256).save(ROOT / "installer/pokebola.ico",
                   sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    # Android adaptive icon: 108dp canvas, launchers crop to a ~66% circle,
    # so the ball takes ~62% of the canvas, centred on transparency
    for dpi, px in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                    ("xxhdpi", 324), ("xxxhdpi", 432)):
        canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        b = ball(round(px * 0.62), margin=0.0)
        off = (px - b.width) // 2
        canvas.paste(b, (off, off), b)
        canvas.save(ROOT / f"mobile/android/app/src/main/res/drawable-{dpi}/ic_launcher_foreground.png")
    print("ok")


if __name__ == "__main__":
    main()
