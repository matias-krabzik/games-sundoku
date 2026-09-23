"""Extract registered parallax layers without regenerating original artwork.

Requires Pillow, NumPy, OpenCV. Guides use a 2048×683 grid; exports preserve the
2172×724 source plus 48 pixels of overscan. Object masks have real negative
spaces; only the ground planes use continuous height contours.
"""
from pathlib import Path
import hashlib
import cv2
import numpy as np
from PIL import Image, ImageDraw
from object_masks import TREES, ARCH, SUN, BRIDGE

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/images/world-1-horizontal.png'
OUT = Path(__file__).resolve().parent / 'legacy-layers'
QA = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
SOURCE_HASH = 'f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_HASH
rgb = np.array(Image.open(SOURCE).convert('RGB'))
h, w = rgb.shape[:2]
x, y = np.arange(w), np.arange(h)[:, None]
cv2.setRNGSeed(71)


def contour(points):
    assert all(a[0] < b[0] for a, b in zip(points, points[1:]))
    return np.interp(x, np.array(points)[:, 0] * w / 2048,
                     np.array(points)[:, 1] * h / 683)


def polygon(points):
    image = Image.new('L', (w, h))
    ImageDraw.Draw(image).polygon([(px*w/2048, py*h/683) for px, py in points], fill=255)
    return np.array(image)


def refine_object(spec, margin=6):
    """Constrained graph cut around a *closed* silhouette, including holes.

    Only a narrow uncertain band is classified. Definite background outside
    the band and inside branch holes can never turn into foreground.
    """
    guide = polygon(spec['outline'])
    holes = np.zeros((h, w), np.uint8)
    for hole in spec['holes']:
        holes |= polygon(hole)
    guide[holes > 0] = 0
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (margin*2+1, margin*2+1))
    allowed = cv2.dilate(guide, kernel)
    core = cv2.erode(guide, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25,25)))
    # Brown trunks/branches and orange wood need their own foreground seeds;
    # they are narrower than the eroded foliage core.
    rr,gg,bb = rgb.astype(float).transpose(2,0,1)
    wood = (rr>gg*1.12)&(rr>bb*1.7)&(gg<205)&(guide>0)
    core[wood] = 255
    # Small negative spaces are traced explicitly and must remain open.
    allowed[holes > 0] = 0
    if spec['name'] in {tree['name'] for tree in TREES}:
        sky = (bb>gg+6)|((np.maximum.reduce([rr,gg,bb])-np.minimum.reduce([rr,gg,bb])<35)&(gg>210))
        allowed[sky] = 0
        core[sky] = 0
        guide[sky] = 0
    ys, xs = np.where(allowed)
    l, r = max(0,xs.min()-3), min(w,xs.max()+4)
    t, b = max(0,ys.min()-3), min(h,ys.max()+4)
    mask = np.full((b-t,r-l),cv2.GC_BGD,np.uint8)
    mask[allowed[t:b,l:r]>0] = cv2.GC_PR_BGD
    mask[guide[t:b,l:r]>0] = cv2.GC_PR_FGD
    mask[core[t:b,l:r]>0] = cv2.GC_FGD
    mask[holes[t:b,l:r]>0] = cv2.GC_BGD
    cv2.grabCut(rgb[t:b,l:r].copy(), mask, None,
                np.zeros((1,65),np.float64), np.zeros((1,65),np.float64),
                5, cv2.GC_INIT_WITH_MASK)
    result = np.zeros((h,w),np.uint8)
    result[t:b,l:r] = np.isin(mask,[cv2.GC_FGD,cv2.GC_PR_FGD]).astype('uint8')*255
    # Discard disconnected background specks, retain any component touching
    # the known foreground guide (sun rays are intentionally disconnected).
    n, labels, stats, _ = cv2.connectedComponentsWithStats(result)
    for label in range(1,n):
        if stats[label,cv2.CC_STAT_AREA] < 6 or not (core[labels==label]>0).any():
            result[labels==label] = 0
    result[holes > 0] = 0
    return result


# Horizon envelope. Fine skyline detail is refined against sky colour below.
ridge = contour([(0,200),(220,194),(300,209),(365,190),(435,215),
 (487,195),(545,190),(582,203),(620,218),(673,236),(760,245),
 (846,238),(910,254),(968,229),(1051,204),(1080,222),(1159,245),
 (1205,231),(1267,218),(1319,216),(1380,206),(1437,222),
 (1490,240),(1550,233),(1600,214),(1675,221),(1742,200),
 (1785,189),(1840,211),(1920,218),(2048,214)])

front = contour([(0,540),(40,535),(95,548),(150,566),(206,585),
 (250,569),(293,594),(346,609),(402,605),(460,586),(512,566),
 (560,545),(606,532),(650,544),(695,563),(745,585),(790,575),
 (831,593),(887,604),(930,628),(980,644),(1080,650),(1180,654),
 (1310,663),(1410,660),(1480,646),(1540,618),(1600,600),
 (1660,600),(1710,582),(1760,583),(1810,570),(1850,554),
 (1900,518),(1940,506),(1980,518),(2048,495)])
# Follow the actual foreground hill crests, leaving air around tree trunks.
ground = contour([(0,269),(80,264),(133,271),(200,287),(277,298),
 (340,301),(406,294),(450,294),(480,296),(527,311),(585,329),(646,349),
 (701,357),(764,363),(822,379),(904,398),(983,419),(1033,417),
 (1060,430),(1140,451),(1200,425),(1250,389),(1290,370),
 (1340,350),(1400,347),(1460,334),(1510,321),(1580,305),
 (1640,288),(1660,280),(1715,279),(1760,280),(1810,264),(1870,262),
 (1930,263),(1990,265),(2048,267)])
terrain_mask = (y >= ground).astype('uint8')*255
objects = {}
for spec in [*TREES, ARCH, SUN, BRIDGE]:
    objects[spec['name']] = refine_object(spec)
    terrain_mask |= objects[spec['name']]
# A nearby shrub in front of the oak must remain on its ground plane as well.
shrub = dict(name='oak-shrub',outline=[(0,202),(12,204),(25,211),(40,208),
 (50,219),(65,220),(73,237),(84,250),(94,266),(85,292),(0,300)], holes=[])
terrain_mask |= refine_object(shrub,4)

# Distant mountains/trees keep their own silhouette. Avoid using nearby tree
# pixels as sky/ground classification seeds; these are removed by inpainting.
land = (y >= ridge).astype('uint8')*255
r,g,b = rgb.astype(float).transpose(2,0,1)
vegetation = (g>b*1.20)&(g>r*1.01)&(g-b>20)&(y>110*h/683)
nearby = cv2.dilate(terrain_mask,np.ones((13,13),np.uint8))
land[vegetation & (nearby==0)] = 255
land = cv2.morphologyEx(land,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
# Keep the distant skyline connected to the landscape, not isolated fragments
# left beside a foreground tree that has just been extracted.
n, labels, stats, _ = cv2.connectedComponentsWithStats(land)
for label in range(1,n):
    if not (labels[-1] == label).any():
        land[labels==label]=0
for spec in [
 dict(name='cypress-left',outline=[(1924,214),(1928,181),(1930,159),(1933,143),
 (1932,126),(1938,105),(1940,86),(1946,66),(1953,54),(1958,68),
 (1962,88),(1967,104),(1966,122),(1971,138),(1972,155),(1978,177),
 (1977,211)],holes=[]),
 dict(name='cypress-right',outline=[(1980,215),(1985,179),(1988,152),(1990,127),
 (1993,109),(1996,85),(2002,65),(2011,54),(2017,72),(2021,93),
 (2022,112),(2028,134),(2029,153),(2036,178),(2041,217)],holes=[]),
]:
    land |= refine_object(spec,4)

# Foreground now follows actual flowers/leaves instead of cutting through them.
# The old grass contour is retained as ground; local flower silhouettes extend
# upward only where the foreground plant is actually present.
foreground = (y >= front).astype('uint8')*255
FRONT_PLANTS = [
 dict(name='left-flower',outline=[(0,441),(25,457),(40,462),(48,455),(60,460),
 (69,454),(85,465),(93,470),(111,474),(120,488),(129,495),(126,510),
 (117,520),(105,523),(105,545),(132,552),(148,574),(136,610),(0,640)],holes=[]),
 dict(name='flower-1',outline=[(198,654),(208,623),(226,608),(245,588),
 (249,577),(257,575),(265,582),(279,578),(291,585),(291,595),
 (312,593),(322,604),(317,615),(300,624),(291,623),(279,639),
 (279,659),(298,678),(207,681)],holes=[]),
 dict(name='flower-2',outline=[(697,660),(707,621),(731,611),(750,589),
 (742,580),(748,569),(760,565),(767,552),(779,555),(790,566),
 (803,571),(808,580),(800,591),(785,600),(784,620),(806,645),
 (792,678),(710,681)],holes=[]),
 dict(name='flower-3',outline=[(848,678),(853,656),(877,644),(888,632),
 (877,621),(883,605),(899,606),(905,598),(916,601),(925,612),
 (940,614),(947,625),(943,638),(926,647),(914,657),(912,680)],holes=[]),
 dict(name='right-flower',outline=[(1809,680),(1813,646),(1841,615),
 (1864,602),(1872,583),(1886,577),(1902,566),(1913,550),(1926,550),
 (1941,558),(1956,554),(1971,563),(1975,578),(1964,589),(1955,598),
 (1937,602),(1928,618),(1932,640),(1941,671),(1941,683)],holes=[])
]
for spec in FRONT_PLANTS:
    foreground |= refine_object(spec,5)

# Narrow antialiasing only: no blurred silhouettes or broad fringe/halo.
def antialias(mask):
    return cv2.GaussianBlur(mask,(3,3),.45)

alphas = [np.full((h,w),255,np.uint8),antialias(land),
          antialias(terrain_mask),antialias(foreground)]
images=[]
for i,name in enumerate(['sky','distance','terrain','foreground']):
    higher = np.maximum.reduce(alphas[i+1:]) if i<3 else np.zeros((h,w),np.uint8)
    # Remove complete objects, including from behind semi-transparent edges.
    # This avoids a second tree outline following the rear plane.
    hidden = (higher>0).astype('uint8')*255
    filled = cv2.inpaint(rgb,hidden,5,cv2.INPAINT_TELEA) if hidden.any() else rgb.copy()
    rgba = np.dstack([filled,alphas[i]])
    images.append(Image.fromarray(rgba))
    padded = np.pad(rgba,((48,48),(48,48),(0,0)),mode='edge')
    if i>0: padded[:48,:,3]=0
    padded[padded[:,:,3]==0,:3]=0
    Image.fromarray(padded).save(OUT/f'{name}.png',optimize=True)

composite=Image.new('RGBA',(w,h))
for layer in images: composite.alpha_composite(layer)
composite.save(QA/'reassembled.png')
diff=np.abs(np.asarray(composite)[:,:,:3].astype(int)-rgb.astype(int))
# Antialiased silhouette edges may differ slightly from the flattened original;
# interior artwork is preserved exactly. Do not optimise for a zero-difference
# composite by keeping unwanted background pixels attached to the foreground.
edge=np.zeros((h,w),bool)
for alpha in alphas[1:]: edge |= (alpha>0)&(alpha<255)
assert (diff[~edge]==0).all(), 'Changed pixels outside antialiased silhouettes'
assert diff.mean()<1, f'Unexpected reconstruction drift: {diff.mean()}'
# Regression checks for the unwanted scenery that used to travel with trunks.
for px,py in [(180,244),(435,284),(504,290),(665,346),(1310,346),
              (1690,272),(1865,230)]:
    assert alphas[2][round(py*h/683),round(px*w/2048)] == 0, (px,py)
for px,py in [(463,284),(701,348),(1358,344),(1798,240),(1938,240)]:
    assert alphas[2][round(py*h/683),round(px*w/2048)] == 255, (px,py)
print('Original SHA256:',SOURCE_HASH)
print('Recomposition: mean RGB delta',round(float(diff.mean()),4),
      '; unchanged pixels',round(float((diff.max(axis=2)==0).mean()*100),2),'%')
for p in OUT.glob('*.png'):
    im=Image.open(p);alpha=np.array(im.getchannel('A'))
    assert im.mode=='RGBA' and (p.stem=='sky' or (alpha==0).any())
    print(p.name,'transparent:',int((alpha==0).sum()),'antialiased:',int(((alpha>0)&(alpha<255)).sum()))
# Individual objects help review branches and negative spaces on contrasting
# backgrounds without confusing them with the ground's legitimate scenery.
for name,mask in objects.items():
    rgba=np.dstack([rgb,antialias(mask)])
    rgba[rgba[:,:,3]==0,:3]=0
    (QA/'object-previews').mkdir(exist_ok=True)
    Image.fromarray(rgba).save(QA/'object-previews'/f'{name}.png')
