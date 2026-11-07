"""Shades a raw top-down capture into a minimap image (D-077; per region D-100).

Raw capture (260 units across):
  godot --path game --resolution 1024x1024 --script res://tests/capture_overview.gd -- <world.tscn> <raw.png> 260 [palette]
Then: python3 tools/minimap_image.py <raw.png> <out.png> <layout.gd> [snow]
"snow" tones down a very white snowfield so paths and cliffs stay readable.
"""
import re
import sys
from PIL import Image, ImageDraw, ImageEnhance

S = 260.0
N = 1024
raw, out, layout = sys.argv[1:4]
snow = len(sys.argv) > 4 and sys.argv[4] == "snow"
text = open(layout).read()
half = float(re.search(r"const PLAY_HALF := ([\d.]+)", text).group(1))
plateaus = []
for height, outline in re.findall(r'"height": ([\d.]+), "base".*?"outline": \[(.*?)\],', text, re.S):
    points = [(float(a), float(b)) for a, b in re.findall(r"Vector2\((-?[\d.]+), (-?[\d.]+)\)", outline)]
    plateaus.append((float(height), points))


def px(x, z):
    return ((x + S / 2) / S * N, (z + S / 2) / S * N)


img = Image.open(raw).convert("RGB")
if snow:
    img = ImageEnhance.Brightness(img).enhance(0.86)
    img = ImageEnhance.Contrast(img).enhance(1.35)
rim = (70, 86, 112) if snow else (92, 64, 40)
for height, poly in plateaus:
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon([px(*p) for p in poly], fill=255)
    lit = ImageEnhance.Brightness(img).enhance(1.0 + 0.012 * height)
    lit = ImageEnhance.Color(lit).enhance(0.85)
    img = Image.composite(lit, img, mask)
draw = ImageDraw.Draw(img)
for height, poly in plateaus:
    pts = [px(*p) for p in poly]
    draw.line(pts + [pts[0]], fill=rim, width=7)
# Darken outside the playable square (cliffs / border).
edge = Image.new("L", (N, N), 255)
a = px(-half, -half)
b = px(half, half)
ImageDraw.Draw(edge).rectangle([a, b], fill=0)
img = Image.composite(ImageEnhance.Brightness(img).enhance(0.55), img, edge)
draw.rectangle([a, b], outline=rim, width=6)
img = ImageEnhance.Contrast(img).enhance(1.05)
img.resize((512, 512), Image.LANCZOS).save(out, optimize=True)
