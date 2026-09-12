# Estado de la partida: vidas infinitas

Generado con la herramienta integrada `image_gen`. Recurso: `assets/images/tutorial/lives-icons.png` (RGBA, 1774 × 887). Los iconos se componen por separado mediante regiones del atlas; no se aplica nine-patch a los dibujos.

Corazón coral e infinito azul con volumen y brillo. Etiqueta semántica en Flutter. Pincel existente de 28 px dentro del botón circular de 52 px.

Alfa verificado: rango 0–255, esquinas transparentes, 63,1 % de píxeles con alfa cero. Huecos del infinito transparentes.

## Prompt final

Use case: stylized-concept. Asset type: transparent game UI icon atlas for SunDoku.
Create exactly TWO SEPARATE reusable icons, side by side, on a landscape 2:1 transparent canvas. Left half: a friendly plump red/coral HEART, symmetric rounded upper lobes, rounded lower point, softly beveled edges, polished toy-like 3D enamel. Right half: a thick royal/navy BLUE INFINITY symbol, a horizontal figure eight with two fully transparent holes and a beautifully readable crossover, smooth inflated tube, same toy-like polished 3D material. Each icon centered in its own half, no overlap, generous transparent gap; each icon occupies about 75% of its half's width and 60% of canvas height. Both are front-facing, level and horizontal, same visual scale, warm lighting from upper left, tasteful white specular highlight and soft darker modeled underside. Match a premium cheerful children's sudoku game whose icons are glossy gold stars and thick rounded glossy royal-blue arrows, on cream and sunshine-gold buttons. Icon silhouettes must stay simple and readable at 32 px. No faces, text, captions, numbers, badges, circular button surfaces, extra stars, scenery, or cast shadows outside the artwork.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements and the two infinity holes. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

