// Remove the neutral matte produced by the original warm forest asset exports.
// Usage: node tool/extract_forest_alpha.cjs source.png output.png
// Requires sharp. This is specific to these exports, not a general segmenter.
const sharp = require('sharp');
const [source, output] = process.argv.slice(2);
if (!source || !output) throw new Error('Expected source.png and output.png');
(async () => {
  const {data, info} = await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject: true});
  for (let i = 0; i < data.length; i += 4) {
    const chroma = Math.max(data[i], data[i + 1], data[i + 2]) - Math.min(data[i], data[i + 1], data[i + 2]);
    data[i + 3] = Math.round(Math.max(0, Math.min(1, (chroma - 8) / 16)) * 255);
    if (data[i + 3] === 0) data[i] = data[i + 1] = data[i + 2] = 0;
  }
  await sharp(data, {raw: info}).trim({background: '#00000000', threshold: 1}).png().toFile(output);
})();
