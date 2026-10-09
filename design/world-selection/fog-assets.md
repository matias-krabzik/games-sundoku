# Niebla de los destinos — 8 de octubre de 2026

Recursos individuales generados con la herramienta integrada `image_gen`, copiados sin modificar su canal alfa. No se integra ninguna maqueta de pantalla como fondo ni se toman capturas para esta entrega.

| Recurso | Tamaño original | Alfa | Píxeles transparentes |
| --- | --- | --- | --- |
| `assets/images/world-selection/fog-light.png` | 2172 × 724 | 0–253 | 72,1 % |
| `assets/images/world-selection/fog-medium.png` | 2157 × 729 | 0–253 | 52,3 % |
| `assets/images/world-selection/fog-dense.png` | 1774 × 887 | 0–254 | 61,6 % |

Los tres PNG son RGBA: el resto de sus píxeles también tiene alfa parcial, sin un fondo opaco ni un patrón de cuadros pintado. Se inspeccionó el arte generado y se verificaron numéricamente el canal alfa y la copia de los recursos.

## Composición y movimiento

`WorldOverviewScene` dibuja paisaje, agua y criaturas; encima sitúa `WorldOverviewFog`, y finalmente los controles reales de Flutter. La niebla ignora los toques y no agrega elementos de accesibilidad. Tarjetas y medallones bloqueados no se montan. El resto de la UI permanece por encima.

Cada zona utiliza seis bandas con tamaños, fases, densidades y velocidades diferentes. Las piezas se desplazan de izquierda a derecha y se repiten en ambas dimensiones para cubrir la pantalla. Su tamaño y su velocidad se calculan en coordenadas de pantalla, independientes del zoom: solo se acerca el paisaje. Las máscaras suaves siguen las regiones bloqueadas del mapa, por lo que la niebla no invade Valle del Sol ni deja ver los destinos aún bloqueados al desplazar o ampliar el fondo. Los PNG se decodifican una sola vez a 1024 px de ancho y se comparten entre las piezas.

El ambiente y el descubrimiento se detienen al salir de la pantalla, pasar a segundo plano o pausar YouTube Playables. Al regresar continúan sin saltos. Con movimiento reducido, el descubrimiento es inmediato.

La secuencia de descubrimiento dura 1,6 segundos: la cámara se desplaza hacia el nuevo destino, las bandas de niebla ascienden con aceleración y abandonan la pantalla; cuando ya salieron, aparecen el medallón y la tarjeta con entrada vertical, opacidad y un pequeño rebote de escala. No se permite activar el destino durante su aparición. `navigation/worldOverview.revealedWorlds` recuerda las revelaciones terminadas: volver al selector no repite la animación, pero sí muestra una que quedó pendiente. Los guardados anteriores conservan sus destinos ya disponibles.

El selector parte de una cámara acercada (1,8× en vertical y 2,1× en horizontal), con pellizco hasta 4×. Al seleccionar, aumenta suavemente el acercamiento solo si hace falta para centrar realmente el grupo sin mostrar bordes vacíos; no considera centrado un punto detenido por el límite de la imagen. Arrastrar o desplazar con rueda/trackpad mueve el mapa en ambos ejes. La cámara mantiene el punto bajo los dedos al cambiar el zoom, evita bordes vacíos y limita su centro a la región descubierta, dejando visible la frontera con niebla. Los límites se amplían al desbloquear un destino. Paisaje, agua, partículas y puntos comparten las coordenadas del mapa; la niebla conserva su tamaño en pantalla y solo su máscara sigue el área bloqueada. Volver, el título, Ajustes y DEV permanecen fijos.

Tocar la tarjeta o el medallón selecciona y centra su destino, sin abrirlo. Una vez finalizado el centrado aparece debajo el botón amarillo compartido «Ir al destino», con una entrada de 240 ms. Es la única acción que abre el destino. Después de aparecer, el botón conserva su selección al tocar el fondo o explorar el mapa y acompaña a su tarjeta; elegir otro destino cambia la selección. Un toque sin desplazamiento o con un movimiento mínimo del dedo no modifica la cámara. El encuadre reserva espacio para tarjeta y botón, también en horizontal y ventanas bajas.

El desplazamiento táctil termina con una inercia breve (velocidad limitada y frenado exponencial); rueda y trackpad también conservan un pequeño recorrido final. Un nuevo toque detiene la inercia. El primer fotograma, de duración cero, conserva la velocidad en vez de interpretarse como una colisión con el borde. Con movimiento reducido no hay inercia.

Validación sin capturas: pruebas de cámara, límites, zoom, gestos, secuencia de descubrimiento, persistencia, pausa, navegación y adaptación a móvil/tablet/escritorio con texto al 200 %.

El menú DEV del selector completa un destino por pulsación, en orden: Valle del Sol → Bosque de la Cumbre → Ríos Cruzados. Conserva los niveles ya completados, guarda el cambio de forma atómica y genera resultados válidos para los desafíos del tercer destino. No aparece en release.

## Prompts utilizados

Cada generación utilizó el siguiente prompt común y, al final, `Variant: ` seguido de su variante. Se solicitó `transparent_background: true` mediante la herramienta integrada; no se usó la API/CLI de respaldo.

```text
Use case: stylized-concept. Production game sprite for SunDoku's animated fog-of-war. Generate ONE individual, reusable fog bank, isolated with real alpha. NOT a scene or a screen.
Style: delicate ground-level fairytale mist, warm ivory-white highlights, extremely subtle pale cool-blue inner shading, softly illustrated volume, matching the lush polished storybook 3D game. Long irregular feathered wisps with slightly billowing center, asymmetrical natural outline. Mist is genuinely translucent inside as well as fading smoothly to zero alpha outside. Do NOT draw a flat translucent rectangle. Do NOT draw a puffy cumulus cloud with a hard silhouette; no outlines, snow, smoke, dark shading, colored background, scenery, frame, text, UI or glow. All wisps stay fully inside the image with generous completely transparent margins so animation cannot expose hard cut edges.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```

### Ligera

```text
Wide thin low-density ribbon of drifting mist, approximately 3:1 canvas. Faint semitransparent veil, long trailing filaments on both sides, most visible core alpha around 30-45 percent, lots of open transparent air. Delicate stretched S-curve silhouette.
```

### Media

```text
Wide medium-density bank of ground mist, approximately 3:1 canvas. Several connected soft overlapping wisps in ONE connected individual fog bank, core alpha around 55-70 percent, edges dissipating completely. Organic rolling silhouette, modest vertical volume, asymmetrical tapered ends.
```

### Densa

```text
Broad full-bodied but semitransparent dense mist bank, approximately 2:1 canvas, thicker vertical mass than a ribbon. Core alpha around 75-85 percent with real transparent holes and wispy thin edges. A low amorphous rolling mound with long tapered ends, no hard cloud lobes; near-transparent smaller wisps around its base.
```
