# SunDoku para YouTube Playables

## Compilar

Requiere Flutter 3.47.2 / Dart 3.13.2 o una versión compatible. Desde la raíz:

```sh
python3 tool/build_youtube_playables.py
```

El script genera `build/youtube_playables/` y `build/sundoku-youtube-playables.zip`, separados de `build/web/`. Compila con `YOUTUBE_PLAYABLES=true`, incluye CanvasKit y fuentes locales, inserta el SDK oficial antes del bootstrap y usa rutas relativas para poder servir el juego desde un subdirectorio. El ZIP contiene `index.html` en su raíz. Valida cantidad de archivos, caracteres de los nombres y límites de tamaño por archivo y paquete.

Para probar las rutas locales:

```sh
python3 -m http.server 8765 --directory build
# Abrir http://127.0.0.1:8765/youtube_playables/
```

La compilación web normal sigue usando `flutter build web --release` y su SQLite habitual. En la variante Playables, si `ytgame` no existe o `IN_PLAYABLES_ENV` es falso, la partida vive solo en memoria. Este caso sirve para revisar la interfaz localmente; **no prueba** el guardado real del SDK.

## Integración

- El widget de carga envía `firstFrameReady` después del primer frame visible. La home envía `gameReady` una sola vez tras quedar visible y usable.
- El adaptador de `dart:js_interop` registra los callbacks de pausa, reanudación y audio antes de `loadData`. Un adaptador falso cubre las pruebas.
- En YouTube, `loadData` debe terminar correctamente antes de cualquier `saveData`. Los datos vacíos crean una partida nueva; los errores, JSON corrupto y versiones futuras muestran un error recuperable sin sobrescribir la nube.
- Se usa el `GameSave` completo, con tableros iniciales, partidas, valores, notas, cronómetro, estado, progreso, estadísticas y ajustes. El esquema actual es 1 y la variante Playables migra el esquema 0. No se descartan campos desconocidos.
- Los cambios se agrupan durante 2 segundos y las escrituras se serializan. Una partida nueva o una partida completada fuerza un intento de guardado; la pausa del SDK detiene primero los cronómetros y luego fuerza otro. Un fallo de `saveData` deja el último estado en memoria para reintentar.
- `onPause` bloquea entradas y animaciones, detiene audio y movimiento y conserva la pausa manual. `onResume` es el único evento que devuelve actividad en YouTube. El silencio de YouTube prevalece sobre las opciones de audio del juego.
- No hay autenticación, backend, anuncios ni compras. Los enlaces externos se muestran como texto en Playables. No se añadió `sendScore` porque la puntuación actual mezcla distintos tipos de partida y no define un récord global comparable.

## Verificar

```sh
flutter analyze --no-pub
flutter test --no-pub test/playables/playables_integration_test.dart
flutter build web --release
```

La compilación local y las pruebas con el adaptador falso **no son certificación**. La Test Suite pública quedó cargando al intentar abrir el servidor HTTP local desde su página HTTPS; no llegó ninguna solicitud al servidor. Para cerrar la validación, hay que servir el paquete desde una URL HTTPS accesible por la suite:

Medición local del paquete de esta entrega, con un SDK falso que marca el instante de `gameReady`: 19 recursos propios descargados, 16,78 MiB sin compresión (incluido `index.html`) y 10,76 MiB estimados al aplicar gzip nivel 6 a esos mismos archivos. En el navegador local, `firstFrameReady` ocurrió a los 221 ms y `gameReady` a los 305 ms; la home estaba pintada. El servidor local no comprimía HTTP, y el cálculo no incluye el SDK alojado por YouTube ni las condiciones de red de los dispositivos. La Test Suite debe confirmar el tamaño y tiempo reales.

1. Servir el paquete con compresión HTTP y medir en la [SDK Test Suite](https://developers.google.com/youtube/gaming/playables/reference/test_suite_guide) la descarga hasta `gameReady` y el tiempo interactivo. El ZIP y el tamaño bruto no sustituyen esta medida.
2. En la Test Suite comprobar `loadData/saveData`, una partida guardada que se reanuda, datos corruptos, pausa, reanudación, mute y las señales de disponibilidad.
3. Subir el ZIP al Developer Portal y probar el Dev Link en YouTube web, Android e iOS. Revisar allí la política CSP, los logs de red y la memoria real. La publicación y la aprobación quedan fuera de esta entrega.

Límites consultados en las [reglas de estabilidad](https://developers.google.com/youtube/gaming/playables/certification/requirements_stability): descarga inicial menor que 30 MiB (recomendado menor que 15 MiB), paquete menor que 250 MiB, archivo menor que 30 MiB y guardado menor que 3 MiB. El guardado de cierre de hasta 64 KiB es una recomendación adicional de las [reglas de integración](https://developers.google.com/youtube/gaming/playables/certification/requirements_integration). El juego conserva el historial completo aunque alguna partida avanzada exceda ese objetivo recomendado.
