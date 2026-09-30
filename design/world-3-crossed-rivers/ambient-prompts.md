# Recursos ambientales de Ríos Cruzados

Generados con la herramienta integrada de ImageGen como ocho PNG RGBA independientes. El arte aprobado del mapa `assets/images/map/crossed-rivers/terrain.png` fue la referencia de color, iluminación, volumen y pincelada. Cada recurso se usa como sprite pequeño sobre el mapa, por lo que debe conservar una silueta clara.

## Indicaciones de cada recurso

- `leaf-round.png`: una sola hoja verde de árbol de copa redondeada, carnosa y suavemente curvada, con verdes lima y oliva y la misma luz cálida del follaje del mapa.
- `leaf-willow.png`: una sola hoja estrecha, alargada y algo caída, verde dorada, correspondiente a los sauces de la orilla.
- `leaf-pine.png`: una sola ramita pequeña de pino, compacta y con agujas verde oscuro, de los pinos de los acantilados.
- `petal.png`: un solo pétalo flotante blanco marfil con leve matiz rosado y centro cálido, como las flores pequeñas junto al río.
- `butterfly.png`: una mariposa pequeña de alas crema y amarillo suave, detalles cálidos discretos y cuerpo oscuro, ilustrada en vista lateral de vuelo.
- `dragonfly.png`: una libélula pequeña turquesa y verde azulado, con alas translúcidas claras y cuerpo fino, ilustrada en vista lateral de vuelo.
- `mayfly.png`: un insecto de agua diminuto y delicado, cuerpo dorado tenue, alas translúcidas y patas finas, visible sobre el agua a escala de mapa.
- `fish.png`: un pez de río pequeño azul turquesa con reflejos dorados, visto de lado, apto para nadar semitransparente bajo la superficie.

En cada generación se agregó literalmente este requisito:

> Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.

> Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Los ocho resultados seleccionados se redujeron a un máximo de 256 px por lado conservando RGBA. Se verificó que los cuatro extremos de cada imagen tienen alfa 0 y que el canal alfa contiene transparencia real entre el contorno y el lienzo.

## Revisión para animación lateral

Se editaron los sprites originales de cada insecto con ImageGen integrado para separar cuerpo y ala. En cada prompt se repitieron literalmente los dos requisitos de transparencia y arte individual de arriba. La composición final de las piezas ocurre en Flutter, con el ala girando y variando su anchura desde su raíz; el cuerpo conserva su forma.

- `butterfly-body-v2.png`: editar `butterfly.png` en cuerpo único de mariposa azul y amarilla, de perfil estricto mirando a la derecha, sin alas; incluir cabeza, antenas, tórax, abdomen y patas pequeñas.
- `butterfly-wing-v2.png`: editar `butterfly.png` como una sola ala azul con marcas crema y amarillas; raíz fina en el extremo inferior derecho para usarla como bisagra.
- `dragonfly-body-v2.png`: editar `dragonfly.png` como cuerpo único de libélula turquesa de perfil mirando a la derecha, con abdomen largo, cabeza y patas, sin alas y sin ojos sobredimensionados.
- `dragonfly-wing-v2.png`: editar `dragonfly.png` como una sola ala estrecha y translúcida de libélula, con raíz a la izquierda y venas delicadas.
- `mayfly-body-v2.png`: editar `mayfly.png` como cuerpo único de insecto dorado de perfil mirando a la derecha, con filamentos de cola y patas finas, sin alas.
- `mayfly-wing-v2.png`: editar `mayfly.png` como una sola ala alta, marfil translúcido, con raíz inferior izquierda y venas doradas finas.

Estas seis piezas se recortaron a su contorno alfa y se redujeron a un máximo de 256 px por lado conservando el canal RGBA. El pez existente se conserva de perfil; Flutter anima su cola por separado.
