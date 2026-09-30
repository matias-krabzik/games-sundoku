# SunDoku · propuesta de estilo unificado

Propuesta visual del 18 de septiembre de 2026, a partir de las 12 capturas de iPad. No aplicada a la UI.

## Dirección

Conservar Doku, logo, paisajes, medallas e iconos. Unificar las superficies con crema cálido, borde miel continuo, iluminación superior izquierda y relieve suave. Reservar el amarillo intenso para la acción principal y la selección. Azul para acciones secundarias; crema para cerrar o confirmar sin iniciar una partida.

Los PNG de esta carpeta son superficies vacías independientes, no pantallas terminadas. El texto y los controles se componen con widgets reales. Las propuestas no sustituyen automáticamente el catálogo actual.

## Piezas

| Imagen | Uso propuesto |
| --- | --- |
| `panel.png` | Marco común de pausa, ajustes, resumen y práctica completada; altura según contenido |
| `header.png` | Títulos de juego, tutorial y partida rápida; sin chispas laterales |
| `card.png` | Filas de ajustes, dificultades y tarjetas de información |
| `tile.png` | Casillas y teclas neutrales, con relieve más discreto |
| `board.png` | Base del tablero; las 81 casillas se componen encima |
| `footer.png` | Pie del mapa de lado a lado, con relieve únicamente superior |

Reutilizar los botones actuales `home/play-button.png` y `home/blue-button.png`, los controles circulares de `home/header-surfaces.png` y el sol de `map/score-sun.png`.

## Aplicación por pantalla

1. **Home:** conservar logo y Doku. Botones con una misma altura y ancho según contenido; estado del mundo en tarjeta compacta del mismo material crema.
2. **Mapa:** conservar medallas y paisaje. Footer con nombre del camino y marcador de puntos, sin repetir estrellas ni contadores de niveles.
3. **Tutorial:** encabezado sin chispas, indicador de pasos uniforme, explicación ajustada al texto y acción inferior estable. Mantener las explicaciones sobre el tablero real.
4. **Juego:** tablero menos saturado. Casillas neutrales crema, selección dorada, relacionadas con tinte suave. Mantener una sola jerarquía para vidas, puntos, tiempo y pausa; controles de navegación circulares consistentes.
5. **Pausa:** panel compacto, título, mensaje breve y Continuar amarillo. Mismo material y borde que los demás modales.
6. **Ajustes:** panel de altura ajustada, menos espacio entre grupos, filas del mismo estilo que las dificultades. Conservar los controles y acciones existentes.
7. **Resumen de nivel:** nombre y estado, estrellas una sola vez, tabla de tres rondas y total. Eliminar frases que repiten las mismas cifras. Acciones inferiores alineadas; OK pequeño y crema.
8. **Victoria de partida rápida:** resultado compacto con puntos y tiempo destacados. Evitar tabla con una única fila repetida como total. Doku puede acompañar sin separar el título del resultado con un gran vacío.
9. **Partida rápida:** conservar los cinco iconos existentes. Filas de igual altura, selección clara y acciones inferiores; Continuar amarillo y Nueva partida azul.

## Tipografía y composición

- Mantener Baloo para títulos y acciones; cuerpo con peso menor que los títulos.
- Unificar tres jerarquías: título, contenido y contexto secundario.
- Botones y encabezados en una línea, adaptados al ancho; cuerpo con saltos naturales.
- Espaciado coherente en múltiplos de 8, sin alturas vacías forzadas en los modales.
- Una luz, un tipo de sombra y un grosor de bisel por familia de superficies.
- Las superficies adaptables se integrarían mediante `UiSurface` y nine-patch, conservando esquinas y bordes. Iconos y personajes mantienen su proporción.

## Producción

Generación con la herramienta integrada de imágenes. Los prompts completos y las fuentes se conservan en `prompts.json`. La comprobación del canal alfa se registra en `alpha-check.json`. Esta entrega no incluye cambios en Dart ni incorporación al catálogo de producción.
