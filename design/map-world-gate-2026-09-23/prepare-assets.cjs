// Local alpha cleanup and a tightly masked composite of the AI repair.
// Usage: node prepare-assets.cjs <generated-sun.png> <generated-arch.png>
// Requires sharp/pngjs; run from the project root. No image generation here.
const fs = require('fs');
const {execFileSync} = require('child_process');
const sharp = require('sharp');
const {PNG} = require('pngjs');
const out = 'design/map-world-gate-2026-09-23';

async function removeNeutralBackdrop(path, seeds = []) {
  const {data, info} = await sharp(path).ensureAlpha().raw().toBuffer({resolveWithObject: true});
  const {width: w, height: h} = info;
  const n = w * h, exterior = new Uint8Array(n), queue = new Int32Array(n);
  const chroma = p => {
    const i = p * 4;
    return Math.max(data[i], data[i+1], data[i+2]) - Math.min(data[i], data[i+1], data[i+2]);
  };
  let head = 0, tail = 0;
  const add = p => {
    if (!exterior[p] && chroma(p) < 40) {
      exterior[p] = 1;
      queue[tail++] = p;
    }
  };
  for (let x = 0; x < w; x++) {add(x); add((h-1)*w+x);}
  for (let y = 0; y < h; y++) {add(y*w); add(y*w+w-1);}
  for (const [x, y] of seeds) add(Math.floor(y*h)*w+Math.floor(x*w));
  while (head < tail) {
    const p = queue[head++], x = p % w, y = Math.floor(p/w);
    if (x) add(p-1);
    if (x+1<w) add(p+1);
    if (y) add(p-w);
    if (y+1<h) add(p+w);
  }
  const result = Buffer.from(data);
  for (let p=0; p<n; p++) {
    if (!exterior[p]) continue;
    const x=p%w, y=Math.floor(p/w), c=chroma(p), i=p*4;
    let nearest=-1, distance=100;
    if (c>=4) {
      for (let dy=-4; dy<=4; dy++) for (let dx=-4; dx<=4; dx++) {
        if (x+dx<0 || x+dx>=w || y+dy<0 || y+dy>=h) continue;
        const q=(y+dy)*w+x+dx, d=dx*dx+dy*dy;
        if (d<distance && !exterior[q] && chroma(q)>=80) {nearest=q; distance=d;}
      }
    }
    result[i+3] = nearest<0 ? 0 : Math.round(255*Math.min(1,c/chroma(nearest)));
    for (let channel=0; channel<3; channel++) result[i+channel] = nearest<0 ? 0 : data[nearest*4+channel];
  }
  return sharp(result, {raw:{width:w,height:h,channels:4}}).png().toBuffer();
}

async function main() {
  const sun = await removeNeutralBackdrop(process.argv[2]);
  const trimmed = await sharp(sun).trim({threshold:8}).png().toBuffer();
  await sharp(trimmed).resize(500,500,{fit:'contain',background:'#00000000'})
    .extend({top:6,bottom:6,left:6,right:6,background:'#00000000'})
    .png().toFile('assets/images/map/gate-sun.png');

  // The arch opening is an enclosed transparent region, so seed it too.
  const arch = await removeNeutralBackdrop(process.argv[3], [[.42,.45]]);
  await sharp(arch).resize(380,300,{fit:'fill'}).png().toFile(`${out}/arch-repair.png`);
  const repair = PNG.sync.read(fs.readFileSync(`${out}/arch-repair.png`));
  // Pin the pre-extraction terrain so reruns cannot accumulate masked edits.
  const terrain = PNG.sync.read(execFileSync('git',['show','1deb2e7:assets/images/map/layers/terrain.png'],{maxBuffer:32*1024*1024}));
  for (let y=34; y<155; y++) for (let x=101; x<220; x++) {
    // Below the diagonal rays, preserve the distant vegetation to either side.
    if (y>=136 && (x<145 || x>176)) continue;
    // Replace alpha as well as color to remove the rays over empty space.
    const mask = Math.min(1,(x-101)/8,(219-x)/8,(y-34)/6,(154-y)/6);
    const i=((y+210)*terrain.width+x+1950)*4, j=(y*repair.width+x)*4;
    const a=terrain.data[i+3]/255, b=repair.data[j+3]/255;
    const alpha=(1-mask)*a+mask*b;
    for (let c=0;c<3;c++) terrain.data[i+c]=alpha ? Math.round(((1-mask)*a*terrain.data[i+c]+mask*b*repair.data[j+c])/alpha) : 0;
    terrain.data[i+3]=Math.round(alpha*255);
  }
  fs.writeFileSync('assets/images/map/layers/terrain.png',PNG.sync.write(terrain));
  await sharp('assets/images/map/layers/terrain.png')
    .extract({left:1950,top:210,width:380,height:300}).png().toFile(`${out}/arch-without-sun.png`);
  console.log('Saved RGBA sun and local terrain repair.');
}
main().catch(error => {console.error(error);process.exitCode=1;});
