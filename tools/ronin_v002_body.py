"""Continuous anatomy and grounded adult proportions for Ember Ronin v002."""

import math
import bpy
from mathutils import Vector
from character_geometry import ellipsoid, link, mesh, plate, tube

ARMS = [((-0.49, -0.08, 2.84), (-0.75, -0.08, 2.41), (-0.81, -0.40, 2.07)), ((0.49, -0.08, 2.84), (0.77, -0.16, 2.43), (1.02, -0.52, 2.58))]


def gaussian(value, center, width):
    return math.exp(-((value - center) / width) ** 2)


def trunk(surface):
    levels = [(1.70, 0.29, 0.20), (1.90, 0.28, 0.20), (2.12, 0.29, 0.19), (2.35, 0.35, 0.225), (2.62, 0.46, 0.235), (2.78, 0.44, 0.19), (2.87, 0.32, 0.15), (2.96, 0.15, 0.125)]
    vertices, faces = [], []
    rows, columns = 90, 96
    for row in range(rows):
        z = 1.70 + row / (rows - 1) * 1.26
        pair = next((i for i in range(len(levels) - 1) if levels[i][0] <= z <= levels[i + 1][0]), len(levels) - 2)
        a, b = levels[pair], levels[pair + 1]
        t = (z - a[0]) / (b[0] - a[0])
        width = a[1] * (1 - t) + b[1] * t
        depth = a[2] * (1 - t) + b[2] * t
        for column in range(columns):
            angle = column / columns * math.tau
            x = width * math.cos(angle)
            y = depth * math.sin(angle) - (z - 1.70) * 0.06
            front = max(0, -math.sin(angle)) ** 9
            # Broad, shallow anatomical planes; no separate spherical muscles.
            chest = 0.10 * gaussian(abs(x), 0.20, 0.18) * gaussian(z, 2.65, 0.13)
            abdomen = sum(0.037 * gaussian(abs(x), 0.095, 0.075) * gaussian(z, height, 0.075) for height in (2.18, 2.34, 2.49))
            sternum = 0.014 * gaussian(x, 0, 0.025) * gaussian(z, 2.55, 0.3)
            y -= front * (chest + abdomen - sternum)
            vertices.append((x, y, z))
    for row in range(rows - 1):
        for column in range(columns):
            a = row * columns + column
            b = row * columns + (column + 1) % columns
            faces.append((a, b, b + columns, a + columns))
    faces += [tuple(range(columns - 1, -1, -1)), tuple(range((rows - 1) * columns, rows * columns))]
    return mesh('v002 continuous anatomical torso', vertices, faces, surface)


def muscle(name, start, end, width, depth, surface):
    start, end = Vector(start), Vector(end)
    obj = ellipsoid(name, (start + end) / 2, (width, depth, (end - start).length / 2 + width * 0.35), surface, 32, 20)
    obj.rotation_euler = (end - start).to_track_quat('Z', 'Y').to_euler()
    return obj


def unified_skin(p):
    before = set(bpy.context.scene.objects)
    trunk(p['skin'])
    link('v002 neck', (0, -0.075, 2.84), (0, -0.11, 3.19), (0.15, 0.125), p['skin'], 32)
    for shoulder, elbow, wrist in ARMS:
        muscle('v002 integrated deltoid', Vector(shoulder) + Vector((0, 0, 0.04)), Vector(shoulder) + Vector((0, 0, -0.20)), 0.19, 0.19, p['skin'])
        muscle('v002 upper arm anatomy', shoulder, elbow, 0.165, 0.17, p['skin'])
        ellipsoid('v002 elbow joint', elbow, (0.12, 0.125, 0.13), p['skin'], 24, 16)
        muscle('v002 forearm anatomy', elbow, wrist, 0.12, 0.135, p['skin'])
    bpy.ops.object.select_all(action='DESELECT')
    parts = list(set(bpy.context.scene.objects) - before)
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    body = bpy.context.object
    body.name = 'v002 unified skin sculpt'
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    remesh = body.modifiers.new('Fuse anatomical surfaces', 'REMESH')
    remesh.mode, remesh.voxel_size = 'VOXEL', 0.012
    remesh.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth = body.modifiers.new('Relax sculpt joins', 'SMOOTH')
    smooth.factor, smooth.iterations = 0.8, 7
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    body.data.materials.clear()
    body.data.materials.append(p['skin'])
    for polygon in body.data.polygons:
        polygon.use_smooth = True
    tube('v002 healed clavicle scar', [(0.13, -0.28, 2.78), (0.22, -0.31, 2.75), (0.31, -0.31, 2.71)], 0.0035, p['scar'])


def lower_body(p):
    for side in (-1, 1):
        hip = (side * 0.23, 0.04, 1.82)
        knee = (side * 0.46, -0.18 if side < 0 else -0.04, 1.02)
        ankle = (side * 0.59, 0.02 if side < 0 else 0.17, 0.22)
        muscle('v002 fitted trouser thigh', hip, knee, 0.205, 0.22, p['leather'])
        muscle('v002 calf and cloth', knee, ankle, 0.145, 0.16, p['leather'])
        foot = ellipsoid('v002 shaped leather boot', (ankle[0], ankle[1] - 0.17, 0.14), (0.145, 0.32, 0.135), p['leather'], 32, 16)
        ellipsoid('v002 boot sole', (ankle[0], ankle[1] - 0.17, 0.055), (0.15, 0.325, 0.045), p['iron'], 32, 12)
        for i in range(7):
            t = 0.15 + i * 0.075
            center = Vector(ankle).lerp(Vector(knee), t)
            direction = (Vector(knee) - Vector(ankle)).normalized()
            link('v002 flat boot binding', center - direction * 0.022, center + direction * 0.022, (0.145, 0.148), p['cloth'], 24)
        x, y, z = knee
        plate('v002 angular knee armor', [(x - 0.13, y - 0.20, z + 0.10), (x + 0.13, y - 0.20, z + 0.10), (x + 0.12, y - 0.25, z - 0.08), (x, y - 0.28, z - 0.19), (x - 0.12, y - 0.25, z - 0.08)], 0.025, p['iron'], 0.005)
        plate('v002 tapered shin plate', [(x - 0.11, y - 0.18, z - 0.15), (x + 0.11, y - 0.18, z - 0.15), (ankle[0] + 0.07, ankle[1] - 0.17, 0.27), (ankle[0] - 0.07, ankle[1] - 0.17, 0.27)], 0.025, p['iron'], 0.005)


def gauntlets(p):
    for shoulder, elbow, wrist in ARMS:
        start = Vector(wrist).lerp(Vector(elbow), 0.15)
        end = Vector(wrist).lerp(Vector(elbow), 0.78)
        link('v002 tapered vambrace', start, end, (0.15, 0.18), p['iron'], 16)
        for factor in (0.17, 0.71):
            center = Vector(wrist).lerp(Vector(elbow), factor)
            direction = (Vector(elbow) - Vector(wrist)).normalized()
            link('v002 bracer leather restraint', center - direction * 0.024, center + direction * 0.024, (0.16 if factor < 0.5 else 0.186,) * 2, p['leather'], 20)
        ellipsoid('v002 gloved palm', wrist, (0.105, 0.10, 0.13), p['leather'], 24, 16)
        for finger in range(4):
            x = wrist[0] - 0.072 + finger * 0.046
            tube('v002 bent glove finger', [(x, wrist[1] - 0.06, wrist[2] + 0.07), (x, wrist[1] - 0.12, wrist[2] + 0.03), (x, wrist[1] - 0.12, wrist[2] - 0.05), (x, wrist[1] - 0.065, wrist[2] - 0.08)], 0.023, p['leather'])
        muscle('v002 wrapped thumb', Vector(wrist) + Vector((0.10, -0.03, 0.06)), Vector(wrist) + Vector((0.045, -0.115, -0.035)), 0.029, 0.028, p['leather'])
