# Juego de escritorio

- Ventana nativa inicial: 1024×768 de contenido; mínimo 960×720, proporción 4:3 al redimensionar. macOS ajusta el mínimo si el área útil del monitor no permite esas medidas y aplica el tamaño después de restaurar ventanas antiguas.
- En macOS, Windows y Linux, cuando hay al menos 660 px de ancho disponible, el tablero y la botonera forman un conjunto centrado: tablero de hasta 430 px, separación de 24 px y números en 3×3 de 54 px por ficha, con 6 px entre fichas.
- Borrar y Ayuda quedan debajo de la botonera. El mensaje de ayuda aparece debajo del conjunto, hasta 430 px de ancho, para mantenerlo legible.
- En móvil se conserva la fila horizontal de números. Ventanas de escritorio demasiado estrechas (por ejemplo en un navegador) también pueden usar esa disposición. El contenido admite scroll cuando falta altura, sin perder tablero, selección o ayuda.
- Límites de Flutter centralizados en `lib/widgets/game_layout.dart`; se reutiliza `TutorialNumberTray`, sin generar nuevas imágenes ni duplicar botones.

Pruebas de geometría, selección, edición y conservación de estado: `test/desktop_game_layout_test.dart`. Capturas: `game-4x3.png` y `game-help-4x3.png`.

Implementación nativa: [NSWindow](https://developer.apple.com/documentation/appkit/nswindow), [WM_GETMINMAXINFO](https://learn.microsoft.com/windows/win32/winmsg/wm-getminmaxinfo), [GTK geometry hints](https://docs.gtk.org/gtk3/method.Window.set_geometry_hints.html). La compilación nativa se verifica en macOS; Windows y Linux requieren validación en sus sistemas.
