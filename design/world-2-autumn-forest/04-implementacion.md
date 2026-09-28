# Implementación y compatibilidad del guardado

Estado: diseño técnico, sin cambios de código. Los nombres de componentes nuevos son propuestas; los archivos enlazados describen la base actual.

## Hallazgos del repositorio

| Área actual | Observación | Trabajo necesario |
| --- | --- | --- |
| [level_catalog.dart](../../lib/data/level_catalog.dart) | `mapLevelId` construye IDs del mundo 1 y `initialLevelCatalog` contiene sus diez juegos. | Catálogo de mundos y niveles con identidad completa. |
| [level_progress.dart](../../lib/data/level_progress.dart) | Usa `kMap1Nodes` para límites, desbloqueos, puntos y juego disponible. | Consultas de progreso acotadas a un mundo. |
| [game_repository.dart](../../lib/data/repositories/game_repository.dart) | `startGeneratedLevel` acepta 2–10. El desbloqueo de partida rápida recorre `initialLevelCatalog`. | Inicio por ID y regla explícita de completar el mundo 1. |
| [first_experience_controller.dart](../../lib/controllers/first_experience_controller.dart) | Comparte tutorial, juego normal y partida rápida; limita `levelNumber` a 1–10 y deduce el final desde el catálogo actual. | Contexto del juego separado de las lecciones del valle. |
| [game_session.dart](../../lib/domain/models/game_session.dart) | `CellProgress.notes` ya se serializa, ordena y elimina duplicados. Valores y notas no pueden coexistir. | Reutilizar el formato; añadir reglas de acceso y presentación. |
| [game_session_controller.dart](../../lib/controllers/game_session_controller.dart) | Ya expone `setNotes`, pero la entrada requiere reloj activo. | Permitir entrada guiada con reloj detenido, de forma explícita. |
| [sudoku_board.dart](../../lib/widgets/sudoku_board.dart) | Recibe valores, pistas y resaltados, pero no una colección de notas para dibujar. | Canal de datos y render de anotaciones. |
| [tutorial_journey.dart](../../lib/widgets/tutorial_journey.dart) | Tiene teclado, borrado y ayuda; el borrado solo se habilita si hay un valor. | Botón lápiz, modo de entrada y borrado de notas. |
| [map_screen.dart](../../lib/screens/map_screen.dart), [map_chrome.dart](../../lib/widgets/map_chrome.dart) | Nodos, nombres, largo y textos corresponden al valle. | Configuración del mundo y progreso en encabezado/pie. |
| [map_level_button.dart](../../lib/widgets/map_level_button.dart) | Carga `level-number-N.png`; solo existe el conjunto usado por el valle. | Números mediante `Text`, incluidos 11–21; revisar aspecto del valle. |
| [map_parallax_scene.dart](../../lib/widgets/map_parallax_scene.dart), [map_ambient_motion.dart](../../lib/models/map_ambient_motion.dart) | Capas, 2172 × 724, flores, copas y ruta están fijadas al arte actual. | Geometría, capas y emisores configurables; conservar el perfil del valle. |
| [app.dart](../../lib/app.dart) | Construye un mapa y no conecta `onNextWorld`. | Conectar el sol, seleccionar mundo y conservar rutas de regreso. |
| [save_codec.dart](../../lib/data/services/save_codec.dart), [game_save.dart](../../lib/domain/models/game_save.dart) | Esquema 1 con `levels`, `puzzles`, `sessions`, `progress`, `modules`; el catálogo queda dentro del guardado. | Reconciliación aditiva del contenido al abrir partidas existentes. |

## Modelo de contenido propuesto

| Concepto | Datos mínimos |
| --- | --- |
| `WorldDefinition` | ID estable, nombre visible, orden, lista ordenada de IDs de niveles, requisitos de acceso, recap y referencia al perfil visual. |
| Nivel | `LevelDefinition` existente: ID, worldId, tres puzzleIds, requisitos. Metadatos de título y objetivo asociados por ID. |
| `MapSceneDefinition` | Tamaño lógico del panorama, capas/segmentos, márgenes, factores de profundidad, recorrido, anclajes y emisores. |
| Lección de notas | ID y versión, puzzleId fijo, secuencia de pasos, casillas objetivo y pistas justificativas. |
| Progreso | Se sigue calculando desde `LevelRecord` y las sesiones. No duplicar estrellas en un nuevo contador de mundo. |

Identificadores del bosque: `world-2`, `world-2/level-1` … `world-2/level-21` y `world-2/level-N/sudoku-1` … `sudoku-3`. Los IDs del valle conservan exactamente su forma actual.

El primer nivel del bosque requiere completar los diez niveles del valle. Cada nivel posterior requiere completar el anterior del bosque. Las consultas `worldCompleted`, `notesUnlocked` y `quickPlayUnlocked` son conceptos distintos:

- `worldCompleted(worldId)`: todos los niveles definidos para ese mundo tienen las estrellas requeridas; un mundo inexistente o sin niveles no cuenta como completado.
- `quickPlayUnlocked`: mundo 1 completado, aunque existan más mundos.
- `notesUnlocked`: juego 1 del mundo 2 completado.
- `notesPracticeAllowed(context)`: tutorial de entrada autorizado o sesión del juego 1 del bosque, después de terminar ese tutorial. Habilita uso local antes del desbloqueo permanente; no concede acceso en otros modos.
- `isLastLevel`: posición final dentro del mundo del nivel actual; no búsqueda del siguiente número en el catálogo global.

Añadir el bosque a un catálogo que se recorre con `every` para habilitar partida rápida bloquearía otra vez esa función. Este caso debe quedar cubierto antes de ampliar el catálogo.

## Actualización de partidas existentes

Se propone mantener `GameSave.schemaVersion = 1`: las notas y los campos extensibles ya existen. Introducir una revisión de **contenido** en `modules`, independiente de la versión de formato.

Secuencia de apertura:

1. Leer, decodificar y validar la partida actual con el comportamiento existente.
2. Construir en memoria la reconciliación del catálogo: añadir únicamente definiciones ausentes del bosque y el marcador de revisión correspondiente.
3. Conservar los IDs y definiciones existentes, partidas en curso, valores, notas, seeds, tiempo, errores, puntos, perfil, ajustes y campos desconocidos.
4. Validar el resultado, incluidas referencias y prerrequisitos, y guardarlo mediante la cola de escritura y revisión esperada del repositorio.
5. Publicar el estado nuevo únicamente tras guardarlo. Si falla, conservar la partida anterior y permitir reintentar; no reiniciar el perfil ni marcar la migración como hecha.
6. Abrir otra vez no vuelve a añadir registros, no genera nuevas recompensas y no altera sesiones existentes.

Se agregan definiciones de **niveles**, no 63 tableros completos al cargar la home. Las definiciones de sudoku se materializan al iniciar cada nivel. Si una definición existente entra en conflicto con el catálogo, no sobrescribirla; conservar su contenido guardado y tratar el conflicto explícitamente antes de continuar.

No mover ni renombrar `firstExperience`, `generatedLevel/2` … `generatedLevel/10`, las partidas rápidas ni `world1GateCelebrated`. Un adaptador puede mapear esos módulos del valle al nuevo contexto de juego. La historia archivada no entra en esta actualización.

## Estado adicional propuesto en `modules`

| Clave propuesta | Contenido / regla |
| --- | --- |
| `contentCatalog` | Revisión de contenido incorporada con éxito. No cambia el formato del guardado. |
| `navigation/adventure` | Último worldId disponible visitado; selección por mundo. Sin duplicar `activeSessionId`. |
| `adventure/world-2/level-N` | Enlace a sesión, índice de ronda, comienzo y selección, siguiendo el patrón actual pero sin colisiones con el valle. |
| Estado de UI por puzzleId | Modo respuesta/anotaciones y casilla seleccionada de ese sudoku. Puede integrarse en el módulo del nivel, identificado por puzzleId. |
| `announcements/notes` | Si ya se mostró la recompensa del lápiz. No decide si la herramienta está desbloqueada. |
| `tutorials/notes/v1` | Estado pendiente/en curso/completado, stepId estable, selección, modo y progreso de la copia didáctica `tutorials/notes/v1/example`. No pertenece a una ronda puntuable. |

En cada campo nuevo, ausencia significa el estado inicial seguro. El desbloqueo permanente deriva del progreso. El permiso de práctica depende del contexto y no se guarda como un desbloqueo global. Completar el tutorial, ganar el juego 1 y ver el anuncio son tres estados distintos.

## Juego común y control de lecciones

Pasar a la pantalla un contexto con worldId, levelId, posición visible y número de rondas. Mantener un adaptador para las entradas numéricas del valle mientras se cambia el cableado.

- Reutilizar `GameSessionController` y el repositorio para edición y persistencia.
- Mantener las lecciones iniciales ligadas explícitamente a `world-1/level-1`. Un nivel con número local 1 en otro mundo no debe ejecutar el tutorial de filas y columnas.
- Añadir un controlador específico de la lección de notas que coordine pasos y resaltados. No copiar toda `FirstExperienceController` para crear otra versión de la pantalla.
- Presentar la lección al entrar al bosque si está pendiente o interrumpida. «Practicar» confirma su finalización y abre el juego 1; volver antes conserva el paso. Si falla el inicio del nivel tras guardar la lección, permitir reintentar sin repetirla.
- Separar permiso de entrada de permiso para contabilizar tiempo: juego libre activo y paso interactivo guiado pueden aceptar entradas, pero solo el primero hace correr el reloj.
- El guion usa operaciones verificadas por paso; no utiliza las herramientas DEV para editar una partida real.
- La copia didáctica no participa en puntuación, rachas, ayudas, estrellas ni finalización de niveles. Las colocaciones guiadas no llaman a la ayuda que descuenta puntos. El juego 1 comienza con sus propias definiciones y conserva las reglas normales de puntuación.
- Al cerrar/cubrir la pantalla se cancelan tareas visuales y se guarda la pausa. No deben quedar temporizadores avanzando pasos fuera de la ruta.

## Escrituras de anotaciones

El `setNotes` actual pasa por `_editCell`, que puede sustituir un valor por `null` y recorre la lógica de puntuación. La interfaz por sí sola no basta para proteger ese comportamiento.

La operación de notas deberá:

1. Validar desbloqueo permanente **o permiso de práctica para ese contexto**, sesión/tablero editable y permiso de entrada o de lección. La copia didáctica usa su almacenamiento aislado. Fuera de la práctica autorizada, la operación sigue bloqueada antes de ganar el juego 1.
2. Rechazar pistas fijas y casillas con respuestas escritas; nunca borrar su valor para poder anotar.
3. Validar rango 1–9, quitar duplicados y ordenar; misma colección implica operación sin cambios.
4. Guardar exclusivamente notas y estado de UI pertinente. Mantener puntos, racha, errores, ayudas y estado de finalización.
5. Serializar toques rápidos; no calcular todos los toggles a partir de una copia vieja de la lista.
6. Publicar y avanzar un paso didáctico solamente después de la escritura confirmada.

Escribir una respuesta seguirá eliminando las notas de esa casilla en la misma transacción. No se eliminan notas de otras casillas. Las ayudas usan valores confirmados, no listas de notas como restricciones.

La representación recibe valores y notas por separado. Las notas no entran en contadores de números completos, detección de conflictos de respuestas ni animaciones de victoria. El borrador considera una casilla ocupada si tiene valor o notas.

## Mapa, navegación y presentación

- `MapScreen`, `LevelProgress`, pie, nodos y gate reciben el mundo. El recorrido de cámara recibe sus nodos; no importa `kMap1Nodes` internamente.
- Los números de medallones se dibujan con `Text` y ajustan ancho sin perder la forma del soporte. Comprobar 1, 9, 10, 11 y 21 y las etiquetas accesibles con worldId.
- La escena recibe configuración de capas y tamaño lógico. La de mundo 1 conserva los valores actuales; la del bosque se diseña según [05 · Arte](05-arte.md).
- Conectar el sol del valle a `world-2` solo cuando ese contenido esté disponible. Mantener su revelación de 1,1 s, cambio uniforme, rebote, sonido y marca de una sola vez.
- Parametrizar el recap por mundo, sin felicitar por el valle al terminar el bosque y sin reiniciar el descubrimiento de partida rápida.
- El selector de mundos y las transiciones usan las rutas y componentes ilustrados existentes. El título del juego mantiene el ancho y la alineación actuales.

## Audio

`MusicScene.map` utiliza hoy una pista común. El perfil del mapa debe poder seleccionar una pista por mundo, pasando esa identidad al observador de rutas; cambiar de mapa no debe cortar en seco la música.

Para el prototipo se reutiliza música existente. Una pista nueva requiere registrar fuente, autor y licencia en los créditos antes de distribuirla. No se incorpora ninguna descarga con estas specs. El TODO de reemplazar los sonidos del sol sigue vigente y es independiente del bosque.

## Desarrollo y reinicios

Las herramientas DEV deben aceptar worldId y levelId, sin asumir rangos 1–10 ni borrar módulos por comparar solo el número local.

- Preparar entrada al bosque: completar valle y dejar el bosque sin empezar.
- Preparar recompensa de notas: juego 1 del bosque con dos rondas ganadas y la tercera a una casilla de completarse.
- Preparar tutorial: valle completo, bosque sin empezar, tutorial de entrada pendiente y lápiz sin desbloqueo permanente.
- Preparar práctica: tutorial terminado, juego 1 del bosque en curso y permiso de notas limitado a ese juego.
- Completar mundo menos la última ronda: bosque con 62/63 rondas, último tablero a una casilla.
- Reiniciar tutorial: solo estado didáctico/copia de práctica; no quitar estrellas silenciosamente.
- Reiniciar mundo 2: elimina su progreso dependiente, aviso y tutorial; conserva el valle, partida rápida y su descubrimiento. Las notas se vuelven a bloquear por la regla de progreso.
- Reiniciar mundo 1 completo: requiere una operación DEV explícita que también reinicie los mundos dependientes; no puede dejar el bosque avanzado pero con prerrequisitos inválidos.

Todo control DEV permanece fuera de compilaciones de producción. Conservar las opciones actuales para dejar una ronda a una casilla de completarse.
