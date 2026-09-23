"""Chroma-key the AI cutout and composite AI fill only into removed foreground.

The generative calls are recorded in prompts.md. This local step creates real
alpha, removes key spill, preserves original pixels outside the repair mask,
and adds the shared overscan used by the map renderer.
"""
from pathlib import Path
import argparse
import hashlib
import sys
import cv2
import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent))
from layer_geometry import pad_layer
ROOT=HERE.parents[2]
SOURCE=ROOT/'assets/images/world-1-horizontal.png'
OUT=ROOT/'assets/images/map/layers'
EXPECTED='f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==EXPECTED
parser=argparse.ArgumentParser()
parser.add_argument('--install',action='store_true')
args=parser.parse_args()
original=np.array(Image.open(SOURCE).convert('RGB'))
h,w=original.shape[:2]
chroma=np.array(Image.open(HERE/'foreground-chroma.png').convert('RGB'))
assert chroma.shape==original.shape

def extract_alpha():
    pixels=chroma.astype(np.float32)
    key=np.median(pixels[:h//2].reshape(-1,3),axis=0)
    excess=np.minimum(pixels[:,:,0],pixels[:,:,2])-pixels[:,:,1]
    solid=excess<10
    background=excess>180
    # Get nearest unmixed subject colour to estimate partial coverage along the
    # border. Key colours never become a pink outline on the final PNG.
    _,labels=cv2.distanceTransformWithLabels((~solid).astype('uint8'),
        cv2.DIST_L2,5,labelType=cv2.DIST_LABEL_PIXEL)
    lut=np.zeros((labels.max()+1,3),np.float32)
    lut[labels[solid]]=pixels[solid]
    clean=lut[labels]
    delta=clean-key
    alpha=np.clip(np.sum((pixels-key)*delta,axis=2)/
        np.maximum(np.sum(delta*delta,axis=2),1),0,1)
    alpha[solid]=1
    alpha[background]=0
    alpha[alpha<.04]=0
    recovered=np.clip((pixels-(1-alpha[:,:,None])*key)/
        np.maximum(alpha[:,:,None],.001),0,255)
    recovered[alpha==0]=0
    return np.dstack([recovered.astype('uint8'),np.round(alpha*255).astype('uint8')])

foreground=extract_alpha()
Image.fromarray(foreground).save(HERE/'foreground-cutout.png',optimize=True)
# The guide marks the entire nearest foreground mass, including tiny gaps.
# Those gaps also need a plausible background when the cutout moves sideways.
mask=(foreground[:,:,3]>0).astype('uint8')*255
mask=cv2.dilate(mask,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(47,47)))
mask=cv2.morphologyEx(mask,cv2.MORPH_CLOSE,np.ones((9,9),np.uint8))
Image.fromarray(mask).save(HERE/'repair-mask.png')
guide=original.copy()
guide[mask>0]=[255,0,255]
Image.fromarray(guide).save(HERE/'terrain-repair-guide.png')

if (HERE/'terrain-ai-fill.png').exists():
    generated=np.array(Image.open(HERE/'terrain-ai-fill.png').convert('RGB'))
    assert generated.shape==original.shape
    # Blend inside the mask only; all pixels outside it remain the original.
    weight=np.clip(cv2.distanceTransform((mask>0).astype('uint8'),cv2.DIST_L2,5)/7,0,1)
    terrain=np.round(original*(1-weight[:,:,None])+generated*weight[:,:,None]).astype('uint8')
    terrain=np.dstack([terrain,np.full((h,w),255,np.uint8)])
    Image.fromarray(terrain).save(HERE/'terrain-background.png',optimize=True)
    combined=Image.alpha_composite(Image.fromarray(terrain),Image.fromarray(foreground))
    combined.save(HERE/'combined-preview.png')
    assert (terrain[:,:,:3][mask==0]==original[mask==0]).all()
    if args.install:
        # Approved near terrain silhouette. Deeper layers are installed by
        # background-v3/build_assets.py, without changing these near assets.
        approved=np.array(Image.open(
            HERE.parent/'terrain-cut-no-pine-hill/terrain-mask.png').convert('L'))
        assert approved.shape==terrain.shape[:2]
        near_terrain=terrain.copy()
        near_terrain[:,:,3]=approved
        for name,rgba in [('foreground',foreground),('terrain',near_terrain)]:
            if name == 'foreground':
                # foreground-v3 installs the AI-painted continuation. Do not
                # overwrite it with the former mirrored/stretched margins.
                continue
            rgba=rgba.copy()
            rgba[rgba[:,:,3]==0,:3]=0
            padded=pad_layer(rgba,name)
            Image.fromarray(padded).save(OUT/f'{name}.png',optimize=True)
print('Foreground alpha:',int((foreground[:,:,3]==0).sum()),'clear pixels;',
      int(((foreground[:,:,3]>0)&(foreground[:,:,3]<255)).sum()),'edge pixels')
