# Character Visual Phase 1 Implementation Plan

> Implementation record: the image generator produced 1254 × 1254 sheets. The final loader uses three clean cells per animation row because several fourth-column poses clip their cell. The character sheets were later restyled into chibi pixel art with nearest-neighbor filtering and no mipmaps. The code and tests are the source of truth for the shipped atlas contract.

**Goal:** Replace procedural soldier art with original, cohesive 2D sprites for five roles and two teams, with idle, walk, and attack animation, while preserving gameplay.

**Architecture:** Use one transparent 4-column by 4-row sprite sheet per role and team. A small visual resource module constructs `SpriteFrames` from fixed cells; `AnimatedSprite2D` in `unit.tscn` renders them. `unit.gd` maps its existing movement and combat state to animation without affecting simulation timing.

**Tech Stack:** Godot 4.7 GDScript, built-in image generation for original PNG sprite sheets, existing Godot headless smoke tests.

**Spec:** `strategy-game/docs/superpowers/specs/2026-10-12-character-visual-phase-1-design.md`

## Global Constraints

- Entirely 2D in Godot; no Blender or 3D model/rendering pipeline.
- No unit stat, collision, command, AI, targeting, input, or battle-rule changes.
- Original art only; *They Came for the Crown* is a mood reference, not an asset source or a design to copy.
- No terrain rewrite, new tutorial, persistent order markers, or death/FX overhaul in phase 1.
- Preserve current selection, aura, health, arrow trace, and hit overlays.

## File map

- `strategy-game/assets/units/<role>_<team>.png`: ten original transparent sprite sheets, one per role/team.
- `strategy-game/scripts/unit_visuals.gd`: one responsibility: validate sheet layout and build/cache `SpriteFrames` for a role/team.
- `strategy-game/scenes/unit.tscn`: adds the animated sprite child under the existing `CharacterBody2D`.
- `strategy-game/scripts/unit.gd`: selects the art and animation from existing state, keeps `_draw()` for overlays/shadow only.
- `strategy-game/tests/unit_visual_smoke.gd`: checks the asset mapping, animation transitions, and preservation of command/combat behavior.

## Review Focus

1. Missing or malformed sprite sheet: the focused test must fail before that build can ship. Covered by Task 1 validation and Task 3 regression gate.
2. Team/role mismatch: all ten combinations should resolve to the right sheet. Covered by Task 1 exhaustive mapping test.
3. Fast attack-to-walk transition: animation must not restart each frame or hide an attack entirely. Covered by Task 2 transition test.
4. Dense formations at camera zoom limits: all silhouettes, team colors, and overlays remain readable. Covered by Task 3 visual inspection.
5. Sprite migration accidentally changes movement or damage: existing combat, command, and touchpad smoke tests stay green. Covered by Task 3 regression run.

---

### Task 1: Original character sheets and loader

**Files:**
- Create: `strategy-game/assets/units/swordsman_blue.png`, `swordsman_red.png`, `spearman_blue.png`, `spearman_red.png`, `axeman_blue.png`, `axeman_red.png`, `archer_blue.png`, `archer_red.png`, `general_blue.png`, `general_red.png`
- Create: `strategy-game/scripts/unit_visuals.gd`
- Create: `strategy-game/tests/unit_visual_smoke.gd`

**Interfaces:**
- Produces: `UnitVisuals.frames_for(unit_type: int, team: int, is_general: bool) -> SpriteFrames`
- Produces: `UnitVisuals.validate_sheet(texture: Texture2D) -> bool`
- Frame contract: each sheet is 1254 × 1254, laid out as a four-column atlas with 314 × 314 sampled cells. Rows 0, 1, 2 are idle, walk, attack. Three clean frames are sampled per active row; the fourth column is skipped except for selected spear and axe attack poses. Assets are rendered at 0.22 scale in Godot.

- [ ] **Step 1: Generate the ten sheets using the built-in image generation tool.** Generate each role's blue sheet, then generate a red cloth variant using the blue sheet as an edit reference. Save all final PNGs in `assets/units/`. Use this prompt, replacing bracketed role/team descriptions with the exact role and cloth color:

```text
Use case: stylized-concept
Asset type: game-ready 2D character animation sprite sheet
Primary request: Original small medieval [ROLE] soldier with [BLUE/RED] team cloth, in a polished stylized hand-painted 2D indie RTS style. Four-column, four-row square atlas. Row 1: four subtle idle frames. Row 2: four walking frames with alternating legs. Row 3: four attack frames with readable [WEAPON] action. Row 4: transparent empty cells. Maintain exactly the same character, outfit, scale, lighting, and foot anchor across every frame.
Composition/framing: fixed three-quarter top-down camera angle; one centered full-body soldier in each of the twelve active square cells; generous transparent margins; no cell overlap.
Materials/textures: shaded cloth, worn leather, steel, wood; clear silhouette at small display size.
Constraints: transparent background, no terrain, no cast shadow, no grid lines, no labels, no text, no watermark, original character design, exact 4x4 cell layout.
```

Role descriptions: swordsman = short blade and shield; spearman = long spear; axeman = broad axe; archer = bow and quiver; general = cloak, crest, and command banner. Edit red variants by changing only team cloth color and preserving frame registration.

- [ ] **Step 2: Inspect and import every sheet before integration.** Reject or regenerate any sheet with merged cells, inconsistent character identity, clipped weapons, opaque background, foot-anchor drift, illegible team color, or missing attack motion. Verify pixel dimensions with `sips -g pixelWidth -g pixelHeight -g format` and alpha by visual inspection. Run `/Users/joshuats/Downloads/Godot.app/Contents/MacOS/Godot --headless --editor --import --path strategy-game --quit` so the PNGs are available to headless tests.

- [x] **Step 3: Write a focused loader test.** In `unit_visual_smoke.gd`, load `res://scripts/unit_visuals.gd`; for `team in range(2)` and each of the five roles, assert `frames_for(...)` is not null and has three frames each for `idle`, `walk`, and `attack`. Assert a deliberately invalid 128 × 128 `ImageTexture` fails `validate_sheet()`. Use the existing `SceneTree` test pattern and exit nonzero on failure:

```gdscript
extends SceneTree
const VISUALS = preload("res://scripts/unit_visuals.gd")

func _initialize() -> void:
	for team in range(2):
		for role in range(5):
			var frames: SpriteFrames = VISUALS.frames_for(mini(role, 3), team, role == 4)
			if frames == null:
				push_error("Missing role/team sprite: %d/%d" % [role, team])
				quit(1)
				return
			for animation in [&"idle", &"walk", &"attack"]:
			if frames.get_frame_count(animation) != 3:
					push_error("Wrong frame count: %s" % animation)
					quit(1)
					return
	var bad_image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	if VISUALS.validate_sheet(ImageTexture.create_from_image(bad_image)):
		push_error("Accepted malformed sheet")
		quit(1)
		return
	quit(0)
```

- [ ] **Step 4: Run the test red.** Run `/Users/joshuats/Downloads/Godot.app/Contents/MacOS/Godot --headless --path strategy-game --script res://tests/unit_visual_smoke.gd`; expect failure because `UnitVisuals` does not exist yet.

- [x] **Step 5: Implement `unit_visuals.gd`.** Use a `RefCounted` helper with static methods and a static cache. `validate_sheet()` returns true only for a non-null 1254 × 1254 texture. On invalid/missing assets, `push_error()` and return null; the test gate rejects that build. Core implementation:

```gdscript
extends RefCounted

const CELL_SIZE := 314
const ROLES := ["swordsman", "spearman", "axeman", "archer", "general"]
const TEAMS := ["blue", "red"]
const ANIMATIONS := [&"idle", &"walk", &"attack"]
static var cache: Dictionary = {}

static func validate_sheet(texture: Texture2D) -> bool:
	return texture != null and texture.get_size() == Vector2(1254, 1254)

static func frames_for(unit_type: int, team: int, is_general: bool) -> SpriteFrames:
	var role := 4 if is_general else clampi(unit_type, 0, 3)
	var side := clampi(team, 0, 1)
	var key := "%d_%d" % [role, side]
	if cache.has(key):
		return cache[key]
	var path := "res://assets/units/%s_%s.png" % [ROLES[role], TEAMS[side]]
	var texture := load(path) as Texture2D
	if not validate_sheet(texture):
		push_error("Invalid unit sprite sheet: %s" % path)
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in range(3):
		frames.add_animation(ANIMATIONS[row])
		frames.set_animation_loop(ANIMATIONS[row], row != 2)
		frames.set_animation_speed(ANIMATIONS[row], 18.0 if row == 2 else (6.0 if row == 0 else 9.0))
		for column in range(3):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(floorf(column * 1254.0 / 4.0), floorf(row * 1254.0 / 4.0), CELL_SIZE, CELL_SIZE)
			frames.add_frame(ANIMATIONS[row], frame)
	cache[key] = frames
	return frames
```

- [x] **Step 6: Run the focused test green and commit.** Re-run the command from Step 4 and commit assets, loader, and test with `git commit -m 'Add original animated soldier sprite sheets'`.

### Task 2: Unit scene and animation state

**Files:**
- Modify: `strategy-game/scenes/unit.tscn`
- Modify: `strategy-game/scripts/unit.gd`
- Modify: `strategy-game/tests/unit_visual_smoke.gd`

**Interfaces:**
- Consumes: `UnitVisuals.frames_for(unit_type: int, team: int, is_general: bool) -> SpriteFrames`
- Produces: `BattleUnit.visual_sprite: AnimatedSprite2D`
- Produces: `BattleUnit._update_visual_animation() -> void`

- [ ] **Step 1: Extend the focused test to instantiate all ten `Unit` variants.** Configure type/team before `add_child()`, assert the `AnimatedSprite2D` exists, frames match the role/team, and the sprite is visible. Set state/velocity to IDLE, MOVING, ATTACKING and call `_update_visual_animation()`; assert `idle`, `walk`, `attack` respectively. Set `attack_fx_timer` positive and ensure repeated calls do not reset attack frame to zero; set it to zero and ensure animation returns to walk/idle. Verify `calculate_damage_against()` and `move_to()` still return their pre-migration values/flags.

- [ ] **Step 2: Run test red.** Use the Task 1 Godot command; expect missing `AnimatedSprite2D` or `_update_visual_animation()`.

- [ ] **Step 3: Add the scene child.** Add `[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]` with `centered = true`, `offset = Vector2(0, -12)`, and `scale = Vector2(0.22, 0.22)`; keep the root type and script unchanged. Set child z order so the shadow is below it and selection/health overlays remain above it.

- [ ] **Step 4: Wire sprite loading and state changes.** Add `const UnitVisuals = preload("res://scripts/unit_visuals.gd")` and `@onready var visual_sprite: AnimatedSprite2D = $AnimatedSprite2D`. In `_ready()`, assign `visual_sprite.sprite_frames = UnitVisuals.frames_for(unit_type, team, is_general)` and set `visual_sprite.flip_h = team == 1`. In `configure_type()`, refresh visuals if `is_node_ready()`, because the prebattle army menu can change type. In `_process()`, call `_update_visual_animation()` after visual timers update. Keep `attack_fx_timer` driven by the existing damage event. Use this animation selector so repeated process calls do not restart a frame:

```gdscript
func _update_visual_animation() -> void:
	if visual_sprite.sprite_frames == null:
		return
	var wanted: StringName = &"idle"
	if attack_fx_timer > 0.0:
		wanted = &"attack"
	elif velocity.length_squared() > 25.0 or state == State.MOVING or state == State.CHASING or state == State.ROUTING:
		wanted = &"walk"
	if visual_sprite.animation != wanted or (wanted != &"attack" and not visual_sprite.is_playing()):
		visual_sprite.play(wanted)
```

- [ ] **Step 5: Remove only the old body/equipment drawing after visual QA.** Keep `_draw()` shadow, selection, aura, hit flash, projectile trace, routing ring, and health bar. Delete `_draw_soldier()` and `_draw_equipment()` after every sprite combination displays correctly and the Task 1 asset test passes. If needed, adapt the existing health-bar y offset to clear taller weapons without changing hitboxes.

- [ ] **Step 6: Run focused test and commit.** Run the Task 1 test command, then `git commit -m 'Animate 2D soldier sprites in battle'` with the scene, script, and test.

### Task 3: Visual and gameplay regression gate

**Files:**
- Modify only files from Tasks 1–2 if validation finds a concrete defect.

**Interfaces:**
- Consumes: the completed ten-sheet roster, `UnitVisuals`, and `BattleUnit.visual_sprite`.
- Produces: a verified phase-1 build with no mechanic changes.

- [ ] **Step 1: Run the existing headless test set.** Run every `strategy-game/tests/*_smoke.gd` and `interaction_stress.gd` with `Godot --headless --path strategy-game --script res://tests/<file>`, collecting each exit code. Fix any regression, then rerun the failing case and the affected suite.

- [ ] **Step 2: Inspect the game at 0.6×, default 0.8×, and 2.0× zoom.** Check all five roles on both teams, each animation, blue/red cloth distinction, selection/health overlays, and dense formation readability. Capture screenshots for comparison and confirm no sprite clips its cell or shifts at animation boundaries.

- [ ] **Step 3: Run one natural battle and verify mechanics.** Check combat starts and resolves normally, no invisible units, no change in movement destination or damage, and prebattle type changes update sprites immediately.

- [ ] **Step 4: Commit any QA fixes.** Stage only touched asset/code/test files and commit with `git commit -m 'Polish phase 1 unit visuals'`; do not commit generated logs or screenshots unless they are intentional review artifacts.

## Completion criteria

Every blue/red role is visually identifiable at normal zoom; idle/walk/attack animation is visible and aligned; existing gameplay tests pass; no mechanics change; only phase 1 is implemented.
