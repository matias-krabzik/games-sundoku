"""Apply the user's two black trim guides to the clean, registered source."""
from pathlib import Path
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
source = np.array(Image.open(HERE.parent / 'background-v3/distance.png').convert('RGBA'))
marked = np.array(Image.open(HERE / 'annotated.png').convert('RGBA'))
assert source.shape == (724, 2172, 4)
assert marked.shape == (980, 3196, 4)
cut = np.zeros(source.shape[:2], dtype=bool)
# The vertical strokes at the two sides identify reflection seams, not cuts.
# Only the horizontal and curved strokes around the upper valley are trim lines.
for x0, y0, x1, y1 in [(1228, 390, 1387, 425), (1532, 403, 1836, 480)]:
    region = marked[y0:y1, x0:x1]
    ink = (region[:, :, 3] > 200) & (region[:, :, :3].max(axis=2) < 30)
    for col in range(ink.shape[1]):
        rows = np.flatnonzero(ink[:, col])
        if rows.size:
            x = x0 + col - 512
            bottom = y0 + rows[-1] - 128
            cut[:bottom + 1, x] = True
source[cut] = 0
source[source[:, :, 3] == 0, :3] = 0
Image.fromarray(source).save(HERE / 'center.png', optimize=True)
Image.fromarray((cut * 255).astype('uint8')).save(HERE / 'trim-mask.png')
guide = Image.new('RGBA', (3196, 1100), (255, 0, 255, 255))
guide.alpha_composite(Image.fromarray(source), (512, 128))
guide.convert('RGB').save(HERE / 'outpaint-guide.png')
print('Trimmed', int(cut.sum()), 'pixels within the two marked column ranges.')
