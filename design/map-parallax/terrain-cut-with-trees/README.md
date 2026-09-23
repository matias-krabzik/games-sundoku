# Propuesta de corte de terrain con los árboles cercanos

Revisión visual solicitada antes de cambiar las capas activas del mapa.

Se conservan el montecito inicial, el árbol grande de la izquierda y los árboles
cercanos con las lomas donde nacen. También quedan el camino completo, la cerca,
el puente, el arroyo cercano y el arco del sol. Las colinas más profundas,
montañas lejanas y nubes se separarán en las otras capas.

La herramienta integrada de imágenes genera una propuesta sobre magenta siguiendo
`prompt.md`. `build_preview.py` extrae su alfa y lo aplica a los píxeles del terreno
actual en `../ai-v2/terrain-background.png`, sin sustituir los colores por la
reinterpretación generada. Es una propuesta de límite; todavía no es el recurso
de producción ni incluye la reconstrucción de las capas posteriores.

La segunda salida de IA quitó erróneamente parte del suelo inferior. Se corrige
uniendo su máscara con la de `../terrain-cut-proposal/terrain-mask.png`, que ya
conservaba toda esa parte. También se restituye la loma inicial según el contorno
de la original y se recuperan las siluetas vegetales de los cipreses sobre ella.
La base inferior queda completa; los ajustes locales solo modifican el alfa.

- `terrain-proposed.png`: propuesta RGBA con transparencia real.
- `terrain-cutline.png`: límite amarillo sobre el fondo actual; el exterior se oscurece.
- `preview-light.png` y `preview-dark.png`: revisión sobre fondos de contraste.
- `terrain-mask.png`: alfa de la propuesta.
- `terrain-chroma.png`: salida intermedia de IA.

No se modifican los PNG activos en `assets/images/map/layers/` ni la imagen original.
