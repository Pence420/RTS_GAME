extends RefCounted

const SHEET_SIZE := 1254
const GRID_COUNT := 4
const CELL_SIZE := 314
const ROLES := ["swordsman", "spearman", "axeman", "archer", "general"]
const TEAMS := ["blue", "red"]
const ANIMATIONS := [&"idle", &"walk", &"attack"]
const DEFAULT_COLUMNS := [0, 1, 2]
const LONG_WEAPON_ATTACK_COLUMNS := [0, 1, 3]
# The spear and banner extend into adjacent atlas cells in the middle poses.
const WIDE_ATTACK_COLUMNS := [0, 3, 0]

static var _frames_cache: Dictionary = {}


static func validate_sheet(texture: Texture2D) -> bool:
	return texture != null and texture.get_size() == Vector2(SHEET_SIZE, SHEET_SIZE)


static func frames_for(unit_type: int, team: int, is_general: bool) -> SpriteFrames:
	var role_index := 4 if is_general else clampi(unit_type, 0, 3)
	var team_index := clampi(team, 0, 1)
	var cache_key := "%d_%d" % [role_index, team_index]
	if _frames_cache.has(cache_key):
		return _frames_cache[cache_key]
	var path := "res://assets/units/%s_%s.png" % [ROLES[role_index], TEAMS[team_index]]
	var texture := load(path) as Texture2D
	if not validate_sheet(texture):
		push_error("Missing or invalid unit sprite sheet: %s" % path)
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in range(ANIMATIONS.size()):
		var animation: StringName = ANIMATIONS[row]
		frames.add_animation(animation)
		frames.set_animation_loop(animation, row != 2)
		frames.set_animation_speed(animation, 16.0 if row == 2 else (5.0 if row == 0 else 9.0))
		var columns: Array = DEFAULT_COLUMNS
		if row == 2:
			if role_index == 1 or role_index == 4:
				columns = WIDE_ATTACK_COLUMNS
			elif role_index == 2:
				columns = LONG_WEAPON_ATTACK_COLUMNS
		for column in columns:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.filter_clip = true
			frame.region = Rect2(_cell_start(column), _cell_start(row), CELL_SIZE, CELL_SIZE)
			frames.add_frame(animation, frame)
	_frames_cache[cache_key] = frames
	return frames


static func _cell_start(index: int) -> float:
	return floorf(float(index) * float(SHEET_SIZE) / float(GRID_COUNT))
