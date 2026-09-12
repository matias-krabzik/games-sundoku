# Bienvenida: marco dorado e historia animada

El encabezado reproduce la composición de la referencia del 11 de septiembre: placa marfil con borde dorado brillante, sol a la izquierda, título azul y subtítulo gris azulado. El título y la historia comparten `UiSurface.goldCreamPanel`; los textos siguen siendo widgets Flutter y el sol reutiliza `HomeIcon`. No se integra la captura completa ni se duplican imágenes por tamaño.

`assets/images/tutorial/gold-cream-panel.png` es una extracción vacía hecha con ImageGen integrado. El PNG final se copió sin modificar píxeles desde `exec-b49094f3-a0d9-46bf-b4e7-db661454fc7a.png`. Tiene 2169 × 725 píxeles, modo RGBA, alfa de 0 a 255, 38,66 % de píxeles totalmente transparentes y las cuatro esquinas con alfa 0. Pillow se usó exclusivamente para inspeccionar esos datos. Los pases anteriores RGB con cuadros dibujados se descartaron.

El recorte nine-patch y la zona central están centralizados en `UiSurfaceCatalog`. La forma y el bisel se mantienen al crecer tanto el encabezado como la tarjeta de historia. La ilustración del guía y el botón inferior reutilizan sus recursos anteriores.

## Secuencia

La bienvenida es la primera de seis historias, con progreso segmentado arriba. El botón amarillo «Siguiente» está disponible desde el comienzo, incluso mientras se anima el contenido. Ningún temporizador cambia de historia.

1. En la primera visita, Doku aparece con un breve fundido y escala.
2. Después aparece la tarjeta y se escribe el texto con pausas entre frases.
3. Al terminar, aparecen el separador, el sol y «No necesitas hacer cuentas».

La tarjeta mantiene su tamaño durante la escritura. Volver desde otra historia muestra la bienvenida completa, sin repetir la espera. Con reducción de movimiento o navegación accesible también se muestra completa; el lector de pantalla recibe una descripción del texto entero, sin anuncios por letra.

«Siguiente», un toque a la derecha o un deslizamiento a la izquierda avanzan. En las historias posteriores, un toque a la izquierda o un deslizamiento a la derecha permiten volver. Las flechas del teclado navegan y Espacio avanza; el lector de pantalla tiene acciones de anterior y siguiente. La narración no captura esos gestos para exigir un toque adicional. El contenido central puede desplazarse verticalmente sin cambiar de historia y el botón queda en la zona inferior segura.

Después siguen el ejemplo del bloque, el tablero completo, las filas, las columnas y las pistas. No hay ejercicios obligatorios antes de jugar; la guía práctica permanece dentro de las partidas. Secuencia completa: [Implementación de la primera experiencia](../design/first-experience/implementacion.md).

La ayuda «DEV · Volver» solo se construye si `kDebugMode` y `showDeveloperControls` están activos. Está separada del encabezado y no aparece en la versión para jugadores. La navegación del sistema conserva el comportamiento del flujo existente.

## Prompts y procedencia

Referencia: `codex-clipboard-8fc2bd53-2e51-4f7d-b593-7e5f6666bd1c.png` adjunta por el usuario. Extracción: solo la placa superior, sin sol, letras, personaje ni controles, manteniendo el borde amarillo/dorado, brillo blanco, bisel inferior naranja e interior marfil. Se solicitó transparencia RGBA real, una superficie reutilizable vacía, nunca una pantalla completa, y composición de todos los textos e iconos con widgets Flutter. Los prompts de extracción incluyeron los requisitos de `AGENTS.md`.

Prompt final de limpieza (ImageGen integrado):

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork exactly. Real RGBA transparency, zero alpha outside the blank individual UI panel, no painted checkerboard. No text or icons; these are separate Flutter widgets. Reuse the existing artwork.
```

Pruebas: `test/widgets/tutorial_story_test.dart`, `test/first_experience_test.dart`, `test/tutorial_journey_widget_test.dart` y `test/widgets/ui_surface_art_test.dart` cubren animación y tip, navegación sin esperas, accesibilidad, controles de desarrollo, composición adaptable y conservación de esquinas. Las capturas generadas por las pruebas son renders de Flutter con datos de prueba.
