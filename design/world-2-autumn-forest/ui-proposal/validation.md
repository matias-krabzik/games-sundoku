# Validación de la primera implementación

24 de septiembre de 2026.

## Resultado

- Análisis de los 13 archivos Dart nuevos/modificados de esta entrega: sin diagnósticos.
- 73 casos relevantes aprobados entre repositorio, controladores, nuevas anotaciones, ayudas, tablero, tutorial y diseño móvil; una prueba de escritorio falla también en una copia limpia de HEAD.
- Las nueve pruebas nuevas de anotaciones pasan: cuatro de repositorio, dos de controlador y tres de widgets.
- Hot reload realizado en el simulador iPad Pro 11-inch (M5); consulta posterior sin errores de ejecución.
- Captura móvil revisada con el lápiz, sus checks y la cuadrícula «#». Los archivos `notes-current-*` son capturas del juego real y no arte para integrar.

## Cobertura

Escritura y borrado de notas, notas duplicadas, toques rápidos serializados, validación de valores, protección de respuestas y pistas fijas, escritura de respuesta sobre notas, puntuación y estrellas intactas, fallo de guardado sin publicar cambios, reanudación y estado separado por sudoku. La UI conserva el mismo elemento del tablero al redimensionar y acepta texto ampliado.

## Incidencias anteriores a esta entrega

- `test/desktop_game_layout_test.dart:80`: espera que Volver esté a 24 px del borde superior, pero obtiene 29 px. Se reprodujo exactamente el mismo resultado en una copia temporal del HEAD `286c596`; no se cambió la posición del encabezado para satisfacer esa expectativa.
- El análisis global también encuentra el switch no exhaustivo de `SudokuBoardReveal.givens` en `test/widgets/sudoku_expansion_test.dart:37` y avisos existentes en `device_game_feedback.dart`. No son cambios introducidos por las anotaciones.
- La captura horizontal de tablet conserva el comportamiento actual: tablero móvil de ancho proporcional con desplazamiento vertical. Revisar por separado el límite de tamaño del tablero/controles en tablets; no se rediseñó esa distribución en esta entrega.

## Pendiente de mundo 2

El acceso global y el permiso de práctica todavía deben derivarse del progreso real del bosque. Por ahora la herramienta se prueba desde DEV; `notesEnabled` permite conectarla desde el futuro flujo. El repositorio valida las ediciones de notas pero no decide los desbloqueos de contenido. No se implementaron el tutorial de entrada, sus 63 rondas ni el anuncio del desbloqueo.
