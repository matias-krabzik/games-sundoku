# Mapa configurable de SunDoku

## Base compartida

Todos los mundos usan `MapScreen` y `MapParallaxScene`, basados en Valle del Sol. Se retiró `ForestParallaxScene` y el directorio de arte del bosque anterior ya no se incluye en el bundle.

El mundo 1 conserva sus diez posiciones, imágenes, velocidades de parallax, cámara, partículas y sol. El mundo 2 conserva sus 21 juegos, 63 sudokus, progreso y tutorial de anotaciones; usa las seis capas del bosque primaveral con 21 posiciones distribuidas sobre su sendero. Los originales sobre gris se conservan en `design/`; los PNG RGBA preparados están en `assets/images/map/spring-forest/`.

## Archivos

- `lib/models/world_map_definition.dart`: contrato de configuración y distribución sobre el camino.
- `lib/data/valley_map.dart`: capas y valores originales del valle.
- `lib/data/spring_forest_map.dart`: imágenes, márgenes, camino y partículas del segundo mundo.
- `lib/data/world_catalog.dart`: nombres, contenido y mapa de cada mundo.
- `lib/widgets/map_layout.dart`: tamaño del panorama, separación de marcadores y encuadre.
- `lib/widgets/map_parallax_scene.dart`: único renderizador de fondos y movimiento.
- `lib/previews/map_preview.dart`: previews compartidas de 10 y 21 niveles, verticales y horizontales.

## Configurar un fondo

Crear un `WorldMapDefinition`, como dato, y asignarlo al campo `map` del mundo. No crear un widget nuevo.

| Campo | Uso |
| --- | --- |
| `sourceSize` | Dimensiones del panorama original sin márgenes; conserva la relación de aspecto. |
| `path` | Puntos normalizados entre 0 y 1 en orden de recorrido. Admite curvas que vuelven hacia la izquierda. La cámara automática por X se usa solo en rutas horizontales; el bosque usa encuadre manual vertical. |
| `layers` | Cualquier cantidad de capas, cada una con ID único y su asset. |
| `plane` | `background`, `terrain` o `foreground`; el orden de la lista se respeta dentro de cada grupo. |
| `horizontalPadding`, `verticalPadding` | Márgenes simétricos ya pintados en cada PNG, en píxeles de la imagen original. No generan contenido faltante. |
| `motion.scrollFactor` | 1 acompaña al terreno, menos de 1 se desplaza más despacio y más de 1 más rápido. |
| `motion.tilt` | Desplazamiento adicional con sensor o puntero. |
| `motion.cameraFactor` | Cuánto acompaña la capa al movimiento vertical del terreno. |
| `motion.drift`, `driftFrequency` | Amplitud en píxeles y frecuencia en radianes por segundo del movimiento autónomo, por ejemplo de nubes. |
| `camera` | Altura objetivo del camino, intensidad y límite de movimiento vertical. |
| `terrainTilt` | Inclinación compartida por terreno, niveles, estrellas y salida. |
| `ambient` | Opcional: assets de hojas/abejas, flores y copas en coordenadas del panorama, y capa de primer plano a la que pertenecen. Sin este campo no se cargan ni dibujan partículas. |
| `gate` | Opcional: imagen, centro normalizado y diámetro original del botón de salida. |
| `numberAssets` | Ilustraciones numéricas existentes opcionales. Los números sin asset se dibujan con `Text`. |
| `markerSeparation` | Separación visual mínima proporcional al botón; por defecto 1.55. El valle mantiene 1 para conservar su distribución aprobada. |
| `focusLastWhenCompleted` | Al abrir un mundo ya terminado, seleccionar el último nivel; por defecto se conserva la entrada al primero del valle. |

El camino, el puente, sus dos orillas y todo el cauce que deba moverse unido se colocan en una capa `terrain`. Las capas de terreno usan exactamente la transformación de los marcadores; su `motion` adicional se ignora para que los botones no se deslicen fuera del camino.

Un fondo simple puede ser una sola capa `terrain`; no es obligatorio usar seis imágenes. Reducir movimiento desactiva inclinación, profundidad adicional, deriva y partículas conservando el desplazamiento manual.

## Cantidad y posiciones de niveles

La cantidad se deriva de `AdventureWorld.names.length`. Sin posiciones explícitas, `nodesFor` distribuye los niveles a lo largo del camino por distancia, teniendo en cuenta la relación de aspecto. `nodes` permite ubicar cada uno manualmente; debe haber una posición por nombre y números consecutivos desde 1. Valle del Sol usa sus posiciones manuales originales.

Para cambiar el arte del mundo 2, basta asignar su nueva configuración al mismo registro `world-2`. No cambiar IDs, orden ni cantidad de sus juegos al sustituir el paisaje: de ese modo se conserva el progreso existente.

La definición del mapa no crea los sudokus ni sus reglas. Al agregar niveles jugables hay que incorporar también sus puzzles y revisar la compatibilidad de partidas guardadas en el catálogo/repositorio. Los callbacks de introducción, apertura de partidas, navegación y acciones DEV específicas se conectan desde `app.dart`.

## Salida y persistencia

Un mundo sin `gate` no muestra salida ni inicia una revelación. Con `gate`, se desbloquea al completar todos sus niveles; `onNextWorld` define el destino. El registro de revelación es independiente para cada mundo. El mundo 1 conserva la clave histórica `world1GateCelebrated`; los demás usan `worldGate/<id>/celebrated`. Los reseteos DEV limpian la celebración del mundo afectado.

## Preparar el arte del bosque

Las capas de `design/world-2-spring-forest/mountain-panorama-v1/layers-gray/` se exportan con `python3 tool/prepare_spring_forest.py`. Conservan el lienzo de 2172 × 724; foreground recibe un píxel transparente adicional para igualarlo. El gris se convierte en alfa conservando las flores y piedras. Se reservan 120 px laterales y 40 px verticales de la ilustración como margen real; el área lógica es 1932 × 644. No hay espejado ni deformación. El puente y todo el cauce permanecen en terrain. Las velocidades se limitan al margen disponible; para aumentarlas más habrá que ampliar el arte.

La integración del bosque pasó 24 pruebas de mapas, recorrido, notas y progreso, además del análisis estático.

## Verificación

50 pruebas aprobadas: configuración de capas y velocidades distintas, cámara según el camino, 21 niveles y redimensionado, parallax del valle, partículas y sensores, regreso al mapa, revelación del sol y persistencia independiente por mundo, progreso y tutorial de anotaciones. Análisis estático de los archivos afectados sin incidencias. Capturas revisadas del valle en móvil/horizontal y del mapa compartido de 21 niveles en tablet.

El bosque usa ahora el panorama aprobado hasta el pie de la montaña. Los 21 niveles siguen su nuevo sendero, con markerSeparation 2.6. La montaña cercana y el cauce permanecen en terrain; mountains representa solo las sierras distantes.

## Recorrido hasta la cima

El bosque tiene ahora 20 niveles, con posiciones explícitas en springForestNodes: siguen el sendero y sus curvas de subida, con el 20 al final del camino superior. Márgenes de 60 px horizontales y 40 verticales, área lógica 2052 × 644, separación 2.0. En ventanas bajas, allowVerticalPan permite arrastrar arriba/abajo; focusY mantiene visible el nivel seleccionado. Las capas y marcadores comparten ese movimiento también con animaciones reducidas. Las antiguas definiciones y partidas del nivel 21 se conservan en guardados históricos, pero no cuentan para completar el mundo actual.
