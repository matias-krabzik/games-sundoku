# Continuidad del primer plano

El recurso final `foreground.png` (2428 × 884 RGBA) conserva exactamente el
recorte aprobado de 2172 × 724 en x=128, y=80. Los márgenes izquierdo, derecho
e inferior son pintura de IA, sin reflejos, mosaicos ni repetición de bordes.

Se usó la herramienta integrada de imágenes. Los prompts exactos están en
`prompt.md`, `left-prompt.md`, `right-prompt.md` y `right-bottom-prompt.md`.
La primera ampliación completa cambió el registro y sirve solo como fuente
para el margen inferior. Los laterales se completaron por separado; el segundo
relleno derecho elimina el corte horizontal que dejó su primera generación.

`build_assets.py` elimina el magenta y sus contaminaciones, registra solo la
pintura nueva con transformaciones de semejanza medidas contra el original y
restaura todos los píxeles del recorte aprobado. En los 32 píxeles exteriores
adyacentes aplica una corrección de color y alfa que decae hacia afuera; conserva
la textura nueva y no clona, refleja ni estira la imagen. El margen vertical
de 80 píxeles cubre con holgura los aproximadamente 32 píxeles máximos de cámara
e inclinación. Se recorta la zona exterior sobrante, sin prolongar filas.

```sh
python3 design/map-parallax/foreground-v3/build_assets.py --install
```

El exportador comprueba registro, alfa, conservación del original y continuidad
opaca del borde inferior. `foreground-dark.png` y `foreground-light.png` son
vistas de revisión; solo `foreground.png` se copia al juego. La imagen original
del mapa no se modifica.
