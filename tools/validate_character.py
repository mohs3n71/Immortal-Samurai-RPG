"""Re-import the actual GLB and compare its triangle count with the source."""

import json
import sys
from pathlib import Path
import bpy

DIRECTORY = Path(__file__).resolve().parents[1] / 'assets/characters/ember-ronin/models'
VERSION = sys.argv[-1] if sys.argv[-1] in ('v001', 'v002') else 'v001'


def main():
    source = json.loads((DIRECTORY / f'validation-{VERSION}.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(DIRECTORY / f'ember-ronin-{VERSION}.blend'))
    blend_objects = len([obj for obj in bpy.context.scene.objects if obj.parent and obj.parent.name.startswith('Ember_Ronin')])
    assert blend_objects == source['mesh_objects']
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(DIRECTORY / f'ember-ronin-{VERSION}.glb'))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    triangles = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
        assert len(obj.data.vertices) > 0
        assert all(len(polygon.vertices) >= 3 for polygon in obj.data.polygons)
    assert triangles == source['evaluated_triangles'], (triangles, source)
    assert not any(obj.type in {'CAMERA', 'LIGHT', 'ARMATURE'} for obj in bpy.context.scene.objects)
    report = {'blend_reopen': 'passed', 'blend_character_parts': blend_objects, 'glb_reimport': 'passed', 'glb_mesh_objects': len(meshes), 'glb_triangles': triangles, 'triangle_count_matches_source': True, 'studio_camera_lights_floor_excluded': True, 'deformation_animation_android_checks': 'not performed; static design draft'}
    (DIRECTORY / f'export-checks-{VERSION}.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
