# Limpieza de alfa — pasos 01 a 03

Registro histórico de las láminas conceptuales, no plantilla de producción. Para recursos nuevos se aplica la [plantilla vigente](prompts.md): extraer elementos por separado, reutilizar botones/cards, superficies sin texto y textos mediante `Text` de Flutter; acciones amarillas abajo y contenido principal centrado. No repetir las instrucciones históricas de conservar texto dibujado o una pantalla completa.

Edición mediante la herramienta integrada `image_gen`; sin edición de píxeles con scripts. Pillow se usó solo para inspección.

Los tres archivos finales tienen 1024 × 1536 píxeles, modo RGBA y alfa de 0 a 254. Las cuatro esquinas son completamente transparentes (alfa 0). El valor máximo 254 corresponde a una opacidad de 99,6 % y se conservó tal como lo devolvió la herramienta. Se verificaron visualmente los textos y la posición de los números. En el paso 02 el personaje se redujo y desplazó para dejar visible toda la casilla del 9.

## 01-bienvenida

- Entrada original: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-bb1f42ff-df23-4892-9995-cb8245a510d7.png`
- Primer pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-ae962c3d-b40c-4199-99ba-40bff3d03dc2.png`
- Segundo pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-d9b0eb78-b56a-4632-b7f3-94534a2487e1.png`
- Fuente final: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-d9b0eb78-b56a-4632-b7f3-94534a2487e1.png`
- Archivo del proyecto: `01-bienvenida.png`

### Prompt del primer pase

```text
Use case: background-extraction. This input image is the edit target. Produce a clean transparent PNG RGBA of this EXACT UI illustration. Remove ONLY the gray and white checkerboard pattern currently painted behind the UI. Every background pixel outside the actual UI artwork must have real alpha 0, not a painted transparency checkerboard, not white, not gray, not black. Preserve crisp anti-aliased art edges and any subtle real shadow alpha. Do not redraw, rephrase or alter the Spanish text, ivory/gold/navy palette, toy 3D materials, or visual style. The mascot, 3x3 notebook, both cream plaques, button, lettering, dimensions and positions must remain unchanged. Keep the original portrait aspect ratio. Output must include an actual alpha channel with completely transparent corners. NO checkerboard pattern of any kind may be baked into the output.
```

### Prompt del segundo pase

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork and text exactly.
```

## 02-bloque

- Entrada original: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-1a655c09-7bb0-4a66-8775-76e5b5c4391b.png`
- Primer pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-a35dafff-07b8-4421-8cdc-aafc289150e6.png`
- Segundo pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-d7b862d4-9111-47e8-9f06-b71ff98ad43c.png`
- Ajuste de personaje: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-f56e26d3-7f0c-4966-b8eb-290c81ff016d.png`
- Fuente final: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-6938c7a9-63d4-4171-98bd-3cf3f71ff2ed.png`
- Archivo del proyecto: `02-bloque.png`

### Prompt del primer pase

```text
Use case: background-extraction. This input image is the edit target. Produce a clean transparent PNG RGBA of this EXACT UI illustration. Remove ONLY the gray and white checkerboard pattern currently painted behind the UI. Every background pixel outside the actual UI artwork must have real alpha 0, not a painted transparency checkerboard, not white, not gray, not black. Preserve crisp anti-aliased art edges and any subtle real shadow alpha. Do not redraw, rephrase or alter the Spanish text, ivory/gold/navy palette, toy 3D materials, or visual style. Keep the 3x3 board with rows exactly [8,3,5], [4,1,6], [9,2,blank], the highlighted blank, separate 7 button and all lettering exactly unchanged. Also move the sun mascot slightly downward (and if necessary slightly left) or reduce it a little so no part of the mascot covers the bottom-left board cell containing 9. The entire 9 and its entire cell must be clearly visible. Keep mascot fully within canvas and above the bottom instruction plaque. All other elements fixed. Keep the original portrait aspect ratio. Output must include an actual alpha channel with completely transparent corners. NO checkerboard pattern of any kind may be baked into the output.
```

### Prompt del segundo pase

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork and text exactly.
```

### Prompt del ajuste del personaje

```text
Edit only the small sun mascot: shrink it by 25% and move it down so its highest ray is BELOW the entire 3x3 board's bottom edge. Keep its feet just above the bottom instruction plaque, and keep it at the left side. No part of the mascot may overlap ANY of the nine board cells. Preserve absolutely everything else: board digits, gold 7 button, Spanish lettering, plaques, progress bar, colors, textures and exact layout. Preserve the genuine transparent background with real alpha. No new background, no glow.
```

### Prompt final para restablecer el alfa

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork and text exactly.
```

## 03-expansion

- Entrada original: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-1c775de1-f16f-4c80-9ce0-73b061d95629.png`
- Primer pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-1def1fe7-e426-4f01-bd37-cb75d4cc6d7c.png`
- Segundo pase: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-f1181ed5-7549-4f4f-8c44-8d03e4cfdb7d.png`
- Fuente final: `/Users/mati/.codex/generated_images/01a08e40-346c-7e22-99b0-3a709a59e294/exec-f1181ed5-7549-4f4f-8c44-8d03e4cfdb7d.png`
- Archivo del proyecto: `03-expansion.png`

### Prompt del primer pase

```text
Use case: background-extraction. This input image is the edit target. Produce a clean transparent PNG RGBA of this EXACT UI illustration. Remove ONLY the gray and white checkerboard pattern currently painted behind the UI. Every background pixel outside the actual UI artwork must have real alpha 0, not a painted transparency checkerboard, not white, not gray, not black. Preserve crisp anti-aliased art edges and any subtle real shadow alpha. Do not redraw, rephrase or alter the Spanish text, ivory/gold/navy palette, toy 3D materials, or visual style. The full 9x9 board, gold framed center 3x3 block and its digits rows [8,3,5], [4,1,6], [9,2,7], mascot, arrows, plaques, button, all text and all placement must remain unchanged. Keep the original portrait aspect ratio. Output must include an actual alpha channel with completely transparent corners. NO checkerboard pattern of any kind may be baked into the output.
```

### Prompt del segundo pase

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork and text exactly.
```
