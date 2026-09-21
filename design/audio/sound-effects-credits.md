# Efectos de sonido de SunDoku

## Kenney

Autor: Kenney.
Fuente confirmada por el propietario del proyecto: https://kenney.nl/
Catálogo: https://kenney.nl/assets
Licencia de los recursos del catálogo: Creative Commons CC0 1.0 Universal.
Referencia: https://kenney.nl/support
Licencia: https://creativecommons.org/publicdomain/zero/1.0/

| Efecto | Uso |
| --- | --- |
| maximize | Activar un check |
| minimize | Desactivar un check |
| question | Abrir un modal |

Los originales OGG se conservan en assets/audio/sfx. Se generaron copias WAV PCM de 16 bits para reproducción compatible con iOS; la app ajusta el volumen.

## Pendiente para la pantalla de créditos

Incluir «Efectos de sonido: Kenney (kenney.nl), CC0 1.0» junto con los créditos musicales registrados en music-credits.md.
CC0 no exige atribución, pero el usuario pidió incluirla. Implementar la pantalla más adelante.

## Mixkit — Completion of a level

- Archivo: `assets/audio/sfx/win/mixkit-completion-of-a-level-2063.wav`.
- Uso previsto: completar un nivel.
- Proveedor: Mixkit; la página consultada no identifica un autor individual.
- Fuente confirmada por el usuario: https://mixkit.co/free-sound-effects/video-game/
- Licencia: Mixkit Sound Effects Free License (no es CC0).
- Condiciones: https://mixkit.co/license/modal/sfxFree/
- Verificación: 2026-09-21. Permite incorporar el efecto en videojuegos comerciales; no permite redistribuirlo por separado como recurso o biblioteca.
- Crédito previsto: «Completion of a level — Mixkit», con enlace a la fuente y licencia, en la futura pantalla de créditos.

Integrado: suena una vez al ganar cada sudoku, incluidas las rondas intermedias y la partida rápida; la música de fondo baja gradualmente durante el efecto (aproximadamente 300 ms) y recupera su volumen gradualmente al terminar (aproximadamente 800 ms), si está habilitada, respetando la preferencia de efectos. Se precarga sin editar el WAV original.
