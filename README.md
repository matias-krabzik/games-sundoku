# SunDoku

Novela visual de Sudoku para niños, con Sol como mascota. La historia se cuenta
entre y a través de partidas de Sudoku.

## Diseño responsive

El proyecto se adapta al tamaño de la ventana, incluyendo móvil, tablet y escritorio.
Volver y Configuración siguen los extremos del ancho útil, dentro de `SafeArea`.
El tablero permanece centrado con un máximo de 430 px lógicos; los números tienen
un máximo de 54 px por lado, igual que la navegación, y Borrar mide 52 px.
En ventanas bajas, el contenido permite desplazamiento. Las reglas están en
[AGENTS.md](AGENTS.md) y los límites compartidos en
[game_layout.dart](lib/widgets/game_layout.dart).

El fondo de la home usa el giroscopio únicamente en Android/iOS. En escritorio
sigue al puntero, conserva inmóviles los controles y vuelve al centro al salir.
En escritorio también responde cuando la ventana sigue visible sin tener el foco.
El efecto se detiene al ocultar la home o la ventana, dejar la app móvil en segundo
plano o activar movimiento reducido. La implementación compartida está en
`lib/widgets/parallax_background.dart`.

## Datos y progreso

El progreso y los ajustes se guardan localmente, sin login. Cada nivel contiene
tres sudokus fijos y conserva los mejores resultados al repetirlo.

Ver [estructura de datos, diagramas y guía de integración](docs/guardado-local.md).

## Festejos del tutorial

Al ganar, el tablero actual conserva su transición y queda delante de los anteriores:
dos tableros en abanico al terminar el segundo sudoku y tres al terminar el tercero.
Las miniaturas usan las partidas resueltas guardadas y el mismo `SudokuBoard`.

`VictoryParticles` emite destellos dorados durante 1,4 s en las dos primeras
victorias y confeti con estrellas durante 2,6 s en la tercera. Empieza cuando llega
el tablero, no bloquea controles, no se repite al reconstruir o restaurar la pantalla
y respeta movimiento reducido. Se pinta detrás de los tableros y Doku.

Se evaluó [confetti](https://pub.dev/packages/confetti); para estos dos efectos
acotados se usa [CustomPainter con repaint](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html),
que permite repintar las partículas sin reconstruir ni recalcular el layout en cada
tick. El componente reutilizable no necesita paquetes ni imágenes adicionales.

## Requisitos

- Flutter SDK (canal `stable`, 3.47.x o superior) — incluye Dart.
  Instalación: https://docs.flutter.dev/get-started/install
- Para correr en Android: Android Studio + un emulador o dispositivo con depuración USB.
- Para correr en iOS/macOS (solo en Mac): Xcode.
- Para correr en web: Chrome.

Verificar el entorno:

```bash
flutter doctor
```

## Puesta en marcha

```bash
git clone <repo-url>
cd sundoku
flutter pub get
flutter run            # elige un dispositivo, o:
flutter run -d chrome  # web
```

## Desarrollo

```bash
flutter analyze                     # análisis estático
dart format .                       # formateo
flutter test                        # tests
flutter test test/widget_test.dart  # un solo archivo de test
```

## Builds

```bash
flutter build apk       # Android
flutter build ipa       # iOS
flutter build web       # Web
flutter build macos     # macOS
```

Plataformas configuradas: android, ios, web, macos, linux, windows.
