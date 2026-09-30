# Ríos Cruzados — mapa de 30 niveles

Arte preparado con la herramienta integrada `image_gen`, usando el concepto aprobado y los mundos existentes como referencia. Alcance: 30 posiciones y arte/capas; no se modificó el juego ni se crearon sudokus nuevos.

## Entrega

- [Vista desplazable](extended-v1/preview.html): 30 medallones existentes, modos vertical/horizontal/escritorio, selección de capas y movimiento suave opcional.
- [Panorama completo](extended-v1/panorama.svg): **8142 × 724 px**, documento autocontenido con los PNG incrustados a escala nativa. Sin texto ni indicadores.
- [Distribución](extended-v1/layout.json): posiciones, cuatro tramos, márgenes, capas seleccionadas y transiciones.
- [Capas](extended-v1/layers): fondo, terreno y primer plano por tramo; capas base por tramo, tres correcciones de terreno, tres recursos frontales de unión y una banda transparente de césped para el empalme 8–9.
- [Validación](extended-v1/review/validation.json): dimensiones, canal alfa, huellas y comprobaciones de geometría.

## Espacio entre niveles

Cuatro zonas: entrada del bosque, orillas abiertas, cascadas y lago. La composición mide aproximadamente 3,75 veces el ancho del concepto inicial; se añadió paisaje sin estirar ni repetir el terreno.

La distancia mínima entre centros es **270,09 px de origen**. El visor mantiene tres anchos nominales de botón como mínimo, contando también el medallón, la cinta y las estrellas en la revisión.

- Horizontal, 844 × 390: al menos 164 px entre centros, botones de unos 55 px.
- Vertical, 390 × 640: al menos 268 px entre centros, botones de unos 89 px.
- 30 indicadores, sin superposiciones de sus envolventes; todos los PNG cargados.
- Uniones revisadas entre las zonas. Se corrigieron el brillo del primer fondo y el árbol cortado en la entrada de las cascadas.

## Capas y alfa

Los ocho PNG seleccionados de terreno/primer plano son RGBA, con alfa de 0 a 255 y zonas exteriores realmente transparentes. Los fondos son rectángulos opacos porque incluyen cielo y paisaje distante completos. Se revisaron en un visor que respeta el alfa.

Las salidas nativas varían entre 2169–2172 px de ancho y 724–725 px de alto. Se conservan sin remuestreo: el ensamblado alinea el origen de cada tramo y recorta el excedente del lienzo. No estirar para igualar dimensiones. El manifiesto fija un área útil de 8022 × 644, con origen x=60, y=40.

Las tres capas de cada tramo conservan su registro. El terreno y los indicadores comparten coordenadas. Los solapamientos y las máscaras horizontales están documentados en `layout.json`. El visor muestra movimientos pequeños de 4–5 px; la intensidad y el rendimiento en Flutter se comprobarán al integrar.

El fondo `01-backdrop-v2.png` se reutiliza en los tramos 1 y 3. Las revisiones vigentes están en `layout.json`; las anteriores se conservan aparte.

## Prompts

- Concepto aprobado: `references/approved-concept.png` y su prompt.
- Tramos: `extended-v1/master-prompts.md`.
- Extracciones: `extended-v1/layer-prompts.md`.
- Correcciones: `extended-v1/corrections.md`.

## Alcance

La entrega es arte y distribución. El visor es un documento local de revisión, sin progreso guardado. No añade mundos a la aplicación. La adaptación del ensamblado por tramos al renderizador de Flutter y las partidas de los 30 niveles quedan para la integración.


## Revisión de empalmes

La revisión 3 corrige las plantas repetidas del primer plano con tres recursos distintos en las uniones de los niveles 8–9, 16 y 23. El recorrido de terreno conserva los parches que hacen continuos esos caminos, y el sendero del nivel 30 concluye dentro del lienzo en un claro de la cima. Para revisar cada zona en el visor, abrí `extended-v1/preview.html?level=8`, `?level=16`, `?level=23` o `?level=30`.


### Revisión 4

Se ajustó la franja de pinos lejanos entre los niveles 8 y 9 y se añadió una banda de césped inferior con alfa real. La ruta mantiene exactamente el mismo PNG y su hash se registra en `extended-v1/review/validation.json`. Abrí `extended-v1/preview.html?level=8` para ver el empalme.
