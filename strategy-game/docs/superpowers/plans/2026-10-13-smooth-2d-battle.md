# Smooth 2D Battle Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native implementation. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the existing Godot battle a cohesive, smooth, readable 2D tactical look inspired by the visual restraint of *Bad North*.

**Architecture:** Keep the battle, unit, input, and menu scene structure. Replace the current dense pixel assets with original smooth raster art, then tune CanvasItem filtering, effects, and panel colors around those assets. Use the existing animation state machine and battlefield coordinates without altering combat rules.

**Tech Stack:** Godot 4.7, GDScript, `AnimatedSprite2D`, `AtlasTexture`, original PNG assets generated through the built-in image generation tool.

**Spec:** `strategy-game/docs/superpowers/specs/2026-10-13-smooth-2d-battle-art-direction.md`

## Global Constraints

- The game stays fully 2D in Godot; no 3D nodes or models.
- Keep combat rules, stats, AI, collisions, squad commands, selection geometry, input, and camera perspective unchanged.
- Preserve the current chibi proportions, role equipment, blue/red identification, three animation states, and fixed foot anchor.
- Use original art; the reference supplies visual direction only.
- Keep the central field low contrast and decorations clear of unit command targets.

## Review Focus

1. **Missing or invalid terrain texture:** the battle scene should still load and render its expected field; Task 2 adds a texture load assertion and runs `hud_smoke.gd`.
2. **Irregular atlas frame boundaries:** no stray sprite fragments or cropped equipment should appear; Task 3 checks every frame region against its source and inspects all roles in combat.
3. **Crowded formations at zoom limits:** all roles and team colors should remain legible; Task 3 checks 40 vs 40 at default, minimum, and maximum zoom.
4. **Small supported window:** HUD controls and counters should remain visible; Task 4 runs `hud_smoke.gd` at its 1152 × 648 and 1440 × 900 checks.
5. **Menus and combat after palette changes:** Start Game, pause, options, and battle results should still work; Task 4 runs menu and battle-result smoke tests.

## File map

- `assets/terrain/battlefield_smooth.png`: low-noise original field and road, drawn below every unit.
- `assets/units/{role}_{team}.png`: ten smooth 1254 × 1254 animation atlases for five roles and two teams.
- `scripts/battle.gd`: terrain resource path and drag marker drawing; battle logic is untouched.
- `scenes/battle.tscn`: battle texture filtering and HUD palette.
- `scripts/unit_visuals.gd`: inspected frame regions and animation setup.
- `scenes/unit.tscn`: smooth sprite filtering, scale, and foot anchor.
- `scripts/unit.gd`: restrained 2D shadows and combat feedback only.
- `scripts/main_menu.gd`, `scenes/main_menu.tscn`, `scenes/game_menu.tscn`: menu background and coordinated panel palette.
- `tests/unit_visual_smoke.gd`, `tests/hud_smoke.gd`, `tests/main_menu_smoke.gd`, `tests/result_smoke.gd`: focused regression checks.

## Task 1: Battle direction sample

**Files:** Create `strategy-game/docs/art/smooth-battle-direction.png`. Do not change game code in this task.

**Interfaces:** Consumes the approved spec and a screenshot of current deployment; produces a visual reference for Tasks 2–4.

- [ ] **Step 1: Capture the baseline.** Run `Godot --path strategy-game res://scenes/battle.tscn`, capture the deployment view, and record the current default camera zoom (`0.8`) and field size (`1600 × 900`).
- [ ] **Step 2: Generate one original 16:9 battle direction image.** Use the built-in image generation tool with this brief: “Smooth 2D painted tactical medieval battle, small readable blue and red chibi squads, broad muted sage grass, simple winding tan road through the middle, sparse rounded edge trees, matte light, soft ground shadows, understated dark HUD, no pixel grid, no 3D perspective, no text, no copied game assets.” Copy the final PNG into `docs/art/`.
- [ ] **Step 3: Compare at gameplay scale.** Display the sample at 1152 × 648 and 2560 × 1600; check whether the 40-vs-40 groups remain visually separable, the road does not dominate the center, and the palette works with HUD labels.
- [ ] **Step 4: Show the sample to the player.** Use `open_in_codex` and a local image preview. Apply any correction to the sample before generating production assets.
- [ ] **Step 5: Commit.** `git add strategy-game/docs/art/smooth-battle-direction.png && git commit -m "Define smooth battle visual target"`.

## Task 2: Smooth battlefield environment

**Files:** Create `strategy-game/assets/terrain/battlefield_smooth.png` and its Godot `.import`; modify `strategy-game/scripts/battle.gd`, `strategy-game/scenes/battle.tscn`, and `strategy-game/tests/hud_smoke.gd`.

**Interfaces:** Consumes the approved sample; produces `TERRAIN_TEXTURE: Texture2D` rendered across `FIELD_SIZE`.

- [ ] **Step 1: Generate the production terrain.** Use the sample as a style reference. Create an opaque 16:9 smooth 2D field without characters or UI, with a subdued road near the current center and sparse scenery at the top/bottom edges. Copy it to `assets/terrain/battlefield_smooth.png`.
- [ ] **Step 2: Check the asset before wiring it.** Verify its width and height are at least 1024 × 576 and its aspect ratio is within 0.05 of 16:9. Reject noisy or high-contrast versions while the asset is still replaceable. Add this check near the beginning of `hud_smoke.gd`'s `_run()`; it also confirms Godot can load the final image:

```gdscript
var terrain := load("res://assets/terrain/battlefield_smooth.png") as Texture2D
if terrain == null or terrain.get_width() < 1024 or terrain.get_height() < 576 or absf(float(terrain.get_width()) / float(terrain.get_height()) - 16.0 / 9.0) > 0.05:
	_fail("Smooth battlefield texture is missing or has the wrong size")
	return
```
- [ ] **Step 3: Switch the battle resource.** In `battle.gd`, replace only the terrain preload:

```gdscript
const TERRAIN_TEXTURE: Texture2D = preload("res://assets/terrain/battlefield_smooth.png")
```

- [ ] **Step 4: Enable smooth filtering.** In the root `Battle` node of `battle.tscn`, set `texture_filter = 2` (`CanvasItem.TEXTURE_FILTER_LINEAR`). Keep `draw_texture_rect(TERRAIN_TEXTURE, Rect2(Vector2.ZERO, FIELD_SIZE), false)` and all battle coordinates.
- [ ] **Step 5: Import and test.** Run `Godot --headless --editor --path strategy-game --quit`, then `Godot --headless --path strategy-game --script res://tests/hud_smoke.gd`. Expect import success and `HUD smoke passed`. Visually inspect the field with units at default zoom.
- [ ] **Step 6: Commit.** Add the new PNG, `.import`, `battle.gd`, and `battle.tscn`; commit `"Replace pixel battlefield with smooth 2D terrain"`.

## Task 3: Smooth role and team sprites

**Files:** Replace the ten `strategy-game/assets/units/{role}_{team}.png` assets and imports; modify `strategy-game/scripts/unit_visuals.gd`, `strategy-game/scenes/unit.tscn`, and `strategy-game/tests/unit_visual_smoke.gd`.

**Interfaces:** `frames_for(unit_type: int, team: int, is_general: bool) -> SpriteFrames` stays unchanged. Every returned set retains `idle`, `walk`, and `attack`, each with three frames.

- [ ] **Step 1: Create one shared character guide.** Use the approved sample and current silhouettes to specify matte steel, simplified cloth and leather, soft antialiased edges, common three-quarter pose, and a fixed foot baseline. Generate each role with the same guide; generate both blue and red versions without moving equipment or changing pose order.
- [ ] **Step 2: Inspect all 90 visible frames.** For ten sheets × three states × three used poses, check alpha boundaries and foot alignment. Record per-role/team row origins and any pose-specific column choice in `unit_visuals.gd`; keep every `Rect2` within the 1254 × 1254 sheet. Do not assume the generated grid is regular.
- [ ] **Step 3: Update the focused test first.** Keep checks for roles, teams, paths, animation transitions, and prebattle type changes. Change the filter expectation in `unit_visual_smoke.gd` to:

```gdscript
if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
	_fail("Smooth sprite is not using linear filtering")
	return
```

Add a check for every generated `AtlasTexture.region`:

```gdscript
if frame.region.position.x < 0.0 or frame.region.position.y < 0.0 or frame.region.end.x > frame.atlas.get_width() or frame.region.end.y > frame.atlas.get_height():
	_fail("Sprite frame extends beyond source atlas")
	return
```

- [ ] **Step 4: Run the updated test and observe the expected filter failure.** Run `Godot --headless --path strategy-game --script res://tests/unit_visual_smoke.gd`; it should fail until the scene filter changes.
- [ ] **Step 5: Wire the assets.** Change `AnimatedSprite2D.texture_filter` to `2` in `unit.tscn`. Keep its existing offset and tune scale only if the new sprites materially change unit footprints. Update `unit_visuals.gd` regions and validate every frame in the running game.
- [ ] **Step 6: Re-test.** Run `unit_visual_smoke.gd`, `unit_types_smoke.gd`, and `natural_battle_smoke.gd`. Inspect idle/walk/attack and both teams in a 40-vs-40 battle at default, minimum, and maximum zoom. Confirm no chopped weapons, extra fragments, or jumping foot anchors.
- [ ] **Step 7: Commit.** Add the ten PNGs/imports, loader, scene, and test; commit `"Restyle tactical units as smooth 2D characters"`.

## Task 4: Effects, HUD, and menus

**Files:** Modify `strategy-game/scripts/unit.gd`, `strategy-game/scenes/battle.tscn`, `strategy-game/scripts/main_menu.gd`, `strategy-game/scenes/main_menu.tscn`, and `strategy-game/scenes/game_menu.tscn`; test `strategy-game/tests/hud_smoke.gd`, `strategy-game/tests/main_menu_smoke.gd`, and `strategy-game/tests/result_smoke.gd`.

**Interfaces:** Existing signals, button paths, action labels, command handlers, and scene transitions remain unchanged.

- [ ] **Step 1: Tune effects.** In `unit.gd`'s `_draw()`, retain the shadow, selection, attack, shot, hit, routing, and health cues, but use a softer olive shadow and narrower translucent combat arcs. Do not edit timers or damage logic.
- [ ] **Step 2: Simplify the menu background.** Replace `main_menu.gd`'s checkerboard rectangles and block troops with a low-contrast smooth 2D battlefield treatment or a derived original menu image. Keep the title and button hierarchy.
- [ ] **Step 3: Align scene palettes.** In the three `.tscn` files, choose muted charcoal-green panels, one warm accent for primary actions, and blue/red battle counters. Preserve text contrast and all node names.
- [ ] **Step 4: Run regression checks.** Run `hud_smoke.gd`, `main_menu_smoke.gd`, and `result_smoke.gd`; expect their success messages. Inspect menu, options, deployment, battle, pause, and result screens at 1152 × 648 and 1440 × 900.
- [ ] **Step 5: Review gameplay boundaries.** `git diff` should show only assets, visual drawing, texture settings, scene styles, and focused visual tests. Run `git diff --check` and inspect a complete battle for role readability and control visibility.
- [ ] **Step 6: Commit and push.** Commit `"Polish smooth 2D battle effects and interface"`, then push the completed visual pass to `main` if the session's existing push authorization still applies.
