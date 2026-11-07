"""Build the Ember Ronin v001 static approval model, without third-party meshes."""

import math
from pathlib import Path
import bpy
from mathutils import Vector
from character_geometry import box, ellipsoid, link, material, plate, ring, torso, tube

ROOT = Path(__file__).resolve().parents[1]
CHARACTER = ROOT / 'assets/characters/ember-ronin'


def palette():
    return {
        'skin': material('Warm ochre skin', (0.44, 0.205, 0.085), roughness=0.5),
        'skin_light': material('Raised muscle planes', (0.53, 0.265, 0.12), roughness=0.48),
        'dark': material('Blue black iron', (0.025, 0.044, 0.057), 0.65, 0.3),
        'edge': material('Brushed iron edges', (0.09, 0.13, 0.15), 0.75, 0.28),
        'red': material('Oxblood lacquer', (0.32, 0.026, 0.022), 0.35, 0.3),
        'red_light': material('Crimson lacquer highlight', (0.55, 0.055, 0.025), 0.35, 0.27),
        'gold': material('Antique brass', (0.55, 0.315, 0.095), 0.78, 0.28),
        'ivory': material('Ivory ceramic mask', (0.79, 0.73, 0.56), 0.15, 0.26),
        'cloth': material('Deep teal linen', (0.012, 0.16, 0.16), 0, 0.85),
        'wrap': material('Graphite bindings', (0.035, 0.033, 0.03), 0, 0.8),
        'steel': material('Tempered blade', (0.28, 0.42, 0.48), 0.88, 0.2),
        'blade_edge': material('Honed silver edge', (0.72, 0.83, 0.84), 0.9, 0.17),
        'eye': material('Ember eye slits', (1.0, 0.15, 0.025), 0.3, 0.25, 2),
    }


def legs(p):
    for side in (-1, 1):
        hip = (side * 0.25, 0, 1.53)
        knee = (side * 0.49, -0.12, 0.87)
        ankle = (side * 0.55, 0.015, 0.24)
        link('Loose trouser thigh', knee, hip, (0.21, 0.24), p['wrap'])
        ellipsoid('Cloth knee', knee, (0.21, 0.20, 0.22), p['wrap'])
        link('Bound lower leg', ankle, knee, (0.135, 0.18), p['wrap'])
        box('Split toe boot', (side * 0.55, -0.13, 0.14), (0.32, 0.55, 0.23), p['dark'], 0.07)
        box('Boot toe division', (side * 0.55, -0.40, 0.16), (0.014, 0.02, 0.13), p['gold'], 0.003)
        for i in range(4):
            z = 0.31 + i * 0.105
            ring('Calf linen binding', (side * 0.54, 0.015 - i * 0.02, z), 0.14 + i * 0.008, 0.022, p['cloth'])
        plate('Shin guard', [(side * 0.55 - 0.12, -0.17, 0.35), (side * 0.55 + 0.12, -0.17, 0.35), (side * 0.49 + 0.145, -0.31, 0.78), (side * 0.49 - 0.145, -0.31, 0.78)], 0.07, p['dark'])
        plate('Knee shield', [(side * 0.49 - 0.17, -0.32, 0.97), (side * 0.49 + 0.17, -0.32, 0.97), (side * 0.49 + 0.12, -0.36, 0.79), (side * 0.49, -0.38, 0.73), (side * 0.49 - 0.12, -0.36, 0.79)], 0.06, p['red'])


def body(p):
    torso('Muscular torso', [(1.48, 0.29, 0.22), (1.7, 0.29, 0.21), (2.0, 0.33, 0.24), (2.27, 0.45, 0.27), (2.5, 0.51, 0.25), (2.65, 0.43, 0.19), (2.74, 0.21, 0.16)], p['skin'])
    link('Neck', (0, 0, 2.64), (0, 0, 3.02), (0.16, 0.15), p['skin'])
    for side in (-1, 1):
        ellipsoid('Pectoral', (side * 0.23, -0.22, 2.43), (0.265, 0.125, 0.17), p['skin_light'])
        for z, width in [(2.16, 0.115), (1.99, 0.105), (1.83, 0.095)]:
            ellipsoid('Abdominal plane', (side * 0.11, -0.23, z), (width, 0.055, 0.095), p['skin_light'])
        ellipsoid('Shoulder deltoid', (side * 0.54, 0, 2.58), (0.245, 0.255, 0.255), p['skin_light'])
    # Diagonal harness fitted over the front and back; separate from the skin.
    plate('Chest leather harness', [(-0.42, -0.28, 2.67), (-0.25, -0.34, 2.7), (0.31, -0.295, 1.76), (0.14, -0.30, 1.73)], 0.045, p['wrap'])
    plate('Harness brass trim', [(-0.42, -0.295, 2.67), (-0.4, -0.31, 2.68), (0.17, -0.32, 1.74), (0.14, -0.31, 1.73)], 0.012, p['gold'], 0.005)
    box('Harness buckle', (-0.13, -0.38, 2.27), (0.20, 0.045, 0.22), p['gold'], 0.02, (0, -0.52, 0))
    box('Harness buckle inset', (-0.13, -0.41, 2.27), (0.115, 0.015, 0.13), p['dark'], 0.009, (0, -0.52, 0))
    plate('Back harness', [(-0.42, 0.21, 2.67), (-0.24, 0.25, 2.7), (0.32, 0.25, 1.76), (0.14, 0.25, 1.73)], 0.04, p['wrap'])


def armor(p):
    torso('Wide belt', [(1.57, 0.36, 0.28), (1.76, 0.36, 0.28)], p['dark'])
    for z in (1.58, 1.74):
        obj = ring('Belt piping', (0, 0, z), 0.34, 0.02, p['gold'])
        obj.scale.y = 0.8
    plate('Belt crest', [(-0.135, -0.31, 1.79), (0.135, -0.31, 1.79), (0.13, -0.35, 1.56), (0, -0.37, 1.48), (-0.13, -0.35, 1.56)], 0.04, p['gold'])
    plate('Belt crest inset', [(-0.085, -0.365, 1.74), (0.085, -0.365, 1.74), (0.075, -0.39, 1.59), (0, -0.405, 1.54), (-0.075, -0.39, 1.59)], 0.02, p['red'])
    # Six radial lamellar skirt panels leave the legs and silhouette readable.
    for angle in (-135, -90, -45, 45, 90, 135):
        a = math.radians(angle)
        for row in range(4):
            radius = 0.36 + row * 0.06
            z = 1.49 - row * 0.145
            obj = box('Skirt iron rim', (math.sin(a) * radius, -math.cos(a) * radius, z), (0.32 + row * 0.024, 0.075, 0.18), p['dark'], 0.018)
            obj.rotation_euler = (0, 0, a)
            inset = box('Crimson lamellar plate', (math.sin(a) * (radius + 0.045), -math.cos(a) * (radius + 0.045), z + 0.012), (0.27 + row * 0.024, 0.035, 0.115), p['red_light'] if row == 0 else p['red'], 0.013)
            inset.rotation_euler.z = a
            for offset in (-0.10, 0.10):
                x = math.sin(a) * (radius + 0.07) + math.cos(a) * offset
                y = -math.cos(a) * (radius + 0.07) + math.sin(a) * offset
                ellipsoid('Lamellar brass rivet', (x, y, z + 0.02), (0.022, 0.022, 0.022), p['gold'], 8, 6)
    plate('Teal front tabard', [(-0.135, -0.32, 1.59), (0.135, -0.32, 1.59), (0.17, -0.45, 0.89), (0.03, -0.48, 0.76), (-0.13, -0.44, 0.92)], 0.028, p['cloth'])
    tube('Tabard embroidered seam', [(-0.105, -0.354, 1.5), (-0.10, -0.48, 0.95), (0.03, -0.51, 0.81), (0.13, -0.49, 0.92)], 0.008, p['gold'])
    # Asymmetric armor protects the character's left shoulder.
    ellipsoid('Left shoulder iron base', (-0.58, 0, 2.65), (0.36, 0.31, 0.23), p['dark'])
    for i in range(3):
        box('Left overlapping shoulder lacquer', (-0.60 - i * 0.075, -0.02, 2.81 - i * 0.11), (0.52, 0.48, 0.11), p['red'], 0.045, (0, -0.18, 0))
    tube('Shoulder gold ridge', [(-0.98, -0.23, 2.61), (-0.88, -0.27, 2.82), (-0.58, -0.27, 2.89), (-0.37, -0.22, 2.84)], 0.02, p['gold'])
    for side in (-1, 1):
        link('Neck collar wrap', (side * 0.10, 0.03, 2.81), (side * 0.43, 0.03, 2.69), (0.10, 0.13), p['wrap'])


def arms(p):
    positions = [((-0.58, 0, 2.55), (-0.89, -0.04, 2.13), (-0.81, -0.34, 1.82)), ((0.56, 0, 2.55), (0.86, -0.12, 2.25), (1.12, -0.38, 2.36))]
    for shoulder, elbow, wrist in positions:
        link('Upper arm', elbow, shoulder, (0.15, 0.21), p['skin'])
        middle = (Vector(shoulder) + Vector(elbow)) / 2
        ellipsoid('Bicep', middle + Vector((0, -0.055, 0)), (0.18, 0.17, 0.23), p['skin_light'])
        ellipsoid('Elbow', elbow, (0.155, 0.16, 0.16), p['skin'])
        link('Forearm', wrist, elbow, (0.105, 0.17), p['skin'])
        start = Vector(wrist).lerp(Vector(elbow), 0.1)
        end = Vector(wrist).lerp(Vector(elbow), 0.8)
        link('Iron bracer', start, end, (0.14, 0.185), p['dark'])
        for factor in (0.16, 0.75):
            center = Vector(wrist).lerp(Vector(elbow), factor)
            delta = (Vector(elbow) - Vector(wrist)).normalized() * 0.025
            link('Bracer brass cuff', center - delta, center + delta, (0.155 if factor < 0.5 else 0.18,) * 2, p['gold'])
        center = Vector(wrist).lerp(Vector(elbow), 0.47) + Vector((0, -0.13, 0))
        ellipsoid('Bracer lacquer inset', center, (0.12, 0.055, 0.16), p['red'])
        ellipsoid('Gloved fist', wrist, (0.13, 0.125, 0.15), p['wrap'])
        for i in range(4):
            ellipsoid('Finger knuckle', (wrist[0] - 0.09 + i * 0.055, wrist[1] - 0.10, wrist[2] + 0.01), (0.032, 0.045, 0.065), p['skin_light'], 8, 6)


def head(p):
    ellipsoid('Dark head under mask', (0, 0.015, 3.13), (0.265, 0.235, 0.34), p['wrap'])
    # Faceted ceramic plates surround visible recessed eye slits.
    for side in (-1, 1):
        plate('Ivory mask brow', [(side * 0.025, -0.27, 3.43), (side * 0.235, -0.19, 3.36), (side * 0.26, -0.22, 3.20), (side * 0.06, -0.32, 3.22)], 0.07, p['ivory'], 0.015)
        plate('Ivory mask cheek', [(side * 0.06, -0.33, 3.16), (side * 0.255, -0.24, 3.16), (side * 0.22, -0.24, 3.00), (side * 0.05, -0.30, 2.91)], 0.065, p['ivory'], 0.018)
        plate('Recessed ember eye', [(side * 0.065, -0.29, 3.19), (side * 0.215, -0.24, 3.20), (side * 0.18, -0.27, 3.155), (side * 0.08, -0.30, 3.16)], 0.025, p['eye'], 0.005)
        plate('Crimson temple stripe', [(side * 0.19, -0.255, 3.36), (side * 0.22, -0.24, 3.35), (side * 0.16, -0.30, 3.24), (side * 0.13, -0.315, 3.25)], 0.012, p['red_light'], 0.003)
        link('Mask fastening', (side * 0.21, -0.15, 3.09), (side * 0.28, 0.10, 3.10), (0.026, 0.026), p['gold'], 8)
    plate('Central mask keel', [(-0.025, -0.32, 3.43), (0.025, -0.32, 3.43), (0.055, -0.39, 3.13), (0, -0.35, 2.89), (-0.055, -0.39, 3.13)], 0.08, p['ivory'])
    tube('Gold mask center seam', [(0, -0.34, 3.40), (0, -0.407, 3.15), (0, -0.367, 2.94)], 0.012, p['gold'])
    plate('Forehead ember diamond', [(0, -0.353, 3.38), (0.045, -0.35, 3.32), (0, -0.372, 3.26), (-0.045, -0.35, 3.32)], 0.02, p['red_light'], 0.006)
    # A swept segmented crest gives the original draft a different silhouette.
    for i in range(6):
        ellipsoid('Swept hair lock', (0, 0.015 + i * 0.065, 3.43 + math.sin(i * 0.47) * 0.13), (0.13 - i * 0.01, 0.15, 0.14), p['dark'], 10, 8)
    ring('Topknot gold binding', (0, 0.31, 3.46), 0.10, 0.025, p['gold'], (math.pi / 2, 0, 0))
    tube('Headband flowing tail', [(0.15, 0.16, 3.28), (0.34, 0.38, 3.18), (0.55, 0.51, 3.22), (0.73, 0.56, 3.12)], 0.045, p['cloth'])


def sword(p):
    grip = Vector((1.12, -0.40, 2.36))
    axis = Vector((0.48, 0, 0.88)).normalized()
    across = Vector((axis.z, 0, -axis.x))
    guard = grip + axis * 0.22
    bottom = grip - axis * 0.28
    link('Sword graphite grip', bottom, guard, (0.06, 0.06), p['wrap'])
    for i in range(8):
        center = bottom.lerp(guard, (i + 0.5) / 8)
        link('Sword grip brass binding', center - axis * 0.012, center + axis * 0.012, (0.063, 0.063), p['gold'], 8)
    link('Sword pommel', bottom - axis * 0.06, bottom, (0.085, 0.07), p['gold'])
    link('Sword crossguard', guard - across * 0.19, guard + across * 0.19, (0.045, 0.045), p['gold'], 8)
    vertices = []
    samples = 12
    for i in range(samples):
        t = i / (samples - 1)
        center = guard + axis * (0.06 + t * 1.40) + across * (0.18 * t * t)
        width = (0.095 * (1 - 0.25 * t)) if i < samples - 1 else 0.002
        vertices += [tuple(center - across * width + Vector((0, -0.022, 0))), tuple(center + across * width + Vector((0, -0.022, 0))), tuple(center - across * width + Vector((0, 0.022, 0))), tuple(center + across * width + Vector((0, 0.022, 0)))]
    faces = [(0, 2, 3, 1)]
    for i in range(samples - 1):
        a, b = i * 4, (i + 1) * 4
        faces += [(a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2), (a, a + 2, b + 2, b), (a + 1, b + 1, b + 3, a + 3)]
    faces.append(tuple(range((samples - 1) * 4, samples * 4)))
    from character_geometry import mesh
    mesh('Curved tempered sword blade', vertices, faces, p['steel'], 0.005)
    edge_points = []
    for i in range(samples):
        t = i / (samples - 1)
        width = (0.095 * (1 - 0.25 * t)) if i < samples - 1 else 0.002
        point = guard + axis * (0.06 + t * 1.40) + across * (0.18 * t * t + width)
        edge_points.append(tuple(point + Vector((0, -0.025, 0))))
    tube('Continuous silver cutting edge', edge_points, 0.012, p['blade_edge'])


def build():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    p = palette()
    legs(p)
    body(p)
    armor(p)
    arms(p)
    head(p)
    sword(p)
    # Curves become real exportable geometry; all character parts share a root.
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'CURVE':
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.convert(target='MESH')
            obj.select_set(False)
    bpy.ops.object.empty_add(type='PLAIN_AXES')
    root = bpy.context.object
    root.name = 'Ember_Ronin_v001_STATIC_APPROVAL_DRAFT'
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'MESH':
            obj.parent = root
    bpy.context.scene.unit_settings.system = 'METRIC'
    bpy.context.scene['asset_stage'] = 'Unapproved static design draft; no rig or animation'
    return root
