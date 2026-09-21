# Iconos de Partida rápida

Recursos: `assets/images/quick-play/{easy,normal,medium,hard,extreme}.png`.
Son dibujos independientes, proporcionales y sin texto; las tarjetas siguen usando `UiSurface`.

Generados con la herramienta integrada de imágenes tomando como referencia la propuesta
`exec-a23e8339-507f-42b4-a92a-1e3904826f07.png`.
Se pidió extraer, respectivamente, el sol dorado, la pieza azul, las tres piezas unidas,
el rayo azul con borde dorado y la corona dorada y azul. El prompt exigía conservar
las formas, colores y luces de la referencia, sin reinterpretación, texto ni tarjetas,
y fondo RGBA genuinamente transparente.

El generador devolvió RGB con una cuadrícula pintada. Se eliminó el fondo gris conectado
al exterior conservando los brillos interiores y se exportaron PNG RGBA con un máximo
de 320 px. Se verificaron alfa cero en el exterior y la composición sobre fondo azul.

Fuentes (directorio original de imágenes generadas):

- Fácil: `exec-cea1590c-e7c8-4a63-8033-7cd18c5a23f2.png`
- Normal: `exec-78323b55-59c7-4ce9-8a37-98b136283c6d.png`
- Medio: `exec-713832ff-5372-447d-bfea-b6f6018de681.png`
- Difícil: `exec-1d12cd4e-fa23-4cfb-884f-f70fe95b4b7a.png`
- Extremo: `exec-8389f14f-b6af-4851-9714-0fb8a81f7b3b.png`
