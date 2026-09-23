"""Register AI outpainted margins around the unchanged approved foreground."""
from pathlib import Path
import argparse
import sys
import cv2
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'background-v3'))
from keying import chroma_key

ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--install', action='store_true')
args = parser.parse_args()

# Similarity registrations measured against the approved source with SIFT.
# Only the new AI paint is registered; original flowers/plants are not scaled.
def registered(name, matrix):
    rgb = np.array(Image.open(HERE / name).convert('RGB'))
    rgba = chroma_key(rgb).astype('float32') / 255
    rgba[:, :, :3] *= rgba[:, :, 3:]
    return cv2.warpAffine(rgba, np.array(matrix, dtype='float32'), (2428, 980),
                          flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT)


paint = registered('foreground-ai.png', [
    [1.11836836, .00656045, 107.177009],
    [-.00656045, 1.11836836, 58.716233]])
left = registered('left-ai.png', [
    [.50100321, -.00110138, 103.823045 - 128],
    [.00110138, .50100321, -26.834768 + 340]])
right = registered('right-complete-ai.png', [
    [.61198052, -.00036035, .479955 + 1788],
    [.00036035, .61198052, -143.666648 + 340]])

# Join the independently generated edges under the preserved source rectangle.
xx = np.arange(2428)[None, :, None]
for patch, mix in [(left, np.clip((400 - xx) / 180, 0, 1)),
                   (right, np.clip((xx - 2040) / 180, 0, 1))]:
    paint = paint * (1 - mix) + patch * mix

source = np.array(Image.open(HERE.parent / 'ai-v2/foreground-cutout.png').convert('RGBA'))
source[source[:, :, 3] == 0, :3] = 0
original = source.astype('float32') / 255
original[:, :, :3] *= original[:, :, 3:]

# Correct color/alpha differences right at each joining edge. This adds a
# decaying color correction to unique AI texture; no pixels are reflected,
# tiled, stretched or copied outward as a replacement for painted margins.
raw = paint.copy()
for distance in range(1, 33):
    fade = (1 - distance / 33) ** 2
    paint[128:852, 128-distance] += (original[:, 0] - raw[128:852, 128]) * fade
    paint[128:852, 2299+distance] += (original[:, -1] - raw[128:852, 2299]) * fade
    paint[851+distance, 128:2300] += (original[-1] - raw[851, 128:2300]) * fade
paint = np.clip(paint, 0, 1)
paint[128:852, 128:2300] = original

# The 80 px vertical reserve is over twice the maximum foreground camera/tilt
# offset. Crop unused margin beyond the generated art instead of repeating it.
paint = paint[48:-48]
alpha = paint[:, :, 3:]
rgb = np.clip(paint[:, :, :3] / np.maximum(alpha, 1/255), 0, 1)
rgba = np.round(np.concatenate([rgb, alpha], axis=2) * 255).astype('uint8')
rgba[rgba[:, :, 3] == 0, :3] = 0
rgba[80:804, 128:2300] = source
assert rgba.shape == (884, 2428, 4)
assert np.array_equal(rgba[80:804, 128:2300], source)
assert (rgba[:80, :, 3] == 0).all()
assert (rgba[-1, :, 3] == 255).all(), 'Incomplete lower painted margin'
image = Image.fromarray(rgba)
image.save(HERE / 'foreground.png', optimize=True)
for name, color in [('dark', (25, 34, 48, 255)), ('light', (235, 239, 244, 255))]:
    Image.alpha_composite(Image.new('RGBA', image.size, color), image).save(
        HERE / f'foreground-{name}.png')
if args.install:
    image.save(ROOT / 'assets/images/map/layers/foreground.png', optimize=True)
print('Foreground: original center unchanged; AI margins; true alpha;', image.size)
