extends RefCounted

const SHEET_SIZE := 1254
const GRID_COUNT := 4
const FRAME_WIDTH := 314
const FRAME_HEIGHT := 380
const ROLES := ["swordsman", "spearman", "axeman", "archer", "general"]
const TEAMS := ["blue", "red"]
const ANIMATIONS := [&"idle", &"walk", &"attack"]
const DEFAULT_COLUMNS := [0, 1, 2]
# The matte atlases use tall characters and wider spacing between animation rows.
# General banners start slightly higher than the other silhouettes.
const ROW_STARTS := [
	[60, 440, 820], # swordsman
	[60, 440, 839], # spearman
	[60, 440, 820], # axeman
	[60, 440, 820], # archer
	[45, 440, 830], # general
]
# Long weapons and banners cross cell boundaries in the later poses. Repeating the
# clean ready pose closes the short attack cycle without drawing detached fragments.
const ATTACK_X_AND_WIDTH := [
	[[0, 314], [313, 314], [0, 314]], # swordsman
	[[0, 314], [313, 296], [0, 314]], # spearman
	[[0, 314], [313, 314], [0, 314]], # axeman
	[[0, 314], [330, 296], [963, 291]], # archer
	[[0, 314], [313, 290], [0, 314]], # general
]

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
		for pose in range(DEFAULT_COLUMNS.size()):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.filter_clip = true
			if row == 2:
				var crop: Array = ATTACK_X_AND_WIDTH[role_index][pose]
				frame.region = Rect2(crop[0], ROW_STARTS[role_index][row], crop[1], FRAME_HEIGHT)
			else:
				frame.region = Rect2(_cell_start(DEFAULT_COLUMNS[pose]), ROW_STARTS[role_index][row], FRAME_WIDTH, FRAME_HEIGHT)
			frames.add_frame(animation, frame)
	_frames_cache[cache_key] = frames
	return frames


static func _cell_start(index: int) -> float:
	return floorf(float(index) * float(SHEET_SIZE) / float(GRID_COUNT))
