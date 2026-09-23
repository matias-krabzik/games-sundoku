from pathlib import Path
from PIL import Image
import numpy as np
from layer_geometry import PADDING, BACKGROUND_PADDING, SOURCE_SIZE, horizontal_padding, vertical_padding
p=Path(__file__).resolve().parent
root=p.parents[1]
names=['sky','clouds','mountains','distance','terrain','foreground']
layers=[]
w,h=SOURCE_SIZE[0]+BACKGROUND_PADDING*2,SOURCE_SIZE[1]+PADDING*2
for name in names:
 layer=Image.open(root/'assets/images/map/layers'/f'{name}.png').convert('RGBA')
 registered=Image.new('RGBA',(w,h))
 registered.alpha_composite(layer,(BACKGROUND_PADDING-horizontal_padding(name),PADDING-vertical_padding(name)))
 layers.append(registered)
checker=((np.indices((h,w))[0]//16+np.indices((h,w))[1]//16)%2*45+170).astype('uint8')
back=Image.fromarray(np.dstack([checker,checker,checker,np.full_like(checker,255)]))
preview_height=round(h*1134/w)
strip=Image.new('RGB',(1134,preview_height*len(layers)))
for i,im in enumerate(layers):
 out=Image.alpha_composite(back,im)
 strip.paste(out.resize((1134,preview_height)),(0,preview_height*i))
strip.save(p/'layers-preview.jpg')
frames=[]
for tick in range(48):
 t=np.sin(tick/48*np.pi*2)
 canvas=Image.new('RGBA',(w,h))
 for i,im in enumerate(layers):
  dx=round([489,474,380,195,0,-87][i]*t);dy=round([-10,-10,-6,-4,0,14][i]*t)
  canvas.alpha_composite(im,(dx,dy))
 cropped=canvas.crop((BACKGROUND_PADDING,PADDING,w-BACKGROUND_PADDING,h-PADDING))
 assert cropped.getchannel('A').getextrema()==(255,255), 'Uncovered edge'
 frames.append(cropped.resize((1086,362)).convert('RGB'))
frames[12].save(p/'motion-extreme.png')
frames[0].save(p/'motion-preview.gif',save_all=True,append_images=frames[1:],duration=65,loop=0)
