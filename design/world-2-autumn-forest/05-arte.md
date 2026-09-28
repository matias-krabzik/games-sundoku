# Bosque de Otoño · Arte, mapa y movimiento

Estado: dirección visual para producir después del prototipo funcional. No hay imágenes generadas como parte de estas specs.

## Identidad

Bosque natural y amable, con árboles altos, hojas ocres y rojizas, helechos, raíces, piedras redondeadas, un arroyo y puentes de madera. Luz cálida entre las copas. El estilo sigue siendo la ilustración de SunDoku: formas suaves, materiales con volumen, colores legibles y un ambiente luminoso.

La diferencia con el valle está en el encuadre más recogido, la vegetación vertical y la paleta de otoño. Sin cristales ni elementos minerales mágicos. Las anotaciones se expresan mediante el lápiz, el cuaderno y las acciones del tutorial; no se convierten en números pintados en el paisaje.

Paleta orientativa: ocre, naranja tostado, rojo suave, corteza marrón, verde musgo y azul grisáceo para el agua. Se conserva el azul marino de los textos y el amarillo de las acciones de la aplicación.

## Tres tramos de un recorrido

| Tramo | Juegos | Composición |
| --- | --- | --- |
| Entrada del bosque | 1–7 | Árboles más separados, sendero de tierra, primeras hojas caídas, tronco antiguo y luz de mañana. |
| Arroyo | 8–14 | Curvas del agua, piedras, helechos y un puente. Mayor profundidad entre troncos. |
| Gran claro | 15–21 | Sendero con una leve subida, árboles antiguos, cascada al fondo y un claro cálido como cierre. |

El camino avanza de izquierda a derecha con cambios suaves de altura. Los nodos se colocan después de aprobar la composición; sus centros siguen el suelo y evitan tapar los puntos de interés. El bosque debe sentirse recorrido, no una secuencia de carteles.

## Tamaño y segmentación

Referencia inicial del panorama: **4608 × 768 unidades lógicas**, relación 6:1 frente al 3:1 del valle. Es un punto de partida para distribuir 21 juegos, no el tamaño obligatorio de cada archivo.

Producir una composición maestra y dividirla en segmentos contiguos. Propuesta: tres segmentos de unas 1536 unidades de ancho, con zonas de solapamiento para verificar uniones. Las capas profundas pueden usar menos resolución si la prueba visual lo permite.

- No estirar ni espejar el fondo del valle para alargarlo.
- Mantener continuidad de camino, agua, luz y vegetación en todas las uniones.
- Cargar y precargar segmentos próximos a la cámara, según el desplazamiento propio de cada capa. No decodificar todos los archivos al entrar a la home.
- La extensión final del mapa se ajusta a la separación de los medallones. Si 21 nodos no caben bien en horizontal, se amplía el recorrido en lugar de reducir sus botones.
- Verificar los límites con los medallones, sus estrellas, halo y área táctil completa, especialmente en ventanas bajas.

## Capas propuestas

| Capa | Contenido | Desplazamiento horizontal relativo inicial |
| --- | --- | --- |
| Cielo | Degradado cálido/azul desde Flutter, visible entre copas. | Fondo continuo. |
| Bosque lejano | Siluetas suaves, lomas y cascada distante del último tramo. | 0,30–0,40 del terreno. |
| Vegetación intermedia | Troncos, copas secundarias y orilla lejana. | 0,60–0,70. |
| Terreno | Camino, puente, rocas, bases de árboles y anclajes de niveles. | 1,00; misma transformación que los botones. |
| Primer plano | Ramas laterales, hojas cercanas, helechos y troncos que enmarcan. | 1,08–1,12. |
| Ambiente independiente | Hojas, mariposas y cruces ocasionales de aves. | Movimiento propio y profundidad definida. |

Son valores de partida para el prototipo. El movimiento debe distinguirse al hacer scroll horizontal; las capas lejanas no siguen al frente a igual velocidad. La cámara sigue la altura del camino suavemente y con límites para mantener visible la interacción.

Los márgenes se calculan para el mapa nuevo. Para cada capa contemplar su desplazamiento relativo máximo respecto al terreno, tilt, movimiento de cámara y filtrado. Con parallax centrado, el margen horizontal debe cubrir al menos `|1 − factor| × scrollMáximo / 2`, convertido a unidades de origen, más el desplazamiento del sensor/puntero y un margen de borde. Comprobar ambos extremos. No copiar los 128/512 px del valle sin recalcularlos.

El movimiento del sensor sigue siendo opcional, con origen neutro recalibrado al rotar. En escritorio puede responder al puntero. Sin sensor funcional se mantiene el parallax de scroll.

## Recursos reutilizables

Reutilizar `UiSurface` / `UiSurfaceArt`, `IllustratedActionButton`, paneles de recap, medallones, estrellas, iconos de navegación, sol y arte existente de Doku cuando sea adecuado.

Inventario nuevo mínimo:

- Capas segmentadas del bosque y metadatos de su geometría.
- Icono de lápiz azul, si el inventario actual no ofrece uno adecuado. Su estado activo se compone en Flutter sobre la superficie existente.
- Hoja otoñal para partículas si la hoja existente no encaja. Las variantes de fauna se consideran después de validar el mapa básico.

La recompensa del lápiz se compone con widgets y un recurso individual. No se genera un modal completo, una pantalla, textos, números de nivel ni etiquetas incrustadas.

## Producción y transparencia

Aplicar las [reglas de AGENTS.md](../../AGENTS.md) y la plantilla vigente de [prompts de arte](../first-experience/prompts.md) antes de producir cualquier recurso. Todos los prompts de generación o edición deben incorporar los dos requisitos obligatorios de transparencia y de elementos reutilizables establecidos allí.

Para las capas, el arte solicitado es exclusivamente la capa independiente; las áreas fuera de ella y los huecos entre ramas tienen alfa cero. El cielo de Flutter proporciona el fondo continuo de la composición.

Orden de producción:

1. Composición de referencia del recorrido, sin UI; sirve para acordar encuadre y distribución antes de cortar.
2. Separación por profundidad, conservando el mismo sistema de coordenadas.
3. Reconstrucción de las áreas ocultas detrás del primer plano y de los márgenes necesarios para el parallax.
4. Exportación por capa/segmento, con dimensiones y offset registrados; conservar los originales maestros.
5. Comprobación real de alfa y de bordes sobre fondo claro, oscuro y de contraste. Un tablero de cuadros dibujado no es transparencia.
6. Revisión de la composición dentro de Flutter, moviendo la cámara por todo el recorrido. No basta con abrir cada PNG por separado.

No integrar uniones espejadas, rellenos estirados, halos de recorte o restos de una capa inferior pegados a las hojas.

## Ambiente y audio

Primera entrega ambiental: brisa y hojas otoñales con intensidad moderada. Reutilizar la mecánica de interacción con el espacio libre del mapa. Los rectángulos de protección evitan que hojas u otros elementos tapen medallones, estrellas, navegación y sol.

Después de validar rendimiento: mariposas cerca del arroyo y un cruce ocasional de pájaros. No añadir todas las especies como requisito para que el mapa sea jugable. Los animales visibles no desaparecen por un cambio brusco de opacidad; las recolocaciones suceden fuera de cámara.

Al cubrir el mapa o enviar la app al fondo se detienen animaciones y sensores. Con movimiento reducido se mantienen las capas estáticas, sin tilt, brisa ni animaciones de cámara obligatorias. El scroll manual permanece disponible.

La música final debe ser tranquila y compatible con las licencias del juego. Para el prototipo se usa una pista existente. Sonidos de agua y aves son opcionales posteriores y deben respetar Ajustes → Sonidos, sin desplazar la música al cambiar de pantalla.

## Validación visual y rendimiento

- Capturas de cada tramo en teléfono, tablet, escritorio y horizontal; texto ampliado; estados bloqueado, disponible y completado.
- Desplazamiento completo a ambos extremos y por uniones de segmentos: sin vacíos ni saltos de profundidad.
- Medallones y anclajes del suelo coinciden durante scroll, tilt y resize. Probar especialmente juegos 11–21.
- Objetivo provisional: animación fluida a 60 Hz en el dispositivo físico mínimo elegido para QA; registrar tiempos de cuadros en modo profile y ajustar antes de añadir fauna.
- Presupuesto inicial orientativo: hasta 96 MiB de texturas decodificadas del mapa visibles y precargadas; medir el coste real, no el peso comprimido de los PNG. Reducir resolución de capas lejanas y precarga si se excede.
- Las cifras se calibran con el prototipo y quedan registradas; no constituyen mediciones ya realizadas ni requisitos garantizados por los recursos actuales.
