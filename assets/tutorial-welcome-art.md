# Arte de bienvenida del tutorial

Asset final: `assets/images/tutorial/welcome-guide.png`.

Se extrajeron únicamente el sol guía y el cuaderno con la cuadrícula 3×3 vacía del concepto aprobado. Se mantuvieron la pose de saludo, la sudadera azul, el emblema solar, el rostro y los materiales de la referencia. Los títulos, paneles y botón no forman parte de este recurso; la pantalla reutiliza el arte de la home para esos elementos.

El encabezado, la tarjeta de historia, el marco del tablero y los botones usan el [catálogo compartido de superficies nine-patch](ui-surfaces.md). El personaje y los iconos conservan su proporción original.

El ajuste vigente del paso 1 incorpora el marco dorado de la nueva referencia, el regreso exclusivo de desarrollo y la secuencia Doku → historia → tip → botón. Detalles y procedencia del recurso en [Bienvenida animada](tutorial-step1-animation.md).

## Integración de la primera etapa

- Entrada desde el nivel 1 del mapa. Una sola ruta conserva el estado de la introducción.
- Bienvenida breve con historia, guía y botón «Vamos paso a paso». Los textos y controles son widgets accesibles, no texto dentro de una captura.
- Se reutilizan el fondo existente de la home, los paneles y botones ilustrados y el icono de regreso del mapa. Los números del tablero son textos Flutter con relieve y degradado azul.
- El botón abre una breve explicación del bloque, y «Empezar» revela el bloque central 3×3 del componente real `SudokuBoard`. La bienvenida, la explicación y el bloque comparten el mismo tablero montado. Los nueve números elegidos se guardan como borrador al salir y volver.
- El [paso 2](tutorial-step2-art.md) permite completar el bloque y pulsar «Siguiente» para expandir el mismo tablero a 9×9. Las lecciones de filas y columnas y las tres partidas corresponden a las etapas siguientes del mismo flujo; completar el bloque todavía no inicia una partida.
- La regla permanente para pedir transparencia en todas las generaciones está en `AGENTS.md`.

La referencia histórica del texto es [Nikoli: Sudoku](https://www.nikoli.co.jp/en/puzzles/sudoku/).

## Validación

- PNG RGBA, 1375 × 1144 píxeles.
- Alfa mínimo 0 y máximo 255; 43,04 % de píxeles totalmente transparentes.
- Las cuatro esquinas tienen alfa 0.
- Caja significativa (alfa > 10), en píxeles con límite derecho/inferior exclusivo: `(56, 12, 1353, 1120)`.
- Caja significativa normalizada, formato izquierda/arriba/derecha/abajo: `(0.040727, 0.010490, 0.984000, 0.979021)`.
- Región recomendada con margen suave: `(0.038, 0.008, 0.986, 0.982)`.
- No hay texto ni números; se conserva la cuadrícula 3×3 del cuaderno.
- Pillow se usó solo para leer metadatos y medir el alfa, sin reescribir ni editar píxeles. El archivo final se copió sin modificación desde la salida de la herramienta integrada ImageGen.
- La interfaz se verificó con capturas de widgets reales en 390 × 844, 320 × 568 y 844 × 390. También se comprobó texto al doble de tamaño, navegación, continuidad del tablero, guardado del borrador y reintento ante errores de almacenamiento.
- `flutter analyze` sin incidencias; pruebas del controlador, tablero, flujo de bienvenida y regresión del mapa aprobadas.

### Corrección de composición en el teléfono

La bienvenida anterior cambiaba a altura libre al superar una escala de texto de 1,05 y dejaba el botón demasiado arriba. Ahora el encabezado y la acción inferior ocupan zonas fijas dentro de `SafeArea`; solo el personaje, la tarjeta y los mensajes forman el contenido central desplazable. El conjunto se centra cuando cabe y el arte reduce su tamaño en pantallas pequeñas. Con texto muy grande se usan los rótulos breves «Bienvenida» y «Comenzar», manteniendo la escala elegida por el usuario.

La prueba de regresión reproduce el fallo con escala 1,1 y comprueba 16 combinaciones de tamaño/escala: el botón permanece a 12 píxeles lógicos del borde inferior seguro y no se mueve al desplazar el contenido. También se verificó la interfaz mediante captura del moto g75 5G conectado, después de una recarga en caliente, sin errores de ejecución. Se conservaron los recursos RGBA existentes y los textos de Flutter.

La acción inferior reutiliza `IllustratedActionButton`, compartido con «Jugar» de la home. Mide la etiqueta y ajusta el ancho dentro del espacio disponible, manteniendo «Vamos paso a paso» en una línea mediante `Text`. Las referencias de 244 × 78 píxeles lógicos, o 224 × 70 en composición compacta, determinan el tamaño de los bordes; no son una proporción fija para etiquetas más largas.

`NineSliceArt` utiliza [`Image.centerSlice`](https://api.flutter.dev/flutter/widgets/Image/centerSlice.html), el equivalente de Flutter al escalado [Nine-patch de Android](https://developer.android.com/studio/write/draw9patch). Las esquinas y el grosor del bisel se conservan mientras crecen las zonas centrales. El PNG RGBA original no se modifica: el recorte del atlas, los márgenes transparentes y las nueve zonas se resuelven durante el renderizado. Con poco espacio, el texto se ajusta dentro del botón sin deformar su superficie.

## Procedencia

Referencia: `/Users/mati/Projects/Games/SunDoku/sundoku/design/first-experience/01-bienvenida.png`.

1. Extracción inicial (RGB, descartada): `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-d8b76cd3-c0e0-47f5-a752-eee96600d974.png`.
2. Primer pase de limpieza (RGB, descartado): `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-779a6247-a223-434a-a558-31320578da5e.png`.
3. Limpieza final con transparencia real: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-6685576c-fa73-4bf3-abef-0e1bc5cf0677.png`.

## Prompts exactos

Los prompts de abajo son el registro de la extracción ya realizada. Para futuras extracciones se usa la [plantilla vigente](../design/first-experience/prompts.md): un recurso por elemento, superficies de modales/cards/botones sin texto, reutilización del arte existente y todos los textos escritos con `Text` de Flutter. La composición del asistente mantiene las acciones amarillas abajo y el contenido principal centrado.

### Extracción

```text
Use case: background-extraction. Extract ONLY the full-body friendly sun mascot in the navy hoodie together with the ivory ring-bound standing notebook he is holding, from this reference image. Keep the exact character identity, friendly waving pose, face, clothing, 3D toy materials, lighting, gold and navy colors, and notebook shape. Keep the notebook's blank 3 by 3 grid and small decorative sun emblem. Remove the entire header plaque, all text, bottom information plaque, button and every other UI element. Show just the isolated mascot and notebook together, fully visible and centered, large enough to fill the image comfortably with a small clear margin. True transparent background: output genuine RGBA PNG with alpha 0 everywhere outside the mascot and notebook. No checkerboard, no new background, no halo, no scene, no letters or numbers. Preserve clean anti-aliased foreground edges.
```

### Primera limpieza

```text
Remove the background. Keep only the existing foreground artwork, isolated on genuine transparency. All gray and white checkerboard background pixels must have zero alpha, including the gaps around and inside the icons. Preserve shapes, positions, sizes and opaque original colors exactly. Export RGBA PNG with real alpha. No checkerboard. No new background. No glow.
```

### Limpieza final

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork exactly.
```
