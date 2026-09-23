# Parallax del mapa

El mapa compone seis recursos independientes en `assets/images/map/layers/`.
Todos conservan el panorama central de 2172 × 724. Cielo, nubes y montañas usan 3196 × 980 (512 píxeles de margen horizontal y 128 vertical). Distance usa 3196 × 820 (512 horizontales y 48 verticales). Terrain usa 2428 × 980 (128 por lado). Foreground usa 2428 × 884 (128 horizontales y 80 verticales). Distance y foreground tienen ampliaciones pintadas por IA sin reflejos ni estiramientos.

| Recurso | Contenido |
| --- | --- |
| `sky.png` | Cielo azul sin nubes, opaco, con luz cálida hacia la derecha. |
| `clouds.png` | Nubes extraídas sobre transparencia real. |
| `mountains.png` | Montañas lejanas y valle completo con bosques, lomas y lago, hasta abajo. |
| `distance.png` | Lomas lejanas, pinos, valle, lago y cascada. Incluye la loma de pinos del inicio. |
| `terrain.png` | Corte aprobado del terreno próximo, sus árboles, camino, cerca, puente, arroyo y arco. |
| `foreground.png` | Flores, hojas, arbustos y rocas más cercanas. |

El cielo y las nubes ya no están dibujados en distance. Terrain conserva la parte inferior completa y el corte aprobado en `terrain-cut-no-pine-hill/`. El arte de foreground y terrain se conserva exactamente; solo se amplían sus márgenes exteriores.

La original sigue intacta en `assets/images/world-1-horizontal.png`, SHA-256
`f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f`.

## Fuentes y reproducción

- `ai-v2/`: extracción del primer plano, reparación de su fondo y aplicación de la máscara aprobada. Conserva los prompts originales.
- `foreground-v3/`: continuación de los bordes izquierdo, derecho e inferior pintada con IA; registro y conversión a RGBA conservando el recorte central aprobado.
- `terrain-cut-no-pine-hill/`: máscara y lámina de corte aprobadas.
- `background-v3/`: cielo, nubes, reconstrucción del paisaje posterior, recortes de lomas/montañas, prompts exactos y conversión local a RGBA. Su README detalla los ajustes de alineación y bordes.
- `distance-v4/`: imagen anotada por el usuario, recortes de las franjas superiores y continuidad pintada para ambos laterales y la base. Conserva el centro salvo los recortes señalados.

Con las dependencias de `requirements.txt`, exportar en este orden:

```sh
python3 design/map-parallax/ai-v2/build_assets.py --install
python3 design/map-parallax/foreground-v3/build_assets.py --install
python3 design/map-parallax/background-v3/build_assets.py --install
python3 design/map-parallax/distance-v4/prepare.py
python3 design/map-parallax/distance-v4/build_assets.py --install
```

Sin `--install`, los scripts producen solo salidas de revisión. El exportador de capas posteriores comprueba que no cambia terrain, foreground ni distance; los dos últimos tienen exportadores propios. Los píxeles transparentes se guardan con RGB cero; las anotaciones, los fondos claros/oscuros y los dameros de revisión nunca se incorporan a los PNG del juego.

## Movimiento y validación

`MapParallaxScene` desplaza cada profundidad con scroll e inclinación. Los niveles y luces comparten la transformación de terrain. La cámara sigue el camino; navegación y pie permanecen fuera de la transformación.

El parallax está ligado directamente al scroll horizontal: sky avanza al 55 % de la velocidad del camino, nubes al 60 %, montañas al 65 %, distance al 82 % y foreground al 108 %. Un desplazamiento de 400 píxeles separa las montañas del camino en 140 píxeles. La inclinación añade profundidad, pero el efecto funciona también sin sensor. Las nubes oscilan con amplitud horizontal de 40 píxeles de la imagen original, un ciclo de unos 31 segundos y velocidad máxima de 8 píxeles por segundo (antes 0,5). Su amplitud vertical es de 2 píxeles. La animación y el sensor se detienen al ocultar el mapa, pausar la aplicación o activar movimiento reducido.

`layer_geometry.py` centraliza los márgenes. Foreground y distance emplean exclusivamente las continuaciones de sus exportadores propios, sin reflejos ni píxeles repetidos. Los exportadores conservan el centro aprobado y unen la pintura nueva fuera del recorte; distance además aplica los dos contornos indicados por el usuario. Las otras capas aún usan la prolongación exterior anterior (reflejo horizontal y continuidad vertical; el cielo prolonga su color). Los márgenes cubren el desplazamiento completo, la inclinación y la oscilación de las nubes incluso en vistas estrechas. El renderer conserva la escala original al compensar los márgenes horizontal y vertical de cada capa.

Las pruebas de widgets cubren carga de las seis capas en móvil y tablet, alineación con niveles, scroll, movimiento suave de nubes, visibilidad, sensores, rotación y movimiento reducido. Se revisan alfa y composición con desplazamientos extremos. La composición del cielo y las zonas reconstruidas no se declara idéntica píxel por píxel a la original: son ediciones de IA; los recursos próximos aprobados se conservan exactamente.

El antiguo `extract_layers.py` escribe solo en `legacy-layers/`. El backdrop completo usado durante la transición ya no se dibuja ni se necesita en el bundle.
