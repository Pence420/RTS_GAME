# Character visual pass — phase 1

## Intent and scope

The player wants the current tactical battle to look like a polished, stylized 2D medieval RTS. The reference is the broad art direction of *They Came for the Crown*: readable small soldiers, warm materials, and a three-quarter battlefield view. All new assets must be original. The game stays entirely in Godot's 2D renderer.

This specification covers only phase 1: replacing the procedural soldier drawings with cohesive character sprites and adding readable idle, walk, and attack animation. It does not change battle rules, unit stats, command behavior, selection geometry, input, collision, or AI. The eight previously selected gameplay features are deferred until the visual pass is reviewed.

## Existing implementation

`scenes/unit.tscn` is a `CharacterBody2D` with no sprite child. `scripts/unit.gd` draws the body, equipment, shadows, selection indicators, health bar, arrow trace, and hit feedback in `_draw()`. Unit movement and combat states already drive `velocity`, `state`, `attack_fx_timer`, and other visual timers. Terrain is drawn procedurally in `scripts/battle.gd`. There are no character bitmap assets in the project.

## Phase breakdown

1. **Characters now:** original sprites for swordsman, spearman, axeman, archer, and general; blue and red team variants; aligned idle, walk, and attack frames; soft ground shadows. Keep existing battlefield and effects for this phase.
2. **Environment later:** authored grass, path, rocks, and tree assets with coherent colors and depth ordering. This is a visual pass only; terrain mechanics remain a separate gameplay feature.
3. **Motion and effects later:** death animation, stronger impact and projectile art, dust, lighting accents, and final polish across units and terrain.

## Art direction and assets

Characters use a consistent three-quarter, top-down view with compact proportions and clear equipment silhouettes. Spearmen carry a long vertical diagonal spear; swordsmen have shield and short blade; axemen have a broad axe; archers have bow and quiver; generals have a distinct cloak and banner or crest. Steel, leather, cloth, and wood should read as materials at gameplay zoom. Blue and red cloth identify teams without changing equipment shapes. The art uses a restrained earthy palette, soft painted shading, clean edges, and transparent backgrounds. No text, watermarks, or borrowed game assets.

Each character type uses the same canvas size and a fixed foot anchor, so switching animation cannot make a unit jump. Source images and final game-ready frames live under `res://assets/units/`. Team variants can be derived by controlled cloth recoloring if they remain equally readable. The final in-game size must remain close to current unit footprints, and silhouettes must remain distinct at the default camera zoom.

## Godot integration

Add an `AnimatedSprite2D` child to `scenes/unit.tscn`, backed by `SpriteFrames` resources or imported frame textures. Godot supports sprite sheets and individual frames in `AnimatedSprite2D` ([Godot 2D sprite animation guide](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)). `unit.gd` selects the sprite set by unit type and team and changes animation using existing state and attack events. Idle loops while stationary, walk loops while moving, and attack plays briefly when damage is dealt before returning to the appropriate state. Horizontal mirroring follows the existing team facing. Animation timing must not delay or trigger attacks; gameplay remains authoritative.

Keep selection rings, general aura, health bars, arrow traces, and hit feedback in `_draw()` for phase 1. Remove only the procedural body and equipment artwork after the new sprites are verified. A soft oval shadow remains under each sprite and follows its foot anchor. Character art must render above the shadow and beneath selection/status overlays. Sprite import filtering should preserve intentional detail without introducing blur or jagged shimmering at the normal zoom range.

## Validation

- Inspect every unit type and both teams in a running battle at default zoom and at the camera's min/max zoom, including crowded formations.
- Check idle, walk, and attack transitions, facing, anchor alignment, silhouette clarity, and whether health/selection overlays remain legible.
- Run the existing Godot headless smoke tests covering unit types, combat, commands, menu flow, touchpad controls, and battle results. Add a focused visual-state test only if it catches a real integration risk that the existing tests cannot cover.
- Confirm no game rules, unit stats, collision, target selection, or input behavior changed.

## Out of scope

No Blender or 3D pipeline, no new gameplay mechanics, no terrain rewrite, no new tutorial or persistent order markers, and no death/FX overhaul in phase 1.
