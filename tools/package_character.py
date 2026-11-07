"""Lay out actual model renders and encode the preview turntable with Pillow."""

from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont

DIRECTORY = Path(__file__).resolve().parents[1] / 'assets/characters/ember-ronin/renders'
VERSION = 'v001'


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', size)


def model_sheet():
    canvas = Image.new('RGB', (2400, 1360), '#101e27')
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 35), 'EMBER RONIN', font=font(48), fill='#eae1ca')
    draw.text((73, 100), f'FIRST CHARACTER  /  {VERSION}  /  STATIC 3D DESIGN DRAFT', font=font(22), fill='#bf9460')
    positions = [(40, f'front-{VERSION}.png', '01  FRONT'), (820, f'side-{VERSION}.png', '02  SIDE'), (1600, f'back-{VERSION}.png', '03  BACK')]
    for x, filename, label in positions:
        image = Image.open(DIRECTORY / filename).convert('RGB')
        image.thumbnail((760, 1100))
        canvas.paste(image, (x + (760 - image.width) // 2, 165))
        draw.text((x + 35, 1250), label, font=font(22), fill='#b6c7c8')
    draw.text((75, 1310), 'Rendered from the supplied mesh.  Design approval pending.  No rig or animation.', font=font(20), fill='#839b9f')
    canvas.save(DIRECTORY / f'model-sheet-{VERSION}.png')


def turntable():
    paths = sorted(DIRECTORY.glob(f'turntable-??-{VERSION}.png'))
    if len(paths) != 24:
        raise ValueError(f'Expected 24 frames, found {len(paths)}')
    frames = [Image.open(path).convert('RGB') for path in paths]
    frames[0].save(DIRECTORY / f'turntable-{VERSION}.gif', save_all=True, append_images=frames[1:], duration=110, loop=0, optimize=False)


def inspect_images():
    records = []
    for path in sorted(DIRECTORY.glob(f'*{VERSION}.png')):
        image = Image.open(path)
        records.append(f'{path.name}: {image.size}, {image.mode}')
    icon = Image.open(DIRECTORY / f'head-icon-{VERSION}.png')
    assert icon.size == (1024, 1024)
    assert icon.mode == 'RGBA'
    assert icon.getchannel('A').getextrema() == (0, 255)
    records.append('Head icon: square RGBA; transparent and opaque pixels confirmed.')
    (DIRECTORY / f'image-checks-{VERSION}.txt').write_text('\n'.join(records), encoding='utf-8')
    print('\n'.join(records))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', choices=('v001', 'v002'), default='v001')
    VERSION = parser.parse_args().version
    model_sheet()
    turntable()
    inspect_images()
