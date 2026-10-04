# W3-05 · Contador, umbral y estrella

Depende de: [W3-04](04-introduccion.md). Siguiente: [W3-06](06-pruebas-y-entrega.md).

## Objetivo

Mostrar cómo los puntos del sudoku terminado permiten ganar su estrella. Una
barra que se llena y un contador revelan el resultado ya confirmado en W3-02.
No cambiar reglas, guardar desde frames de animación ni añadir un segundo sistema
de recompensas. Una ronda corresponde a una estrella; no hay tres umbrales de
puntaje dentro de un mismo sudoku.

## Secuencia

1. Termina la ronda y se guarda el resultado. Detener reloj y bloquear tablero.
2. Aparece el panel actual adaptado, con estrella de esa ronda apagada, meta
   numérica y marcador de umbral sobre la barra. Las estrellas previas se conservan.
3. Contador de 0 a puntos finales; barra continua y monotónica sincronizada.
   No hay bonus de tiempo: el contador usa los puntos confirmados. Meta y escala
   permanecen fijas; el resultado indica si se agotó el plazo.
4. En el primer frame que alcanza o supera la meta, **solo si el resultado fue
   aprobado**, iluminar la estrella, hacer un pulso corto y reproducir el sonido y
   partículas existentes. La estrella queda encendida al concluir.
5. Al finalizar el conteo, mostrar Continuar para éxito o Reintentar para fallo.
   Al salir al mapa después de la primera o segunda estrella, reconocer el resultado y dejar preparada la siguiente ronda sin iniciar su reloj. El mapa ofrece «Continuar»; al entrar, la ronda nueva ofrece «Jugar». Si ya estaba iniciada, se conserva su tablero y ofrece «Continuar». Los fallos y la tercera estrella conservan «Ver resultado».

La referencia de escala de la barra se fija al entrar al resultado; debe incluir
meta y puntaje final y permitir identificar dónde se cruza el umbral. Propuesta:
usar como techo el mayor entre referencia perfecta y puntos finales. No usar `puntos/meta` saturado como única información si eso impide
mostrar cuánto se superó la meta. Etiquetas fuera de la textura, sin texto dibujado.

Conteo propuesto de aproximadamente 1,2–1,8 segundos, ajustable tras revisión visual;
el tiempo no crece proporcionalmente a miles de puntos. Usar duración finita,
curva suave y pulso breve. No introducir nuevas imágenes o sonidos antes de
comprobar los recursos existentes. Respetar volumen, silencio y movimiento reducido.

## Fallos y casos límite

- Resuelto con puntaje insuficiente: estrella apagada, barra hasta el resultado,
  mensaje «Te faltaron X puntos» y Reintentar.
- Sin tiempo: estrella apagada, «Se acabó el tiempo» y Reintentar, incluso con
  puntaje suficiente. El contador nunca reactiva un reloj vencido.
- Sin vidas: mostrar puntaje obtenido, motivo de fallo y Reintentar. Nunca celebrar
  si los puntos superan la meta pero el tablero no fue aprobado.
- Condición perfecta incumplida: explicar el motivo («Este desafío es sin pistas»
  o «Este desafío requiere terminar sin errores»), aunque supere el umbral.
- Si hay varios motivos, mostrar primero el determinante (vidas, tiempo, tablero, condición
  perfecta, puntaje) y conservar el detalle accesible; no dar un mensaje falso.
- Meta exacta: la estrella se enciende al llegar al valor final.
- Puntaje cero: resultado inmediato/animación breve, sin división por cero.
- Saltar la animación con toque/acción accesible muestra el resultado final;
  ese mismo evento no activa Continuar ni Reintentar. Es la misma convención de
  completar primero y avanzar después de los tutoriales.
- Con movimiento reducido, resultado final inmediato, sin partículas/pulso
  obligatorios ni dependencia del callback de una animación.
- Suspensión, rotación y reanudación no duplican la recompensa ni el sonido. Si se
  reabre un resultado pendiente se puede mostrar completo, con su acción disponible.

## Continuidad visual y accesibilidad

Reutilizar panel crema/dorado, estrellas, barra y botones del catálogo compartido.
Mantener el fondo de la partida. El foco pasa al resumen después de guardar; el
tablero detrás no recibe entradas. Anunciar resultado, meta y acción una vez, sin
leer cada incremento del contador. Soportar teclado, puntero y toque.

La acción inferior permanece en SafeArea. Mantener tamaños de texto y proporciones
de los recursos; probar números largos, tiempos, mensajes de fallo y texto al 200 %.
El resultado no debe empequeñecer la partida que queda detrás ni cambiar el layout
al regresar. La animación de estrellas del mapa puede reflejar el progreso guardado,
pero no crear otro premio ni interferir con esta secuencia.

## Pruebas y aceptación

| ID | Caso | Resultado |
| --- | --- | --- |
| A01 | Resultado aprobado que supera meta | Contador monotónico; una iluminación al cruzar; continúa hasta el puntaje final. |
| A02 | Resultado exactamente igual a meta | Iluminación al final, sin perder el evento por redondeo/frame. |
| A03 | Puntaje inferior a meta | Ningún pulso de estrella ganada; diferencia exacta. |
| A04 | Puntaje alto con fallo por vidas/tiempo/pistas/tablero | Estrella apagada durante toda la secuencia. |
| A05 | Cero puntos y puntajes grandes | Escala estable, textos legibles, duración acotada. |
| A06 | Toque durante conteo y segundo toque | Primer toque termina; segundo ejecuta una sola transición. |
| A07 | Redimensionar, suspender, cerrar/reabrir | Resultado persistente; no duplica premio, sonidos ni navegación. |
| A08 | Movimiento reducido y accesibilidad | Resultado completo y accionable sin depender de animaciones. |
| A09 | Tercera ronda | Una estrella de ronda, luego resumen actual; no capas de victoria simultáneas. |
| A10 | Demostración de tutorial | Misma presentación, ninguna escritura de progreso real. |

Las pruebas de widgets deben avanzar el reloj virtual en momentos significativos
(antes del umbral, cruce, final). No basar toda la comprobación en `pumpAndSettle`
o esperas reales. Las pruebas de dominio de W3-02 siguen siendo la autoridad del premio.

## Cierre

- [x] A01–A10 cubiertos, con video de éxito y fallo en app/widgets reales.
- [x] La lógica funciona igual al omitir por completo la animación.
- [x] No hay celebraciones anticipadas, barras saltando ni doble navegación.
- [x] Aspecto coherente con los resúmenes y recursos existentes.

Implementación, pruebas, videos y alcance: [W3-05](results/README.md).
