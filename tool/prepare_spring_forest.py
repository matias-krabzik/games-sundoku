"""Remove the user-requested gray matte without trimming layer registration."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

root = Path(__file__).resolve().parents[1]
src = root / 'design/world-2-spring-forest/mountain-panorama-v1/layers-gray'
dst = root / 'assets/images/map/spring-forest'
dst.mkdir(parents=True, exist_ok=True)
composite = Image.new('RGBA', (2172, 724))
for name in ['sky', 'clouds', 'mountains', 'distance', 'terrain', 'foreground']:
    im = Image.open(src / f'{name}.png').convert('RGBA')
    if im.width != 2172:
        padded = Image.new('RGBA', (2172, 724), (128,128,128,255))
        padded.paste(im, (0, 0))
        if name == 'sky':
            padded.paste(im.crop((im.width-1, 0, im.width, im.height)), (im.width, 0))
        im = padded
    rgb = np.array(im)[:,:,:3].astype(float)
    if name != 'sky':
        # Restrict to matte-colored, nearly neutral pixels. Connected components
        # preserve similarly colored rocks enclosed within the illustration.
        candidate = (rgb.max(2)-rgb.min(2) < 13) & (rgb.mean(2)>105) & (rgb.mean(2)<150)
        mask = Image.fromarray((candidate*255).astype('uint8')).copy()
        from PIL import ImageDraw
        # Exterior matte regions and enclosed openings larger than 8px.
        eroded = mask.filter(ImageFilter.MinFilter(9))
        for y in range(0, im.height, 8):
            for x in range(0, im.width, 8):
                if eroded.getpixel((x,y)) == 255 and mask.getpixel((x,y)) == 255:
                    ImageDraw.floodfill(mask, (x,y), 128)
        background = np.array(mask)==128
        # No chroma-only key: white flowers and gray bed stones stay opaque.
        alpha = np.where(background, 0, 255).astype('uint8')
        alpha_image = Image.fromarray(alpha)
        if name in ('mountains', 'distance', 'clouds'):
            # Remove the neutral fringe left along the atmospheric silhouettes.
            alpha_image = alpha_image.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.35))
        im.putalpha(alpha_image)
    im.save(dst / f'{name}.png')
    composite = Image.alpha_composite(composite, im)
    print(name, im.size, im.getextrema()[3])
composite.save('/private/tmp/spring-forest-composite.png')
