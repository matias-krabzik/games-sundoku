# Propuesta visual · Anotaciones

24 de septiembre de 2026. Primera maqueta aprobada con una corrección: agregar una subdivisión «#» dentro de las casillas y conservar la distribución real de la app. La herramienta está implementada para probarla desde DEV; el flujo del mundo 2 todavía está pendiente.

## Implementación sobre el diseño actual

- [Captura móvil con la cuadrícula](notes-current-mobile.png).
- [Validación y pendientes](validation.md).
- Durante una partida, abrir **DEV → Probar anotaciones**. El lápiz aparece entre borrar y ayuda. El permiso de prueba se guarda solo para ese nivel o dificultad rápida y se ignora en compilaciones de producción.
- La superficie amarilla y el check indican que el lápiz está activo. Tocar un número añade o quita su nota; los nueve números siguen disponibles en este modo.
- Se guardan notas, modo y selección por sudoku. Las respuestas grandes reemplazan las notas de su casilla; anotar sobre una respuesta no la borra. Borrar notas no cambia puntos ni rachas.
- No se cambiaron el fondo, el encabezado, el tamaño del tablero ni la distribución existente de los controles. La lectura ampliada usa texto con padding sobre el fondo actual.
- El parámetro `notesEnabled` de la pantalla queda preparado para la futura integración del desbloqueo/práctica. Todavía no existe la conexión al mundo 2 ni su tutorial de entrada.

## Maqueta inicial de referencia

- [Vista móvil · 390 × 844](notes-mobile.png), exportada a 3×.
- [Vista tablet horizontal · 1024 × 768](notes-tablet.png), exportada a 2×.
- [Lápiz azul independiente](pencil-blue.png), PNG RGBA de 1254 × 1254.
- [Prompt del lápiz](prompt.md).

## Qué se propone

El lápiz acompaña al borrador y la ayuda. Su superficie amarilla, marca de selección y etiqueta «Activo» indican que los números del teclado escriben anotaciones. Desactivarlo permite volver a colocar respuestas grandes. Las miniaturas ocupan posiciones fijas en una cuadrícula 3 × 3 dentro de cada casilla; la selección muestra una lectura ampliada para no depender de leer números pequeños.

La imagen corresponde a la práctica del juego 1: el permiso es local y todavía no se ha ganado el desbloqueo permanente. El flujo actualizado es **entrada al mundo → tutorial → tres rondas del juego 1 con anotaciones → anuncio del desbloqueo → uso libre en aventura y partida rápida**.

El texto inferior es un recordatorio propuesto para esa primera práctica, no un mensaje que deba ocupar siempre la pantalla. La indicación «En práctica» desaparece al obtener el desbloqueo permanente.

## Producción y revisión

Se reutilizaron el fondo actual, Baloo 2, superficies del catálogo `UiSurface`, tablero, teclado, barra de estado, navegación, borrador y ayuda. El paisaje de esta maqueta no representa el arte final del Bosque de Otoño. El título y la ronda están centrados; la fila de herramientas alinea los botones por arriba. Las notas de ejemplo corresponden a candidatos legales del tablero mostrado.

Solo el lápiz es arte nuevo generado con IA. La salida original simulaba transparencia con cuadros; se retiró ese fondo localmente y se verificó el canal alfa real y su composición sobre crema. El PNG independiente conserva la transparencia al guardarlo aquí.

Las primeras maquetas se compusieron con widgets existentes y texto real de Flutter mediante un renderizador temporal fuera del código de la aplicación. Los PNG de pantalla son referencias de revisión, no recursos para integrar como pantallas aplanadas. Las capturas `notes-current-*` corresponden a los widgets reales de la app y se exportan desde la prueba de interacción de anotaciones.

La prueba cubre activación desde DEV, escritura, borrado y conservación del mismo tablero al cambiar de tamaño y ampliar texto. El rediseño completo de la maqueta inicial no se integró.
