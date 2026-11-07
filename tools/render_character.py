"""Generate source, GLB, approval renders and machine-readable mesh checks."""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from ember_ronin import CHARACTER, build
from character_geometry import material


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat('-Z', 'Y').to_euler()


def light(name, position, energy, color, size, target=(0, 0, 1.9)):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = energy
    data.color = color
    data.shape = 'DISK'
    data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = position
    aim(obj, target)


def studio(scene):
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    # CPU fallback keeps the source runnable without a supported GPU.
    try:
        preferences = bpy.context.preferences.addons['cycles'].preferences
        preferences.compute_device_type = 'OPTIX'
        preferences.get_devices()
        for device in preferences.devices:
            device.use = device.type == 'OPTIX'
        if any(device.type == 'OPTIX' for device in preferences.devices):
            scene.cycles.device = 'GPU'
    except (TypeError, RuntimeError):
        scene.cycles.device = 'CPU'
    scene.world.color = (0.11, 0.11, 0.11)
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.065, 0.09, 0.12, 1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.35
    scene.view_settings.view_transform = 'AgX'
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.resolution_percentage = 100
    light('Warm large key', (3, -5, 7), 850, (1, 0.79, 0.58), 4)
    light('Cool soft fill', (-4, -2, 4), 650, (0.47, 0.73, 1), 4)
    light('Amber edge light', (2, 3, 5), 1100, (1, 0.35, 0.13), 3)
    light('Top softbox', (-1, 1, 7), 500, (0.75, 0.9, 1), 3)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0.01))
    floor = bpy.context.object
    floor.name = 'Studio floor - not exported'
    floor.data.materials.append(material('Studio slate', (0.025, 0.044, 0.053), 0.1, 0.62))
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = 'Approval camera'
    camera.data.type = 'ORTHO'
    scene.camera = camera
    return camera, floor


def render(scene, camera, name, position, target, scale, size):
    camera.location = position
    aim(camera, target)
    camera.data.ortho_scale = scale
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.filepath = str(CHARACTER / 'renders' / name)
    bpy.ops.render.render(write_still=True)


def export_model(root, version='v001'):
    bpy.ops.object.select_all(action='DESELECT')
    objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    for obj in objects + [root]:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(CHARACTER / f'models/ember-ronin-{version}.glb'), export_format='GLB', use_selection=True, export_apply=True, export_animations=False, export_yup=True)
    dependency_graph = bpy.context.evaluated_depsgraph_get()
    triangles = vertices = 0
    for obj in objects:
        evaluated = obj.evaluated_get(dependency_graph)
        data = evaluated.to_mesh()
        data.calc_loop_triangles()
        vertices += len(data.vertices)
        triangles += len(data.loop_triangles)
        evaluated.to_mesh_clear()
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    dimensions = [max(v[i] for v in corners) - min(v[i] for v in corners) for i in range(3)]
    report = {'blender_version': bpy.app.version_string, 'mesh_objects': len(objects), 'evaluated_vertices': vertices, 'evaluated_triangles': triangles, 'bounds_xyz_m': dimensions, 'armatures': 0, 'animation_clips': 0, 'textures': 0, 'stage': 'static design approval draft; not Android validated'}
    (CHARACTER / f'models/validation-{version}.json').write_text(json.dumps(report, indent=2), encoding='utf-8')


def main():
    root = build()
    export_model(root)
    scene = bpy.context.scene
    camera, floor = studio(scene)
    render(scene, camera, 'preview-v001.png', (6, -10, 6), (0.55, 0, 2.00), 5.15, (1500, 1500))
    # Save the editable source with the preview framing and lighting included.
    bpy.ops.wm.save_as_mainfile(filepath=str(CHARACTER / 'models/ember-ronin-v001.blend'))
    render(scene, camera, 'front-v001.png', (0.60, -10, 2.05), (0.60, 0, 2.05), 5.1, (1000, 1100))
    render(scene, camera, 'back-v001.png', (0.60, 10, 2.05), (0.60, 0, 2.05), 5.1, (1000, 1100))
    render(scene, camera, 'side-v001.png', (10, 0, 2.05), (0, 0, 2.05), 4.75, (850, 1100))
    # From this camera the character's forward direction (-Y) points screen right.
    render(scene, camera, 'fighting-stance-v001.png', (-8, -4, 4), (0.45, 0, 2.0), 5.1, (1400, 1400))
    floor.hide_render = True
    scene.render.film_transparent = True
    render(scene, camera, 'head-icon-v001.png', (4, -9, 4.2), (0.05, 0.04, 3.23), 1.08, (1024, 1024))
    floor.hide_render = False
    scene.render.film_transparent = False
    # Turntable frames are a preview only, not character animation clips.
    scene.cycles.samples = 16
    for i in range(24):
        angle = i * math.tau / 24
        position = (0.45 + 10 * math.sin(angle), -10 * math.cos(angle), 5.0)
        render(scene, camera, f'turntable-{i:02d}-v001.png', position, (0.45, 0, 2.0), 5.3, (640, 640))


if __name__ == '__main__':
    main()
