# Vida ambiental del mapa

Se guardó el mapa y su parallax antes de comenzar: commit `c94d69d`.

[Vista animada del mapa en móvil](preview.gif), capturada del renderizado de Flutter. Es una muestra de revisión, no un recurso usado por el juego.

## Primera etapa implementada

- Brisa compartida con períodos tranquilos y ráfagas suaves.
- Hojas con caída, giro y aleteo, distribuidas detrás de los árboles, sobre el terreno y en primer plano. Las cercanas se levantan brevemente de la vegetación antes de caer.
- Dos abejas con alas animadas; vuelan entre las flores de `foreground.png`, se posan y vuelven a salir.
- Un toque en una zona libre produce una ráfaga corta y aleja suavemente a las abejas cercanas. Los niveles, la navegación y los arrastres conservan sus gestos.
- Cada partícula acompaña el scroll y la inclinación de su capa. Las hojas se atenúan alrededor de los niveles para conservar su legibilidad. Las abejas permanecen opacas desde su aparición, también al pasar sobre los niveles; no interceptan los toques.
- Se detiene el reloj al abandonar el mapa, abrir un modal o suspender la aplicación. Con «reducir movimiento» los efectos ambientales se omiten.
- La densidad depende del ancho visible; máximo 18 hojas, 2 abejas y 4 ráfagas locales. Se reutiliza el reloj del parallax y se descarta el dibujo fuera de la pantalla.

No se modificaron las seis imágenes del paisaje en esta etapa. El balanceo de flores recortadas y los efectos del agua quedan como posibles ampliaciones.

## Recursos

Generados con la herramienta integrada de imágenes, usando el arte existente de SunDoku como referencia. Se conserva cada elemento por separado; no hay texto ni pantallas dibujadas.

| Recurso | Referencia | Salida RGBA |
| --- | --- | --- |
| Hoja | `design/map-parallax/ai-v2/foreground-cutout.png` | `assets/images/map/ambient/leaf.png`, 136 × 151 |
| Cuerpo de abeja | `assets/images/world-1-horizontal.png` | `assets/images/map/ambient/bee.png`, 200 × 156 |

Las alas se dibujan y animan por separado en Flutter. Las primeras respuestas de la IA tenían un damero opaco. Se corrigieron mediante una segunda edición sobre magenta uniforme, seguida de eliminación local del fondo y del halo de color. Los PNG finales tienen alfa real, bordes suavizados y margen completamente transparente. El redimensionado usa alfa premultiplicado.

Prompts completos: [hoja](leaf-prompt.md), [abeja](bee-prompt.md), [corrección de fondo de la hoja](leaf-key-prompt.md) y [corrección de fondo de la abeja](bee-key-prompt.md).

Se conservan los originales de las generaciones y los intermedios magenta. `export_sprites.py` reproduce los PNG finales con Pillow, NumPy y OpenCV, reutilizando el conversor de transparencia del mapa.

## Validación

`test/models/map_ambient_motion_test.dart` comprueba población y números finitos durante cinco minutos simulados con scroll y toques, aterrizaje sobre flores, reacción y recuperación tras un toque, coordenadas por capa y continuidad al cambiar el viewport.

`test/widgets/map_parallax_scene_test.dart` comprueba carga del arte, gestos, parallax, sensores, pausa al abrir un modal, suspensión, reducción de movimiento y renderizado en 390 × 844, 1194 × 834 y 844 × 390.

Ejecutar las pruebas relacionadas:

```sh
flutter test --no-pub test/models/map_ambient_motion_test.dart test/widgets/map_parallax_scene_test.dart test/widgets/map_footer_test.dart test/widget_test.dart
```

Para exportar capturas y secuencias animadas de la UI real:

```sh
MAP_CAPTURE_DIR=/tmp/sundoku-ambient MAP_CAPTURE_MOTION=1 flutter test --no-pub test/widgets/map_parallax_scene_test.dart --plain-name 'map renders the separated'
```
