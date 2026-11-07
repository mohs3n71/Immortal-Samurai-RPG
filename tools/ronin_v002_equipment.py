"""Angular mask, thin armor and forged katana for the mature v002 revision."""

import math
import random
import bpy
from mathutils import Vector
from character_geometry import ellipsoid, link, mesh, plate, tube
from ronin_v002_surfaces import curved_panel
from ronin_v002_body import ARMS


def mask_and_hair(p):
    ellipsoid('v002 fitted head cowl', (0, -0.095, 3.235), (0.195, 0.185, 0.265), p['hair'], 40, 28)
    for side in (-1, 1):
        plate('v002 severe ivory brow', [(side * 0.008, -0.29, 3.51), (side * 0.16, -0.245, 3.43), (side * 0.202, -0.265, 3.335), (side * 0.045, -0.358, 3.275), (side * 0.012, -0.345, 3.31)], 0.027, p['ivory'], 0.004)
        plate('v002 narrow recessed eye', [(side * 0.048, -0.33, 3.267), (side * 0.182, -0.275, 3.323), (side * 0.17, -0.28, 3.30), (side * 0.06, -0.33, 3.247)], 0.010, p['eye'], 0.001)
        plate('v002 cutting cheek plane', [(side * 0.05, -0.35, 3.24), (side * 0.19, -0.27, 3.29), (side * 0.18, -0.24, 3.16), (side * 0.10, -0.29, 3.045), (side * 0.012, -0.33, 3.005)], 0.027, p['ivory'], 0.004)
        plate('v002 crimson mask slash', [(side * 0.13, -0.281, 3.42), (side * 0.157, -0.272, 3.405), (side * 0.115, -0.313, 3.31), (side * 0.098, -0.325, 3.31)], 0.004, p['red'], 0.001)
        tube('v002 thin mask strap', [(side * 0.18, -0.21, 3.20), (side * 0.20, -0.04, 3.20), (side * 0.15, 0.08, 3.20)], 0.009, p['leather'])
    plate('v002 sharp nasal ridge', [(-0.013, -0.32, 3.49), (0.013, -0.32, 3.49), (0.036, -0.395, 3.245), (0.018, -0.385, 3.13), (0, -0.35, 3.003), (-0.018, -0.385, 3.13), (-0.036, -0.395, 3.245)], 0.018, p['ivory'], 0.003)
    tube('v002 tarnished central seam', [(0, -0.337, 3.47), (0, -0.411, 3.245), (0, -0.40, 3.14), (0, -0.363, 3.04)], 0.0035, p['brass'])
    # Fracture lines are subtle ceramic marks, without copying a Valve rune.
    tube('v002 old temple fracture', [(-0.14, -0.28, 3.43), (-0.10, -0.314, 3.395), (-0.115, -0.32, 3.355)], 0.0016, p['iron'])
    tube('v002 cheek wear mark', [(0.13, -0.288, 3.215), (0.09, -0.325, 3.17), (0.11, -0.31, 3.15)], 0.0012, p['iron'])
    # Narrow swept strands replace the large rounded crest of v001.
    rng = random.Random(12)
    for i in range(34):
        x = (i / 33 - 0.5) * 0.25
        crown = math.sqrt(max(0, 1 - (x / 0.14) ** 2)) * 0.05
        points = [(x, -0.10, 3.445), (x * 0.85, 0.01, 3.49 + crown + rng.uniform(-0.006, 0.006)), (x * 0.5, 0.20, 3.49 + crown * 0.7), (x * 0.15, 0.31, 3.43)]
        hair_strand(points, p['hair'])
    ellipsoid('v002 compact tied topknot', (0, 0.245, 3.47), (0.072, 0.115, 0.065), p['hair'], 24, 16)
    link('v002 topknot binding', (0, 0.24, 3.45), (0, 0.28, 3.45), (0.072, 0.072), p['leather'], 20)
    for side in (-1, 1):
        plate('v002 flat cloth headband tail', [(side * 0.02, 0.06, 3.26), (side * 0.10, 0.06, 3.25), (side * 0.22, 0.32, 3.15), (side * 0.35, 0.43, 3.05), (side * 0.31, 0.44, 3.00), (side * 0.15, 0.32, 3.08)], 0.008, p['cloth'], 0.001)


def hair_strand(points, surface):
    data = bpy.data.curves.new('v002 tapered swept hair', 'CURVE')
    data.dimensions = '3D'
    data.bevel_depth, data.bevel_resolution, data.resolution_u = 0.006, 2, 6
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)
    for i, (point, position) in enumerate(zip(spline.bezier_points, points)):
        point.co = position
        point.handle_left_type = point.handle_right_type = 'AUTO'
        point.radius = (0.4, 1, 0.85, 0.15)[i]
    obj = bpy.data.objects.new('v002 tapered swept hair', data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(surface)


def armor(p):
    for angle in (-150, -90, -30, 30, 90, 150):
        for row in range(5):
            top = 1.85 - row * 0.126
            curved_panel('v002 overlapping curved lamella', math.radians(angle), 0.34 + row * 0.041, 0.88, top, top - 0.16, 0.046, p['red'])
            # Worn metal lower edges use fine geometry instead of fat piping.
            a = math.radians(angle)
            radius = 0.34 + row * 0.041 + 0.047
            points = [(math.sin(a + u * 0.88) * radius, -math.cos(a + u * 0.88) * radius, top - 0.16 + 0.025 * abs(u) * 2) for u in (-0.5, -0.3, 0, 0.3, 0.5)]
            tube('v002 exposed plate edge', points, 0.003, p['edge'])
            for offset in (-0.28, 0.28):
                r = 0.34 + row * 0.041 + 0.008
                ellipsoid('v002 small armor rivet', (math.sin(a + offset) * r, -math.cos(a + offset) * r, top - 0.045), (0.009, 0.009, 0.009), p['brass'], 8, 6)
    for z in (1.86, 1.94):
        curved_panel('v002 layered leather waist belt', 0, 0.31, math.tau, z + 0.05, z - 0.035, 0, p['leather'])
    plate('v002 forged belt clasp', [(-0.09, -0.335, 1.99), (0.09, -0.335, 1.99), (0.085, -0.35, 1.84), (0, -0.365, 1.79), (-0.085, -0.35, 1.84)], 0.018, p['iron'], 0.004)
    tube('v002 belt clasp seam', [(-0.065, -0.36, 1.96), (0.065, -0.36, 1.96), (0.06, -0.375, 1.86), (0, -0.385, 1.82), (-0.06, -0.375, 1.86), (-0.065, -0.36, 1.96)], 0.003, p['brass'])
    tabard(p)
    shoulder(p)
    # Harness follows the rebuilt pectoral planes rather than floating above them.
    chest_harness(p)
    chest_harness(p, back=True)
    tube('v002 harness small buckle', [(-0.08, -0.38, 2.51), (0.01, -0.38, 2.55), (0.07, -0.38, 2.42), (-0.02, -0.38, 2.38), (-0.08, -0.38, 2.51)], 0.007, p['brass'])


def chest_harness(p, back=False):
    levels = [(1.70, 0.29, 0.20), (1.90, 0.28, 0.20), (2.12, 0.29, 0.19), (2.35, 0.35, 0.225), (2.62, 0.46, 0.235), (2.78, 0.44, 0.19), (2.87, 0.32, 0.15), (2.96, 0.15, 0.125)]
    from ronin_v002_body import gaussian
    vertices, faces = [], []
    for row in range(40):
        t = row / 39
        z = 2.87 - t * 0.92
        index = next(i for i in range(len(levels) - 1) if levels[i][0] <= z <= levels[i + 1][0])
        a, b = levels[index], levels[index + 1]
        blend = (z - a[0]) / (b[0] - a[0])
        width = a[1] * (1 - blend) + b[1] * blend
        depth = a[2] * (1 - blend) + b[2] * blend
        for offset in (-0.048, 0.048):
            x = -0.30 + t * 0.49 + offset
            sine = math.sqrt(max(0.01, 1 - (x / width) ** 2))
            chest = 0.10 * gaussian(abs(x), 0.20, 0.18) * gaussian(z, 2.65, 0.13)
            abs_plane = sum(0.037 * gaussian(abs(x), 0.095, 0.075) * gaussian(z, h, 0.075) for h in (2.18, 2.34, 2.49))
            sternum = 0.014 * gaussian(x, 0, 0.025) * gaussian(z, 2.55, 0.3)
            y = -depth * sine - (z - 1.7) * 0.06 - sine ** 9 * (chest + abs_plane - sternum) - 0.018
            if back:
                y = depth * sine - (z - 1.7) * 0.06 + 0.018
            vertices.append((x, y, z))
    faces = [(2 * row, 2 * row + 1, 2 * row + 3, 2 * row + 2) for row in range(39)]
    obj = mesh('v002 fitted back harness' if back else 'v002 fitted diagonal leather harness', vertices, faces, p['leather'])
    obj.modifiers.new('Harness thickness', 'SOLIDIFY').thickness = 0.015


def tabard(p):
    vertices, faces = [], []
    rows, columns = 18, 12
    for row in range(rows):
        v = row / (rows - 1)
        for column in range(columns):
            u = column / (columns - 1) - 0.5
            x = u * (0.24 + v * 0.10) + 0.035 * math.sin(v * 4)
            y = -0.40 - v * 0.30 + 0.009 * math.sin(u * 28 + v * 4)
            z = 1.85 - v * 0.83 + (0.045 * math.sin(u * 35) if row == rows - 1 else 0)
            vertices.append((x, y, z))
    for row in range(rows - 1):
        for column in range(columns - 1):
            a = row * columns + column
            faces.append((a, a + 1, a + 1 + columns, a + columns))
    obj = mesh('v002 folded weathered teal tabard', vertices, faces, p['cloth'])
    obj.modifiers.new('Cloth thickness', 'SOLIDIFY').thickness = 0.007
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def shoulder(p):
    for row in range(3):
        x = -0.48 - row * 0.11
        z = 2.99 - row * 0.105
        vertices = [(x + 0.15, -0.27, z - 0.03), (x - 0.18, -0.28, z - 0.08), (x - 0.24, -0.05, z - 0.10), (x - 0.17, 0.21, z - 0.06), (x + 0.15, 0.19, z + 0.005), (x + 0.09, -0.02, z + 0.06)]
        obj = mesh('v002 angular overlapping shoulder shell', vertices, [(0, 1, 5), (1, 2, 5), (2, 3, 5), (3, 4, 5), (4, 0, 5)], p['iron'] if row == 0 else p['red'])
        obj.modifiers.new('Shoulder plate thickness', 'SOLIDIFY').thickness = 0.022
        bevel = obj.modifiers.new('Worn shoulder edges', 'BEVEL')
        bevel.width, bevel.segments = 0.005, 2
        obj.modifiers.new('Shoulder normals', 'WEIGHTED_NORMAL')
        tube('v002 shoulder exposed lower edge', vertices[:5], 0.004, p['edge'])
        for point in (vertices[0], vertices[3]):
            ellipsoid('v002 shoulder rivet', Vector(point) + Vector((0, -0.007, 0.014)), (0.012, 0.012, 0.012), p['brass'], 8, 6)


def katana(p):
    grip = Vector(ARMS[1][2]) + Vector((0, -0.04, 0))
    axis = Vector((0.68, 0, 0.73)).normalized()
    across = Vector((axis.z, 0, -axis.x))
    guard = grip + axis * 0.16
    bottom = grip - axis * 0.27
    link('v002 katana leather grip', bottom, guard, (0.039, 0.039), p['leather'], 20)
    for i in range(11):
        center = bottom.lerp(guard, (i + 0.5) / 11)
        # Crossed wrapping is narrow, dull cloth, not bright gold rings.
        tube('v002 crossed katana wrap', [center - across * 0.034 + Vector((0, -0.022, 0)), center + across * 0.034 + axis * 0.025 + Vector((0, -0.022, 0))], 0.006, p['cloth'])
    link('v002 katana pommel', bottom - axis * 0.035, bottom, (0.046, 0.044), p['brass'], 12)
    link('v002 compact iron tsuba', guard - across * 0.12, guard + across * 0.12, (0.024, 0.024), p['iron'], 16)
    vertices, faces, edge = [], [], []
    count = 30
    for i in range(count):
        t = i / (count - 1)
        width = 0.049 * (1 - 0.22 * t) if i < count - 1 else 0.001
        center = guard + axis * (0.035 + t * 1.35) + across * (0.14 * t * t)
        vertices += [tuple(center - across * width), tuple(center + Vector((0, -0.013, 0))), tuple(center + across * width), tuple(center + Vector((0, 0.013, 0)))]
        edge.append(tuple(center + across * width))
    for i in range(count - 1):
        for j in range(4):
            a, b = 4 * i + j, 4 * i + (j + 1) % 4
            faces.append((a, b, b + 4, a + 4))
    faces += [(3, 2, 1, 0), tuple(range((count - 1) * 4, count * 4))]
    mesh('v002 curved diamond-section forged katana', vertices, faces, p['steel'])
    tube('v002 honed katana edge', edge, 0.0015, p['edge'])
