extends SceneTree

const VISUALS = preload("res://scripts/unit_visuals.gd")
const ROLE_NAMES := ["swordsman", "spearman", "axeman", "archer", "general"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for team in range(2):
		for role in range(ROLE_NAMES.size()):
			var frames: SpriteFrames = VISUALS.frames_for(mini(role, 3), team, role == 4)
			if frames == null:
				_fail("Missing frames for %s team %d" % [ROLE_NAMES[role], team])
				return
			for animation in [&"idle", &"walk", &"attack"]:
				if not frames.has_animation(animation) or frames.get_frame_count(animation) != 3:
					_fail("Invalid %s frames for %s team %d" % [animation, ROLE_NAMES[role], team])
					return
				for index in range(3):
					var frame := frames.get_frame_texture(animation, index) as AtlasTexture
					if frame == null or frame.atlas == null:
						_fail("Missing atlas cell for %s %s team %d" % [ROLE_NAMES[role], animation, team])
						return
					var expected_path := "res://assets/units/%s_%s.png" % [ROLE_NAMES[role], "blue" if team == 0 else "red"]
					if frame.atlas.resource_path != expected_path:
						_fail("Wrong sheet for %s team %d" % [ROLE_NAMES[role], team])
						return
					if frame.region.position.x < 0.0 or frame.region.position.y < 0.0 or frame.region.end.x > frame.atlas.get_width() or frame.region.end.y > frame.atlas.get_height():
						_fail("Sprite frame extends beyond source atlas")
						return
					var visible_bounds := frame.get_image().get_used_rect()
					if visible_bounds.size.x < 100 or visible_bounds.size.y < 150:
						_fail("Sprite frame is empty or cropped too tightly for %s %s team %d" % [ROLE_NAMES[role], animation, team])
						return
	var invalid := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	if VISUALS.validate_sheet(ImageTexture.create_from_image(invalid)):
		_fail("Accepted malformed sprite sheet")
		return
	var unit_scene: PackedScene = load("res://scenes/unit.tscn")
	for team in range(2):
		for role in range(ROLE_NAMES.size()):
			var unit := unit_scene.instantiate() as BattleUnit
			unit.team = team
			unit.is_general = role == 4
			if not unit.is_general:
				unit.configure_type(role)
			root.add_child(unit)
			var sprite := unit.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if sprite == null or sprite.sprite_frames == null or not sprite.visible:
				_fail("Unit scene has no visible sprite for %s team %d" % [ROLE_NAMES[role], team])
				return
			if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
				_fail("Smooth sprite is not using linear filtering")
				return
			var source := sprite.sprite_frames.get_frame_texture(&"idle", 0) as AtlasTexture
			var expected := "res://assets/units/%s_%s.png" % [ROLE_NAMES[role], "blue" if team == 0 else "red"]
			if source == null or source.atlas.resource_path != expected:
				_fail("Unit scene selected wrong sprite for %s team %d" % [ROLE_NAMES[role], team])
				return
			unit.queue_free()
	await process_frame
	var actor := unit_scene.instantiate() as BattleUnit
	actor.team = 0
	actor.configure_type(BattleUnit.UnitType.SWORDSMAN)
	root.add_child(actor)
	var visual := actor.get_node("AnimatedSprite2D") as AnimatedSprite2D
	actor.state = BattleUnit.State.IDLE
	actor.velocity = Vector2.ZERO
	actor.call("_update_visual_animation")
	if visual.animation != &"idle":
		_fail("Idle unit did not play idle animation")
		return
	actor.state = BattleUnit.State.MOVING
	actor.velocity = Vector2(80, 0)
	actor.call("_update_visual_animation")
	if visual.animation != &"walk":
		_fail("Moving unit did not play walk animation")
		return
	actor.attack_fx_timer = 0.18
	actor.call("_update_visual_animation")
	visual.frame = 1
	actor.call("_update_visual_animation")
	if visual.animation != &"attack" or visual.frame != 1:
		_fail("Attack animation restarts on repeated update")
		return
	actor.attack_fx_timer = 0.0
	actor.call("_update_visual_animation")
	if visual.animation != &"walk":
		_fail("Attack did not return to movement animation")
		return
	actor.configure_type(BattleUnit.UnitType.ARCHER)
	var changed := visual.sprite_frames.get_frame_texture(&"idle", 0) as AtlasTexture
	if changed == null or changed.atlas.resource_path != "res://assets/units/archer_blue.png":
		_fail("Prebattle unit type change did not update sprite")
		return
	actor.queue_free()
	print("Unit visual assets passed: five roles, two teams, three animation states.")
	quit(0)


func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
