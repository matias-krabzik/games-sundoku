# Superficies compartidas de la UI

`lib/widgets/ui_surface_art.dart` centraliza diez superficies obtenidas de siete PNG reutilizables. `NineSliceArt` aplica `Image.centerSlice` al recorte del atlas: crecen el centro y los tramos rectos, conservando esquinas y biseles. Los PNG originales y su transparencia real permanecen intactos; no se generan archivos por botón ni por tamaño.

| Superficie | PNG existente | Usos |
| --- | --- | --- |
| `goldButton` | `home/play-button.png` | Jugar, Vamos paso a paso, Siguiente, Listo y Guardar |
| `creamPanel` | `home/status-panel.png` | Estado de la home, tarjetas del mapa, modales y filas de ajustes |
| `goldCreamPanel` | `tutorial/gold-cream-panel.png` | Encabezados, historia e instrucciones del tutorial con el borde dorado de la referencia |
| `goldTile` | `tutorial/block-tiles.png` | Marco del tablero, casilla seleccionada y botones numéricos |
| `creamTile` | `tutorial/block-tiles.png` | Casillas del tablero real, tanto en el bloque inicial como al expandirse |
| `creamPill` | `home/header-surfaces.png` | Perfil de la home |
| `creamRound` | `home/header-surfaces.png` | Configuración, regresar, navegación del mapa y controles del tutorial |
| `goldRound` | `map/icons.png` | Cerrar modales y navegación resaltada del mapa |
| `progressTrack` | `home/progress.png` | Base del progreso en home, mapa y bloque del tutorial |
| `progressFill` | `home/progress.png` | Relleno de progreso y separador del tutorial |

Las rutas de la tabla son relativas a `assets/images/`. Las coordenadas de recorte, zonas centrales y tamaños de referencia se definen una sola vez en `UiSurfaceCatalog`. `HomeArt`, `MapRoundSurface`, `SettingsPanelSurface` y `SettingsGoldSurface` delegan a ese catálogo; no mantienen copias de los recortes.

`UiSurfacePanel` ajusta el panel al contenido real. `IllustratedActionButton` mide la etiqueta para adaptar el ancho y mantener una línea. Los textos siguen siendo widgets `Text`, y los iconos se componen encima de las superficies vacías. Los botones cuadrados mantienen su forma circular al cambiar de tamaño. En rellenos de progreso diminutos, los bordes reducen su escala conjuntamente cuando ya no caben.

Personajes, fondos, logo, iconos, estrellas y medallones son dibujos: conservan su proporción y no usan nine-patch. Interruptores, campos de texto y otros controles dibujados por Flutter ya son adaptables y no necesitan nuevos PNG.

La extracción antigua `settings/done-button.png` se conserva como referencia, pero se excluye del paquete de assets de la aplicación: todas las acciones amarillas reutilizan el botón de la home.

## Validación

`test/widgets/ui_surface_art_test.dart` compara píxeles de las esquinas al variar el ancho y la altura, comprueba barras vacías y rellenos muy pequeños, y verifica transparencia y silueta de los botones circulares. Las pruebas de navegación, tutorial, perfil, ajustes y tablero cubren sus integraciones. También se revisan capturas renderizadas de home, mapa, bienvenida, perfil y ajustes.
