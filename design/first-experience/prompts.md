# Prompts de la primera experiencia

## Reglas vigentes para producir e integrar recursos

- Las láminas completas de los pasos 01–10 son referencias visuales. Para la UI se extrae cada elemento necesario por separado: personaje, iconos y superficies vacías de modales, paneles y cards. No usar una lámina completa ni un modal aplanado como imagen de la pantalla.
- Reutilizar primero los botones amarillos, cards, paneles y demás recursos existentes de home, ajustes y mapa. Generar únicamente el arte que falte.
- Las superficies adaptables usan nine-patch: mantener esquinas y biseles fijos y ampliar solo las zonas centrales. En los botones, usar `IllustratedActionButton` para ajustar el ancho a la etiqueta sin deformar el PNG ni forzar saltos de línea. Si hace falta arte nuevo para una superficie adaptable, pedir esquinas definidas y una zona central continua apta para este escalado.
- Todos los textos se escriben con `Text` de Flutter, incluidos títulos, instrucciones, etiquetas de botones, estados y valores variables. El texto citado en el guion es contenido para Flutter, no una instrucción para dibujarlo dentro del PNG.
- Botones amarillos de acción siempre abajo, dentro de `SafeArea`. El resto del contenido principal se centra en el espacio disponible por encima; encabezados y navegación conservan su zona superior. Aplicar la misma distribución en horizontal, con texto ampliado y en pantallas pequeñas; el contenido central puede desplazarse sin quedar tapado por las acciones.
- Mantener una sola introducción por pasos, con estado compartido. El tablero y sus resaltados son interactivos y las reglas se explican sobre el tablero real.
- Todos los recursos nuevos deben ser PNG RGBA con fondo realmente transparente, también entre elementos. Verificar alfa y apariencia antes de integrarlos.

## Plantilla vigente para cada extracción o generación

Reemplazar el recurso solicitado y la referencia, emitir un recurso independiente por llamada y conservar siempre los dos párrafos finales. Si ya existe un recurso reutilizable, no generar otro.

```text
Use case: background-extraction (or stylized-concept only for missing artwork).
Requested asset: [one specific foreground element needed for this step].
Reference: [approved concept as edit target, or existing SunDoku art as style reference].
Preserve SunDoku's existing character identity, soft sculpted 3D finish, ivory and gold materials, and navy accents. Extract only the requested element, fully visible with clean margins. Remove all other scene and UI elements. Modal, panel, card and button surfaces must be blank and reusable.

Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```

## Archivo histórico de los conceptos aprobados

Los prompts siguientes documentan exactamente las láminas que ya se generaron. Sus instrucciones de dibujar textos o pantallas completas no se reutilizan para producción; las reglas y la plantilla vigentes de arriba las sustituyen para cualquier trabajo nuevo.

Modo: herramienta integrada image_gen. Referencias: home-phone.png y map-phone.png de la carpeta de capturas de esta tarea. Se generó una lámina por paso; los pases de limpieza alfa se documentan por separado en esta carpeta.

## Instrucción visual histórica común

Use case: ui-mockup. Create one polished portrait storyboard keyframe for SunDoku's beginner onboarding, 1024x1536. Input image 1 is STYLE AND MASCOT REFERENCE: preserve the exact adorable golden sun character, rounded triangular sun rays, huge warm dark eyes, navy hoodie with tiny gold sun emblem; same sculpted soft 3D mobile-game finish. Input image 2 is UI MATERIAL REFERENCE: warm ivory cards, cream upper rims, champagne-gold lower bevels, deep navy rounded Baloo-like lettering, luminous yellow tactile buttons. These are references, not edit targets. This is a new UI-only illustration. NO landscape background, no new scenery, no phone frame, no device bezel, no watermarks. Real transparent RGBA PNG background: zero alpha outside the illustrated UI, cards, character and tiny contact shadows. Never draw a checkerboard or opaque backdrop. Center the entire composition with generous transparent margins. Render frontal readable UI, not an angled board. Keep all text in clear correctly spelled Spanish. Short heading at top on cream pill, main learning object centered, small friendly sun mascot beside a bottom cream explanation card, gold primary action below. Large readable numbers. Strong navy numerals and fine warm gray internal grid lines, with bold navy dividers every third row and column. Each grid cell MUST be geometrically exact. No extra decorative numerals or duplicate text. Use restrained highlights, not distracting confetti except on success scenes.

## 01-bienvenida

STEP 01, welcoming history. Top pill exact text "Tu primer sudoku" with small subtitle "NIVEL 1 · PARTIDA 1 DE 3". Main object: our exact sun mascot from image1 sitting beside a small open cream puzzle booklet, showing a simple blank 3x3 grid; one tiny familiar gold sun emblem. Friendly inviting expression, waving once. Below, a large ivory card contains this exact short history in three neatly spaced lines/paragraphs: "Antes se llamaba Number Place." "En 1984, Nikoli lo llevó a Japón." "Allí recibió el nombre Sudoku." A separate emphasized final sentence "No necesitas hacer cuentas." Gold CTA exact text "Vamos paso a paso". Aim at a complete beginner; warm, quiet, inviting composition. No flags, cultural stereotypes, invented historical imagery or new mascot.

## 02-bloque

STEP 02, place nine digits freely in one box. Top pill exact text "Empecemos con 9 casillas". Main learning object: one large isolated 3x3 square board ONLY THREE ROWS AND THREE COLUMNS, thick rounded ivory frame and a gold outline, exactly nine square cells. Front-on, no perspective. For this snapshot place exactly these rows in navy: first row "8 3 5", second row "4 1 6", third row "9 2 [empty]". Bottom-right empty cell glows pale yellow. Immediately below the board a single large gold number tile "7" with a navy upward arrow aimed at the empty bottom-right cell; this is the last unused number. Small sun mascot points to the board from beside the bottom card. Bottom cream instruction card exact text "Del 1 al 9, una vez cada uno." and below "Elige el orden que quieras." Small progress exact text "8 de 9 colocados". No CTA button other than the interactive number tile7. Preserve the exact numbered board content, especially the central1 and emptylower-rightcell.

## 03-expansion

STEP 03, the small block expands into a real sudoku. Top pill "Tu bloque es parte del tablero". Large full SQUARE9x9 board of exactly81squarecells, exactly9rowsand9columns, bold dividers afterrow3,afterrow6,aftercolumn3,aftercolumn6, making NINE3x3blocks. The center3x3block, rows4–6columns4–6, has a bright golden border and these exact numbers: row4columns4,5,6 =8,3,5; row5=4,1,6; row6=9,2,7. All72othercells completelyblank. The eight surrounding3x3blocks are fully visible; subtle small gold outward arrows OUTSIDE the board suggest they just unfolded from the center. No duplicate insetgrid, keep oneexactboard. Small sun mascot at lowerleft. Bottom cream card exact text "9 bloques forman el tablero." and "En cada bloque: del 1 al 9, sin repetir." Gold CTA "Ver las filas".

## 04-filas

STEP 04, teach a horizontal ROW. Top ivory title pill exact text "Una fila cruza todo el tablero". Main object is one exact square Sudoku board9x9,81cells, nine3x3blocks: strong navy dividers aftereach3cells. All cells BLANK except central3x3 at rows4,5,6 and columns4,5,6, which reads 8 3 5 / 4 1 6 / 9 2 7. Highlight ONLY the fifth row of ninecells with a pale golden horizontal band, crossing all threeblocks fromlefttoright; its onlyexistingnumbers are4atcolumn4,1atcolumn5,6atcolumn6. Rows4and6number cells remainivory. Use a slightlystronggoldborder onthecentral1. Place navy horizontal directional arrows immediatelyoutsideboard onleftandright alignedwithrow5 to showitsfullwidth. No othernumbers anywhere inboard. A small exact SunDoku sun-hoodie mascot at bottomleft OUTSIDEBOARD points horizontally. Bottom cream instruction "En cada fila: del 1 al 9, sin repetir." and a smaller secondline "Mira sus nueve casillas." Gold CTA "Ver las columnas". Do NOT highlight threeentireblocks or onlythecentralblock; highlight one ninecellrow.

## 05-columnas

STEP 05, teach a vertical COLUMN. Match previous step's exact 9x9 squaregrid81cells andnine3x3blocks, front-on, strong navy dividers every3cells. Top title "Una columna va de arriba abajo". All cells BLANK except the centered3x3 with EXACTnumbers rows4–6 columns4–6 =8 3 5 / 4 1 6 / 9 2 7. Highlight ONLYcolumn5 as a softgold verticalstripe coveringallninecells; its existingnumbers are3atrow4,1atrow5,2atrow6. Add navy up/down arrows outside board aligned with column5 and thinbrightgold frame on central1. Allothercellscream. Small sunhoodiemascot belowboard, never overlapping boardcells. Bottomcreamcard exact text "En cada columna: del 1 al 9, sin repetir." and "Bloque, fila y columna: las tres reglas." Gold CTA "Probemos juntos". Do not shade awholebandofthreecolumns; highlight a SINGLE ninecellcolumn.

## 06-primera-partida

STEP 06, solving the first almost-complete Sudoku with a reason. Top pill "Busquemos el número que falta", smallsubheading "PARTIDA 1 DE 3". Main object square9x9gridof81cells, nine3x3blocks, exactnavyvisiblegivennumbers as follows; periods mean EMPTYcells and mustNOTbeprinted:
69278.541
78.541692
541692783
.278354.6
835416927
416927835
278354169
3541.92.8
169278354
Read carefully: EXACTLY6emptycells total at row1col6,row2col3,row4col1,row4col8,row8col5,row8col8. Central3x3mustremain835/416/927. Highlight row2 ONLY as agold horizontalstrip, and give its emptythirdcell a goldoutlinedpulse. Firstrowandotherrowsremainivory. Directlybelowboard add a short palette of nine roundcreamnumberbuttons 1,2,3,4,5,6,7,8,9 inoneevenrow, with onlybutton3gold. Small SunDoku mascot besidebottomcardwithoutcoveringboard. Bottomcardexacttext "En esta fila solo falta el 3." and "Toca la casilla y después el 3." No automaticplacement, noillustratedhandcoveringcells. No other CTA. Mathematical correctness essential; no duplicatednumberwithinrow/column/block.

## 07-primer-logro

STEP 07, celebrate first Sudoku solved and transition to second. Titlecreamplaque "¡Tu primer sudoku!" with smallline "NIVEL 1 · 1 DE 3 COMPLETADOS". Main image: existinggoldenSunDoku level1medallionfrommapreference, exactthickgoldcoinwithnavy1, navycurvedribbonandgoldtrim; ONEgoldstar onleft andTWOivoryunearnedstars(centerandright), allthreedistinct. Underthismascotfullbodywarmlycelebrateswithhandsup, sameexactgoldensun/navyhoodie, a FEW tinygoldandskyblueconfettipiecesontransparentalpha. Lowercreamcardexacttext "Lo resolviste paso a paso." and "Vamos a practicar una vez más." GoldCTA "Vamos al segundo". No9x9boardneededhere. Do NOT implylevel1completed; thisisonlyfirstofthreepuzzles. Keepgeneroustransparentoutsideedges.

## 08-segunda-partida

STEP 08, practice with optional help. Top ivory pill exact text "Ahora elige dónde empezar" and smaller "NIVEL 1 · PARTIDA 2 DE 3". Small progress shows one earned goldstar followed by two ivory stars. Main board is exactly9x9squarecells with thick navy dividers every3rowsandcolumns. Exact given digits, periods mean EMPTY cells notprinted:
7.3541.6.
692783451
5416928.3
927835146
...416297
41.927385
278354619
3541697.8
169.785..
There are exactly12 emptycells. No cell or answer is automatically highlighted, all givensdarknavy on ivory, all blanksblank. Center3x3remains835/416/927. Beneathboard asingleevenrowofninecreamnumberbuttons1through9, all equal emphasis. Small sunmascot besidebottomcreamcard, NEVERcoverboard. Bottom instruction exact text "Busca una fila, columna o bloque casi completo." and "Si lo necesitas, te doy una pista." A small golden button with existingSunDoku sunemblem reads "Dame una pista". Make clear optional support with less handholding thanfirstgame, no numbersoutsidepalette orgrid.

## 09-tercera-partida

STEP 09, a gentle independent third Sudoku. Title exact text "Este lo empiezas tú" with subheading "NIVEL 1 · PARTIDA 3 DE 3". Small progress two earned goldstars, one ivoryempty star. Main board exactly9x9,81cells,nine3x3blocks, allbolddividers exact. Exact given digits, periodsmeanEMPTYcellsnotprinted:
29678..41
38.54.692
..5692783
72983541.
.3.416927
61.927835
961.78.54
4..16..78
.7.354169
Exactly18emptycells. Center3x3mustread835/416/927. Noautomaticcellselection, allgiven digitsnavyonivory. Beneathboardoneevenrowofnumberbuttons1through9, no answer highlighted. Sunhoodiemascot now SMALLER atbottomleft toleaveplayerautonomy, butsamecharacterandstyle. Creambottomcardtext "A tu ritmo. Las tres reglas te acompañan." and smallgoldbutton "Necesito una pista". No timer, no hearts, no penalty icons, noextratext.

## 10-nivel-completo

STEP10, all three introductory sudokus completed. Topivoryplaque exacttext "¡Completaste el nivel 1!" and subheading "3 DE 3 SUDOKUS". Heroobject oneexistingSunDoku goldlevel1medallion with navy1, attachednavyribbonwithgoldtrimandTHREEearnedgoldstars, exactmaterialandstylefrommapreference. Mascotgoldensuninbluehoodieproudlysmilesbesidethemedal, holdsnoobjects. Smallamountofelegantgoldconfettifloatsongenuinetransparency. Creambottomcardexacttext "Ya sabes mirar bloques, filas y columnas." and secondline "Tu aventura acaba de empezar." GoldCTA "Volver al mapa". Underbuttonsmallcreamstatuspill "Nivel 2 desbloqueado". Joyfulbutquiet, generousspacing, no gridnecessary, no invented scenery. Showfirstlevelmasteryandall3starsconsistentwithgameprogress.
