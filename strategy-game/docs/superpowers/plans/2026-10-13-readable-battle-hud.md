# Readable Battle HUD Implementation Plan

> **For agentic workers:** Execute natively in this session, preserving the user's earlier choice. Track the tasks below in order.

**Goal:** Make chibi formations readable, add death splatter, and replace the verbose battle HUD with a compact portrait dock and Orders tray.

**Architecture:** Keep battle commands in battle.gd. A CanvasLayer HUD script manages presentation and portrait signals; a Control drawing script renders the olive frames. Death effects live on a ground layer independent of squad lifetime.

**Tech Stack:** Godot 4.7, GDScript, CanvasItem drawing, existing raster sprite atlases, native SVG icons.

**Spec:** ../specs/2026-10-13-readable-battle-hud-design.md

## Global Constraints

- Keep the current smooth chibi artwork.
- Keep formation bonuses and unit statistics intact.
- Clicking HUD controls must never issue a world order or pan the camera.
- Dead portraits disable without changing the identity of remaining squad buttons.
- Effects survive removal of a squad's final soldier and draw below living units.

## Review Focus

- Minimum window size: default squads and dock controls stay visible.
- Open Orders tray: clicks do not reach battlefield drag handling.
- Last soldier dies: the ground stain survives squad deletion and later frees itself.
- Type change in deployment: portraits and animation phase update together.
- Routing or dead squad: portrait identity stays fixed and command buttons disable.

### Task 1: Formation readability

- [x] Measure alpha overlap using the actual idle textures at the scene sprite scale and slot offsets; fail above 10%.
- [x] Set unit scale to 0.18, slot spacing to Vector2(42, 50), and assign deterministic idle phase by slot index.
- [x] Adjust mirrored deployment lanes and camera/HUD safe margins.
- [x] Run visual and formation smoke tests; inspect deployment.

Files: scenes/unit.tscn, scripts/unit.gd, scripts/squad.gd, scripts/battle.gd, scripts/camera_controller.gd, tests/presentation_smoke.gd.

### Task 2: Compact HUD

- [x] Replace full-width panels with centered native olive frames and compact top strength bars.
- [x] Add stable General/A/B/C/D portrait selection signals in battle_hud.gd.
- [x] Put the existing formation, command, and pointer buttons in a default-hidden Orders tray, preserving their scene paths.
- [x] Replace four-line status with two lines plus tooltip details. Update HUD on roster, morale, type, selection, and phase changes.
- [x] Exclude the visible top controls, dock, and tray rectangles from world input for both mouse buttons.
- [x] Exercise selection, tray state, target prompts, zoom, menus, and touchpad drag at minimum and larger sizes.

Files: scenes/battle.tscn, scripts/battle_hud.gd, scripts/hud_frame.gd, scripts/battle.gd, assets/ui/menu.svg, assets/ui/orders.svg, tests/hud_smoke.gd, tests/touchpad_controls_smoke.gd, tests/presentation_smoke.gd.

### Task 3: Death feedback

- [x] Add a dedicated GroundEffects node and parent effects there before emitting the casualty signal.
- [x] Pass the current sprite texture, scale, flip, and offset to the death effect.
- [x] Render an irregular stain, brief droplets, and a falling sprite. Fade and free the complete effect after 3.5 seconds.
- [x] Kill the last soldier in a squad; assert effect survival, ground ownership, and cleanup.
- [x] Run battle, morale, result, and casualty regression tests; inspect combat, then commit and push the completed presentation pass.

Files: scripts/death_effect.gd, scripts/unit.gd, scenes/battle.tscn, scripts/battle.gd, tests/presentation_smoke.gd.

Validation completed: all 18 game tests passed; deployment, expanded Orders, death splash, and fading ground stains were inspected in rendered screenshots. Added a formation-edge regression after the wider Shield Wall exposed an out-of-field destination.
