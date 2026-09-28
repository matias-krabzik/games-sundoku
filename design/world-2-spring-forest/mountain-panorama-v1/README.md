# Capas del bosque hasta la montaña

Generadas con image_gen integrado; prompts completos en prompts.md. Original aprobado en master.png.

Orden: sky, clouds, mountains, distance, terrain, foreground.

Sky contiene cielo azul sin nubes. Mountains contiene solo cordillera lejana. Terrain conserva árboles próximos, camino, puente, cauce completo y montaña de llegada unidos; se completó por abajo para cubrir el movimiento del primer plano. Foreground contiene vegetación y rocas decorativas próximas.

Son intermedios opacos sobre gris, no exportaciones transparentes finales. Aplicadas al juego: el script tool/prepare_spring_forest.py exporta los PNG RGBA a assets/images/map/spring-forest/. El exportador retira el gris preservando piedras y flores e iguala lienzos a 2172 px sin estirar. Se revisaron capturas del inicio y llegada. El mapa reserva márgenes reales de 120/40 px y separa los niveles 2.6 veces el tamaño del botón (antes 1.55). No tienen overscan lateral adicional.

El panorama aprobado sigue siendo 3:1. Para duplicar físicamente la longitud habrá que generar tramos adicionales; no estirar este arte.

Dimensiones verificadas:

- clouds.png: 2172 × 724, RGB.
- distance.png: 2172 × 724, RGB.
- foreground.png: 2172 × 724, RGB.
- mountains.png: 2172 × 724, RGB.
- sky.png: 2171 × 724, RGB.
- terrain.png: 2171 × 724, RGB.
