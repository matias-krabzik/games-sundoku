# Superficies compartidas de la UI

Los botones de la home usan dos iconos PNG RGBA independientes: `home/adventure-map.png` para Aventura (`HomeGlyph.map`) y `home/quick-play-bolt.png` para Partida rápida (`HomeGlyph.bolt`). `HomeIcon` conserva su proporción con `BoxFit.contain`; estos dibujos no usan nine-patch. El icono de play permanece en `home/icons.png` y sigue siendo el icono predeterminado de `IllustratedActionButton` para el resto de las acciones.

`lib/widgets/ui_surface_art.dart` centraliza las superficies reutilizables. `NineSliceArt` aplica `Image.centerSlice` al recorte del atlas: crecen el centro y los tramos rectos, conservando esquinas y biseles. Los PNG y su transparencia real permanecen intactos; no se generan archivos por botón ni por tamaño.

| Superficie | PNG existente | Usos |
| --- | --- | --- |
| `goldButton` | `home/play-button.png` | Jugar, Vamos paso a paso, Siguiente, Listo y Guardar |
| `blueButton` | `home/blue-button.png` | Acciones secundarias «Aventura» y «Nueva partida», con azul luminoso, borde crema/dorado suave y texto azul oscuro; nine-patch conserva los extremos y el bisel. PNG RGBA con transparencia real, renovado el 23-09-2026 |
| `creamPanel` | `home/status-panel.png` | Estado de la home, tarjetas del mapa, modales y filas de ajustes |
| `goldCreamPanel` | `tutorial/gold-cream-panel.png` | Encabezados, historia e instrucciones del tutorial con el borde dorado de la referencia |
| `goldCreamCard` | `tutorial/gold-cream-panel.png` | Ronda actual en el resumen: comparte el mismo recorte nine-patch del panel y aplica un tinte amarillo suave en Flutter, conservando su alfa |
| `mapProgressPanel` | `map/progress-card-panel.png` | Fondo anterior del mapa, conservado como referencia; el progreso de home y mapas comparte `creamPanel` mediante `HomeArt(HomeSurface.status)` |
| `mapProgressRound` | `map/progress-card-round.png` | Flechas habilitadas de nivel dentro de la tarjeta flotante |
| `mapProgressTrack` | `map/progress-card-track.png` | Pista anterior del mapa, conservada como referencia |
| `mapProgressFill` | `map/progress-card-fill.png` | Relleno anterior del mapa, conservado como referencia |
| `goldTile` | `tutorial/block-tiles.png` | Marco del tablero, casilla seleccionada y botones numéricos |
| `creamTile` | `tutorial/block-tiles.png` | Casillas del tablero real, tanto en el bloque inicial como al expandirse |
| `creamPill` | `home/header-surfaces.png` | Perfil de la home |
| `creamCapsule` | `home/header-surfaces.png` | Botón Ok de los resúmenes; reutiliza el arte circular con centro extensible para conservar extremos redondeados y bisel continuo |
| `creamRound` | `home/header-surfaces.png` | Configuración, regresar, navegación del mapa y controles del tutorial |
| `goldRound` | `map/icons.png` | Cerrar modales y navegación resaltada del mapa |
| `progressTrack` | `home/progress.png` | Base compartida del progreso en home, mapas y bloque del tutorial |
| `progressFill` | `home/progress.png` | Relleno compartido del progreso en home y mapas, y separador del tutorial |
| `adventureRibbon` | `world-selection/aventura-ribbon.png` | Lazo azul y dorado de los destinos, vacío; el nombre se compone con `CurvedRibbonTitle` |
| `adventurePlaque` | `world-selection/aventura-plaque.png` | Placa crema y dorada compartida por los contadores de niveles y estrellas |

Las rutas de la tabla son relativas a `assets/images/`. Las coordenadas de recorte, zonas centrales y tamaños de referencia se definen una sola vez en `UiSurfaceCatalog`. `HomeArt`, `MapRoundSurface`, `SettingsPanelSurface` y `SettingsGoldSurface` delegan a ese catálogo; no mantienen copias de los recortes. La miniatura del mundo 2 es un dibujo independiente, `map/world-2-thumbnail.png`, mientras que el número y el nombre del mundo siguen siendo `Text`.

`UiSurfacePanel` ajusta el panel al contenido real. `IllustratedActionButton` mide la etiqueta para adaptar el ancho y mantener una línea. Los textos siguen siendo widgets `Text`, y los iconos se componen encima de las superficies vacías. Los botones cuadrados mantienen su forma circular al cambiar de tamaño. En rellenos de progreso diminutos, los bordes reducen su escala conjuntamente cuando ya no caben. `mapProgressFill` usa `HorizontalSliceArt` con los recortes del catálogo: conserva el degradado vertical completo y solapa las uniones horizontales para evitar franjas en el renderizado del dispositivo. Si los extremos no caben, solo se comprimen horizontalmente.

Personajes, fondos, logo, iconos, estrellas y medallones son dibujos: conservan su proporción y no usan nine-patch. Interruptores, campos de texto y otros controles dibujados por Flutter ya son adaptables y no necesitan nuevos PNG.

La selección de mundos usa dos paisajes opacos sin texto ni controles, `world-selection/overview-portrait.png` (1024 × 1536) y `overview-landscape.png` (1536 × 1024). Ambos derivan de la propuesta aprobada con el camino ascendente y el río a la derecha. Cada destino compone un emblema independiente (`aventura-crest-sun.png`, `aventura-crest-mountain.png` o `aventura-crest-water.png`), un lazo `adventureRibbon` y dos placas `adventurePlaque`. Los cinco PNG conservan su alfa original. Los emblemas mantienen su proporción; las superficies comparten los recortes del catálogo. El nombre sigue la curva del lazo con widgets `Text`, y los contadores reutilizan los iconos de mapa y estrella. La entrada conserva `IllustratedActionButton`. `WorldOverview` registra destinos, agua y vegetación sobre cada paisaje y mantiene su alineación al cambiar la ventana.

`world-selection/cloud.png` es un elemento independiente RGBA de 2172 × 724 píxeles, con alfa real verificado (rango 0–254), reutilizado en dos nubes móviles. Los fondos y la nube se generaron el 05-10-2026; sus originales son `exec-867b3372-054d-4110-8782-363984e0fe15.png`, `exec-4c4b3530-5dd6-4a1e-b400-9983d7cbce67.png` y `exec-e21b81a9-97d6-45ec-aab5-2653ace09ea5.png`, respectivamente. Los insectos, peces, hojas y pétalos reutilizan el arte y el comportamiento de los mapas existentes. Agua, nubes y criaturas se animan por capas y se suspenden al salir de la pantalla, pausar Playables o activar movimiento reducido.

El resumen infantil de niveles compone el panel `goldCreamPanel`, tres tarjetas (`goldCreamCard` para la actual, `creamTile` para las demás), medallones `goldRound` / `creamRound`, estrellas de `MapIcon` y una franja de totales sobre `creamTile`. Reutiliza `IllustratedActionButton` para Continuar y `creamCapsule` para Ok, uno al lado del otro. Todo número, estado, puntaje y tiempo es un `Text`; no incorpora la maqueta como imagen ni duplica los PNG existentes. El contenido puede desplazarse y las acciones permanecen visibles abajo.

La extracción antigua `settings/done-button.png` se conserva como referencia, pero se excluye del paquete de assets de la aplicación: todas las acciones amarillas reutilizan el botón de la home.

## Validación

El acabado del footer añade un degradado crema y miel, rayos vectoriales de bajo contraste y un bisel dorado superior de 10 px con sombra. La luz oscila en ciclos de 12 segundos y repinta solo su capa; se detiene con movimiento reducido, navegación accesible o `TickerMode` desactivado.

El footer del mapa usa `UiSurface.worldFooter`: recorte central del panel crema existente, sin laterales ni borde inferior, con bisel dorado superior dibujado en Flutter. `UiSurface.blueScoreCapsule` reutiliza el botón dorado con nine-patch e interior azul dibujado en Flutter. El sol es `assets/images/map/score-sun.png`: recorte de 146 × 147 píxeles de la propuesta aprobada (`exec-92cd938a-76f6-4b2d-89cb-508af7c226ed.png`, origen 580,854). Conserva los píxeles RGB originales y añade alfa para aislar la silueta; mantiene su proporción, sin nine-patch. El nombre del nivel y el puntaje son texto real. No se integraron las extracciones generadas que devolvieron un tablero de cuadros opaco en lugar de alfa.

`test/widgets/ui_surface_art_test.dart` compara píxeles de las esquinas al variar el ancho y la altura, comprueba barras vacías y rellenos muy pequeños, y verifica transparencia y silueta de los botones circulares. Las pruebas de navegación, tutorial, perfil, ajustes y tablero cubren sus integraciones. También se revisan capturas renderizadas de home, mapa, bienvenida, perfil y ajustes.

Los controles `goldTile` y `creamTile` menores de 80 px reducen proporcionalmente las esquinas y el bisel; mantienen nine-patch para el eje que necesite crecer. Cuando el tamaño coincide con la referencia se dibuja la textura sin subdividirla, evitando uniones visibles en controles pequeños. Las referencias explícitas del tablero se conservan.
