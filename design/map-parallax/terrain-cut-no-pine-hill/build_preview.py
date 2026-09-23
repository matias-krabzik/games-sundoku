"""Review-only terrain separation. Uses AI for alpha and source pixels for RGB."""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
source = np.array(Image.open(HERE.parent / 'ai-v2/terrain-background.png').convert('RGB'))
pixels = np.array(Image.open(HERE.parent / 'terrain-cut-with-trees/terrain-chroma.png').convert('RGB')).astype(np.float32)
assert pixels.shape == source.shape
key = np.median(pixels[:100].reshape(-1, 3), axis=0)
excess = np.minimum(pixels[:, :, 0], pixels[:, :, 2]) - pixels[:, :, 1]
solid = excess < 10
background = excess > 180
_, labels = cv2.distanceTransformWithLabels((~solid).astype('uint8'),
    cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
lut = np.zeros((labels.max() + 1, 3), np.float32)
lut[labels[solid]] = pixels[solid]
delta = lut[labels] - key
alpha = np.clip(np.sum((pixels - key) * delta, axis=2) /
    np.maximum(np.sum(delta * delta, axis=2), 1), 0, 1)
alpha[solid] = 1
alpha[background] = 0
alpha[alpha < .04] = 0
alpha8 = np.round(alpha * 255).astype('uint8')
# The second AI pass accidentally removed the bottom. Union with the initial
# near-ground mask to keep every part of that already approved base intact.
ground = np.array(Image.open(HERE.parent / 'terrain-cut-proposal/terrain-mask.png'))
alpha8 = np.maximum(alpha8, ground)
# The left pine-bearing hill belongs to distance. Use the original AI near-hill
# silhouette instead of the previous manually restored farther hill. Remove
# the two isolated pine components retained by that AI pass at the beginning.
count, labels, stats, _ = cv2.connectedComponentsWithStats(
    (alpha8 > 0).astype('uint8'), connectivity=8)
for label in range(1, count):
    x, y, width, height, area = stats[label]
    if 245 <= x and x + width <= 405 and y + height < 260:
        alpha8[labels == label] = 0
        print(f'Removed distant pine: {(x, y, width, height, area)}')
# Below this point the original is entirely near ground and creek. Preserve it
# fully opaque, including water colors which can confuse chroma-key estimates.
alpha8[500:] = 255
assert np.all(alpha8[ground == 255] == 255)
rgba = np.dstack([source, alpha8])
rgba[alpha8 == 0, :3] = 0
cutout = Image.fromarray(rgba)
cutout.save(HERE / 'terrain-proposed.png', optimize=True)
Image.fromarray(alpha8).save(HERE / 'terrain-mask.png', optimize=True)

# The drawing stays original; only the proposed separation is highlighted.
mask = (alpha8 > 127).astype('uint8')
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
border = cv2.morphologyEx(mask, cv2.MORPH_GRADIENT, kernel,
    borderType=cv2.BORDER_REPLICATE).astype(bool)
muted = source * .25 + np.array([25, 34, 48]) * .75
marked = np.where(mask[:, :, None] > 0, source, muted).astype('uint8')
marked[border] = [255, 211, 47]
Image.fromarray(marked).save(HERE / 'terrain-cutline.png', optimize=True)

for name, color in [('light', (235, 239, 244, 255)), ('dark', (25, 34, 48, 255))]:
    canvas = Image.new('RGBA', cutout.size, color)
    Image.alpha_composite(canvas, cutout).save(HERE / f'preview-{name}.png')

assert (rgba[:, :, :3][alpha8 > 0] == source[alpha8 > 0]).all()
print(f'{cutout.size}: RGBA; {int((alpha8 == 0).sum())} transparent pixels; '
      f'{int(((alpha8 > 0) & (alpha8 < 255)).sum())} antialiased pixels.')
