# SunDoku · Primera experiencia
Guion y referencias visuales para la primera experiencia.

La secuencia implementada, separada en explicaciones breves para una primera lectura, se describe en [Implementación y validación](implementacion.md). Las láminas de este documento son las referencias originales; los textos finales y los pasos intermedios están en esa secuencia.

## Idea
El sol de la home acompaña a una persona que nunca jugó sudoku. Primero permite experimentar; luego presenta una regla por vez; finalmente reduce la ayuda a lo largo de las tres partidas del nivel 1.

El comienzo es un **bloque de 3×3: nueve casillas**. El tablero completo tiene **9×9: 81 casillas**, repartidas en nueve bloques. El jugador decide dónde coloca cada número del 1 al 9 en el primer bloque, una sola vez cada uno. Al expandirse, ese mismo bloque permanece en el centro y conserva sus números.

Los bloques vecinos contienen los mismos nueve números. Lo que no puede repetirse es un número **dentro de una misma fila, columna o bloque**. Las animaciones mostrarán exactamente las nueve casillas afectadas.

Las imágenes son fotogramas conceptuales estáticos, no capturas de una implementación. Su fondo exterior es transparente para conservar después el entorno actual de SunDoku. Los textos y números de las láminas sirven como referencia de revisión; se componen como elementos dinámicos y accesibles en la UI real.

## Reglas de recursos y composición

- Extraer el arte **por elemento**: superficies de modales, paneles o tarjetas, iconos y personaje como recursos independientes. Cada recurso debe tener transparencia RGBA real fuera del dibujo; las láminas completas no se usan como pantallas de la app.
- Reutilizar primero los botones, tarjetas y paneles existentes de la home, ajustes y mapa. Extraer únicamente el arte que falte, conservando el mismo estilo.
- **Todo texto de UI se construye con `Text` de Flutter**, incluidos títulos, explicaciones, etiquetas de botones, contadores y números variables. Los recursos extraídos se entregan sin texto incrustado. La tipografía, el ajuste de líneas y la escala accesible se resuelven en Flutter.
- Los botones amarillos de acción van siempre abajo, dentro del área segura de la pantalla o al pie del modal correspondiente. El resto del contenido se centra en el espacio disponible por encima. Si hace falta desplazamiento por altura o tamaño de letra, se desplaza el contenido y se conserva la acción en su zona inferior.
- Mantener un único wizard con estado persistente y el tablero real del juego. Las explicaciones, resaltados y celebraciones se presentan sobre ese flujo; el mismo tablero conserva sus casillas, selección y números al cambiar de paso o de distribución.

## 01 · Una invitación breve
**Imagen:** [01-bienvenida.png](01-bienvenida.png)

**Texto del sol:**
> Antes se llamaba Number Place. En 1984, Nikoli lo llevó a Japón. Allí recibió el nombre Sudoku.
>
> No necesitas hacer cuentas.

**Acción:** «Vamos paso a paso».

El sol saluda; aparece su pequeño cuaderno. La historia ocupa una sola tarjeta y puede leerse en unos diez segundos, sin avanzar automáticamente. No introducir biografías, fechas adicionales ni supuestas leyendas antiguas.

El personaje y la tarjeta se centran por encima del botón amarillo «Vamos paso a paso», situado abajo. Reutilizar la tarjeta y el botón existentes; extraer el personaje por separado. El título, la historia y la etiqueta del botón se muestran con `Text`.

Esta síntesis se apoya en el relato del propio editor: el pasatiempo ya se publicaba en una revista estadounidense cuando Nikoli lo presentó en Japón en 1984. [Historia y reglas, Nikoli](https://www.nikoli.co.jp/en/puzzles/sudoku/).

## 02 · Crear un primer bloque
**Imagen:** [02-bloque.png](02-bloque.png)

**Texto:**
> Empecemos con 9 casillas.
>
> Del 1 al 9, una vez cada uno. Elige el orden que quieras.

Se presenta solamente un bloque 3×3 grande y una bandeja con nueve fichas, una por número. Se toca una casilla y luego una ficha. Cada ficha utilizada permanece visible y bloqueada; al borrar su casilla vuelve a habilitarse. Antes de confirmar el bloque puede reorganizarse.

Al colocar una ficha, hace un pequeño rebote y actualiza «1 de 9 colocados», etc. Ningún error cuesta puntos. La lámina captura el último movimiento: falta colocar el 7 abajo a la derecha.

**Ejemplo elegido para las imágenes:**
```text
8 3 5
4 1 6
9 2 7
```

Al completar: «¡Ya tienes tu primer bloque!». Botón amarillo «Ver el tablero», abajo. El orden libre se limita a esta construcción inicial; después las respuestas se deducen de las pistas.

El bloque es una vista centrada del tablero real, con fichas interactivas. Reutilizar las superficies de los controles y de la tarjeta; sus números, instrucciones y contador se componen con `Text`, sin incorporarlos a una imagen del bloque.

## 03 · El tablero se abre
**Imagen:** [03-expansion.png](03-expansion.png)

**Texto:**
> Tu bloque es parte del tablero.
>
> 9 bloques forman el tablero. En cada bloque: del 1 al 9, sin repetir.

El bloque se reduce suavemente manteniendo su centro. En unos 900 ms aparecen los ocho bloques alrededor, en dos tandas suaves. No se cambian ni se reordenan los números que puso el jugador. Las líneas gruesas separan los nueve bloques.

Un contorno dorado recorre el bloque central y después señala brevemente otro bloque vacío para mostrar que la misma regla se aplica a todos.

**Acción:** botón amarillo «Ver las filas», abajo.

La expansión ocurre en el mismo tablero del wizard. El tablero y la tarjeta de explicación permanecen centrados; se reutiliza la tarjeta y su texto se actualiza con `Text`.

## 04 · Mirar una fila
**Imagen:** [04-filas.png](04-filas.png)

**Texto:**
> Una fila cruza todo el tablero.
>
> En cada fila: del 1 al 9, sin repetir. Mira sus nueve casillas.

Se ilumina la fila central, de izquierda a derecha, cruzando los tres bloques. El 1 del centro recibe un contorno. El sol explica: «Este 1 ya está en esta fila. Aquí no puede aparecer otro 1».

El jugador toca cualquier casilla de esa fila para identificarla. Si toca fuera, se repite el recorrido y se invita a volver a probar, sin castigo. No iluminar tres bloques completos ni enseñar restricciones entre bloques como si fueran una regla distinta.

**Acción:** botón amarillo «Ver las columnas», abajo. El resaltado se anima sobre las casillas del tablero real y la explicación usa una tarjeta reutilizada con `Text`.

## 05 · Mirar una columna
**Imagen:** [05-columnas.png](05-columnas.png)

**Texto:**
> Una columna va de arriba abajo.
>
> En cada columna: del 1 al 9, sin repetir.

El brillo horizontal desaparece y se recorre la columna central de arriba abajo. Se conserva el mismo 1 como punto de referencia. El jugador toca una casilla de esa columna.

**Cierre del sol:**
> Bloque, fila y columna: las tres reglas.

Los tres tipos de región se señalan una vez, por separado, sin superponer todos los resaltados. Puede repetirse la explicación.

**Acción:** botón amarillo «Probemos juntos», abajo. Se mantiene la composición centrada y el mismo tablero; solo cambian el resaltado y el texto de la tarjeta reutilizada.

## 06 · Completar juntos el primer sudoku
**Imagen:** [06-primera-partida.png](06-primera-partida.png)

El sol anticipa: «Ahora voy a poner algunas pistas. Tú completarás las que faltan». Los números dados aparecen por bloques durante aproximadamente un segundo. El centro se conserva y el resto del tablero queda con **seis huecos**.

«Ahora busquemos qué número falta». Las pistas dadas se mantienen fijas. La casilla seleccionada y los números que añada el jugador tendrán una distinción visual además del color.

Las ayudas se componen con tarjetas existentes y texto dinámico sobre este mismo tablero. Los iconos necesarios se extraen por separado; no se sustituyen las casillas, explicaciones o controles por una ilustración completa. Cualquier botón amarillo de acción ocupa la zona inferior, con el contenido centrado por encima.

En el ejemplo de las imágenes, filas y columnas se cuentan desde 1:

| Turno | Casilla | Deducción y texto | Ayuda |
|---|---|---|---|
| 1 | F2C3 = 3 | «En esta fila solo falta el 3. Toca la casilla y después el 3». | Iluminar la fila y luego la ficha 3. |
| 2 | F4C1 = 9 | «Ahora mira esta columna: están todos menos el 9. Aquí va un 9». | Recorrer C1 de arriba abajo. |
| 3 | F8C8 = 7 | «Este bloque tiene ocho números. Solo le falta el 7». | Enmarcar el bloque inferior derecho. Su fila y su columna aún tienen dos huecos; el bloque muestra mejor la razón. |
| 4 | F4C8 = 1 | «¡Ahora te toca! ¿Qué número falta en esta fila?». | Señalar la fila sin revelar la respuesta. |
| 5 | F8C5 = 6 | «Busca el número que falta». | Ayuda solo al pedirla. |
| 6 | F1C6 = 3 | «Una casilla más. ¡Ya casi está!». | Dejar actuar al jugador. |

Las tres primeras colocaciones reciben una confirmación ligada al motivo, por ejemplo: «¡Sí! Ahora esta fila tiene del 1 al 9». En las últimas, una confirmación breve basta.

Si se coloca un número incompatible, se señalan las dos casillas relacionadas y se explica: «Ya hay un 5 en esta fila. Miremos qué falta». Evitar responder únicamente «Incorrecto». En estos ejemplos, cada hueco guiado tiene una respuesta deducible de las pistas visibles.

## 07 · Celebrar y continuar
**Imagen:** [07-primer-logro.png](07-primer-logro.png)

**Texto:**
> ¡Tu primer sudoku!
>
> Lo resolviste paso a paso. Vamos a practicar una vez más.

Se revisa visualmente el tablero y se ilumina **una de las tres estrellas** del medallón del nivel 1. El sol hace un pequeño salto. El mensaje indica **1 de 3 completados**, no que terminó el nivel.

**Acción:** botón amarillo «Vamos al segundo», abajo. Abre directamente la segunda partida del nivel 1, sin regresar al mapa.

La celebración se centra sobre el flujo. Si usa un modal, reutilizar su panel y botón; el medallón, las estrellas y el personaje son elementos independientes. El mensaje y el contador se muestran con `Text`.

## 08 · Segunda partida: elegir dónde mirar
**Imagen:** [08-segunda-partida.png](08-segunda-partida.png)

**Texto:**
> Ahora elige dónde empezar.
>
> Busca una fila, columna o bloque casi completo. Si lo necesitas, te doy una pista.

Tablero distinto con **doce huecos**. La primera colocación la elige el jugador. No repetir la historia ni toda la explicación de reglas. El sol ocupa menos espacio.

**Ayuda «Dame una pista», en dos pasos:**
1. «Mira este bloque: está casi completo». Se muestra dónde observar, sin dar la respuesta.
2. «Solo le falta el 8». Se explica la deducción concreta del estado actual.

La ayuda debe responder al tablero tal como está en ese momento, no a un orden rígido de jugadas. En este ejemplo hay nueve casillas con candidato único desde el inicio: existe libertad real para elegir.

Reutilizar la tarjeta de ayuda y mantener sus dos explicaciones como `Text` sobre el tablero real centrado. El botón amarillo «Dame una pista» se sitúa abajo.

Al terminar: «¡Dos sudokus completos!». Se ilumina la segunda estrella y se ofrece el botón amarillo inferior «Vamos al tercero», que abre la siguiente partida directamente.

## 09 · Tercera partida: autonomía acompañada
**Imagen:** [09-tercera-partida.png](09-tercera-partida.png)

**Texto:**
> Este lo empiezas tú.
>
> A tu ritmo. Las tres reglas te acompañan.

Otro tablero con **dieciocho huecos**, todos resolubles mediante deducciones simples. No hay casilla preseleccionada ni respuesta destacada automáticamente. El sol se mantiene pequeño y disponible.

**Ayuda:** «Necesito una pista». Mantiene los mismos dos pasos de la segunda partida. Si hay inactividad prolongada, el sol puede hacer un gesto discreto una vez; no revelar respuestas ni abrir mensajes por sorpresa.

Mantener el botón amarillo de ayuda abajo, el tablero centrado y las tarjetas reutilizadas con `Text`. Esta partida continúa dentro del mismo wizard.

El objetivo es observar y completar, no jugar con prisa. Durante este nivel introductorio, usar ayudas no resta estrellas.

## 10 · Cerrar el nivel
**Imagen:** [10-nivel-completo.png](10-nivel-completo.png)

**Texto:**
> ¡Completaste el nivel 1!
>
> Ya sabes mirar bloques, filas y columnas. Tu aventura acaba de empezar.

Las tres estrellas del medallón se iluminan una por una. El nivel 2 queda desbloqueado. La celebración es breve y el jugador controla cuándo continuar.

**Acción:** botón amarillo «Volver al mapa», abajo. El mapa muestra el nivel 1 con 3/3 y el nivel 2 disponible.

Reutilizar la composición de celebración del paso 07: contenido centrado, panel y botón existentes, arte separado por elemento y mensajes o contadores con `Text`.

## Ritmo y trato al jugador
- Una idea y una acción por paso del wizard; la tarjeta no tapa casillas ni botones necesarios.
- Lectura y avance a voluntad, con la opción de repetir explicaciones.
- Un gesto visual suave indica qué mirar. No usar animaciones permanentes alrededor del tablero.
- Con movimiento reducido, sustituir desplazamientos y rebotes por transiciones de opacidad y contornos estáticos.
- Mostrar texto además del color y acompañar los iconos con nombres claros.
- Sin cuenta regresiva ni pérdida de estrellas por aprender o pedir ayuda en este nivel.
- Mantener el progreso si el jugador sale y ofrecer retomar desde el paso pendiente.
- La primera introducción se presenta al entrar por primera vez; después puede repetirse voluntariamente.

## Coherencia de los tableros
La solución de ejemplo de la partida 1 es:
```text
692783541
783541692
541692783
927835416
835416927
416927835
278354169
354169278
169278354
```

Su tablero inicial de seis huecos (`.` = vacío):
```text
69278.541
78.541692
541692783
.278354.6
835416927
416927835
278354169
3541.92.8
169278354
```

Partida 2, doce huecos y solución diferente:
```text
7.3541.6.
692783451
5416928.3
927835146
...416297
41.927385
278354619
3541697.8
169.785..
```

Partida 3, dieciocho huecos:
```text
2967....1
38.54.692
..5692783
72983541.
53.416927
61.927835
961.78.54
45.16..78
.7.354169
```

Los tres ejemplos fueron comprobados: cada uno tiene una solución y se resuelve usando candidatos únicos, sin adivinar. Las partidas 2 y 3 varían filas o columnas válidas para no repetir la misma solución, conservando el bloque central.

Para respetar cualquier orden inicial del jugador, se hace corresponder cada número del centro de la plantilla con el número que él puso en esa posición. Se aplica esa correspondencia a todos los números del tablero y a las explicaciones. Es un renombrado global: conserva las reglas, la solución única y las deducciones del ejemplo. Los textos «falta el 3», etc., son ejemplos que deberán seguir esa correspondencia.

## Entregables
Diez láminas PNG conceptuales, este guion y el conjunto de prompts. Generadas con la herramienta integrada de imágenes, usando como referencias las capturas de la home y el mapa actuales.

Los archivos de prompts y procedencia se encuentran junto a las láminas. No se modificaron `lib/`, `test/`, la configuración Flutter ni los fondos existentes.
