# Imágenes y primera experiencia de SunDoku

- Reutilizar primero el arte existente de la home, ajustes y mapa.
- Todas las generaciones y ediciones de imágenes deben incluir este requisito en el prompt:

  > Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.

- Verificar el canal alfa del PNG final y su apariencia en un visor que respete la transparencia; un patrón de cuadros dibujado no es transparencia. Conservar el alfa al copiar el recurso al proyecto.
- Extraer el arte por elemento: personaje, iconos y superficies de modales, paneles, cards y botones. Cada recurso debe poder componerse por separado en Flutter; no generar ni integrar una pantalla completa como una sola imagen.
- Reutilizar los botones amarillos, cards, paneles y demás recursos existentes antes de generar otros. Los modales se construyen con widgets reales y superficies ilustradas reutilizables.
- Las superficies adaptables usan el catálogo compartido `UiSurface` / `UiSurfaceArt` en `lib/widgets/ui_surface_art.dart`, con recortes nine-patch centralizados por estilo. Reutilizarlo para encabezados, cards, modales, botones de perfil/configuración/regreso y barras de progreso; no duplicar imágenes ni definiciones de recorte por control. Conservar las esquinas, biseles y transparencia. Los controles cuadrados mantienen su silueta circular. Personajes, iconos, medallas y demás dibujos conservan su proporción y no se convierten en nine-patch. Inventario: `assets/ui-surfaces.md`.
- Para las acciones amarillas, reutilizar `IllustratedActionButton`, el mismo componente de «Jugar». Su ancho se adapta al texto y al espacio disponible mediante nine-patch (`NineSliceArt` / `Image.centerSlice`): las esquinas y el grosor del bisel se conservan, y solo se amplían las zonas centrales. Mantener las etiquetas en una línea, sin introducir saltos forzados para encajarlas ni escalar la imagen completa. Aplicar el mismo criterio a nuevas superficies adaptables de cards y modales.
- Todo texto de la UI se escribe con `Text` de Flutter: títulos, instrucciones, etiquetas de botones, estados y valores variables. No incrustar textos ni etiquetas en las imágenes. Las superficies de botones, cards y modales se extraen vacías, sin texto.
- Añadir a todos los prompts de generación y extracción, junto al requisito de transparencia:

  > Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

- Composición del asistente: botones amarillos de acción siempre en la zona inferior, dentro de `SafeArea`; el resto del contenido principal se centra en el espacio disponible encima. Mantener este orden también en horizontal, pantallas pequeñas y texto ampliado. Si hace falta desplazamiento, desplazar el contenido central sin taparlo con las acciones inferiores. Los encabezados y la navegación permanecen en su zona superior.
- Los prompts y láminas antiguos con pantallas enteras o texto dibujado son referencias históricas de diseño. Para producir recursos nuevos se aplican estas reglas y la plantilla vigente de `design/first-experience/prompts.md`.
- La introducción del nivel 1 es un único flujo por pasos. Conserva su estado y el bloque central elegido por el jugador. Las explicaciones de filas y columnas se muestran sobre el tablero real del juego, sin abrir pantallas ilustradas independientes.

# Proyecto responsive

- SunDoku es responsive: usar el espacio disponible de la ventana con `LayoutBuilder` y respetar `SafeArea`, también en horizontal, ventanas pequeñas y texto ampliado.
- En el juego, Volver y Configuración se alinean a los extremos del ancho disponible con margen de 16 px; no quedan dentro del límite del tablero.
- El tablero se centra y se adapta al ancho con un máximo de 430 píxeles lógicos. Los controles no crecen sin límite: números de hasta 54 px por lado (nunca mayores que Volver/Configuración), borrado de 52 px. Mantener estos límites compartidos en `lib/widgets/game_layout.dart`.
- Si falta altura, permitir desplazar el contenido sin ocultar la navegación ni las acciones inferiores del asistente. Conservar el estado del tablero al redimensionar.
