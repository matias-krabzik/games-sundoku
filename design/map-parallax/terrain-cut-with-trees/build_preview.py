"""Review-only terrain separation. Uses AI for alpha and source pixels for RGB."""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
source = np.array(Image.open(HERE.parent / 'ai-v2/terrain-background.png').convert('RGB'))
pixels = np.array(Image.open(HERE / 'terrain-chroma.png').convert('RGB')).astype(np.float32)
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
# Restore the original first hill beneath the left trees. This contour follows
# the visible original ridge and joins the retained tree-bearing near knolls.
hill = np.zeros(alpha8.shape, dtype='uint8')
ridge = np.array([(0, 211), (110, 211), (190, 211), (240, 212),
    (265, 211), (286, 213), (306, 217), (325, 221), (345, 227),
    (365, 233), (386, 241), (408, 248), (430, 255), (455, 264),
    (520, 295), (600, 326), (600, 724), (0, 724)], dtype=np.int32)
cv2.fillPoly(hill, [ridge], 255)
alpha8 = np.maximum(alpha8, hill)
# Recover the cypress silhouettes rooted on that hill from the original RGB.
# This limited region contains foliage against sky/mountains; no other artwork
# is replaced. The AI already retains the other large tree silhouettes.
region = source[120:270, 235:445]
hsv = cv2.cvtColor(region, cv2.COLOR_RGB2HSV)
green = ((hsv[:, :, 0] >= 20) & (hsv[:, :, 0] <= 92) &
    (hsv[:, :, 1] > 35) &
    (region[:, :, 1].astype(int) - region[:, :, 2].astype(int) > 12)).astype('uint8') * 255
green = cv2.morphologyEx(green, cv2.MORPH_CLOSE, np.ones((3, 3), dtype='uint8'))
alpha8[120:270, 235:445] = np.maximum(alpha8[120:270, 235:445], green)
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
