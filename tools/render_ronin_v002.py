"""Build and render the more realistic/aggressive v002 model; preserve v001."""

import sys
import math
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ember_ronin import CHARACTER
from render_character import export_model, render, studio
from ronin_v002_surfaces import palette
from ronin_v002_body import unified_skin, lower_body, gauntlets
from ronin_v002_equipment import armor, mask_and_hair, katana


def build():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    p = palette()
    unified_skin(p)
    lower_body(p)
    gauntlets(p)
    armor(p)
    before_head = set(bpy.context.scene.objects)
    mask_and_hair(p)
    pivot = Vector((0, -0.09, 3.22))
    tilt = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(9), 4, 'X') @ Matrix.Translation(-pivot)
    for obj in set(bpy.context.scene.objects) - before_head:
        obj.matrix_world = tilt @ obj.matrix_world
    katana(p)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'CURVE':
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.convert(target='MESH')
            obj.select_set(False)
    bpy.ops.object.empty_add(type='PLAIN_AXES')
    root = bpy.context.object
    root.name = 'Ember_Ronin_v002_STATIC_APPROVAL_DRAFT'
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            obj.parent = root
    bpy.context.scene.unit_settings.system = 'METRIC'
    bpy.context.scene['asset_stage'] = 'Unapproved mature revision v002; no rig or animation'
    bpy.context.scene['glb_material_limitation'] = 'Procedural grain/pore detail is Blender-only until texture baking; GLB retains constant PBR color/material values.'
    return root


def configure_lighting(scene):
    scene.cycles.samples = 64
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.17
    bpy.data.lights['Warm large key'].energy = 700
    bpy.data.lights['Warm large key'].size = 2.5
    bpy.data.lights['Cool soft fill'].energy = 240
    bpy.data.lights['Cool soft fill'].size = 3
    bpy.data.lights['Amber edge light'].energy = 650
    bpy.data.lights['Amber edge light'].color = (0.86, 0.60, 0.37)
    bpy.data.lights['Top softbox'].energy = 280


def main():
    root = build()
    export_model(root, 'v002')
    scene = bpy.context.scene
    camera, floor = studio(scene)
    configure_lighting(scene)
    render(scene, camera, 'preview-v002.png', (4.5, -11, 4.4), (0.52, 0, 1.96), 4.65, (1600, 1600))
    bpy.ops.wm.save_as_mainfile(filepath=str(CHARACTER / 'models/ember-ronin-v002.blend'))
    if '--preview-only' in sys.argv:
        return
    render(scene, camera, 'front-v002.png', (0.6, -10, 1.96), (0.6, 0, 1.96), 4.6, (1000, 1100))
    render(scene, camera, 'back-v002.png', (0.6, 10, 1.96), (0.6, 0, 1.96), 4.6, (1000, 1100))
    render(scene, camera, 'side-v002.png', (10, 0, 1.96), (0, 0, 1.96), 4.6, (850, 1100))
    render(scene, camera, 'fighting-stance-v002.png', (-7, -6, 3.5), (0.45, 0, 1.95), 4.6, (1500, 1500))
    floor.hide_render = True
    scene.render.film_transparent = True
    render(scene, camera, 'head-icon-v002.png', (3, -10, 4.1), (0, -0.06, 3.25), 0.95, (1024, 1024))
    floor.hide_render = False
    scene.render.film_transparent = False
    scene.cycles.samples = 24
    for i in range(24):
        angle = i * math.tau / 24
        render(scene, camera, f'turntable-{i:02d}-v002.png', (0.5 + 10 * math.sin(angle), -10 * math.cos(angle), 4.4), (0.5, 0, 1.95), 4.75, (640, 640))


if __name__ == '__main__':
    main()
