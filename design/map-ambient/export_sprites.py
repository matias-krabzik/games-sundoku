"""Convert the approved AI magenta intermediates to compact RGBA sprites.

Run with Pillow, NumPy and OpenCV (the same environment as the map exporter).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'map-parallax' / 'background-v3'))
from keying import chroma_key

OUT = HERE.parent.parent / 'assets' / 'images' / 'map' / 'ambient'
OUT.mkdir(parents=True, exist_ok=True)
for name, width in [('leaf', 128), ('bee', 192)]:
    raw = Image.open(HERE / f'{name}-magenta.png').convert('RGB')
    image = Image.fromarray(chroma_key(np.asarray(raw)))
    image = image.crop(image.getchannel('A').getbbox())
    # Resize in premultiplied alpha so black/chroma cannot bleed at the edge.
    image = image.convert('RGBa').resize(
        (width, round(width * image.height / image.width)),
        Image.Resampling.LANCZOS,
    ).convert('RGBA')
    padded = Image.new('RGBA', (image.width + 8, image.height + 8))
    padded.paste(image, (4, 4))
    padded.save(OUT / f'{name}.png', optimize=True)
    alpha = np.asarray(padded.getchannel('A'))
    assert alpha.min() == 0 and alpha.max() == 255
    assert np.all(alpha[[0, -1], :] == 0) and np.all(alpha[:, [0, -1]] == 0)
    print(name, padded.size, 'transparent:', int((alpha == 0).sum()))
