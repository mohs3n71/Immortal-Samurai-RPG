"""Index the likely Meadowlands subtree in the recovered Unity export.

Run from the project root. The output records evidence; it is not a Godot scene.
"""
import collections
import json
from pathlib import Path
import re

SOURCE = Path('../Butcher Hero/ButcherHeroReconstruction')
ASSETS = SOURCE / 'unity_project/ExportedProject/Assets'
OUTPUT = Path('assets/environment/butcher-meadowlands/scene-index.json')
ROOT_TRANSFORM = 17004


def guid_paths():
    paths = {}
    for meta in ASSETS.rglob('*.meta'):
        match = re.search(r'(?m)^guid: ([0-9a-f]+)', meta.read_text(encoding='utf-8'))
        if match:
            paths[match.group(1)] = meta.with_suffix('').relative_to(ASSETS).as_posix()
    return paths


def main():
    transforms = json.loads((SOURCE / 'world_data/Main_transforms.json').read_text(encoding='utf-8'))
    children = collections.defaultdict(list)
    by_id = {}
    for item in transforms:
        children[item['parent_transform_id']].append(item['transform_id'])
        by_id[item['transform_id']] = item
    pending = [ROOT_TRANSFORM]
    selected = []
    while pending:
        current = pending.pop()
        selected.append(by_id[current].copy())
        pending.extend(children[current])
    objects = {item['game_object_id']: item for item in selected}
    assets = guid_paths()
    scene = (ASSETS / 'Scenes/Main.unity').read_text(encoding='utf-8')
    for block in re.split(r'(?m)^--- !u!', scene):
        if not (block.startswith('33 ') or block.startswith('23 ')):
            continue
        game_object = re.search(r'm_GameObject: \{fileID: (\d+)\}', block)
        if not game_object or int(game_object.group(1)) not in objects:
            continue
        obj = objects[int(game_object.group(1))]
        if block.startswith('33 '):
            mesh = re.search(r'm_Mesh: \{fileID: (\d+)(?:, guid: ([0-9a-f]+), type: \d+)?\}', block)
            if mesh:
                obj['mesh'] = {'file_id': int(mesh.group(1)), 'guid': mesh.group(2),
                               'asset': assets.get(mesh.group(2))}
        else:
            section = re.search(r'(?ms)^  m_Materials:\s*\n(.*?)(?=^  \w)', block)
            if section:
                guids = re.findall(r'guid: ([0-9a-f]+)', section.group(1))
                obj['materials'] = [{'guid': guid, 'asset': assets.get(guid)} for guid in guids]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    result = {'source_scene': 'unity_project/ExportedProject/Assets/Scenes/Main.unity',
              'root_transform_id': ROOT_TRANSFORM,
              'identification': 'Grass Meadowlands material is referenced by land meshes in this subtree; region boundary is provisional.',
              'objects': sorted(selected, key=lambda item: item['transform_id'])}
    OUTPUT.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f"Indexed {len(selected)} transforms, {sum('mesh' in x for x in selected)} mesh filters, "
          f"{sum('materials' in x for x in selected)} renderers: {OUTPUT}")


if __name__ == '__main__':
    main()
