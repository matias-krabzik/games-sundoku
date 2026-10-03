# Guardados de referencia anteriores a las reglas del mundo 3

Generados el 03/10/2026 contra `a598639`, con perfil sintético y fecha/seed estables.
No contienen datos del jugador ni se importan automáticamente en la aplicación.
El formato guardado es el actual (schema 1), sin reglas de vidas ni metas nuevas.

| Archivo | Estado |
| --- | --- |
| `new-profile.json` | Perfil nuevo, sin progreso. |
| `world-2-complete.json` | Mundos 1/2 completos por registros sintéticos; notas habilitadas. |
| `world-3-one-star.json` | Primera ronda del nivel 1 resuelta mediante jugadas del repositorio. |
| `world-3-two-stars.json` | Dos rondas resueltas; tercer sudoku pendiente. |
| `world-3-in-progress.json` | Dos estrellas, tercera ronda pausada, una respuesta, notas, un error, una pista y 180 s. |
| `world-3-level-complete.json` | Tres rondas resueltas; la tercera conserva un error y una pista. Debe conservar sus estrellas al migrar. |
| `world-3-complete.json` | Nivel 1 real y niveles 2–30 por registros sintéticos; comprueba conservación del mundo terminado. |

Los registros sintéticos solo preparan prerrequisitos; no son evidencia de haber
jugado esos niveles. La generación resuelve las tres rondas del nivel 1 usando el
motor real. Normaliza únicamente IDs aleatorios de sesión y revisión del almacén;
no inventa puntajes ni altera errores, pistas, notas, tableros o historial.

Verificación habitual:

```sh
flutter test test/data/world3_baseline_test.dart
```

Mantener estos archivos congelados para futuras pruebas de migración. La
regeneración es explícita y se dirige primero a una carpeta temporal:

```sh
W3_BASELINE_EXPORT_DIR=/tmp/sundoku-w3-fixtures flutter test test/data/world3_baseline_test.dart
```

No reemplazar la referencia anterior con guardados de la futura implementación.
El constructor está en `test/support/world3_baseline.dart`. El importador usa
almacenamiento en memoria con revisión reiniciada, sin tocar SQLite/IndexedDB ni
el perfil real. La reapertura de SQLite se cubre además en la suite existente.

Las huellas de los siete archivos están en el
[manifiesto de W3-00](../../../design/world-3-crossed-rivers/gameplay-specs/baseline/manifest.json).
