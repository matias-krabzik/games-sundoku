"""Package the approved master icon into native platform sizes (Pillow required)."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root=Path(__file__).resolve().parents[1]
source=Image.open(root/'assets/images/sundoku-app-icon.png').convert('RGB')
assert source.size == (1024,1024), 'Expected a square 1024px master icon'

def resized(size):
 return source.resize((size,size),Image.Resampling.LANCZOS)

def rounded(size, inset=0):
 canvas=Image.new('RGBA',(size,size))
 edge=size-2*inset
 art=resized(edge).convert('RGBA')
 mask=Image.new('L',(edge,edge))
 ImageDraw.Draw(mask).rounded_rectangle((0,0,edge-1,edge-1),radius=edge*.20,fill=255)
 art.putalpha(mask)
 canvas.alpha_composite(art,(inset,inset))
 return canvas

for platform in ['ios','macos']:
 folder=root/f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset'
 for entry in json.loads((folder/'Contents.json').read_text())['images']:
  size=round(float(entry['size'].split('x')[0])*float(entry['scale'][:-1]))
  icon=resized(size) if platform=='ios' else rounded(size,round(size*.09))
  icon.save(folder/entry['filename'])
for density,scale in [('mdpi',1),('hdpi',1.5),('xhdpi',2),('xxhdpi',3),('xxxhdpi',4)]:
 folder=root/f'android/app/src/main/res/mipmap-{density}'
 rounded(round(48*scale)).save(folder/'ic_launcher.png')
for size in [192,512]:
 rounded(size).save(root/f'web/icons/Icon-{size}.png')
 # Keep the whole illustration inside the central safe circle of maskable icons.
 canvas=Image.new('RGB',(size,size),(12,105,143))
 edge=round(size*.56)
 canvas.paste(resized(edge),((size-edge)//2,(size-edge)//2))
 canvas.save(root/f'web/icons/Icon-maskable-{size}.png')
rounded(32).save(root/'web/favicon.png')
rounded(256).save(root/'windows/runner/resources/app_icon.ico',sizes=[(s,s) for s in [16,24,32,48,64,128,256]])
print('Packaged Doku icon across Flutter, iOS, macOS, Android, web and Windows.')
