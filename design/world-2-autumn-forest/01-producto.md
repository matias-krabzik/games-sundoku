# Producto y funcionamiento de las anotaciones

Estado: especificación propuesta. Contexto y decisiones: [README](README.md).

## Acceso y progresión

| Evento | Resultado esperado |
| --- | --- |
| Faltan rondas del mundo 1 | El bosque permanece bloqueado. El sol conserva su estado gris. |
| Se completan las 30 rondas del mundo 1 | Se habilitan partida rápida y acceso al bosque, independientemente uno del otro. |
| Se vuelve al mapa con la revelación pendiente | Primero se muestra la última estrella, después se enfoca el sol y se ejecuta la animación aprobada. |
| Se toca el sol ya habilitado | Se abre el Bosque de Otoño. En la primera entrada comienza el tutorial de anotaciones; si fue interrumpido se retoma. |
| La revelación ya se había visto antes de actualizar | El sol permite entrar directamente; añadir un mundo no repite la celebración. |
| Se completa una ronda del bosque | Se gana una estrella del juego actual. |
| Se completan las tres rondas de un juego | Se desbloquea el siguiente. No se exige una puntuación ni un tiempo mínimo. |
| Se termina el tutorial de entrada | «Practicar» abre el juego 1, con el lápiz disponible en sus tres rondas. |
| Se completa el juego 1 del bosque | Se desbloquean las anotaciones de forma permanente para ese progreso y se anuncia su disponibilidad. |
| Se abre el juego 2 por primera vez | Se continúa jugando con las anotaciones disponibles, sin repetir el tutorial. |
| Se completan las 63 rondas | Se muestra el repaso del bosque. No se ofrece un destino a un mundo 3 inexistente. |

«Completar el primer nivel» significa ganar sus **tres rondas**, no solamente el primer sudoku. Las estrellas representan rondas completadas; los puntos siguen siendo una medida aparte.

El desbloqueo del bosque depende del progreso guardado del mundo 1. El final de la animación solo controla cuándo se habilita visualmente el botón, no si se ha ganado el acceso.

## Navegación

- «Continuar aventura» lleva al último mundo de aventura visitado y disponible. Una partida rápida no cambia ese destino.
- Al entrar por primera vez al bosque se enfoca el juego 1 y se presenta el tutorial. Una vez terminado, no vuelve a abrirse automáticamente. En visitas siguientes se enfoca el juego en curso o el siguiente disponible; si el mundo está completo, se conserva la selección de esa visita.
- El encabezado del mapa ofrece un acceso «Mundos», con un modal de dos opciones: Valle del Sol y Bosque de Otoño. Reutiliza las superficies actuales e indica el requisito del bosque cuando está bloqueado. Permite volver al valle sin recorrer todo el mapa hacia atrás.
- Cambiar de mundo sustituye el mapa actual en la navegación; cambiar varias veces no acumula pantallas de mapas.
- Home, Ajustes y Agenda siguen accesibles. Volver desde un juego retorna al mapa de ese juego; ir al inicio termina en la home.
- Se conserva «Partida rápida» encima de «Aventura» después del mundo 1 y su descubrimiento de una sola vez.
- Un acceso directo a un mundo o nivel bloqueado debe mostrar su requisito y regresar a un destino disponible.

En la interfaz: «Mundo 2 · Bosque de Otoño», «Juego 1» y, debajo con menor tamaño, «Ronda 1 de 3». La numeración es local al mundo. Los identificadores internos distinguen, por ejemplo, `world-1/level-1` de `world-2/level-1`.

## Desbloqueo del lápiz

El recorrido tiene tres momentos claros: **aprender al entrar → practicar en el juego 1 → desbloquear al ganarlo**. Durante el tutorial y las tres rondas del juego 1, el lápiz funciona con permiso de práctica. Todavía no está disponible en el valle ni en partida rápida. El desbloqueo permanente requiere las tres estrellas del juego 1, no completar la explicación ni usar el lápiz un número determinado de veces.

El resumen del juego 1 incorpora una recompensa breve, con icono independiente y texto:

> ¡Anotaciones desbloqueadas! Ya practicaste con tu lápiz. Ahora puedes usarlo cuando quieras, en Aventura y en Partida rápida.

Acciones: «Seguir al juego 2» y «Volver al mapa», usando los botones actuales. El desbloqueo se calcula a partir de la victoria guardada; no depende de leer el mensaje, tocar un botón ni terminar una animación.

Si el jugador sale antes de ver la recompensa, se conserva el aviso pendiente. Se presenta al siguiente momento adecuado dentro del bosque, una sola vez; no interrumpe una partida rápida. El tutorial ya completado no se repite para mostrar esta recompensa.

Antes de entrar al bosque el lápiz no aparece en los controles de juego. Durante el tutorial y el juego 1 aparece con una indicación breve «En práctica». Fuera de esos contextos sigue oculto hasta el desbloqueo permanente. La agenda habilita el repaso al terminar el tutorial; consultar el repaso no concede el desbloqueo.

Tras desbloquearlo, el lápiz se puede usar en el bosque, en las partidas disponibles del valle y en partida rápida. Desaparece la indicación «En práctica». Abrir otro modo no exige repetir el tutorial.

## Contrato de las anotaciones

Una nota es una posibilidad escrita por el jugador. No es una pista fija, una respuesta confirmada ni una afirmación del juego de que ese número sea correcto.

| Acción | Resultado |
| --- | --- |
| Activar el lápiz | Entra en modo anotaciones. Cambian el estado visual y la etiqueta accesible del botón. |
| Tocar un número con una casilla vacía editable seleccionada | Añade esa nota; tocarla otra vez la quita. |
| Seleccionar otra casilla | Mantiene el modo actual. No escribe ni elimina nada. |
| Desactivar el lápiz | Vuelve al modo respuesta. Las notas existentes permanecen. |
| Escribir una respuesta en una casilla con notas | Guarda el número grande y elimina las notas de esa casilla en la misma operación. |
| Borrar una casilla con notas | Elimina sus notas; para quitar solo una, se toca su número con el lápiz activo. |
| Borrar una respuesta | Deja la casilla vacía. No recupera automáticamente notas anteriores. |
| Usar lápiz sobre una pista fija o una respuesta ya escrita | No modifica la casilla. Se indica «Elige una casilla vacía para anotar». |
| Tocar números sin una casilla seleccionada | No modifica el tablero; se invita a elegir una casilla. |
| Pausar, abrir Ajustes o salir | Se guarda el estado confirmado y se bloquea la entrada. Al reanudar se conserva el modo del mismo sudoku. |
| Empezar otro sudoku | Comienza en modo respuesta. No hereda selección ni notas del anterior. |

- Se permiten notas del 1 al 9, sin duplicados. Las posiciones dentro de la casilla son estables: cuadrícula 3 × 3, del 1 arriba a la izquierda al 9 abajo a la derecha.
- La cuadrícula usa dos líneas horizontales y dos verticales, como un «#» pequeño. Aparece en casillas con anotaciones y en la casilla vacía seleccionada mientras el lápiz está activo. Las respuestas grandes conservan su aspecto sin subdivisiones.
- La entrada manual no filtra candidatos consultando la solución. Una nota equivocada no suma errores ni activa una animación de respuesta incorrecta.
- Los nueve botones deben permitir añadir/quitar notas aunque un número ya aparezca completo en el tablero. No reutilizar sin revisar el filtro actual del teclado de respuestas.
- No se rellenan notas automáticamente ni se eliminan en otras casillas al escribir una respuesta. El tutorial enseña a revisarlas.
- Las notas no consumen ayudas, no otorgan puntos, no rompen rachas ni completan filas, bloques, rondas o juegos. Solo los números grandes participan en esas reglas.
- Una nota única no se convierte por sí sola en respuesta.
- El borrado y los cambios de modo no disparan la música de victoria. Se reutilizan los sonidos de controles existentes, respetando Ajustes.
- Las ayudas existentes siguen basándose en los valores del tablero. No deben considerar las notas del jugador como hechos verdaderos.

## Presentación y accesibilidad

- Lápiz en la fila de herramientas, junto a borrar y ayuda. Estado activo visible por forma/contorno y etiqueta, además del color. Reutilizar `UiSurface` y la estética azul/amarilla.
- Cambio aprobado: conservar la composición y las dimensiones actuales de la pantalla. Incorporar solo lápiz, cuadrícula de notas, indicación de estado y lectura ampliada; no sustituir el diseño por la composición completa de la primera maqueta.
- Todas las notas, números de nivel, etiquetas y mensajes se dibujan con `Text` de Flutter.
- Las notas son más pequeñas que la respuesta, con color sólido y contraste sobre la casilla. La casilla seleccionada muestra también una lectura ampliada: «Anotaciones: 2 y 7» en la zona de ayuda del tablero.
- Esa lectura ampliada mantiene un tamaño de texto normal y admite escala de accesibilidad; no depende de poder leer las miniaturas.
- Semántica sugerida: «Fila 4, columna 6, vacía, anotaciones 2 y 7». Una respuesta y una pista fija se anuncian de forma distinta.
- Conservar los límites de `GameLayout`: tablero hasta 430 px, controles numéricos hasta 54 px, borrado hasta 52 px, navegación con márgenes de 16 px y títulos centrados.
- Aplicar `SafeArea`, padding y scroll al contenido central cuando falte altura. Los botones inferiores del tutorial siguen disponibles.

## Final del bosque

Se reutiliza el recap con título personalizado únicamente si el jugador eligió nombre. Texto propuesto:

> ¡Completaste el Bosque de Otoño!
>
> Aprendiste a guardar posibilidades, revisar tus anotaciones y encontrar una respuesta usando filas, columnas y bloques.
>
> Puedes seguir practicando con tu lápiz en Partida rápida.

Acciones de igual tamaño, con los iconos actuales: «Volver al mapa» e «Ir al inicio». En la home, partida rápida sigue disponible; este final no vuelve a marcarla como una función recién desbloqueada.
