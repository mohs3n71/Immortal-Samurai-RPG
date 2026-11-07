"""Decode a Unity YAML Mesh asset (AssetRipper export) into an OBJ file.
Handles both m_CompressedMesh (packed bit vectors) and raw m_VertexData streams.
Usage: python3 decode_unity_mesh.py <mesh.asset> <out.obj> [material_name]
Unity is left-handed, so X is negated and triangle winding flipped."""
import math, re, struct, sys

FORMAT_SIZES = {0: 4, 1: 2, 2: 1, 3: 1, 4: 2, 5: 2, 6: 1, 7: 1, 8: 2, 9: 2, 10: 4, 11: 4}

def section(text, name):
    m = re.search(r"\n    %s:\n((?:      .*\n)+)" % name, text)
    fields = {}
    for line in m.group(1).splitlines():
        key, _, value = line.strip().partition(": ")
        fields[key.rstrip(":")] = value
    return fields

def unpack(fields, as_float):
    count = int(fields["m_NumItems"])
    bits = int(fields["m_BitSize"] or 0)
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

def decode_compressed(text):
    vertices = unpack(section(text, "m_Vertices"), True)
    uvs = unpack(section(text, "m_UV"), True)
    normals_xy = unpack(section(text, "m_Normals"), True)
    signs = unpack(section(text, "m_NormalSigns"), False)
    triangles = unpack(section(text, "m_Triangles"), False)
    count = len(vertices) // 3
    positions = [vertices[i * 3:i * 3 + 3] for i in range(count)]
    uv = [uvs[i * 2:i * 2 + 2] for i in range(count)]
    normals = []
    for i in range(count):
        nx, ny = normals_xy[i * 2], normals_xy[i * 2 + 1]
        nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
        normals.append([nx, ny, nz if signs[i] else -nz])
    return positions, normals, uv, triangles

def decode_raw(text):
    block = text[text.index("  m_VertexData:"):]
    count = int(re.search(r"m_VertexCount: (\d+)", block).group(1))
    channels = [tuple(int(v) for v in c) for c in re.findall(r"- stream: (\d+)\n\s+offset: (\d+)\n\s+format: (\d+)\n\s+dimension: (\d+)", block)]
    data = bytes.fromhex(re.search(r"_typelessdata: ([0-9a-f]+)", block).group(1))
    strides = {}
    for stream, offset, fmt, dim in channels:
        if dim:
            strides[stream] = max(strides.get(stream, 0), offset + FORMAT_SIZES[fmt] * (dim & 0xF))
    starts, position = {}, 0
    for stream in sorted(strides):
        starts[stream] = position
        position += strides[stream] * count
        position = (position + 15) // 16 * 16
    def read(channel_index):
        stream, offset, fmt, dim = channels[channel_index]
        result = []
        for i in range(count):
            base = starts[stream] + i * strides[stream] + offset
            code = {0: "f", 1: "e"}[fmt]
            size = FORMAT_SIZES[fmt]
            result.append(list(struct.unpack_from("<%d%s" % (dim, code), data, base)))
        return result
    positions, normals, uv = read(0), read(1), read(4)
    index_format = int(re.search(r"m_IndexFormat: (\d+)", text).group(1))
    index_data = bytes.fromhex(re.search(r"m_IndexBuffer: ([0-9a-f]+)", text).group(1))
    code, size = ("H", 2) if index_format == 0 else ("I", 4)
    triangles = list(struct.unpack("<%d%s" % (len(index_data) // size, code), index_data))
    return positions, normals, uv, triangles

def main():
    text = open(sys.argv[1]).read()
    material = sys.argv[3] if len(sys.argv) > 3 else "material"
    compressed = int(re.search(r"m_MeshCompression: (\d+)", text).group(1)) != 0
    positions, normals, uv, triangles = decode_compressed(text) if compressed else decode_raw(text)
    out = open(sys.argv[2], "w")
    out.write("mtllib %s.mtl\nusemtl %s\n" % (material, material))
    for x, y, z in positions:
        out.write("v %.6f %.6f %.6f\n" % (-x, y, z))
    for u, v in uv:
        out.write("vt %.6f %.6f\n" % (u, v))
    for x, y, z in normals:
        out.write("vn %.6f %.6f %.6f\n" % (-x, y, z))
    for t in range(0, len(triangles) - 2, 3):
        a, b, c = triangles[t] + 1, triangles[t + 1] + 1, triangles[t + 2] + 1
        out.write("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % (a, a, a, c, c, c, b, b, b))
    print("vertices", len(positions), "triangles", len(triangles) // 3, "compressed" if compressed else "raw")

main()
