# Paso 2: el primer bloque

La segunda historia usa el fondo existente, el encabezado y el modal dorado de la bienvenida. Muestra un bloque completo como ejemplo, sin exigir colocar números. El editor opcional reutiliza el teclado entre tablero y modal. Doku, los destellos laterales y la flecha son recortes independientes del atlas; conservan su proporción. Las casillas y los botones numéricos usan dos superficies vacías nine-patch del catálogo compartido. Todos los números, títulos, instrucciones y contadores son widgets `Text` de Flutter.

El título del encabezado ocupa todo el ancho interior y queda centrado respecto del panel y de la pantalla. Los destellos tienen 28 píxeles lógicos de ancho y un espacio simétrico de 7 píxeles entre cada dibujo y el panel. El tamaño normal del título se ajusta en una línea; con texto ampliado permite varias líneas centradas. El borrado usa un pincel de limpieza ilustrado sobre el botón circular compartido, sin X ni flecha.

Procedencia, prompt y verificación del recurso: [Pincel de limpieza](tutorial-cleaning-brush.md).

## Comportamiento

- `blockIntroduction` muestra «En un bloque van los números del 1 al 9. Una vez cada uno». El progreso superior marca la historia 2 de 6 y «Siguiente» está disponible desde el principio. El ejemplo completa visualmente los huecos del borrador con los dígitos faltantes y respeta lo que ya eligió el jugador.
- La navegación es manual: botón, toques laterales, deslizamientos horizontales o flechas del teclado; Espacio avanza. No hay temporizador ni ejercicios obligatorios. Al avanzar se guarda el bloque completo y se expande el mismo `SudokuBoard` a 9×9, conservando sus elementos y el orden central. Volver a una historia conserva ese orden.
- «Elegir el orden» abre el editor opcional. Los borradores previos siguen disponibles; una casilla amarilla señala dónde colocar el número. Después de guardarlo se selecciona al azar otra casilla vacía. El jugador también puede elegirla manualmente. Un fallo al guardar conserva la selección y los números anteriores.
- En el editor, el teclado mantiene nueve botones en tres filas de tres. Los dígitos colocados quedan visibles, atenuados y bloqueados; borrarlos los reactiva. El pincel sobre el botón circular compartido permanece a la izquierda del tablero.
- El editor muestra su contador de 0 a 9. Con 9/9 permite expandir el tablero mediante «Siguiente». «Volver a la historia» permite salir antes de completarlo, conservando el borrador. La historia muestra un ejemplo completo sin obligar a rellenar esos huecos manualmente.
- Las historias siguientes explican el tablero, las filas, las columnas y las pistas sobre el tablero real. Solo «Jugar» en la historia 6 crea la sesión. Las partidas mantienen su guía; al terminar las dos primeras se pasa directamente a la siguiente y la tercera lleva al estado final. Secuencia y validación: [Implementación de la primera experiencia](../design/first-experience/implementacion.md).
- En espacios reducidos o con texto ampliado el contenido central se desplaza; el encabezado y la acción inferior conservan sus zonas.

## Recursos y transparencia

Referencia: `/var/folders/pd/jk356v_j78g6gpxz4jgmv6h40000gn/T/codex-clipboard-fabb4260-e897-465b-9d0f-2279f40d411e.png`.

| Recurso final | Tamaño | Alfa mínimo/máximo | Píxeles con alfa 0 |
| --- | --- | --- | --- |
| `assets/images/tutorial/block-tiles.png` | 1774 × 887 | 0 / 255 | 32,36 % |
| `assets/images/tutorial/block-guide-atlas.png` | 1536 × 1024 | 0 / 254 | 63,00 % |

Los archivos RGBA se copiaron sin modificar desde ImageGen. Pillow solo se utilizó para inspeccionar metadatos y alfa. Los primeros resultados RGB se descartaron. Los recortes se definen en `UiSurfaceCatalog` y `TutorialBlockArt`; no hay una imagen por número, tamaño o botón. Los huecos entre los sprites son transparentes de verdad y se comprobaron sobre el fondo de la aplicación.

Salidas finales de ImageGen:

- Casillas: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-b3949060-1734-4c9c-bbf0-8ba716be2390.png`.
- Doku, destellos y flecha: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-ec1b8b8d-3838-42d2-a9ae-70561dc62ab0.png`.

## Prompts usados

Para nuevas generaciones se aplica siempre la plantilla completa de `AGENTS.md` y `design/first-experience/prompts.md`.

### Superficies vacías

```text
Extract ONLY two blank reusable SQUARE tile surfaces from this reference as one simple horizontal 2-column sprite atlas, landscape 2:1 canvas. LEFT tile: the glossy bright yellow gold rounded-square button that carries 7, with thick yellow beveled rim, white highlights, orange lower lip; remove the numeral and arrow entirely. RIGHT tile: one ivory/cream raised rounded-square board cell, with thin warm beige bevel, fine white top highlight; remove its numeral entirely. Both squares front-facing, same 80% cell size, centered in their own equal half of the atlas with generous genuinely transparent space between them. Preserve the exact rounded toy-like style and materials from the reference. Each square has straight sides and rounded corners (~12% corner radius) suitable for nine-patch rendering at other sizes. No board grid, frame, mascot, numbers, icon, letters, shadows beyond a tiny attached lower bevel. These are the reusable pieces requested, not a complete board or screen. Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```

### Dibujos independientes

```text
Extract these THREE independent decorative sprites from this reference as one 2-by-2 square sprite atlas with invisible equal cells and generous transparent gaps. LEFT HALF spanning both rows: the full-body small Doku sun mascot from bottom-left of the reference, same face, blue hoodie, pose, right arm pointing up-right; remove everything else around him, make no changes to his identity. TOP-RIGHT cell: only the cluster of THREE glossy golden teardrop sun rays attached to the right side of the reference header, preserving their fan arrangement; no header. BOTTOM-RIGHT cell: only the blue upward arrow with white outline that points to the selected cell, same thick toy gloss and silhouette. No grid lines, no text, no numbers, no panel, no board, no buttons, no scenery. Each sprite completely isolated and fully visible without overlaps, for proportional runtime cropping. Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```

### Limpieza de alfa de ambos resultados

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork exactly. Real RGBA transparency, zero alpha outside the individual UI artwork and in the gaps, no painted checkerboard. No text or numerals; these will be separate Flutter Text widgets. Reuse existing artwork and keep these sprites independent from the layout.
```

## Verificación

Las pruebas del controlador, del asistente y del tablero verifican historias sin ejercicios obligatorios, navegación manual, vista previa sin sesión, conservación de borradores, edición opcional, reintentos, selección aleatoria de casillas vacías y continuidad al expandir. «Siguiente» está siempre disponible en las historias; el requisito 9/9 se aplica únicamente a la expansión desde el editor. Las pruebas de superficies comparan las esquinas fuera de las zonas estirables.

`TUTORIAL_CAPTURE_DIR` genera capturas del render de Flutter con datos de prueba. Se comprueban tamaños compactos, horizontal y texto al doble, con acción inferior visible y desplazamiento central independiente. Las previsualizaciones del editor, incluido «Bloque · 8 de 9», están en `lib/previews/first_experience_preview.dart`.
