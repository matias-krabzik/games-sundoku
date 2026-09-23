"""Install the user's trimmed distance layer with AI-painted, unique margins."""
from pathlib import Path
import argparse
import hashlib
import sys
import cv2
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'background-v3'))
from keying import chroma_key

ROOT = HERE.parents[2]
OUT = ROOT / 'assets/images/map/layers'
parser = argparse.ArgumentParser()
parser.add_argument('--install', action='store_true')
args = parser.parse_args()
protected = {p: p.read_bytes() for p in OUT.glob('*.png') if p.stem != 'distance'}
assert hashlib.sha256((ROOT / 'assets/images/world-1-horizontal.png').read_bytes()).hexdigest() == \
    'f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f'


def keyed(name):
    image = Image.open(HERE / name).convert('RGB')
    rgba = chroma_key(np.array(image)).astype('float32') / 255
    rgba[:, :, :3] *= rgba[:, :, 3:]
    return rgba


# Restore the requested patch resolution (the AI returned 1210 x 1300).
# The source landscape is restored separately, without any rescaling.
left = cv2.resize(keyed('left-ai.png'), (1024, 1100), interpolation=cv2.INTER_AREA)
right = cv2.resize(keyed('right-ai.png'), (1024, 1100), interpolation=cv2.INTER_AREA)
paint = cv2.warpAffine(keyed('landscape-ai.png'), np.array([
    [1.09551322, .00058368, 478.845584],
    [-.00058368, 1.09551322, 102.064850]], dtype='float32'), (3196, 1100),
    flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT)

# Overlaps lie underneath the original center and in the new lower meadow.
mix = np.clip((1000 - np.arange(1024)) / 280, 0, 1)[None, :, None]
paint[:, :1024] = paint[:, :1024] * (1-mix) + left * mix
mix = np.clip(np.arange(1024) / 280, 0, 1)[None, :, None]
paint[:, 2172:] = paint[:, 2172:] * (1-mix) + right * mix

source = np.array(Image.open(HERE / 'center.png').convert('RGBA'))
original = source.astype('float32') / 255
original[:, :, :3] *= original[:, :, 3:]
raw = paint.copy()
# Match color/alpha at the joins while retaining unique painted texture outside
# the crop. No reflected, tiled or stretched image rows/columns are used.
def match_color(target, boundary, reference, fade):
    # Leave keyed antialiasing untouched. Correcting partially transparent
    # colors/alpha independently can produce bright fringes above the skyline.
    opaque = (target[:, 3] > .999) & (boundary[:, 3] > .999) & (reference[:, 3] > .999)
    target[opaque, :3] += (reference[opaque, :3] - boundary[opaque, :3]) * fade


for distance in range(1, 33):
    fade = (1 - distance/33) ** 2
    match_color(paint[128:852, 512-distance], raw[128:852, 512], original[:, 0], fade)
    match_color(paint[128:852, 2683+distance], raw[128:852, 2683], original[:, -1], fade)
    match_color(paint[851+distance, 512:2684], raw[851, 512:2684], original[-1], fade)
paint = np.clip(paint, 0, 1)
paint[128:852, 512:2684] = original

# Keep 48 px above/below the source: the maximum vertical camera/tilt offset
# of this depth is below 19 source pixels. Discard unused, unfinished overscan.
paint = paint[80:900]
alpha = paint[:, :, 3:]
rgb = np.clip(paint[:, :, :3] / np.maximum(alpha, 1/255), 0, 1)
rgba = np.round(np.concatenate([rgb, alpha], axis=2) * 255).astype('uint8')
rgba[rgba[:, :, 3] == 0, :3] = 0
rgba[48:772, 512:2684] = source
assert rgba.shape == (820, 3196, 4)
assert np.array_equal(rgba[48:772, 512:2684], source)
assert (rgba[:48, :, 3] == 0).all()
assert (rgba[-1, :, 3] == 255).all(), 'Unfinished lower margin'
trim = np.array(Image.open(HERE / 'trim-mask.png')) > 0
assert (rgba[48:772, 512:2684, 3][trim] == 0).all()

image = Image.fromarray(rgba)
image.save(HERE / 'distance.png', optimize=True)
for name, color in [('dark', (25, 34, 48, 255)), ('light', (235, 239, 244, 255))]:
    Image.alpha_composite(Image.new('RGBA', image.size, color), image).save(
        HERE / f'distance-{name}.png')
if args.install:
    image.save(OUT / 'distance.png', optimize=True)
for p, before in protected.items():
    assert p.read_bytes() == before, p.name
print('Distance:', image.size, 'RGBA; user trim applied; original center preserved; AI margins.')
