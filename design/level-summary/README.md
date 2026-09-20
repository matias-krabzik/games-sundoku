# Resumen infantil del nivel

Implementación de la propuesta aprobada el 20 de septiembre de 2026, con Continuar y Ok en la misma fila inferior y sin «Volver al mapa».

Las capturas `level-summary-ipad.png` y `level-summary-mobile.png` están renderizadas con los widgets reales de Flutter y datos de prueba: nivel 2, primera ronda en curso, 0 puntos y 2 segundos. No son imágenes generadas ni recursos incorporados a la aplicación.

Se reutilizan las piezas transparentes existentes: panel dorado, tarjetas crema, estrellas, medallones, botón amarillo y botón Ok. La tarjeta activa usa `UiSurface.goldCreamCard`, una variante con tinte amarillo y esquinas compactas del panel compartido. No requiere nuevos PNG ni texto incrustado. El inventario está en `assets/ui-surfaces.md`.

En ventanas bajas y con texto ampliado, el contenido se desplaza manteniendo las acciones accesibles. Los niveles nuevos conservan Jugar y Ok; la práctica completada conserva Volver a jugar; los niveles terminados muestran sus resultados y Ok.

El nivel 1 comparte el encabezado «Valle del Sol · Nivel 1», la tipografía, las estrellas y las superficies del resumen infantil. Conserva su mensaje de práctica directamente sobre el fondo del modal, sin tarjeta interior, y los botones juntos abajo, sin tarjetas de rondas, contador, puntos ni tiempo. El texto se ajusta al ancho y puede desplazarse con accesibilidad ampliada. Las capturas `practice-summary-ipad.png` y `practice-summary-mobile.png` muestran la práctica completada con estos widgets reales.

Para regenerar las capturas y comprobar el modal:

```sh
SUMMARY_CAPTURE_DIR=design/level-summary flutter test test/completed_level_popover_test.dart
```
