"""Stat icons for the HUD (D-089): damage, damage per fall, enemy hit.

Drawn at 4x and downsampled for smooth edges. Dark brown outline matches the
HUD frame colour (3a2615). Usage: python3 make_stat_icons.py <out_dir>
"""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

S = 512          # working size
OUT = 128        # final size
OUTLINE = (58, 38, 21, 255)
W = 22           # outline width at working size


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def rot(points, angle, cx, cy):
    c, s = math.cos(angle), math.sin(angle)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in points]


def outlined_polygon(d, pts, fill, width=W):
    d.polygon(pts, fill=OUTLINE)
    d.line(pts + [pts[0]], fill=OUTLINE, width=width * 2, joint="curve")
    for p in pts:
        d.ellipse([p[0] - width, p[1] - width, p[0] + width, p[1] + width], fill=OUTLINE)
    d.polygon(pts, fill=fill)


def sword(img, scale=1.0, cx=256, cy=256, angle=-math.pi / 4):
    """A straight katana-like blade, gold guard, wrapped hilt; drawn vertical then rotated."""
    d = ImageDraw.Draw(img)
    k = scale

    def P(pts):
        return rot([(cx + x * k, cy + y * k) for x, y in pts], angle, cx, cy)
    blade = P([(-26, 90), (-26, -150), (0, -205), (26, -150), (26, 90)])
    edge = P([(0, 90), (0, -190), (26, -150), (26, 90)])
    guard = P([(-72, 92), (72, 92), (72, 124), (-72, 124)])
    hilt = P([(-20, 124), (20, 124), (20, 215), (-20, 215)])
    pommel = P([(-30, 210), (30, 210), (30, 236), (-30, 236)])
    for poly, col in ((hilt, (120, 62, 34, 255)), (pommel, (238, 186, 60, 255)), (blade, (206, 216, 228, 255)), (guard, (238, 186, 60, 255))):
        outlined_polygon(d, poly, col, int(W * k))
    d.polygon(edge, fill=(250, 252, 255, 255))
    # Hilt wrapping.
    for t in range(3):
        y = 140 + t * 25
        d.line(P([(-20, y), (20, y + 14)]), fill=(70, 34, 18, 255), width=int(9 * k))
    # Guard shine.
    d.line(P([(-60, 101), (60, 101)]), fill=(255, 236, 150, 255), width=int(7 * k))


def burst(img, cx, cy, r_out, r_in, points, fill):
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(points * 2):
        a = -math.pi / 2 + i * math.pi / points
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    outlined_polygon(d, pts, fill, 16)


def heart_points(cx, cy, size):
    pts = []
    for i in range(120):
        t = i / 120 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * size, cy + y * size))
    return pts


def skull(img, cx, cy, r):
    d = ImageDraw.Draw(img)
    w = int(r * 0.16)
    bone = (246, 238, 220, 255)
    # Jaw then cranium, each with outline.
    jaw = [cx - r * 0.55, cy + r * 0.35, cx + r * 0.55, cy + r * 1.0]
    d.rounded_rectangle([jaw[0] - w, jaw[1] - w, jaw[2] + w, jaw[3] + w], radius=r * 0.25, fill=OUTLINE)
    d.ellipse([cx - r - w, cy - r - w, cx + r + w, cy + r * 0.8 + w], fill=OUTLINE)
    d.rounded_rectangle(jaw, radius=r * 0.2, fill=bone)
    d.ellipse([cx - r, cy - r, cx + r, cy + r * 0.8], fill=bone)
    # Eyes, nose, teeth.
    for side in (-1, 1):
        ex = cx + side * r * 0.4
        d.ellipse([ex - r * 0.27, cy - r * 0.05, ex + r * 0.27, cy + r * 0.45], fill=OUTLINE)
    d.polygon([(cx, cy + r * 0.45), (cx - r * 0.12, cy + r * 0.65), (cx + r * 0.12, cy + r * 0.65)], fill=OUTLINE)
    for t in (-1, 0, 1):
        x = cx + t * r * 0.22
        d.line([(x, cy + r * 0.78), (x, cy + r * 1.0)], fill=OUTLINE, width=int(r * 0.08))
    # Shine.
    d.ellipse([cx - r * 0.6, cy - r * 0.75, cx - r * 0.2, cy - r * 0.45], fill=(255, 255, 255, 255))


def up_arrow(img, cx, cy, size, fill):
    d = ImageDraw.Draw(img)
    pts = [(cx, cy - size), (cx + size * 0.85, cy - size * 0.05), (cx + size * 0.35, cy - size * 0.05),
           (cx + size * 0.35, cy + size * 0.9), (cx - size * 0.35, cy + size * 0.9), (cx - size * 0.35, cy - size * 0.05),
           (cx - size * 0.85, cy - size * 0.05)]
    outlined_polygon(d, pts, fill, 16)


def finish(img, path):
    # Soft drop shadow, then downsample.
    alpha = img.split()[3]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.point(lambda a: int(a * 0.45)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base.alpha_composite(shadow, (8, 12))
    base.alpha_composite(img)
    base.resize((OUT, OUT), Image.LANCZOS).save(path)


def damage(path):
    img = canvas()
    burst(img, 370, 140, 112, 58, 8, (255, 196, 60, 255))
    burst(img, 370, 140, 58, 32, 8, (255, 246, 200, 255))
    sword(img, 1.0, 236, 276, math.pi / 4)
    finish(img, path)


def damage_per_fall(path):
    img = canvas()
    sword(img, 0.95, 256, 250, math.pi / 4)
    skull(img, 220, 270, 118)
    up_arrow(img, 392, 378, 92, (110, 220, 90, 255))
    finish(img, path)


def enemy_hit(path):
    img = canvas()
    d = ImageDraw.Draw(img)
    heart = heart_points(256, 250, 11.8)
    outlined_polygon(d, heart, (226, 58, 52, 255))
    # Lighter top-left shading, kept inside the heart.
    inside = Image.new("L", (S, S), 0)
    ImageDraw.Draw(inside).polygon(heart, fill=255)
    paint = canvas()
    p = ImageDraw.Draw(paint)
    p.ellipse([120, 110, 240, 210], fill=(246, 120, 108, 255))
    p.ellipse([148, 128, 194, 164], fill=(255, 214, 204, 255))
    # Three enemy claw cuts across the heart.
    for off in (-70, 0, 70):
        a = (150 + off, 120)
        b = (360 + off, 390)
        p.line([a, b], fill=OUTLINE, width=46)
        p.line([a, b], fill=(130, 18, 24, 255), width=22)
    clear = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.alpha_composite(Image.composite(paint, clear, inside))
    finish(img, path)


def max_health(path):
    """Fall reward (D-099): +max health, a full heart with a green up arrow."""
    img = canvas()
    d = ImageDraw.Draw(img)
    heart = heart_points(230, 250, 11.0)
    outlined_polygon(d, heart, (226, 58, 52, 255))
    inside = Image.new("L", (S, S), 0)
    ImageDraw.Draw(inside).polygon(heart, fill=255)
    paint = canvas()
    p = ImageDraw.Draw(paint)
    p.ellipse([108, 112, 220, 205], fill=(246, 120, 108, 255))
    p.ellipse([134, 128, 178, 160], fill=(255, 214, 204, 255))
    clear = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.alpha_composite(Image.composite(paint, clear, inside))
    up_arrow(img, 392, 370, 96, (110, 220, 90, 255))
    finish(img, path)


def fast_travel(path):
    """Fast travel (D-100): a glowing portal ring with a swirl and a gold arrow."""
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([60, 60, 452, 452], fill=OUTLINE)
    d.ellipse([84, 84, 428, 428], fill=(70, 150, 220, 255))
    d.ellipse([124, 124, 388, 388], fill=(40, 90, 170, 255))
    for index in range(3):
        start = index * 120
        d.arc([140, 140, 372, 372], start, start + 80, fill=(190, 240, 255, 255), width=26)
        d.arc([190, 190, 322, 322], start + 60, start + 130, fill=(150, 220, 255, 255), width=18)
    d.ellipse([236, 236, 276, 276], fill=(235, 250, 255, 255))
    # Gold arrow at the lower right: "go there".
    pts = [(300, 330), (440, 330), (440, 290), (500, 370), (440, 450), (440, 410), (300, 410)]
    outlined_polygon(d, pts, (255, 206, 72, 255), 14)
    finish(img, path)


def boss_marker(path):
    """Minimap / screen-edge guide to the region boss (D-090): skull on a red badge."""
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([28, 28, 484, 484], fill=OUTLINE)
    d.ellipse([52, 52, 460, 460], fill=(214, 52, 44, 255))
    d.ellipse([86, 70, 300, 200], fill=(236, 96, 84, 255))
    skull(img, 256, 236, 138)
    finish(img, path)


def gate_marker(path):
    """Guide to the open gate once the boss is beaten (D-090): green badge, arch."""
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([28, 28, 484, 484], fill=OUTLINE)
    d.ellipse([52, 52, 460, 460], fill=(84, 182, 76, 255))
    d.rounded_rectangle([150, 150, 362, 400], radius=100, fill=OUTLINE)
    d.rounded_rectangle([176, 176, 336, 400], radius=80, fill=(250, 244, 210, 255))
    d.rectangle([150, 380, 362, 410], fill=OUTLINE)
    finish(img, path)


if __name__ == "__main__":
    out = sys.argv[1]
    damage(out + "/icon_damage.png")
    damage_per_fall(out + "/icon_damage_per_fall.png")
    enemy_hit(out + "/icon_enemy_hit.png")
    boss_marker(out + "/icon_boss_marker.png")
    max_health(out + "/icon_max_health.png")
    fast_travel(out + "/icon_fast_travel.png")
    gate_marker(out + "/icon_gate_marker.png")
