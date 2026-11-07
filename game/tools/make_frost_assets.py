"""Frostlands textures (D-100): snow ground, packed-ice path, and icy versions
of the undead and soldier colour atlases for the frozen undead.

Usage: python3 tools/make_frost_assets.py
Writes assets/environment/frost/{frost-floor,frost-path}-v001.png and
assets/enemies/frost/{Texture_v2_frost,TT_RTS_Units_frost}.png.
"""
import colorsys
import math
import numpy as np
from PIL import Image, ImageFilter

ROOT = "assets/"


def tileable_noise(size, scale, seed, octaves=4):
    """Seamless value noise in 0..1 (sum of wrapped, upsampled random grids)."""
    rng = np.random.default_rng(seed)
    total = np.zeros((size, size))
    weight = 0.0
    amplitude = 1.0
    cells = scale
    for _ in range(octaves):
        grid = rng.random((cells, cells))
        image = Image.fromarray((grid * 255).astype(np.uint8))
        # Wrap by tiling 3x3 before resizing, then crop the middle (seamless).
        tiled = Image.new("L", (cells * 3, cells * 3))
        for i in range(3):
            for j in range(3):
                tiled.paste(image, (i * cells, j * cells))
        big = tiled.resize((size * 3, size * 3), Image.BICUBIC).crop((size, size, size * 2, size * 2))
        total += np.asarray(big, dtype=float) / 255.0 * amplitude
        weight += amplitude
        amplitude *= 0.5
        cells *= 2
    return total / weight


def snow_floor(path, size=512):
    base = tileable_noise(size, 6, 1)
    drift = tileable_noise(size, 3, 2, octaves=2)
    fine = tileable_noise(size, 48, 3, octaves=2)
    light = np.array([0.93, 0.96, 1.0])
    shade = np.array([0.72, 0.80, 0.92])
    t = np.clip(0.55 * base + 0.35 * drift + 0.1 * fine, 0, 1)[..., None]
    color = shade + (light - shade) * t
    # Sparkles: a few bright pixels.
    rng = np.random.default_rng(9)
    sparkle = rng.random((size, size)) > 0.9975
    color[sparkle] = [1.0, 1.0, 1.0]
    rgba = np.dstack([np.clip(color, 0, 1) * 255, np.full((size, size), 255)]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(path)


def ice_path(path, size=256):
    base = tileable_noise(size, 5, 11)
    crack = tileable_noise(size, 20, 12, octaves=3)
    packed = np.array([0.50, 0.57, 0.69])
    pale = np.array([0.66, 0.73, 0.84])
    t = np.clip(base * 0.8 + crack * 0.2, 0, 1)[..., None]
    color = packed + (pale - packed) * t
    # Thin darker lines where the fine noise crosses mid value (ice cracks).
    lines = np.abs(crack - 0.5) < 0.012
    color[lines] *= 0.82
    rgba = np.dstack([np.clip(color, 0, 1) * 255, np.full((size, size), 255)]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(path)


def frost_atlas(source, target):
    """Cold version of a colour atlas: hues pulled toward ice blue, softer
    saturation, lighter; very dark and very light pixels keep their value."""
    image = Image.open(source).convert("RGBA")
    data = np.asarray(image, dtype=float) / 255.0
    out = data.copy()
    rgb = data[..., :3]
    flat = rgb.reshape(-1, 3)
    result = np.empty_like(flat)
    for index, (r, g, b) in enumerate(flat):
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        # Ice blue for everything, with a small hue swing so parts stay apart.
        h = 0.6 + 0.035 * math.sin(2.0 * math.pi * h)
        s = 0.06 + s * 0.42
        v = min(1.0, v * 0.82 + 0.2)
        result[index] = colorsys.hsv_to_rgb(h % 1.0, s, v)
    out[..., :3] = result.reshape(rgb.shape)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(target)


if __name__ == "__main__":
    snow_floor(ROOT + "environment/frost/frost-floor-v001.png")
    ice_path(ROOT + "environment/frost/frost-path-v001.png")
    frost_atlas(ROOT + "enemies/undead/Texture_v2.png", ROOT + "enemies/frost/Texture_v2_frost.png")
    frost_atlas(ROOT + "enemies/undead/TT_RTS_Units_red.png", ROOT + "enemies/frost/TT_RTS_Units_frost.png")
    print("frost assets written")
