# Smooth 2D battle art direction

## Intent

The player selected *Bad North* as the closest visual reference. The current pixel-art terrain is too busy and coarse and gives the battlefield a JRPG-map feel. The soldier designs and their role silhouettes are acceptable; the player wants the entire presentation to feel smoother and more like a readable tactical battle. The game remains fully 2D in Godot, with no gameplay rule changes.

Use the reference for clarity, shape language, restraint, and soft depth, not for copied assets or a 3D rendering pipeline. All replacement art must be original.

## Current state

- `scripts/battle.gd` draws one detailed pixel-art battlefield image across the 1600 × 900 field. Most terrain features are baked into that image.
- Five unit roles in two team colors use pixel-art animation atlases via `scripts/unit_visuals.gd` and `scenes/unit.tscn`. Idle, walk, and attack are already driven by gameplay state.
- `scripts/unit.gd` draws selection, shadows, health, attack, projectile, and hit cues. The battle HUD and main menu use dark flat panels.
- Earlier smooth chibi atlases exist in commit `b6c24ec`, but their glossy armor and dense character detail are only design references, not the target to restore unchanged.

## Chosen approach

Create a cohesive set of smooth 2D raster assets with matte shading, rounded silhouettes, muted greens and earth tones, and restrained detail. The center of the field has low contrast and sparse decoration. Road edges, rocks, and foliage read as broad soft shapes. Trees and larger props stay near field edges and do not obscure units or input targets.

Keep the current chibi proportions, equipment identity, and blue/red cloth distinction. Redraw each role as a simplified smooth illustration: recognizable sword and shield, long spear, broad axe, bow and quiver, or general's banner. Keep faces and armor details understated so formations read at default zoom. Use consistent light direction, edge softness, and shadow treatment across terrain and characters. Avoid pixel outlines, glossy highlights, heavy texture noise, and large attack flourishes.

Use Godot's 2D sprites and CanvasItem drawing. No 3D nodes, 3D models, shaders as a substitute for art, camera perspective change, or gameplay changes. Switch replacement smooth assets to linear texture filtering while preserving clear silhouettes at zoom limits.

## Approaches considered

- Blurring the current pixel images would retain their dense JRPG-style texture and soften unit edges without improving composition.
- Restoring the prior smooth chibi sheets unchanged would restore antialiased edges but preserve glossy, high-detail character rendering.
- The chosen redraw keeps the existing unit design while simplifying both characters and field into one art direction.

## Delivery sequence

1. **Battle direction sample.** Produce one original composed 2D battle view using the current roster and layout as a reference. It establishes palette, terrain detail density, character finish, shadows, and UI tone. Compare it with an in-game screenshot before replacing every atlas.
2. **Environment.** Replace the busy background with a quieter smooth field and road. Add only restrained edge scenery that preserves the same play space. The existing coordinates and gameplay geometry remain unchanged.
3. **Units.** Replace the ten role/team atlases with coherent smooth art. Preserve animation states, frame counts, role mappings, foot anchors, facing, and combat timing. Inspect actual frame boundaries rather than assuming generated sheets use a perfect grid.
4. **Effects and interface.** Soften shadows and combat cues, and align HUD/main-menu colors and panel treatment with the field. Keep control labels, actions, and information accessible.

The sample is a visual approval point. Subsequent stages should be validated independently so inconsistent assets are not propagated through the full set.

## Acceptance checks

- At default camera zoom, all five roles are distinguishable in crowded formations; blue and red teams are immediately separable.
- The battlefield reads as an open tactical arena. Decorations do not compete with squads or hide selection and drag feedback.
- Idle, walk, and attack frames stay anchored; no chopped weapons, stray atlas fragments, or visible jumps.
- UI text, health bars, selection rings, and target/drag feedback remain legible over the new palette.
- Inspect deployment and combat at default, minimum, and maximum zoom. Run focused visual, HUD, menu, and battle smoke tests. Confirm no changes to stats, AI, collision, commands, or input.

## Out of scope

No new unit classes, terrain mechanics, pathfinding changes, battle balance changes, or 3D conversion. Sound design and new game modes are separate work.
