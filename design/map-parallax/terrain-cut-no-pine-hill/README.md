# Terrain aprobado sin la loma lejana de pinos del inicio

Revisión de `../terrain-cut-with-trees/`: la loma de pinos detrás del árbol grande
izquierdo pasa a las capas posteriores. El árbol grande, las lomas próximas al
camino y toda la parte inferior permanecen en terrain.

Se reutiliza la máscara de la extracción de IA ya existente y se elimina la
restitución local de aquella loma junto con los dos pinos aislados. No hay una
nueva generación ni se sustituyen colores: el RGB sigue siendo el del terreno
actual `../ai-v2/terrain-background.png`. El ajuste solo modifica el alfa.

`build_preview.py` produce el PNG transparente `terrain-proposed.png`, la vista
con límite amarillo `terrain-cutline.png`, su máscara y las revisiones sobre
fondos claro y oscuro. La salida conserva 2172 × 724 píxeles.

El usuario aprobó este corte y está integrado en `assets/images/map/layers/terrain.png`
con 128 píxeles de margen. `../ai-v2/build_assets.py --install` reproduce la instalación
usando esta máscara. Las capas profundas se generan por separado en
`../background-v3/`. La imagen original y foreground permanecen sin cambios.
