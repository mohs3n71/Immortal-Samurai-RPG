"""Points a .glb's image URIs at other files (D-100: the frozen undead use the
icy atlases). Usage: python3 glb_retexture.py file.glb old.png=new.png [...]"""
import json, struct, sys

def main():
    path = sys.argv[1]
    swaps = dict(arg.split("=", 1) for arg in sys.argv[2:])
    data = open(path, "rb").read()
    json_length = struct.unpack("<I", data[12:16])[0]
    document = json.loads(data[20:20 + json_length])
    rest = data[20 + json_length:]
    for image in document.get("images", []):
        image["uri"] = swaps.get(image.get("uri"), image.get("uri"))
    text = json.dumps(document, separators=(",", ":")).encode()
    text += b" " * ((4 - len(text) % 4) % 4)
    body = struct.pack("<II", len(text), 0x4E4F534A) + text + rest
    open(path, "wb").write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)

main()
