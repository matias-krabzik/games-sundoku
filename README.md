# SunDoku

Novela visual de Sudoku para niños, con Sol como mascota. La historia se cuenta
entre y a través de partidas de Sudoku.

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
