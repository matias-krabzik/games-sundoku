# Recursos del bosque

Referencia de estilo: `assets/images/world-1-horizontal.png`. Se generaron tres elementos independientes con ImageGen: arboleda de robles/arces otoñales, vegetación baja de helechos/piedras/raíces, y parche de terreno musgoso con hojas. No se generaron pantallas, botones ni textos.

Los prompts pidieron el volumen ilustrado de SunDoku, iluminación cálida, formas naturales y siluetas completas. Todos incluyeron literalmente:

> Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.

> Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Las exportaciones originales trajeron un fondo gris cuadriculado opaco. Se retiró localmente, según la alternativa autorizada, usando `tool/extract_forest_alpha.cjs`. La máscara es específica del fondo neutro y la paleta cálida de estos recursos. Se revisaron los bordes sobre azul oscuro; las imágenes `*-alpha-review.png` son únicamente pruebas opacas de contraste y **no** se cargan en la app.

| Recurso de producción | Dimensiones | Formato | Píxeles transparentes antes de recortar márgenes |
| --- | --- | --- | --- |
| `assets/images/map/forest/grove.png` | 1507 × 951 | PNG RGBA, alfa real | 728204 |
| `assets/images/map/forest/undergrowth.png` | 2120 × 603 | PNG RGBA, alfa real | 855827 |
| `assets/images/map/forest/ground.png` | 2168 × 361 | PNG RGBA, alfa real | 1034596 |

Originales de generación, conservados en `.codex/generated_images/01a0b5ec-32d9-77c3-889a-5c96a9082082`:

- Arboleda: `exec-acb57e54-0d5c-43fd-a8b7-b3ddf0a355b4.png`.
- Vegetación: `exec-ffccad47-d892-4556-9b6a-86055afd5e80.png`.
- Terreno: `exec-f7a1ee9a-ee1a-438e-92eb-bf04531a7dfe.png`.

La composición de Flutter usa sprites a distintas escalas y posiciones, sin espejar. Camino, puente, cielo, medallones y texto se componen por separado. Las capturas del mapa y tutorial se producen en `test/widgets/forest_world_ui_test.dart` con datos de prueba, sin cambiar el guardado del usuario.
