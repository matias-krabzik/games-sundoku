"""Build the four deeper layers; preserve the approved terrain and foreground."""
from pathlib import Path
import argparse
import hashlib
import sys
import cv2
import numpy as np
from PIL import Image
from keying import chroma_key

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from layer_geometry import SOURCE_SIZE, PADDING, pad_layer, vertical_padding
ROOT = HERE.parents[2]
OUT = ROOT / 'assets/images/map/layers'
SIZE = SOURCE_SIZE
parser = argparse.ArgumentParser()
parser.add_argument('--install', action='store_true')
args = parser.parse_args()


def read_rgb(name):
    image = Image.open(HERE / name).convert('RGB')
    assert image.size == SIZE, (name, image.size)
    return np.array(image)


def transparent_rgb(rgb, alpha):
    rgba = np.dstack([rgb, alpha]).astype('uint8')
    rgba[alpha == 0, :3] = 0
    return rgba


def refine_silhouette(rgb, alpha, radius):
    """Snap an AI/contour guide to source edges within a narrow uncertain band."""
    guide = (alpha > 127).astype('uint8')
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (radius * 2 + 1,) * 2)
    allowed = cv2.dilate(guide, kernel)
    core = cv2.erode(guide, kernel)
    classes = np.full(guide.shape, cv2.GC_BGD, dtype='uint8')
    classes[allowed > 0] = cv2.GC_PR_BGD
    classes[guide > 0] = cv2.GC_PR_FGD
    classes[core > 0] = cv2.GC_FGD
    cv2.setRNGSeed(71)
    cv2.grabCut(rgb.copy(), classes, None, np.zeros((1, 65)),
                np.zeros((1, 65)), 3, cv2.GC_INIT_WITH_MASK)
    result = np.isin(classes, [cv2.GC_FGD, cv2.GC_PR_FGD]).astype('uint8') * 255
    return cv2.GaussianBlur(result, (3, 3), .45)


source_path = ROOT / 'assets/images/world-1-horizontal.png'
assert hashlib.sha256(source_path.read_bytes()).hexdigest() == \
    'f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f'
protected = {name: (OUT / f'{name}.png').read_bytes()
             for name in ['terrain', 'foreground', 'distance']}
source = np.array(Image.open(HERE.parent / 'ai-v2/terrain-background.png').convert('RGB'))
near = np.array(Image.open(HERE.parent / 'terrain-cut-no-pine-hill/terrain-mask.png'))
repair = cv2.dilate((near > 0).astype('uint8'),
    cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
weight = np.clip(cv2.distanceTransform(repair, cv2.DIST_L2, 5) / 4, 0, 1)[:, :, None]
repaired = np.round(source * (1 - weight) + read_rgb('distance-ai-fill.png') * weight).astype('uint8')
assert np.array_equal(repaired[repair == 0], source[repair == 0])
Image.fromarray(repaired).save(HERE / 'repaired-background.png', optimize=True)
Image.fromarray(repair * 255).save(HERE / 'distance-repair-mask.png')

# The AI sky has a one-pixel width difference; only this smooth sky plate is
# normalized. None of the registered terrain/land/cloud cutouts is rescaled.
sky = Image.open(HERE / 'sky-ai.png').convert('RGBA').resize(SIZE, Image.Resampling.LANCZOS)
sky.putalpha(255)
clouds = chroma_key(read_rgb('clouds-chroma.png'))
distance_alpha = chroma_key(read_rgb('distance-chroma.png'))[:, :, 3]
# The AI dropped the pale green valley beyond the waterfall. Recover its
# continuous ground from the source's vegetation colors, below the far skyline.
green_horizon = np.array([(0, 185), (250, 200), (450, 225), (650, 245),
    (850, 259), (1050, 270), (1200, 270), (1400, 240), (1600, 237),
    (1800, 226), (2048, 190)])
floor = np.interp(np.arange(SIZE[0]), green_horizon[:, 0] * SIZE[0] / 2048,
                  green_horizon[:, 1] * SIZE[1] / 683)
hsv = cv2.cvtColor(repaired, cv2.COLOR_RGB2HSV)
green = ((hsv[:, :, 0] >= 25) & (hsv[:, :, 0] <= 92) &
         (hsv[:, :, 1] > 25) &
         (repaired[:, :, 1].astype(int) - repaired[:, :, 2].astype(int) > 5) &
         (np.arange(SIZE[1])[:, None] >= floor)).astype('uint8')
green = cv2.morphologyEx(green, cv2.MORPH_OPEN, np.ones((3, 7), dtype='uint8'))
green_start = np.argmax(green, axis=0)
green_start[~green.any(axis=0)] = SIZE[1]
ground = (np.arange(SIZE[1])[:, None] >= green_start).astype('uint8') * 255
distance_alpha = refine_silhouette(repaired, np.maximum(distance_alpha, ground), 10)
# All the lower section is landscape, including bright reflections in water.
distance_alpha[430:] = 255
distance = transparent_rgb(repaired, distance_alpha)

mountains = chroma_key(read_rgb('mountains-chroma.png'))
# Restore the original vertical registration: the AI placed the mountain-only
# skyline 61 source pixels below its reference. Visible RGB is restored below.
mountains = np.concatenate([mountains[61:], np.repeat(mountains[-1:], 61, axis=0)])
# Extend valid mountain RGB into the guide's uncertain band before expanding
# its alpha; transparent source pixels have RGB zero and must not become rims.
known = mountains[:, :, 3] == 255
_, nearest = cv2.distanceTransformWithLabels((~known).astype('uint8'),
    cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
colors = np.zeros((nearest.max() + 1, 3), dtype='uint8')
colors[nearest[known]] = mountains[:, :, :3][known]
mountains[:, :, :3][~known] = colors[nearest][~known]
# Restore the actual source skyline rather than the AI's recomposed peak widths.
# This contour uses the source's 2048x683 review coordinates. A narrow graph cut
# then follows the visible painted edge instead of leaving old sky around it.
ridge_points = np.array([(0, 170), (95, 175), (180, 169), (240, 184),
    (300, 183), (365, 190), (435, 215), (487, 195), (545, 190),
    (582, 203), (620, 190), (673, 214), (710, 225), (760, 232),
    (805, 245), (846, 238), (895, 246), (935, 231), (975, 226),
    (1020, 210), (1052, 204), (1064, 192), (1080, 208), (1120, 232),
    (1168, 247), (1205, 235), (1245, 231), (1290, 213), (1320, 218),
    (1380, 206), (1410, 215), (1460, 218), (1490, 233), (1550, 211),
    (1600, 223), (1675, 216), (1742, 195), (1785, 180), (1840, 200),
    (1890, 180), (1940, 192), (1990, 167), (2048, 159)])
ridge = np.interp(np.arange(SIZE[0]), ridge_points[:, 0] * SIZE[0] / 2048,
                  ridge_points[:, 1] * SIZE[1] / 683)
ridge_alpha = (np.arange(SIZE[1])[:, None] >= ridge).astype('uint8') * 255
mountain_reference = repaired.copy()
mountain_reference[distance_alpha > 127] = mountains[:, :, :3][distance_alpha > 127]
mountains[:, :, 3] = refine_silhouette(mountain_reference, ridge_alpha, 13)
# The white snow tip is a light mountain edge, not part of the white clouds.
snow_tip = np.zeros((SIZE[1], SIZE[0]), dtype='uint8')
snow_polygon = np.round(np.array([(1064, 192), (1055, 205), (1080, 212)]) *
    np.array([SIZE[0] / 2048, SIZE[1] / 683])).astype('int32')
cv2.fillPoly(snow_tip, [snow_polygon], 255)
mountains[:, :, 3] = np.maximum(mountains[:, :, 3], snow_tip)
mountains[430:, :, 3] = 255
# Keep visible original mountain paint. AI supplies the parts hidden by the
# hills/terrain, including an extended base for independent layer movement.
visible = (distance_alpha == 0) & (mountains[:, :, 3] > 0)
mountains[:, :, :3][visible] = repaired[visible]
mountains[mountains[:, :, 3] == 0, :3] = 0

# Complete the former blue lower fill with an AI-painted distant valley. Keep
# the registered silhouette and its first 24 rows of mountain paint untouched;
# blend only inside the opaque layer, never importing the AI's drawn checker.
valley_path = HERE / 'mountains-valley-ai.png'
if valley_path.exists():
    valley = read_rgb(valley_path.name)
    ridge_start = np.argmax(mountains[:, :, 3] > 0, axis=0)
    blend = np.clip((np.arange(SIZE[1])[:, None] - ridge_start - 24) / 40, 0, 1)
    original_ridge = mountains.copy()
    mountains[:, :, :3] = np.round(
        mountains[:, :, :3] * (1 - blend[:, :, None]) +
        valley * blend[:, :, None]).astype('uint8')
    mountains[mountains[:, :, 3] == 0, :3] = 0
    assert np.array_equal(mountains[blend == 0], original_ridge[blend == 0])
    assert np.array_equal(mountains[:, :, 3], original_ridge[:, :, 3])

layers = {'sky': np.array(sky), 'clouds': clouds,
          'mountains': mountains, 'distance': distance}
for name, rgba in layers.items():
    image = Image.fromarray(rgba)
    image.save(HERE / f'{name}.png', optimize=True)
    if name != 'sky':
        assert (rgba[:, :, 3] == 0).any(), f'{name}: missing alpha'
        for suffix, color in [('dark', (25, 34, 48, 255)), ('light', (235, 239, 244, 255))]:
            Image.alpha_composite(Image.new('RGBA', SIZE, color), image).save(
                HERE / f'{name}-{suffix}.png')
    else:
        assert (rgba[:, :, 3] == 255).all()
    if args.install and name != 'distance':
        # distance-v4 installs the annotated trim and painted continuation.
        # Never restore the former reflected/stretched distance margins.
        padded = pad_layer(rgba, name)
        Image.fromarray(padded).save(OUT / f'{name}.png', optimize=True)
    print(name, 'alpha:', int((rgba[:, :, 3] == 0).sum()), 'clear pixels')

combined = Image.new('RGBA', SIZE)
for name, rgba in layers.items():
    trimmed = HERE.parent / 'distance-v4/center.png'
    image = Image.open(trimmed).convert('RGBA') if name == 'distance' and trimmed.exists() else Image.fromarray(rgba)
    combined = Image.alpha_composite(combined, image)
combined.save(HERE / 'distant-scene-preview.png')
for name in ['terrain', 'foreground']:
    top = vertical_padding(name)
    layer = Image.open(OUT / f'{name}.png').convert('RGBA').crop(
        (PADDING, top, PADDING + SIZE[0], top + SIZE[1]))
    combined = Image.alpha_composite(combined, layer)
    assert (OUT / f'{name}.png').read_bytes() == protected[name]
combined.save(HERE / 'combined-preview.png')
assert (np.array(combined)[:, :, 3] == 255).all()
for name, before in protected.items():
    assert (OUT / f'{name}.png').read_bytes() == before, name
