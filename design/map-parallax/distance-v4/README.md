# Distance: recortes y continuidad

El recurso final `distance.png` es RGBA de 3196 × 820. El panorama central de
2172 × 724 está en x=512, y=48. La imagen del usuario, con las marcas negras,
se conserva sin modificar en `annotated.png` y nunca se usa como arte del juego.

`prepare.py` obtiene el centro limpio de `../background-v3/distance.png` y
aplica los dos trazos superiores de la anotación: la línea horizontal sobre
las lomas y la curva sobre el lago/cascada. Las áreas por encima de esos trazos
se vuelven transparentes (3933 píxeles antes visibles). Las líneas verticales
identifican las antiguas uniones espejadas; no se interpretan como recortes.
Fuera de las zonas recortadas se conservan exactamente los píxeles centrales.

Se usó la herramienta integrada de imágenes. Los prompts exactos están en
`prompt.md`, `left-prompt.md` y `right-prompt.md`. `landscape-ai.png` aporta la
continuación inferior; los laterales se generaron por separado para mantener
la composición, sin espejos, estiramientos ni duplicación de bordes.

`build_assets.py` elimina el magenta y su contaminación, normaliza la resolución
de las ampliaciones y registra la pintura inferior contra el original. Restaura
el centro completo ya recortado y compensa diferencias de color en una banda
exterior de 32 píxeles. Esa corrección solo afecta zonas opacas: los bordes
suaves transparentes conservan su alfa y no reciben franjas de color.

Los 48 píxeles de reserva vertical superan el desplazamiento máximo de esta
capa (menos de 19 píxeles de la imagen original). Se conserva toda la parte
inferior original; solo se descarta reserva exterior sobrante. Los 512 píxeles
laterales contienen paisaje nuevo y distinto en ambos lados.

```sh
python3 design/map-parallax/distance-v4/prepare.py
python3 design/map-parallax/distance-v4/build_assets.py --install
```

Se verifican dimensiones, alfa real, borde inferior opaco, recortes, registro
del centro y conservación de las otras cinco capas y de la imagen original.
`distance-dark.png` y `distance-light.png` son vistas de control, no recursos del
juego. El exportador anterior ya no puede reinstalar la versión espejada.
