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

## Créditos implementados

Configuración → Licencias → Música y sonidos incluye «Kenney (kenney.nl)», la fuente y CC0 1.0 en un bloque breve. «Ver licencia» abre el texto oficial completo de `assets/licenses/CC0-1.0.txt`, con un enlace a la licencia oficial. Los efectos y detalles de conversión se documentan aquí.
Fuente del paquete: https://kenney.nl/assets/interface-sounds
CC0 no exige atribución; se incluye a petición del usuario.

## Mixkit — Completion of a level

- Archivo: `assets/audio/sfx/win/mixkit-completion-of-a-level-2063.wav`.
- Uso: completar un sudoku.
- Proveedor: Mixkit; la página consultada no identifica un autor individual.
- Fuente confirmada por el usuario: https://mixkit.co/free-sound-effects/video-game/
- Licencia: Mixkit Sound Effects Free License (no es CC0).
- Condiciones: https://mixkit.co/license/modal/sfxFree/
- Verificación: 2026-09-21. Permite incorporar el efecto en videojuegos comerciales; no permite redistribuirlo por separado como recurso o biblioteca.
- Crédito implementado: «Mixkit», con fuente y nombre de la licencia. «Ver licencia» abre las condiciones oficiales, que enlazan a https://mixkit.co/terms/.
- Condiciones verificadas nuevamente el 2026-09-22; se conserva la distinción de que esta licencia no es CC0.

Integrado: suena una vez al ganar cada sudoku, incluidas las rondas intermedias y la partida rápida; la música de fondo baja gradualmente durante el efecto (aproximadamente 300 ms) y recupera su volumen gradualmente al terminar (aproximadamente 800 ms), si está habilitada, respetando la preferencia de efectos. Se precarga sin editar el WAV original.

## Sonido original de pulsación

`assets/audio/soft-tap.wav` se genera en `tool/generate_ui_audio.py`, sin muestras de terceros. No requiere atribución a un proveedor externo.
