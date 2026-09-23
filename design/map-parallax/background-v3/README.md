# Capas posteriores: cielo, nubes, montañas y distance

Se produjeron con la herramienta integrada de imágenes, sin CLI/API externo.
Los archivos `*-prompt.md` guardan las instrucciones exactas, incluidas las
correcciones tras recibir un damero pintado. Esas dos salidas se descartaron;
los intermediarios finales usan magenta y se convierten a RGBA.

## Fuentes

- `sky-ai.png`: cielo sin nubes ni paisaje, basado en la iluminación original.
  La salida tenía 2171 × 724; solo este fondo liso se ajusta a 2172 × 724.
- `clouds-chroma.png`: nubes extraídas y prolongaciones de partes antes ocultas.
  `keying.py` elimina magenta y descontamina los bordes.
- `distance-inpaint-guide.png`: terrain marcado para reconstruir lo que oculta.
  `distance-ai-fill.png` aporta esa reconstrucción.
- `repaired-background.png`: montaje del fondo previo y el relleno. Conserva
  el RGB previo fuera de una máscara de reparación con 7 píxeles de margen.
- `distance-chroma.png`: guía de las lomas y pinos sin montañas ni cielo.
- `mountains-chroma.png`: montañas y una base extendida detrás de las lomas.
- `mountains-valley-ai.png`: continuación inferior con lomas verdes, árboles
  lejanos y lago, generada con la herramienta integrada. Sustituye el relleno
  azul anterior. Se conserva la silueta alfa existente y los primeros 24 píxeles
  de pintura bajo cada punto de la cresta; una transición interior de 40 píxeles
  une el valle. El damero dibujado por la IA se excluye por completo del recurso.
  `mountains-valley-prompt.md` guarda el prompt exacto.

## Ajustes locales y exportación

`build_assets.py` mantiene el tamaño y registro comunes. Distance conserva el
RGB de la fuente reparada y ajusta el contorno a la vegetación en una banda
estrecha mediante graph cut. Recupera el valle verde pálido que la IA omitió.

La IA desplazó las montañas 61 píxeles hacia abajo. Se corrige el registro y
se ajusta la máscara al horizonte observado en la fuente. La pintura original
se conserva en las áreas visibles; la IA aporta las zonas antes ocultas.
Las nubes extraídas, las formas reconstruidas y el cielo nuevo no implican
identidad exacta de todos sus píxeles con el panorama original.

Los cuatro PNG base son de 2172 × 724. `--install` añade 512 píxeles a izquierda y derecha y 128 arriba y abajo
y copia cielo, nubes y montañas a `assets/images/map/layers/`:

```sh
python3 design/map-parallax/background-v3/build_assets.py --install
```

Distance se conserva aquí como fuente sin anotaciones; su instalación queda a
cargo de `../distance-v4/build_assets.py`, que aplica los recortes indicados por
el usuario y añade continuidad pintada en lugar de reflejos. Este exportador
nunca sobrescribe ese recurso del juego.

El script comprueba que terrain, foreground y distance permanecen intactos. La original
se verifica por SHA-256. `combined-preview.png` muestra las seis capas juntas;
`distant-scene-preview.png` muestra solo las cuatro posteriores. `*-dark.png`
y `*-light.png` sirven para revisar los bordes sobre fondos de contraste.

Los márgenes se construyen con `../layer_geometry.py`, reutilizando los píxeles
laterales por reflejo y prolongando los superiores/inferiores. Solo se amplía
el área exterior; el panorama de 2172 × 724 permanece registrado e intacto.
