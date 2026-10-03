# Mundo 3 · Vidas, puntaje y estrellas

Especificaciones de implementación · 03/10/2026.

Estado: **W3-00 registrada; W3-01–03 completadas**. Base: commit `a598639`.
W3-00 cuenta con [referencia técnica y capturas](baseline/README.md). D06 quedó
resuelta: límite de tiempo activo para ganar la estrella, sin bonus de rapidez.
W3-03 activa en la app las sesiones nuevas del mundo 3 con resultado estático,
reintento y cuenta regresiva. Las sesiones heredadas conservan sus reglas.
[Evidencia visible y validaciones](gameplay/README.md). W3-04–06 siguen pendientes.
Estas especificaciones incorporan las últimas correcciones del usuario; reemplazan
la propuesta anterior de exigir una partida perfecta en todos los niveles 21–30.

## Resultado esperado

Ríos Cruzados conserva sus 30 niveles, tres sudokus por nivel y una estrella por
sudoku aprobado. Resolver el tablero deja de ser suficiente: también debe
alcanzarse su meta de puntos con vidas disponibles antes del límite de tiempo. La meta se acerca al puntaje
perfecto nivel a nivel; **solo el nivel 30 exige expresamente cero errores y cero
pistas**. Al terminar cada ronda, un contador llena una barra hacia la estrella.

| Niveles | Vidas por sudoku | Condición de puntaje |
| --- | ---: | --- |
| 1–10 | 3 | Margen inicial amplio, que disminuye gradualmente. |
| 11–20 | 2 | Margen progresivamente menor. |
| 21–29 | 1 | Margen muy ajustado, todavía menor que el puntaje perfecto. |
| 30 | 1 | Puntaje perfecto, cero errores y cero pistas. |

Con una vida, un error ya termina el intento desde el nivel 21. Antes del 30, las
pistas no tienen una prohibición adicional: se puede utilizarlas, pero su costo
puede impedir alcanzar la meta. Las anotaciones no cuentan como pistas.

Las vidas se renuevan al iniciar cada sudoku o reintentar esa ronda. Las rondas
aprobadas y las estrellas obtenidas se conservan. Las reglas previas de mundos 1
y 2, partida rápida y tutoriales anteriores se mantienen.

## Lectura y ejecución en orden

| Etapa | Especificación | Depende de | Salida verificable |
| --- | --- | --- | --- |
| W3-00 | [Base, alcance y decisiones](00-base-y-decisiones.md) | — | Referencias actuales registradas; política del tiempo identificada. |
| W3-01 | [Reglas y calibración](01-reglas-y-calibracion.md) | W3-00 | Reglas versionadas y metas alcanzables verificadas en varios perfiles. |
| W3-02 | [Estado, guardado y reintentos](02-estado-y-guardado.md) | W3-01 | Resultado persistente, compatibilidad y reintentos sin pérdida de progreso. |
| W3-03 | [Partida y navegación](03-partida-y-navegacion.md) | W3-02 | Flujo completo jugable, con resultado estático y barra de estado adaptada. |
| W3-04 | [Introducción y tutorial](04-introduccion.md) | W3-03 | Primera entrada y repaso con el formato compartido actual. |
| W3-05 | [Contador y estrella animados](05-resultado-animado.md) | W3-04 | Resultado animado sin cambios en la lógica ni premios duplicados. |
| W3-06 | [Pruebas, validación y entrega](06-pruebas-y-entrega.md) | W3-00–05 | Evidencia funcional, visual, de persistencia y plataformas. |

Cada etapa incluye pruebas y criterios de cierre. W3-06 consolida la regresión;
no posterga hasta el final las pruebas de las etapas anteriores. No activar el
nuevo comportamiento visible con solo una parte del flujo integrada. Los nombres
de clases nuevos quedan a criterio de implementación; los contratos son obligatorios.

## Tiempo acordado

D06: el usuario eligió **un límite de tiempo para ganar la estrella**. Solo cuenta
el tiempo activo; pausa, segundo plano y animaciones no lo consumen. Al llegar a
cero termina el intento sin estrella. No hay bonificación de puntos por rapidez.
El balance inicial usa 2 minutos más 30 segundos por casilla vacía: **21 minutos
por sudoku actual de 38 vacíos**, iguales en los tres tramos. Se ajustará con
pruebas de juego; el plazo queda congelado por intento igual que la meta.

## Protección de la experiencia existente

- Mantener el recorrido mundo 2 → santuario → mundo 3, la navegación y los IDs.
- No cambiar arte, capas, cámara, parallax, fauna ni disposición del mapa.
- Reutilizar superficies, estrellas, corazones, tipografía y botones actuales.
- Mantener números debajo del tablero, barra cercana al tablero y partida sin
  scroll. No reducir el tablero de tablet para acomodar controles duplicados.
- Mantener títulos, explicación debajo, tamaño/color del texto, pasos superiores
  y comportamiento de «Siguiente» de los tutoriales actuales.
- Conservar partidas guardadas, récords y recompensas anteriores.

Referencias normativas: [AGENTS.md](../../../AGENTS.md),
[formato compartido de tutoriales](../../first-experience/implementacion.md#formato-compartido-de-los-tutoriales),
[superficies](../../../assets/ui-surfaces.md) y
[puntaje actual](../../scoring/rules.md). Los documentos históricos pueden describir
estados anteriores: verificar el código y el catálogo antes de implementar.

## Seguimiento

- [x] W3-00: referencia técnica registrada; D06 resuelta durante W3-01.
- [x] W3-01: reglas y calibración verificadas; [resultados y alcance](calibration/validation.md).
- [x] W3-02: persistencia y compatibilidad verificadas; [evidencia](persistence/README.md).
- [x] W3-03: flujo jugable y responsive verificados en pruebas automatizadas; [evidencia y límites](gameplay/README.md).
- [ ] W3-04: introducción y repaso verificados.
- [ ] W3-05: contador y estrella verificados.
- [ ] W3-06: regresión y revisión visual cerradas con evidencia.

El checklist distingue trabajo terminado y pendiente. Las etapas de dominio no
equivalen a activar el nuevo flujo ni a validar su presentación en dispositivos.
