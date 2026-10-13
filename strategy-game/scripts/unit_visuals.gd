extends RefCounted

const FRAME_SIZE := Vector2i(32, 32)
const DISPLAY_SCALE := Vector2(3, 3)
# Every authored pose touches source row 30. Centering then lifting by 15
# keeps boots at the physics anchor; the sprite node sits at ground offset 8.
const SPRITE_OFFSET := Vector2(0, -15)
const GROUND_POSITION := Vector2(0, 8)
const ROLES := ["MiniSwordMan", "MiniSpearMan", "MiniHalberdMan", "MiniArcherMan", "MiniKingMan"]
const ANIMATIONS := [&"idle", &"walk", &"attack", &"death"]
# The archer has an extra reload row; the king has extra special-action rows.
const ROWS := [[0, 1, 3, 5], [0, 1, 3, 5], [0, 1, 3, 5], [0, 1, 3, 6], [0, 1, 4, 6]]
const COUNTS := [[4, 6, 6, 4], [4, 6, 7, 5], [4, 6, 6, 5], [4, 6, 11, 4], [4, 5, 10, 6]]
const PALETTE: Shader = preload("res://assets/units/minifolks/team_palette.gdshader")

static var _frames_cache: Dictionary = {}
static var _materials_cache: Dictionary = {}


static func sheet_path(unit_type: int, is_general: bool) -> String:
	return "res://assets/units/minifolks/%s.png" % ROLES[4 if is_general else clampi(unit_type, 0, 3)]


static func validate_sheet(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var size := Vector2i(texture.get_size())
	return size.x >= 192 and size.y >= 192 and size.x % 32 == 0 and size.y % 32 == 0


static func material_for(team: int) -> ShaderMaterial:
	var key := clampi(team, 0, 1)
	if not _materials_cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = PALETTE
		material.set_shader_parameter("red_team", key == 1)
		_materials_cache[key] = material
	return _materials_cache[key]


static func frames_for(unit_type: int, _team: int, is_general: bool) -> SpriteFrames:
	var role := 4 if is_general else clampi(unit_type, 0, 3)
	if _frames_cache.has(role):
		return _frames_cache[role]
	var path := sheet_path(unit_type, is_general)
	var texture := load(path) as Texture2D
	if not validate_sheet(texture):
		push_error("Missing or invalid MiniFolks sheet: %s" % path)
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for action in range(ANIMATIONS.size()):
		var animation: StringName = ANIMATIONS[action]
		frames.add_animation(animation)
		frames.set_animation_loop(animation, action < 2)
		frames.set_animation_speed(animation, 10.0)
		for pose in range(COUNTS[role][action]):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(pose, ROWS[role][action]) * 32, Vector2(FRAME_SIZE))
			frame.filter_clip = true
			frames.add_frame(animation, frame)
	_frames_cache[role] = frames
	return frames
