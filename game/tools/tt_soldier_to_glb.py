"""Convert a Toony Tiny RTS soldier prefab (AssetRipper Unity YAML export) into a
glTF binary (.glb) for Godot: skeleton, skinned body, head/weapon/shield parts
on their bone containers, the shared colour atlas (referenced, not embedded),
and the requested animation clips resampled at 30 fps (D-078).

Usage:
  python3 tt_soldier_to_glb.py <Assets dir> <prefab name> <out.glb> <texture uri> \
      clip_name=AnimationClip/file.anim [clip_name=...]

Unity is left-handed; glTF is right-handed. X is mirrored: positions and normals
negate x, quaternions (x, y, z, w) become (x, -y, -z, w), matrices become S*M*S,
and triangle winding is reversed. UV v is flipped.
"""
import json, math, os, re, struct, sys

FPS = 30.0

# ---------------------------------------------------------------- Unity YAML

def parse_documents(text):
    parts = re.split(r"\n--- !u!(\d+) &(-?\d+)[^\n]*", text)
    docs = {}
    for i in range(1, len(parts), 3):
        docs[parts[i + 1]] = (int(parts[i]), parts[i + 2])
    return docs

def vec(body, key):
    m = re.search(key + r": \{([^}]*)\}", body)
    out = {}
    for item in m.group(1).split(","):
        k, _, v = item.strip().partition(": ")
        out[k] = float(v)
    return out

def file_ids(body, key):
    m = re.search(r"\n  " + key + r":\n((?:  - \{[^\n]*\n)*)", body)
    if not m:
        return []
    return re.findall(r"fileID: (-?\d+)", m.group(1))

def ref_id(body, key):
    m = re.search(key + r": \{fileID: (-?\d+)", body)
    return m.group(1) if m else None

def ref_guid(body, key):
    m = re.search(key + r": \{fileID: -?\d+, guid: ([0-9a-f]{32})", body)
    return m.group(1) if m else None

def guid_index(assets):
    """guid -> file path. Reads <Assets>/guid_index.txt ("Folder/file guid" per
    line) when present, otherwise the .meta files."""
    index = {}
    listing = os.path.join(assets, "guid_index.txt")
    if os.path.exists(listing):
        for line in open(listing, encoding="utf-8", errors="replace"):
            path, _, guid = line.rstrip("\n").rpartition(" ")
            if path:
                index[guid] = os.path.join(assets, path)
        return index
    for folder in ("Mesh", "Material", "Texture2D"):
        directory = os.path.join(assets, folder)
        if not os.path.isdir(directory):
            continue
        for name in os.listdir(directory):
            if name.endswith(".meta"):
                continue
            meta = os.path.join(directory, name + ".meta")
            if os.path.exists(meta):
                m = re.search(r"guid: ([0-9a-f]{32})", open(meta).read())
                if m:
                    index[m.group(1)] = os.path.join(directory, name)
    return index

# ---------------------------------------------------------------- meshes

def section(text, name):
    m = re.search(r"\n    %s:\n((?:      .*\n)+)" % name, text)
    fields = {}
    for line in m.group(1).splitlines():
        key, _, value = line.strip().partition(": ")
        fields[key.rstrip(":")] = value
    return fields

def unpack(fields, as_float):
    count = int(fields["m_NumItems"])
    bits = int(fields.get("m_BitSize") or 0)
    data = bytes.fromhex(fields.get("m_Data", "") or "")
    values, index, bit_pos = [], 0, 0
    for _ in range(count):
        value, filled = 0, 0
        while filled < bits:
            value |= (data[index] >> bit_pos) << filled
            take = min(bits - filled, 8 - bit_pos)
            bit_pos += take
            filled += take
            if bit_pos == 8:
                index += 1
                bit_pos = 0
        value &= (1 << bits) - 1
        if as_float:
            scale = float(fields["m_Range"]) / ((1 << bits) - 1)
            values.append(value * scale + float(fields["m_Start"]))
        else:
            values.append(value)
    return values

def decode_mesh(path):
    text = open(path).read()
    if int(re.search(r"m_VertexCount: (\d+)", text).group(1)) != 0:
        raise SystemExit("raw vertex data not supported for skinned parts: " + path)
    vertices = unpack(section(text, "m_Vertices"), True)
    uvs = unpack(section(text, "m_UV"), True)
    normals_xy = unpack(section(text, "m_Normals"), True)
    signs = unpack(section(text, "m_NormalSigns"), False)
    triangles = unpack(section(text, "m_Triangles"), False)
    count = len(vertices) // 3
    positions = [[-vertices[i * 3], vertices[i * 3 + 1], vertices[i * 3 + 2]] for i in range(count)]
    uv = [[uvs[i * 2], 1.0 - uvs[i * 2 + 1]] for i in range(count)]
    normals = []
    for i in range(count):
        nx, ny = normals_xy[i * 2], normals_xy[i * 2 + 1]
        nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
        nz = nz if signs[i] else -nz
        length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
        normals.append([-nx / length, ny / length, nz / length])
    # Reverse winding for the mirrored handedness.
    indices = []
    for t in range(0, len(triangles) - 2, 3):
        indices += [triangles[t], triangles[t + 2], triangles[t + 1]]
    joints = weights = None
    weight_fields = section(text, "m_Weights")
    if int(weight_fields["m_NumItems"]) > 0:
        packed_weights = unpack(weight_fields, False)
        packed_bones = unpack(section(text, "m_BoneIndices"), False)
        joints = [[0, 0, 0, 0] for _ in range(count)]
        weights = [[0.0, 0.0, 0.0, 0.0] for _ in range(count)]
        vertex, slot, total, bone_pos = 0, 0, 0, 0
        for value in packed_weights:
            weights[vertex][slot] = value / 31.0
            joints[vertex][slot] = packed_bones[bone_pos]
            bone_pos += 1
            slot += 1
            total += value
            if total >= 31:
                vertex, slot, total = vertex + 1, 0, 0
            elif slot == 3:
                weights[vertex][3] = (31 - total) / 31.0
                joints[vertex][3] = packed_bones[bone_pos]
                bone_pos += 1
                vertex, slot, total = vertex + 1, 0, 0
        for w in weights:
            s = sum(w) or 1.0
            for k in range(4):
                w[k] /= s
    bindposes = []
    for m in re.finditer(r"  - e00: (\S+)\n" + "".join(r"    e%d%d: (\S+)\n" % (r, c) for r in range(4) for c in range(4) if (r, c) != (0, 0)), text):
        values = [float(v) for v in m.groups()]
        bindposes.append(mirror_matrix([values[r * 4:r * 4 + 4] for r in range(4)]))
    return {"positions": positions, "normals": normals, "uv": uv, "indices": indices, "joints": joints, "weights": weights, "bindposes": bindposes}

def mirror_matrix(rows):
    sign = [-1, 1, 1, 1]
    return [[rows[r][c] * sign[r] * sign[c] for c in range(4)] for r in range(4)]

def mirror_position(p):
    return [-p["x"], p["y"], p["z"]]

def mirror_rotation(q):
    return [q["x"], -q["y"], -q["z"], q["w"]]

# ---------------------------------------------------------------- animation

def hermite(k0, k1, t, component):
    t0, t1 = k0["time"], k1["time"]
    dt = t1 - t0
    if dt <= 0:
        return k1["value"][component]
    s = (t - t0) / dt
    p0, p1 = k0["value"][component], k1["value"][component]
    m0, m1 = k0["out"][component] * dt, k1["in"][component] * dt
    if not (math.isfinite(m0) and math.isfinite(m1)):
        return p0 if s < 1.0 else p1
    s2, s3 = s * s, s * s * s
    return (2 * s3 - 3 * s2 + 1) * p0 + (s3 - 2 * s2 + s) * m0 + (-2 * s3 + 3 * s2) * p1 + (s3 - s2) * m1

def parse_curve_block(block, components):
    keys = []
    for m in re.finditer(r"time: (\S+)\n\s+value: \{([^}]*)\}\n\s+inSlope: \{([^}]*)\}\n\s+outSlope: \{([^}]*)\}", block):
        def parse(s):
            d = {}
            for item in s.split(","):
                k, _, v = item.strip().partition(": ")
                v = v.strip()
                d[k] = float("inf") if v.lower() in ("infinity", "inf") else (-float("inf") if v.lower() in ("-infinity", "-inf") else float(v))
            return [d[c] for c in components]
        keys.append({"time": float(m.group(1)), "value": parse(m.group(2)), "in": parse(m.group(3)), "out": parse(m.group(4))})
    return keys

def parse_clip(path):
    text = open(path).read()
    stop = float(re.search(r"m_StopTime: (\S+)", text).group(1))
    loop = re.search(r"m_LoopTime: (\d)", text).group(1) == "1"
    tracks = {"rotation": {}, "translation": {}, "scale": {}}
    for kind, key, comps in (("rotation", "m_RotationCurves", ("x", "y", "z", "w")), ("translation", "m_PositionCurves", ("x", "y", "z")), ("scale", "m_ScaleCurves", ("x", "y", "z"))):
        m = re.search(r"\n  %s:\n(.*?)(?=\n  m_[A-Za-z]+:)" % key, text, re.S)
        if not m:
            continue
        for curve in re.split(r"\n  - curve:\n", "\n" + m.group(1))[1:]:
            path_m = re.search(r"\n    path: (.*)", curve)
            if not path_m:
                continue
            keys = parse_curve_block(curve, comps)
            if keys:
                tracks[kind][path_m.group(1).strip()] = keys
    return stop, loop, tracks

def sample(keys, t, n):
    if t <= keys[0]["time"]:
        return keys[0]["value"][:]
    if t >= keys[-1]["time"]:
        return keys[-1]["value"][:]
    for i in range(len(keys) - 1):
        if keys[i]["time"] <= t <= keys[i + 1]["time"]:
            return [hermite(keys[i], keys[i + 1], t, c) for c in range(n)]
    return keys[-1]["value"][:]

# ---------------------------------------------------------------- glTF writer

class Gltf:
    def __init__(self):
        self.data = bytearray()
        self.json = {"asset": {"version": "2.0", "generator": "tt_soldier_to_glb"}, "buffers": [], "bufferViews": [], "accessors": [],
                     "nodes": [], "meshes": [], "skins": [], "materials": [], "textures": [], "images": [], "samplers": [], "animations": [], "scenes": [{"nodes": []}], "scene": 0}

    def add_accessor(self, values, fmt, component, kind, count, target=None, minmax=False):
        while len(self.data) % 4:
            self.data.append(0)
        offset = len(self.data)
        self.data += struct.pack("<" + fmt * len(values), *values)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(self.data) - offset}
        if target:
            view["target"] = target
        self.json["bufferViews"].append(view)
        accessor = {"bufferView": len(self.json["bufferViews"]) - 1, "componentType": component, "count": count, "type": kind}
        if minmax:
            width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[kind]
            accessor["min"] = [min(values[i::width]) for i in range(width)]
            accessor["max"] = [max(values[i::width]) for i in range(width)]
        self.json["accessors"].append(accessor)
        return len(self.json["accessors"]) - 1

    def write(self, path):
        while len(self.data) % 4:
            self.data.append(0)
        self.json["buffers"] = [{"byteLength": len(self.data)}]
        for key in ("skins", "animations", "textures", "images", "samplers", "materials"):
            if not self.json[key]:
                del self.json[key]
        blob = json.dumps(self.json, separators=(",", ":")).encode()
        while len(blob) % 4:
            blob += b" "
        with open(path, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(blob) + 8 + len(self.data)))
            f.write(struct.pack("<II", len(blob), 0x4E4F534A) + blob)
            f.write(struct.pack("<II", len(self.data), 0x004E4942) + bytes(self.data))

def flatten(rows_list):
    # glTF matrices are column-major.
    out = []
    for rows in rows_list:
        for c in range(4):
            for r in range(4):
                out.append(rows[r][c])
    return out

def main():
    assets, prefab, out_path, texture_uri = sys.argv[1:5]
    options = [a for a in sys.argv[5:] if a.startswith("--")]
    clip_args = [a.split("=", 1) for a in sys.argv[5:] if not a.startswith("--")]
    # --root=Name exports only that GameObject's subtree (for kit prefabs).
    root_name = next((o.split("=", 1)[1] for o in options if o.startswith("--root=")), None)
    # --keep=a,b exports only those mesh parts (kit prefabs hold every variant).
    keep = next((set(o.split("=", 1)[1].split(",")) for o in options if o.startswith("--keep=")), None)
    index = guid_index(assets)
    docs = parse_documents(open(os.path.join(assets, "GameObject", prefab + ".prefab")).read())
    gameobjects = {fid: body for fid, (kind, body) in docs.items() if kind == 1}
    transforms = {fid: body for fid, (kind, body) in docs.items() if kind == 4}
    go_name = {fid: re.search(r"m_Name: (.*)", body).group(1).strip().strip("'") for fid, body in gameobjects.items()}
    go_active = {fid: re.search(r"m_IsActive: (\d)", body).group(1) == "1" for fid, body in gameobjects.items()}
    go_of = {fid: ref_id(body, "m_GameObject") for fid, body in transforms.items()}
    transform_of_go = {go: t for t, go in go_of.items()}
    root = next(t for t, body in transforms.items() if ref_id(body, "m_Father") == "0")
    if root_name:
        root = next(t for t, go in go_of.items() if go_name.get(go) == root_name)
        go_active[go_of[root]] = True
    gltf = Gltf()
    node_of = {}
    paths = {}

    def visit(t, parent_path):
        go = go_of[t]
        if not go_active.get(go, True):
            return None
        body = transforms[t]
        node = {"name": go_name[go], "translation": mirror_position(vec(body, "m_LocalPosition")), "rotation": mirror_rotation(vec(body, "m_LocalRotation"))}
        scale = vec(body, "m_LocalScale")
        node["scale"] = [scale["x"], scale["y"], scale["z"]]
        gltf.json["nodes"].append(node)
        index_here = len(gltf.json["nodes"]) - 1
        node_of[t] = index_here
        path = go_name[go] if parent_path is None else parent_path + "/" + go_name[go]
        paths[index_here] = path
        children = []
        for child in file_ids(body, "m_Children"):
            c = visit(child, path)
            if c is not None:
                children.append(c)
        if children:
            node["children"] = children
        return index_here

    root_node = visit(root, None)
    if root_name:
        # A kit sub-root keeps its scale but sits at the origin.
        gltf.json["nodes"][root_node]["translation"] = [0.0, 0.0, 0.0]
        gltf.json["nodes"][root_node]["rotation"] = [0.0, 0.0, 0.0, 1.0]
    gltf.json["scenes"][0]["nodes"] = [root_node]

    gltf.json["samplers"].append({"magFilter": 9729, "minFilter": 9987})
    material_of_texture = {}

    def material_for(uri):
        """One glTF material per colour atlas; the atlas png sits beside the glb."""
        if uri not in material_of_texture:
            gltf.json["images"].append({"uri": uri})
            gltf.json["textures"].append({"source": len(gltf.json["images"]) - 1, "sampler": 0})
            gltf.json["materials"].append({"name": os.path.splitext(uri)[0], "pbrMetallicRoughness": {"baseColorTexture": {"index": len(gltf.json["textures"]) - 1}, "metallicFactor": 0.0, "roughnessFactor": 1.0}})
            material_of_texture[uri] = len(gltf.json["materials"]) - 1
        return material_of_texture[uri]

    def texture_of_renderer(body):
        """Base map of the renderer's first material, or the fallback atlas."""
        m = re.search(r"m_Materials:\n  - \{fileID: -?\d+, guid: ([0-9a-f]{32})", body)
        if m and m.group(1) in index:
            material_text = open(index[m.group(1)], encoding="utf-8", errors="replace").read()
            t = re.search(r"_BaseMap:\n\s+m_Texture: \{fileID: -?\d+, guid: ([0-9a-f]{32})", material_text) or re.search(r"_MainTex:\n\s+m_Texture: \{fileID: -?\d+, guid: ([0-9a-f]{32})", material_text)
            if t and t.group(1) in index:
                source = index[t.group(1)]
                target = os.path.join(os.path.dirname(os.path.abspath(out_path)), os.path.basename(source))
                if not os.path.exists(target):
                    import shutil
                    shutil.copyfile(source, target)
                return os.path.basename(source)
        return texture_uri

    def add_mesh(mesh, name, material=0):
        n = len(mesh["positions"])
        attributes = {
            "POSITION": gltf.add_accessor([v for p in mesh["positions"] for v in p], "f", 5126, "VEC3", n, 34962, True),
            "NORMAL": gltf.add_accessor([v for p in mesh["normals"] for v in p], "f", 5126, "VEC3", n, 34962),
            "TEXCOORD_0": gltf.add_accessor([v for p in mesh["uv"] for v in p], "f", 5126, "VEC2", n, 34962),
        }
        if mesh.get("joints") is not None:
            attributes["JOINTS_0"] = gltf.add_accessor([v for p in mesh["joints"] for v in p], "H", 5123, "VEC4", n, 34962)
            attributes["WEIGHTS_0"] = gltf.add_accessor([v for p in mesh["weights"] for v in p], "f", 5126, "VEC4", n, 34962)
        indices = gltf.add_accessor(mesh["indices"], "H", 5123, "SCALAR", len(mesh["indices"]), 34963)
        gltf.json["meshes"].append({"name": name, "primitives": [{"attributes": attributes, "indices": indices, "material": material}]})
        return len(gltf.json["meshes"]) - 1

    skinned_count = 0
    for fid, (kind, body) in docs.items():
        if kind not in (137, 33):
            continue
        go = ref_id(body, "m_GameObject")
        t = transform_of_go.get(go)
        if t not in node_of:
            continue
        if keep is not None and go_name[go] not in keep:
            continue
        guid = ref_guid(body, "m_Mesh")
        if guid not in index:
            print("missing mesh for", go_name[go], file=sys.stderr)
            continue
        renderer = None
        if kind == 33:
            renderer = next((b for k, b in docs.values() if k == 23 and ref_id(b, "m_GameObject") == go), None)
            if renderer is not None and re.search(r"m_Enabled: 0", renderer):
                continue
        if kind == 137 and any(b not in node_of for b in file_ids(body, "m_Bones")):
            print("skipped", go_name[go], "(its bones are switched off)", file=sys.stderr)
            continue
        try:
            mesh = decode_mesh(index[guid])
        except SystemExit as error:
            print("skipped", go_name[go], "-", error, file=sys.stderr)
            continue
        renderer_body = body if kind == 137 else (renderer or "")
        mesh_index = add_mesh(mesh, go_name[go], material_for(texture_of_renderer(renderer_body)))
        if kind == 137:
            bones = [node_of[b] for b in file_ids(body, "m_Bones")]
            inverse = gltf.add_accessor(flatten(mesh["bindposes"]), "f", 5126, "MAT4", len(mesh["bindposes"]))
            gltf.json["skins"].append({"joints": bones, "inverseBindMatrices": inverse, "skeleton": root_node})
            # The skinned mesh node sits at the root so its own transform is identity.
            gltf.json["nodes"].append({"name": go_name[go] + "_skinned", "mesh": mesh_index, "skin": len(gltf.json["skins"]) - 1})
            gltf.json["nodes"][root_node].setdefault("children", []).append(len(gltf.json["nodes"]) - 1)
            skinned_count += 1
        else:
            gltf.json["nodes"][node_of[t]]["mesh"] = mesh_index

    # Animation paths are relative to the Animator's GameObject.
    animators = [transform_of_go[ref_id(b, "m_GameObject")] for k, b in docs.values() if k == 95]
    animators = [t for t in animators if t in node_of]
    if not animators:
        clip_args = []
        animators = [root]
    prefix = paths[node_of[animators[0]]]
    node_by_path = {p[len(prefix) + 1:]: n for n, p in paths.items() if p.startswith(prefix + "/")}
    for clip_name, clip_path in clip_args:
        stop, loop, tracks = parse_clip(os.path.join(assets, clip_path))
        frames = max(2, int(round(stop * FPS)) + 1)
        times = [min(stop, i / FPS) for i in range(frames)]
        time_accessor = gltf.add_accessor(times, "f", 5126, "SCALAR", frames, None, True)
        samplers, channels = [], []
        for kind, width in (("rotation", 4), ("translation", 3), ("scale", 3)):
            for path, keys in tracks[kind].items():
                node = node_by_path.get(path)
                if node is None:
                    continue
                values = []
                for t in times:
                    v = sample(keys, t, width)
                    if kind == "rotation":
                        length = math.sqrt(sum(c * c for c in v)) or 1.0
                        v = [v[0] / length, -v[1] / length, -v[2] / length, v[3] / length]
                    elif kind == "translation":
                        v = [-v[0], v[1], v[2]]
                    values += v
                output = gltf.add_accessor(values, "f", 5126, "VEC4" if width == 4 else "VEC3", frames)
                samplers.append({"input": time_accessor, "output": output, "interpolation": "LINEAR"})
                channels.append({"sampler": len(samplers) - 1, "target": {"node": node, "path": kind}})
        gltf.json["animations"].append({"name": clip_name + ("_loop" if loop else ""), "samplers": samplers, "channels": channels})
        print("clip", clip_name, "frames", frames, "channels", len(channels), "loop", loop)
    gltf.write(out_path)
    print("wrote", out_path, "nodes", len(gltf.json["nodes"]), "meshes", len(gltf.json["meshes"]), "skins", skinned_count, "bytes", os.path.getsize(out_path))

if __name__ == "__main__":
    main()
