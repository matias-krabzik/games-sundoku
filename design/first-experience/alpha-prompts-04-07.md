# Transparencia de escenas 04–07

Registro histórico de las láminas conceptuales, no plantilla de producción. Para recursos nuevos se aplica la [plantilla vigente](prompts.md): extraer elementos por separado, reutilizar botones/cards, superficies sin texto y textos mediante `Text` de Flutter; acciones amarillas abajo y contenido principal centrado. No repetir las instrucciones históricas de conservar texto dibujado o una pantalla completa.

Modo: herramienta integrada `image_gen`, edición de las escenas aprobadas mediante extracción de fondo. No se editó la aplicación ni se procesaron los píxeles con herramientas externas.

## Prompt final común

```text
Remove the background. Keep only the existing foreground artwork, isolated on genuine transparency. All gray and white checkerboard background pixels must have zero alpha, including all gaps around and inside the separate UI elements. Preserve all Spanish text, numbers, sudoku grid cells and line counts, characters, shapes, positions, sizes and opaque original colors exactly. Export RGBA PNG with real alpha. No checkerboard. No new background. No glow.
```

## Proveniencia

### 04-filas.png

- Entrada: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-9277c8b8-b5a5-41cc-9115-e073b2c3df71.png`
- Salida original: `/Users/mati/.codex/generated_images/01a08e44-d11a-7a92-87ac-954ad5b9681f/exec-df3fee85-5ee9-4697-be4a-0441fb069d0f.png`
- Copia de entrega: `/Users/mati/Projects/Games/SunDoku/sundoku/design/first-experience/04-filas.png`

### 05-columnas.png

- Entrada: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-1d7a0112-e5bf-41da-80b1-5bda1eb737bc.png`
- Salida original: `/Users/mati/.codex/generated_images/01a08e44-d11a-7a92-87ac-954ad5b9681f/exec-54d54fcb-56f8-47f5-89fe-810804848f7f.png`
- Copia de entrega: `/Users/mati/Projects/Games/SunDoku/sundoku/design/first-experience/05-columnas.png`

### 06-primera-partida.png

- Entrada: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-71a604bf-9eb8-44e3-a368-ccdd4245d553.png`
- Salida original: `/Users/mati/.codex/generated_images/01a08e44-d11a-7a92-87ac-954ad5b9681f/exec-b9eed24b-8496-4cb4-8e4e-b0f579d5ea47.png`
- Copia de entrega: `/Users/mati/Projects/Games/SunDoku/sundoku/design/first-experience/06-primera-partida.png`

### 07-primer-logro.png

- Entrada: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-26aa3f85-6999-4951-8cbb-1dfed3ba2daa.png`
- Salida original: `/Users/mati/.codex/generated_images/01a08e44-d11a-7a92-87ac-954ad5b9681f/exec-d1bbb38a-5a52-4e06-8ad4-66d9169032b7.png`
- Copia de entrega: `/Users/mati/Projects/Games/SunDoku/sundoku/design/first-experience/07-primer-logro.png`

## Validación

Las cuatro imágenes son PNG RGBA de 1024 × 1536. Canal alfa real en rango 0–254; el máximo corresponde a una opacidad del 99,6 %. Se conserva sin alterar el alfa devuelto por ImageGen. Los márgenes revisados en (512,20), (20,500), (1000,1000) y (512,1520) tienen alfa0 en las cuatro imágenes.

| Escena | Píxeles alfa 0 | Píxeles alfa ≤3 | Píxeles alfa ≥250 |
|---|---:|---:|---:|
| 04 · Filas | 35,92 % | 37,43 % | 60,94 % |
| 05 · Columnas | 34,93 % | 37,33 % | 60,54 % |
| 06 · Primera partida | 27,26 % | 28,91 % | 68,46 % |
| 07 · Primer logro | 52,37 % | 54,43 % | 43,27 % |

Revisión visual: textos españoles, cuadrículas 9×9, bloque central 835 / 416 / 927, fila y columna resaltadas y dígitos del sudoku se conservaron. En la escena 07 sigue habiendo una estrella dorada y dos crema sobre el medallón 1.

Los canales RGB bajo píxeles transparentes contienen colores interpolados dorados/azules; son invisibles cuando el visor respeta alfa. No son un nuevo fondo. Algunos visores técnicos muestran RGB sin componer la transparencia.
