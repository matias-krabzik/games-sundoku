# Bosque primaveral — capas sobre gris, v1

Fuente: `../spring-forest-master-v2.png`.
Generadas con la herramienta integrada imagegen en modo edición. Se conserva el original. No se modificó el código del juego ni se sustituyeron assets activos.

## Orden de composición, de atrás hacia delante

| Archivo | Contenido | Tamaño |
| --- | --- | --- |
| sky.png | Cielo azul limpio, sin nubes; fondo completo opaco | 2172 × 724 |
| clouds.png | Nubes independientes | 2172 × 724 |
| mountains.png | Montañas lejanas y continuación inferior de respaldo | 2172 × 724 |
| distance.png | Bosque lejano reconstruido detrás de árboles y terreno | 2172 × 724 |
| terrain.png | Árboles grandes, árbol rosa, camino, terreno, puente y cauce seco completo | 2172 × 724 |
| foreground.png | Plantas, flores, helechos y rocas decorativas más cercanas | 2171 × 724 |

## Puente y cauce

El puente colgante y todo el cauce seco visible, tanto detrás como delante del puente, pertenecen a `terrain.png`. En el futuro deben compartir la transformación del camino. No separar el puente ni el cauce en elementos con velocidades distintas.

`foreground.png` no incluye arena, piedras del lecho ni taludes del cauce. Sí conserva las plantas que se superponen a su borde. El terreno inferior se reconstruyó para cubrir zonas antes ocultas por esas plantas.

## Estado de los archivos

PNG RGB opacos, sin canal alfa, por pedido expreso. El gris representa las partes excluidas; el cielo es la excepción porque llena todo el lienzo. No se retiró el gris ni se exportaron archivos transparentes.

Son extracciones generativas y reconstrucciones de zonas ocultas, no segmentaciones exactas píxel por píxel. Se revisaron visualmente las seis imágenes y sus metadatos. No se ha validado todavía una composición animada dentro de Flutter.

El gris solicitado fue #808080. Los resultados tienen pequeñas variaciones cerca de ese valor; una futura máscara debe usar tolerancia y conectividad, con revisión de bordes y sin eliminar grises internos de rocas o sombras. No usar una eliminación global indiscriminada por color.

El primer plano tiene un píxel menos de ancho que el lienzo de referencia. Conservar la altura y el registro original al normalizar el lienzo durante la preparación final; no estirar ni espejar el arte.

El bosque lejano incluye una franja gris inferior, pensada para quedar oculta por el terreno. Antes de integrar, comprobar que esa franja y los límites laterales no se descubran con los desplazamientos máximos. Aún no se agregaron márgenes de extensión para scroll o inclinación.

## Prompts

- `prompts.md`: prompts originales de las seis capas.
- `corrections.md`: correcciones seleccionadas de terreno y montañas.
