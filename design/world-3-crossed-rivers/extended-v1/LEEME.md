# Ríos Cruzados — arte del mapa

Abrí `preview.html` en un navegador para recorrer las 30 posiciones. No necesita servicios externos. En Codex se mostró mediante un servidor HTTP local limitado a esta carpeta.

`panorama.svg` contiene el panorama completo con los PNG incrustados. `layers/` conserva los originales con alfa real en terreno/primer plano; los fondos son opacos. `layout.json` indica cómo colocar y solapar cada plano.

- Lienzo: 8142 × 724 px.
- Área útil: x=60, y=40, ancho=8022, alto=644.
- Cuatro tramos, tres planos por tramo; 18 PNG activos entre capas y correcciones.
- Separación mínima: 270,09 px de origen; al menos tres anchos nominales de botón en el visor.
- Medallones/estrellas reutilizados de SunDoku; números como texto separado.
- Imágenes sin remuestreo; las diferencias de 1–3 px se absorben en solapamientos y recorte del lienzo.
- Transparencia verificada en los 15 PNG RGBA activos de terreno y primer plano, incluida la banda inferior 8–9: ver `review/validation.json`.
- Fondo distante `01-backdrop-v2.png` compartido por los tramos 1 y 3.

Generación y edición: `image_gen` integrado. Se adjuntan prompts de tramos, capas y correcciones. El documento SVG y el visor colocan los PNG sin alterar sus píxeles.

Este paquete es arte y una vista de revisión; no incluye integración con Flutter ni sudokus nuevos. La integración debe respetar los márgenes y las transiciones del manifiesto y comprobar el rendimiento en los dispositivos de destino.


### Revisión 3

`preview.html?level=8`, `?level=16`, `?level=23` y `?level=30` abren la vista centrada en cada zona señalada. La revisión reemplaza el macizo frontal repetido por tres variantes transparentes. El nivel 30 termina ahora en el claro de la cima; el camino queda dentro del lienzo. `review/validation.json` informa las dimensiones, huellas y canales alfa de las capas seleccionadas.


### Revisión 4 · unión 8–9

El visor `preview.html?level=8` muestra la corrección localizada del horizonte de pinos y del césped inferior. La ruta original permanece intacta. `layers/02-backdrop-seam-08-09.svg` conserva el fondo original fuera de la franja de pinos; `layers/foreground-grass-08-09.png` contiene alfa real y queda por debajo del camino. La composición completa está en `panorama.svg` y los detalles de máscara/alfa en `review/validation.json`.


### Revisión 5 · transición sobre el nivel 16

El fondo distante del tramo 02 pierde densidad de pinos de forma gradual antes de la unión con el tramo 03. `preview.html?level=16` muestra esta revisión. La corrección se aplica en una banda del cielo/horizonte lejano; la ruta y las plantas del frente quedan intactas.

### Revisión 6 · primer plano entre los niveles 24 y 27

Se reincorporó el tramo que faltaba de `04-foreground.png` desde x=6250 del panorama. Una entrada gradual de 140 px lo une con la vegetación anterior. El PNG integrado conserva alfa real y el primer plano permanece alineado con el terreno.
