"""Stage selected glTF animations and external files for reference renders."""

import json
import shutil
import sys
import urllib.parse
from pathlib import Path


def choose_idle(animations):
    exact = next((item for item in animations if item.get("name", "").lower() == "idle"), None)
    return exact or next((item for item in animations if "idle" in item.get("name", "").lower()), None)


def stage_model(path, source_root, stage_root):
    data = json.loads(path.read_text(encoding="utf-8"))
    idle = choose_idle(data.get("animations", []))
    if idle and "models" in path.parts:
        data["animations"] = [idle]
    else:
        data.pop("animations", None)
    destination = stage_root / path.relative_to(source_root)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(data), encoding="utf-8")
    for item in data.get("buffers", []) + data.get("images", []):
        uri = item.get("uri", "")
        if not uri or uri.startswith("data:"):
            continue
        name = urllib.parse.unquote(uri)
        target = destination.parent / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            shutil.copy2(path.parent / name, target)


def main(character_id):
    source = Path("assets/characters") / character_id / "source/gltf-v001"
    stage = Path(".tools/character-artwork-stage") / character_id
    for folder in ("models", "attachments"):
        for model in (source / folder).rglob("*.gltf"):
            if not model.name.endswith("_physics.gltf"):
                stage_model(model, source, stage)


if __name__ == "__main__":
    main(sys.argv[1])
