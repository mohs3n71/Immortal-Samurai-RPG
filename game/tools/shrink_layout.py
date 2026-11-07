"""Shrinks the Meadowlands layout (D-093) to about 70 %, keeping the centre intact.

Every map coordinate goes through warp(): within CORE of the centre (village,
start arenas, spawn) nothing moves; beyond it, distance from the centre
(square / Chebyshev distance, so the square border stays square) is
compressed linearly so the old border OLD_HALF lands on NEW_HALF.
Clearing and arena radii stay (combat room); water, groves, orchard and
crop plots shrink with the land.

Usage: python3 tools/shrink_layout.py <source layout.gd> <output layout.gd>
Prints the warped soldier clearings and boss/gate positions for
scripts/enemies/enemy_roster.gd (the game cannot read tools/).
"""
import re
import sys

CORE = 40.0
OLD_HALF = 168.0
NEW_HALF = 118.0
K = (NEW_HALF - CORE) / (OLD_HALF - CORE)


def warp(x, z):
    n = max(abs(x), abs(z))
    if n <= CORE:
        return x, z
    s = (CORE + (n - CORE) * K) / n
    return x * s, z * s


def fmt(v):
    v = round(v, 1)
    return ("%d" % v) if v == int(v) else ("%.1f" % v)


def warp_vec2(text):
    def repl(m):
        x, z = warp(float(m.group(1)), float(m.group(2)))
        return "Vector2(%s, %s)" % (fmt(x), fmt(z))
    return re.sub(r"Vector2\((-?[\d.]+), (-?[\d.]+)\)", repl, text)


def warp_vec3_xz(text, radius_scale=1.0):
    def repl(m):
        x, z = warp(float(m.group(1)), float(m.group(2)))
        return "Vector3(%s, %s, %s)" % (fmt(x), fmt(z), fmt(float(m.group(3)) * radius_scale))
    return re.sub(r"Vector3\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", repl, text)


def warp_vec4_xz(text, radius_scale=1.0):
    def repl(m):
        x, z = warp(float(m.group(1)), float(m.group(2)))
        return "Vector4(%s, %s, %s, %s)" % (fmt(x), fmt(z), fmt(float(m.group(3)) * radius_scale), m.group(4))
    return re.sub(r"Vector4\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", repl, text)


# Old clearing centres and radii (PLAZAS before D-093). Props close to one keep
# their offset from it (the clearing keeps its size), so decoration that rings
# a clearing does not end up inside it.
OLD_PLAZAS = [(-56, -64, 9), (68, -62, 9), (-62, 54, 7), (12, -142, 11), (120, -116, 12), (150, 0, 13),
              (0, 132, 12), (80, 142, 8), (-118, 120, 9), (-128, 20, 8), (-140, -150, 10)]


# The pond sits where the warp bends (just outside CORE), so it and everything
# around it move as one piece with its centre: [x, z, reach].
RIGID_GROUPS = [(54, 46, 14)]


def warp_prop(x, z):
    for px, pz, reach in RIGID_GROUPS:
        if ((x - px) ** 2 + (z - pz) ** 2) ** 0.5 < reach + 8.0:
            cx, cz = warp(px, pz)
            return cx + (x - px), cz + (z - pz)
    for px, pz, r in OLD_PLAZAS:
        if ((x - px) ** 2 + (z - pz) ** 2) ** 0.5 < r + 8.0:
            cx, cz = warp(px, pz)
            return cx + (x - px), cz + (z - pz)
    return warp(x, z)


def warp_props(text):
    def repl(m):
        x, z = warp_prop(float(m.group(2)), float(m.group(3)))
        return '["%s", %s, %s,' % (m.group(1), fmt(x), fmt(z))
    return re.sub(r'\["([^"]+)", (-?[\d.]+), (-?[\d.]+),', repl, text)


def warp_fields(text):
    def repl(m):
        x, z = warp(float(m.group(1)), float(m.group(2)))
        return "[%s, %s, %s, Vector2(%s, %s)]" % (fmt(x), fmt(z), m.group(3), fmt(float(m.group(4)) * 0.8), fmt(float(m.group(5)) * 0.8))
    return re.sub(r"\[(-?[\d.]+), (-?[\d.]+), ([\d.]+), Vector2\(([\d.]+), ([\d.]+)\)\]", repl, text)


def warp_groves(text):
    text = warp_vec2(text)
    return re.sub(r"\], (\d+), ([\d.]+), (\d+)\]", lambda m: "], %d, %s, %s]" % (max(4, round(int(m.group(1)) * 0.55)), m.group(2), m.group(3)), text)


BOSS_ARENA_OLD = (88, -148)
GATE_OLD = (88, -164)


def boss_positions():
    gx, gz = warp(*GATE_OLD)
    # Keep the old 16 units between gate and arena centre (radius 13).
    return (gx, gz + 16.0), (gx, gz)


def transform(name, block):
    if name == "PLAY_HALF":
        return "const PLAY_HALF := %s\n" % fmt(NEW_HALF) + "\n" if False else block.replace("168.0", "%.1f" % NEW_HALF)
    if name == "WORLD_HALF":
        return block.replace("250.0", "200.0")
    if name == "NORTH_NOTCH":
        a = warp(38, -OLD_HALF)[0]
        b = warp(58, -OLD_HALF)[0]
        return re.sub(r"Vector2\([^)]*\)", "Vector2(%s, %s)" % (fmt(a), fmt(b)), block)
    if name == "EAST_NOTCH":
        a = warp(OLD_HALF, 128)[1]
        b = warp(OLD_HALF, 148)[1]
        return re.sub(r"Vector2\([^)]*\)", "Vector2(%s, %s)" % (fmt(a), fmt(b)), block)
    if name in ("PATHS", "STREAM", "OUTFLOW", "LAKE_OUTFLOW", "PLATEAUS", "FLOWER_MEADOWS", "FENCES"):
        return warp_vec2(block)
    if name == "PLAZAS":
        arena, _gate = boss_positions()
        block = block.replace("Vector3(88, -148, 13)", "Vector3(%s, %s, 13)" % (fmt(arena[0]), fmt(arena[1])))
        # Everything else (boss arena already moved: its x,z are inside 118 so warp would move it again).
        parts = block.split("# Region boss arena")
        return warp_vec3_xz(parts[0]) + "# Region boss arena" + parts[1]
    if name == "POND":
        # Moves as one piece (RIGID_GROUPS), keeping its size.
        def pond(m):
            x, z = warp_prop(float(m.group(1)), float(m.group(2)))
            return "Vector3(%s, %s, %s)" % (fmt(x), fmt(z), m.group(3))
        return re.sub(r"Vector3\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", pond, block)
    if name == "REED_SPOTS":
        def reed(m):
            x, z = warp_prop(float(m.group(1)), float(m.group(2)))
            return "Vector2(%s, %s)" % (fmt(x), fmt(z))
        return re.sub(r"Vector2\((-?[\d.]+), (-?[\d.]+)\)", reed, block)
    if name == "LAKE":
        return warp_vec3_xz(block, 0.75)
    if name == "OUTCROPS":
        return warp_vec4_xz(block)
    if name == "ISLAND":
        return warp_vec4_xz(block, 0.75)
    if name in ("VILLAGE", "TERRACE_PROPS", "FOREST", "FARM", "POND_PROPS", "OUTER_GROUPS", "RAISED_GROUPS"):
        return warp_props(block)
    if name == "FIELDS":
        return warp_fields(block)
    if name == "GROVES":
        return warp_groves(block)
    if name == "ORCHARD":
        x, z = warp(84, -164)
        return re.sub(r"\[Vector2\([^)]*\), 3, 8, 8.5, 0.0\]", "[Vector2(%s, %s), 3, 6, 6.5, 0.0]" % (fmt(x), fmt(z)), block)
    return block


def parse_paths(text):
    block = re.search(r"(?ms)^const PATHS := \[(.*?)^\]", text).group(1)
    paths = []
    for m in re.finditer(r"\[([\d.]+), \[(.*?)\]\]", block):
        points = [(float(a), float(b)) for a, b in re.findall(r"Vector2\((-?[\d.]+), (-?[\d.]+)\)", m.group(2))]
        paths.append((float(m.group(1)), points))
    return paths


def closest_on_segment(p, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    length = dx * dx + dz * dz
    t = 0.0 if length == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - az) * dz) / length))
    return ax + dx * t, az + dz * t


def nudge_off_paths(text):
    """Pushes solid props (anything not "none") clear of the warped paths."""
    paths = parse_paths(text)

    def repl(m):
        rest = m.group(4)
        if '"none"' in rest.split("]")[0]:
            return m.group(0)
        x, z = float(m.group(2)), float(m.group(3))
        for _ in range(6):
            moved = False
            for half, points in paths:
                for a, b in zip(points, points[1:]):
                    cx, cz = closest_on_segment((x, z), a, b)
                    dx, dz = x - cx, z - cz
                    d = (dx * dx + dz * dz) ** 0.5
                    need = half + 2.5
                    if d < need:
                        if d < 0.01:
                            dx, dz, d = -(b[1] - a[1]), b[0] - a[0], ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5
                        x, z = cx + dx / d * need, cz + dz / d * need
                        moved = True
            if not moved:
                break
        return '["%s", %s, %s,%s' % (m.group(1), fmt(x), fmt(z), rest)
    return re.sub(r'\["([^"]+)", (-?[\d.]+), (-?[\d.]+),([^\n]*)', repl, text)


# Props that no longer fit after the shrink: (asset, old x, old z).
DROPPED = [("butcher/grass-tree-b", -120, -160)]   # High shrine: left a pocket by the map corner.


def drop_props(text):
    for asset, x, z in DROPPED:
        text, count = re.subn(r'\n\t*\["%s", %s, %s,[^\n]*' % (re.escape(asset), *(re.escape(fmt(v)) for v in warp_prop(x, z))), "", text)
        assert count == 1, (asset, x, z)
    return text


def main(src, dst):
    text = open(src).read()
    pieces = re.split(r"(?m)^(?=const )", text)
    out = []
    for piece in pieces:
        m = re.match(r"const (\w+)", piece)
        out.append(transform(m.group(1), piece) if m else piece)
    result = "".join(out)
    result = nudge_off_paths(result)
    result = drop_props(result)
    result = result.replace("## Hand-authored layout data for the Meadowlands region (D-068, enlarged in D-070).",
                            "## Hand-authored layout data for the Meadowlands region (D-068, enlarged in D-070,\n## shrunk to about 70 % by tools/shrink_layout.py in D-093; the centre is unchanged).")
    result = result.replace("## The original 168 x 168 meadow (\"core\", |x|,|z| < 84) is kept unchanged in the\n## middle; the outer ring adds new places around it.",
                            "## Within 40 units of the centre nothing moved in D-093; beyond it, distances\n## were compressed so the old +/-168 border is now +/-118.")
    open(dst, "w").write(result)
    roster = [(-62, 54), (-56, -64), (68, -62), (-128, 20), (0, 132), (150, 0), (80, 142), (12, -142), (-118, 120), (120, -116), (-140, -150)]
    print("roster plazas:", ", ".join("Vector2(%s, %s)" % tuple(fmt(c) for c in warp(*p)) for p in roster))
    arena, gate = boss_positions()
    print("boss arena: Vector2(%s, %s)  gate: Vector2(%s, %s)" % (fmt(arena[0]), fmt(arena[1]), fmt(gate[0]), fmt(gate[1])))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
