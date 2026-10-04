# W3-06 · Pruebas, validación y entrega

Depende de: W3-00–05. Esta matriz se usa desde W3-00; el cierre final consolida
evidencia y no sustituye las pruebas de cada etapa.

## Orden ejecutable

| Orden | Trabajo | Antes de continuar |
| --- | --- | --- |
| 0 | Referencia, fixtures y D06 | Capturas/estado base y decisión de tiempo registrados. |
| 1 | Política de reglas y cálculo | R01–R12 e informe de calibración; aún sin activar la UI. |
| 2 | Persistencia, resultado y retry | S01–S14; migración y reapertura verificadas. |
| 3 | Integración con resultado estático | F01–F11; ida/vuelta completa y tamaños de pantalla. |
| 4 | Introducción | T01–T10; formato igual a tutoriales actuales. |
| 5 | Contador y estrella | A01–A10; filmación/capturas y accesibilidad. |
| 6 | Regresión y activación conjunta | Matriz completa, evidencias y documentación de entrega. |

Integrar cambios pequeños y revisables. Ejecutar los tests de la capa que cambia
en cada etapa; ampliar la regresión al modificar componentes compartidos. Un fallo
nuevo bloquea la etapa dependiente. Si un problema ya existía, registrar caso,
commit y evidencia; no presentarlo como regresión nueva ni ocultarlo como aprobado.

## Cobertura automática

1. **Dominio:** vidas por tramo; igualdad con meta; cero vidas; condiciones del 30;
   errores repetidos; notas; pistas; cálculo perfecto independiente; redondeo;
   tiempos acordados y determinismo. R01–R12.
2. **Contenido:** tres perfiles sintéticos × 90 rondas; seed/versión reproducibles,
   solución única, metas alcanzables y margen progresivo normalizado. No suponer
   que los 90 tableros de un perfil representan a todos los jugadores.
3. **Repositorio/codec:** resultado y estrella atómicos; fallos de escritura;
   concurrencia; reintentos parciales; sesiones heredadas; preservación de campos;
   reapertura de almacenamiento real y adaptadores Playables. S01–S14.
4. **Controladores:** reloj detenido en pausa/fallo/resultado, bloqueo de entradas,
   ruta pendiente, avance idempotente y cierre sin pérdida de estado. F01–F11.
5. **Widgets:** estado visible, botón de ayuda del 30, tamaños, títulos, texto,
   Siguiente en dos acciones, tablero estable, umbral y celebración. T01–T10/A01–A10.

Priorizar pruebas de comportamiento observable e invariantes. No crear tests que
solo reproduzcan la misma fórmula del código probado. Usar tiempo virtual y seeds
estables, sin esperar segundos reales ni depender de red o datos del usuario.

## Flujos completos

| ID | Recorrido | Verificación |
| --- | --- | --- |
| E01 | Mundo 2 completo → santuario → introducción → mundo 3 nivel 1 | Mismo acceso, tutorial único, condiciones visibles, partida iniciada. |
| E02 | Nivel 1, tres rondas aprobadas → nivel 2 | Tres estrellas, vidas renovadas, resumen y desbloqueo únicos. |
| E03 | Ganar ronda 1, fallar ronda 2, salir y reintentar | Ronda 1 preservada, sudoku 2 nuevo al reintentar; reabrir conserva tablero y vidas del intento. |
| E04 | Nivel 10 → 11 y 20 → 21 | 3→2 y 2→1 vidas; curva de meta sin salto accidental o reinicio. |
| E05 | Nivel 29 con pista | Ayuda permitida; resultado depende de puntaje, sin prohibición perfecta anticipada. |
| E06 | Nivel 30 con una equivocación / intento perfecto | Fallo inmediato / aprobación; ayuda bloqueada y notas funcionales. |
| E07 | Resolver debajo, igual y encima de meta | Tres resultados correctos y contador coherente con cada uno. |
| E08 | Cerrar después de guardar resultado y antes de animación | Premio conservado, resultado recuperable, sin doble estrella. |
| E09 | Guardado antiguo en mundo 3, con sesión parcial | Continúa bajo sus reglas; próxima sesión usa reglas nuevas y tutorial pendiente. |
| E10 | Mundos 1/2, home, rápida, reglas y anotaciones | Flujo y apariencia de referencia conservados. |
| E11 | Completar la tercera ronda del nivel 30 | Mundo terminado una vez; sin nivel 31 ni siguiente mundo inventado. |
| E12 | YouTube Playables pausa/suspende/restaura | No suma tiempo oculto ni pierde reglas, resultado o progreso. |
| E13 | Resolver 1 ms antes / igual al límite, vencer y reintentar | Éxito / fallo; plazo restaurado solo por reintento, otras estrellas intactas. |

Los estados DEV aceleran el acceso, pero no sustituyen E02/E03/E06/E08 ejecutados
mediante jugadas reales. Reinicios de prueba nunca afectan el perfil del usuario.

## Matriz de tamaño y accesibilidad

Dimensiones en píxeles lógicos. Usar texto normal y 200 %; movimiento normal y
reducido al menos en teléfono pequeño, iPad y escritorio. La matriz cubre cambios
de layout además de dispositivos nominales.

| Grupo | Tamaños |
| --- | --- |
| Teléfono vertical | 320×568, 390×844, 430×932 |
| Teléfono horizontal | 568×320, 844×390 |
| Tablet | 768×1024, 834×1210, 1210×834, 1024×1366 |
| Límites de layout grande | 699×900, 700×900, 700×599, 700×600 |
| Escritorio / Playables | 1024×600, 1440×900, 1920×1080 |

Por tamaño: tablero dentro del espacio y de los máximos de `GameLayout`, controles
debajo, márgenes laterales amplios, barra próxima al tablero, ningún overflow ni
scroll de partida. Comprobar acciones de tutorial/resultado en SafeArea, texto sin
recortes, corazones y meta legibles. Probar redimensionado durante partida,
escritura del tutorial y contador final: no pierde estado ni reinicia escenas.

Capturas comparativas mínimas: 390×844, 834×1210, 1210×834 y 1440×900. Incluir:

- Partida de mundos 1/2 antes/después y partida nueva de mundo 3.
- Introducción: título, segmentos, tablero, texto inferior y botones.
- Resultado antes del umbral, estrella ganada y fallo por puntaje/vidas/tiempo.
- Resumen final y regreso al mapa con estrellas correctas.

Verificar al menos iPad de 11 pulgadas en simulador, teléfono vertical/horizontal
y navegador con Playables. Registrar si no hubo dispositivo físico disponible;
una captura de widget no prueba por sí sola el comportamiento del host Playables.
Comparar ruido de partículas/cursor por separado de cambios reales de composición.

## Suites existentes para ampliar

| Área | Archivos actuales |
| --- | --- |
| Puntaje/modelos | `test/domain/scoring/sudoku_scoring_test.dart`, `test/domain/game_models_test.dart` |
| Persistencia | `test/data/game_repository_test.dart`, `test/data/notes_test.dart` |
| Controladores | `test/controllers/game_session_controller_test.dart`, `test/controllers/first_experience_controller_test.dart`, `test/controllers/generated_levels_test.dart` |
| Mundo/progreso | `test/data/crossed_rivers_world_test.dart`, `test/data/world_gate_test.dart`, `test/level_unlock_test.dart`, `test/summit_gate_test.dart`, `test/world_completion_recap_test.dart` |
| Partida/responsive | `test/generated_game_widget_test.dart`, `test/desktop_game_layout_test.dart`, `test/completed_level_popover_test.dart` |
| Tutorial compartido | `test/first_experience_test.dart`, `test/widgets/tutorial_presentation_test.dart`, `test/widgets/tutorial_story_navigation_test.dart`, `test/widgets/notes_tutorial_demo_test.dart` |
| Web/Playables | `test/playables/playables_integration_test.dart`, `test/quick_play_test.dart`, `test/contextual_help_widget_test.dart` |

Crear suites específicas de reglas/resultado/introducción del mundo 3 cuando no
corresponda ampliar las existentes. Añadir sus rutas a la entrega al crearlas;
estos specs no afirman que esos archivos nuevos existan.

Comandos de referencia desde la raíz del proyecto:

```sh
flutter analyze
flutter test test/domain/scoring/sudoku_scoring_test.dart test/domain/game_models_test.dart
flutter test test/data/game_repository_test.dart test/controllers/game_session_controller_test.dart
flutter test test/generated_game_widget_test.dart test/desktop_game_layout_test.dart test/completed_level_popover_test.dart
flutter test test/first_experience_test.dart test/widgets/tutorial_presentation_test.dart test/widgets/notes_tutorial_demo_test.dart
flutter test test/data/crossed_rivers_world_test.dart test/summit_gate_test.dart test/level_unlock_test.dart test/world_completion_recap_test.dart
flutter test test/playables/playables_integration_test.dart
flutter test
git diff --check
```

Ejecutar grupos según la etapa, las suites nuevas al crearlas y la suite completa
al cerrar. No repetir pruebas ya aprobadas sin cambios relevantes. El análisis
no debe introducir errores/avisos nuevos; registrar hallazgos preexistentes.
Compilar con el procedimiento vigente de [YouTube Playables](../../../docs/youtube-playables.md)
al validar esa plataforma; no inventar otro entrypoint o proceso de publicación.

## Evidencia y cierre

Crear un informe de entrega dentro de esta carpeta al implementar, con:

- Commit(s), reglas/versiones, decisión de tiempo y curva final.
- Comandos ejecutados, resultado real, fecha, entorno y fallos previos.
- Informe de calibración, perfiles sintéticos/seeds y fixtures de migración.
- Capturas y videos referenciados, tamaños y escala de texto.
- Matriz R/S/F/T/A/E con estado aprobado/fallido/pendiente y evidencia asociada.
- Riesgos o plataformas no verificadas, sin marcarlos como aprobados.

Checklist de salida:

- [ ] D06 resuelta; metas y guion coinciden con la política del tiempo.
- [ ] W3-00–05 cerradas y casos relevantes R/S/F/T/A/E verificados.
- [ ] Sesiones previas, estrellas y récords preservados.
- [ ] Última vida, meta exacta, pistas y nivel 30 correctos.
- [ ] Resultado y navegación independientes de la animación.
- [ ] Tutorial sin input de sudoku, con formato y continuidad actuales.
- [ ] Ningún cambio accidental de arte, mapa, cámara, fauna o flujo previo.
- [ ] Responsive, accesibilidad y Playables revisados con evidencia.
- [ ] `design/scoring/rules.md` y `docs/guardado-local.md` actualizados al comportamiento
  implementado, distinguiendo los mundos y las sesiones heredadas.
- [ ] README de estos specs actualizado a estado real, sin declarar terminado lo pendiente.

## Validación de esta entrega documental

La entrega documental inicial comprendió únicamente los specs y su enlace desde
el documento del mundo 3; el avance real de las etapas está en el README. Comprobar enlaces locales, referencias de archivos, coherencia de
dependencias y `git diff --check`. Las simulaciones de W3-01 verifican el dominio; no presentan como implementadas
las etapas de persistencia, presentación o activación todavía pendientes.
