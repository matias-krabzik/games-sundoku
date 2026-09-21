# Superficies compartidas de la UI

`lib/widgets/ui_surface_art.dart` centraliza once superficies obtenidas de siete PNG reutilizables. `NineSliceArt` aplica `Image.centerSlice` al recorte del atlas: crecen el centro y los tramos rectos, conservando esquinas y biseles. Los PNG originales y su transparencia real permanecen intactos; no se generan archivos por botón ni por tamaño.

| Superficie | PNG existente | Usos |
| --- | --- | --- |
| `goldButton` | `home/play-button.png` | Jugar, Vamos paso a paso, Siguiente, Listo y Guardar |
| `blueButton` | `home/blue-button.png` | Acción secundaria «Nueva partida», con texto crema e icono de reinicio; nine-patch conserva los extremos y el borde dorado |
| `creamPanel` | `home/status-panel.png` | Estado de la home, tarjetas del mapa, modales y filas de ajustes |
| `goldCreamPanel` | `tutorial/gold-cream-panel.png` | Encabezados, historia e instrucciones del tutorial con el borde dorado de la referencia |
| `goldCreamCard` | `tutorial/gold-cream-panel.png` | Ronda actual en el resumen: comparte el mismo recorte nine-patch del panel y aplica un tinte amarillo suave en Flutter, conservando su alfa |
| `goldTile` | `tutorial/block-tiles.png` | Marco del tablero, casilla seleccionada y botones numéricos |
| `creamTile` | `tutorial/block-tiles.png` | Casillas del tablero real, tanto en el bloque inicial como al expandirse |
| `creamPill` | `home/header-surfaces.png` | Perfil de la home |
| `creamCapsule` | `home/header-surfaces.png` | Botón Ok de los resúmenes; reutiliza el arte circular con centro extensible para conservar extremos redondeados y bisel continuo |
| `creamRound` | `home/header-surfaces.png` | Configuración, regresar, navegación del mapa y controles del tutorial |
| `goldRound` | `map/icons.png` | Cerrar modales y navegación resaltada del mapa |
| `progressTrack` | `home/progress.png` | Base del progreso en home, mapa y bloque del tutorial |
| `progressFill` | `home/progress.png` | Relleno de progreso y separador del tutorial |

Las rutas de la tabla son relativas a `assets/images/`. Las coordenadas de recorte, zonas centrales y tamaños de referencia se definen una sola vez en `UiSurfaceCatalog`. `HomeArt`, `MapRoundSurface`, `SettingsPanelSurface` y `SettingsGoldSurface` delegan a ese catálogo; no mantienen copias de los recortes.

`UiSurfacePanel` ajusta el panel al contenido real. `IllustratedActionButton` mide la etiqueta para adaptar el ancho y mantener una línea. Los textos siguen siendo widgets `Text`, y los iconos se componen encima de las superficies vacías. Los botones cuadrados mantienen su forma circular al cambiar de tamaño. En rellenos de progreso diminutos, los bordes reducen su escala conjuntamente cuando ya no caben.

Personajes, fondos, logo, iconos, estrellas y medallones son dibujos: conservan su proporción y no usan nine-patch. Interruptores, campos de texto y otros controles dibujados por Flutter ya son adaptables y no necesitan nuevos PNG.

El resumen infantil de niveles compone el panel `goldCreamPanel`, tres tarjetas (`goldCreamCard` para la actual, `creamTile` para las demás), medallones `goldRound` / `creamRound`, estrellas de `MapIcon` y una franja de totales sobre `creamTile`. Reutiliza `IllustratedActionButton` para Continuar y `creamCapsule` para Ok, uno al lado del otro. Todo número, estado, puntaje y tiempo es un `Text`; no incorpora la maqueta como imagen ni duplica los PNG existentes. El contenido puede desplazarse y las acciones permanecen visibles abajo.

La extracción antigua `settings/done-button.png` se conserva como referencia, pero se excluye del paquete de assets de la aplicación: todas las acciones amarillas reutilizan el botón de la home.

## Validación

El acabado del footer añade un degradado crema y miel, rayos vectoriales de bajo contraste y un bisel dorado superior de 10 px con sombra. La luz oscila en ciclos de 12 segundos y repinta solo su capa; se detiene con movimiento reducido, navegación accesible o `TickerMode` desactivado.

El footer del mapa usa `UiSurface.worldFooter`: recorte central del panel crema existente, sin laterales ni borde inferior, con bisel dorado superior dibujado en Flutter. `UiSurface.blueScoreCapsule` reutiliza el botón dorado con nine-patch e interior azul dibujado en Flutter. El sol es `assets/images/map/score-sun.png`: recorte de 146 × 147 píxeles de la propuesta aprobada (`exec-92cd938a-76f6-4b2d-89cb-508af7c226ed.png`, origen 580,854). Conserva los píxeles RGB originales y añade alfa para aislar la silueta; mantiene su proporción, sin nine-patch. El nombre del nivel y el puntaje son texto real. No se integraron las extracciones generadas que devolvieron un tablero de cuadros opaco en lugar de alfa.

`test/widgets/ui_surface_art_test.dart` compara píxeles de las esquinas al variar el ancho y la altura, comprueba barras vacías y rellenos muy pequeños, y verifica transparencia y silueta de los botones circulares. Las pruebas de navegación, tutorial, perfil, ajustes y tablero cubren sus integraciones. También se revisan capturas renderizadas de home, mapa, bienvenida, perfil y ajustes.

Los controles `goldTile` y `creamTile` menores de 80 px reducen proporcionalmente las esquinas y el bisel; mantienen nine-patch para el eje que necesite crecer. Cuando el tamaño coincide con la referencia se dibuja la textura sin subdividirla, evitando uniones visibles en controles pequeños. Las referencias explícitas del tablero se conservan.
