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
	var invalid := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	if VISUALS.validate_sheet(ImageTexture.create_from_image(invalid)):
		_fail("Accepted malformed sprite sheet")
		return
	print("Unit visual assets passed: five roles, two teams, three animation states.")
	quit(0)


func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
