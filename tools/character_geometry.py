"""Small mesh-building helpers for the approval draft (Blender 4.5 Python)."""

import math
import bpy
from mathutils import Vector


def material(name, color, metallic=0.0, roughness=0.45, emission=0.0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Metallic'].default_value = metallic
    shader.inputs['Roughness'].default_value = roughness
    if emission:
        shader.inputs['Emission Color'].default_value = (*color, 1)
        shader.inputs['Emission Strength'].default_value = emission
    return result


def finish(obj, name, surface, smooth=False, bevel=0):
    obj.name = name
    obj.data.materials.append(surface)
    if smooth:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    if bevel:
        modifier = obj.modifiers.new('Soft manufactured edges', 'BEVEL')
        modifier.width = bevel
        modifier.segments = 2
        obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    return obj


def mesh(name, vertices, faces, surface, bevel=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return finish(obj, name, surface, bevel=bevel)


def ellipsoid(name, center, scale, surface, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    obj = bpy.context.object
    obj.scale = scale
    return finish(obj, name, surface, smooth=True)


def box(name, center, scale, surface, bevel=0.02, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation:
        obj.rotation_euler = rotation
    return finish(obj, name, surface, bevel=bevel)


def link(name, start, end, radii, surface, vertices=12):
    start, end = Vector(start), Vector(end)
    direction = end - start
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radii[0], radius2=radii[1], depth=direction.length, location=(start + end) / 2)
    obj = bpy.context.object
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    return finish(obj, name, surface, smooth=True)


def tube(name, points, radius, surface):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 1
    data.bevel_depth = radius
    data.bevel_resolution = 2
    spline = data.splines.new('POLY')
    spline.points.add(len(points) - 1)
    for point, position in zip(spline.points, points):
        point.co = (*position, 1)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(surface)
    return obj


def ring(name, center, major, minor, surface, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=32, minor_segments=6, location=center, rotation=rotation)
    return finish(bpy.context.object, name, surface, smooth=True)


def plate(name, outline, depth, surface, bevel=0.015):
    """Extrude an outline supplied in world coordinates along the Y axis."""
    vertices = list(outline) + [(x, y + depth, z) for x, y, z in outline]
    count = len(outline)
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    return mesh(name, vertices, faces, surface, bevel)


def torso(name, levels, surface):
    vertices = []
    segments = 16
    for z, width, depth in levels:
        vertices.extend((width * math.cos(i * math.tau / segments), depth * math.sin(i * math.tau / segments), z) for i in range(segments))
    faces = [tuple(range(segments - 1, -1, -1))]
    for level in range(len(levels) - 1):
        for i in range(segments):
            a = level * segments + i
            b = level * segments + (i + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    faces.append(tuple(range((len(levels) - 1) * segments, len(levels) * segments)))
    obj = mesh(name, vertices, faces, surface)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj
