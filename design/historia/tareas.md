# Tareas: integrar el Camino de los Números

> **Archivado para SunDoku 2.0 (19/09/2026).** Este documento describe el diseño o prototipo anterior. La versión 1.0 mantiene el juego simple: tutorial, sudokus, celebraciones y mapa, sin escenas narrativas. El código del prototipo se conserva como referencia en `prototipo-2.0/`, fuera de la aplicación.

Plan de referencia: [Integración de historia](plan-integracion.md).

## Ajuste inicial de la home

- [x] Mostrar «Aventura» antes de comenzar y «Continuar aventura» cuando existe progreso de aventura, usando el estado que ya recibe la home.
- [x] Dar espacio a la etiqueta larga con el botón ilustrado compartido, conservando una línea y la superficie nine-patch.
- [x] Adaptar la distribución de los dos botones al ancho disponible.
- [x] Ejecutar las pruebas existentes de home e introducción, análisis estático y hot reload de la app conectada.

Verificación de ese primer hito: 29 pruebas aprobadas; análisis sin errores en los archivos modificados; hot reload completado y sin errores de ejecución reportados. La recuperación directa de escenas se agregó luego, en el paso 2 de esta lista; la continuación directa de partidas sin escena pendiente sigue en el paso 3.

## 1. Guion concreto del capítulo inicial

- [x] Escribir el objetivo de Doku y la invitación de Numa en una apertura breve.
- [x] Convertir las explicaciones de bloque, fila y columna en intervenciones de Tilo sobre el tablero actual.
- [x] Definir los mensajes y las acciones de las tres partidas.
- [x] Escribir las tres escenas posteriores a sus victorias.
- [x] Definir las primeras páginas del cuaderno y el momento en que se incorporan.
- [x] Definir continuidad, omisión de diálogos y reanudación.

Entregable redactado: [Capítulo 1, pantalla por pantalla](capitulo-1-guion.md). Las escenas de victoria ya están integradas; la apertura y las lecciones narrativas siguen pendientes.

## 2. Base de escenas y guardado

- [x] Crear el catálogo de treinta escenas de victoria con identificadores estables.
- [x] Guardar escena pendiente, tarjeta actual y escenas leídas u omitidas.
- [x] Conectar la victoria guardada con su escena posterior en la misma escritura.
- [x] Unificar la continuación después de las partidas 1, 2 y 3, contemplando el resumen final y la vuelta al mapa.
- [x] Reanudar correctamente si la app se cierra entre una victoria, su celebración y la escena.
- [x] Mantener los premios independientes de la lectura y evitar que una repetición normal vuelva a encolar la misma escena.
- [x] Mantener partida rápida fuera del flujo narrativo de campaña.
- [x] Usar la imagen de fondo de inicio y las superficies compartidas, con textos reales de Flutter.
- [x] Agregar «Completar menos 1» al DEV del nivel y al mapa, con selección de partida 1, 2 o 3.

Implementación y prueba manual: [Sistema de escenas](sistema-escenas.md). El catálogo y guardado de lecciones se incorporarán al convertir el nivel 1 en capítulo.

## 3. Integrar el nivel 1 como primer capítulo — siguiente trabajo

- [ ] Presentar la apertura al empezar la aventura.
- [ ] Incorporar las explicaciones de Tilo conservando el bloque elegido y el tablero real.
- [ ] Registrar las lecciones aprendidas para habilitar sus fichas en el cuaderno.
- [x] Integrar las tres escenas de victoria y el cierre hacia el nivel 2.
- [x] Hacer que «Continuar aventura» retome una escena pendiente, incluyendo su tarjeta actual.
- [ ] Extender la continuación directa a la apertura, lecciones y partidas en curso sin escena pendiente.
- [ ] Pasar la elección inicial del nombre a la personalización opcional del cuaderno después del primer nivel.
- [ ] Conservar el progreso de jugadores que ya empezaron el tutorial o completaron niveles.
- [ ] Verificar el capítulo completo, guardado, pantallas pequeñas, horizontal, texto ampliado y movimiento reducido.

## 4. Cuaderno del Camino

- [ ] Convertir el acceso «Ver el tutorial» en «Cuaderno».
- [ ] Crear la sección «Aprendido» con las fichas descubiertas.
- [ ] Crear la sección «Mi viaje» con el objetivo actual y escenas disponibles.
- [ ] Permitir releer escenas sin alterar la campaña.
- [ ] Añadir acceso desde pausa y volver al mismo tablero.
- [ ] Añadir ejercicios de repaso aislados después de la primera versión de consulta.

## 5. Completar el valle

- [x] Incorporar un primer guion de veintisiete escenas de victoria para los niveles 2–10.
- [x] Dar a cada nivel una pequeña situación que avance en sus tres partidas.
- [x] Desarrollar el encuentro intermedio con Tilo y las pruebas del mirador.
- [ ] Revisar el ritmo del primer guion jugando el valle completo.
- [ ] Registrar y mostrar el Sello de la Observación al terminar el nivel 10; su entrega ya aparece en el diálogo.
- [x] Preparar la despedida y la presentación del bosque, indicando que aún no está disponible.

## Ilustraciones — después de validar el recorrido

- [ ] Preparar los personajes individuales de Numa y Tilo y las poses necesarias.
- [ ] Sustituir o acompañar el fondo temporal por escena, reutilizando las superficies y manteniendo el texto en Flutter.

## 6. Experiencia y primer desbloqueo

- [ ] Incorporar los premios únicos de XP definidos en el anexo.
- [ ] Mostrar experiencia, rango y sellos en el cuaderno y los resúmenes.
- [ ] Reconocer el progreso ya completado mediante una migración de guardado.
- [ ] Diseñar la primera lección del bosque con Vera.
- [ ] Implementar el lápiz y las notas al comenzar el mundo 2, con controles, representación, guardado y tableros adecuados.

## Primera entrega jugable de historia

- [ ] Completar la base narrativa, el nivel 1 y el cuaderno de consulta.
- [ ] Recorrer desde una instalación nueva hasta el nivel 2.
- [ ] Retomar desde un guardado anterior sin perder tablero, estrellas ni resultados.
- [ ] Revisar el ritmo de juego y lectura antes de extender el relato al valle entero.
