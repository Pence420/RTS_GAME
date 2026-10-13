extends Node2D

const FIELD = preload("res://scripts/battle_field.gd")

const GRASS: Texture2D = preload("res://assets/terrain/grass_tile.png")
const DIRT: Texture2D = preload("res://assets/terrain/dirt_tile.png")
const PROPS: Texture2D = preload("res://assets/terrain/environment_props.png")
const PROP_SCRIPT = preload("res://scripts/terrain_prop.gd")
const FIELD_SIZE := FIELD.SIZE
const PROP_NAMES := ["Oak", "Pine", "Shrub", "RockCluster", "Grass", "Boulder"]
# Measured opaque silhouettes plus four pixels of padding. The source atlas
# has uneven cells and faint alpha specks outside the actual props.
const PROP_REGIONS := [
	Rect2i(40, 190, 429, 476), Rect2i(491, 92, 308, 578), Rect2i(881, 418, 327, 254),
	Rect2i(79, 875, 331, 279), Rect2i(519, 953, 268, 196), Rect2i(905, 925, 299, 234),
]
const EDGE_PROPS := [
	[0, Vector2(145, 165), 150.0],
	[1, Vector2(95, 255), 158.0],
	[1, Vector2(216, 92), 128.0],
	[3, Vector2(166, 196), 44.0],
	[2, Vector2(174, 326), 42.0],
	[5, Vector2(113, 418), 34.0],
	[0, Vector2(112, 558), 135.0],
	[2, Vector2(170, 552), 36.0],
	[1, Vector2(95, 736), 150.0],
	[3, Vector2(101, 798), 52.0],
	[0, Vector2(112, 860), 147.0],
	[2, Vector2(282, 872), 43.0],
]

var prop_textures: Array[Texture2D] = []


func _ready() -> void:
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_build_road()
	_build_ground_patches()
	_crop_prop_textures()
	queue_redraw()


func build_scenery(world: Node2D) -> void:
	for index in range(EDGE_PROPS.size()):
		var spec: Array = EDGE_PROPS[index]
		var point := Vector2(spec[1].x, spec[1].y / 900.0 * (FIELD_SIZE.y - 30.0))
		_add_prop(world, spec[0], point, spec[2], index * 2)
		var reflected := Vector2(FIELD_SIZE.x - point.x, clampf(point.y + (13.0 if index % 2 == 0 else -11.0), 30.0, FIELD_SIZE.y - 4.0))
		_add_prop(world, spec[0], reflected, spec[2], index * 2 + 1)
	for index in range(8):
		var point := Vector2((index + 1) * FIELD_SIZE.x / 9.0, FIELD_SIZE.y / 2.0 + sin(index * 2.1) * 70)
		_add_prop(world, 4, point, 15 + index % 3 * 3, 24 + index)
	_add_prop(world, 2, Vector2(460, 125) + FIELD.START_OFFSET, 32.0, 32)
	_add_prop(world, 3, Vector2(1112, 120) + FIELD.START_OFFSET, 26.0, 33)


func _add_prop(world: Node2D, kind: int, point: Vector2, height: float, index: int) -> void:
	var prop := PROP_SCRIPT.new() as Node2D
	prop.name = "%s_%02d" % [PROP_NAMES[kind], index]
	prop.prop_kind = kind
	prop.prop_texture = prop_textures[kind]
	prop.display_height = height
	prop.position = point
	# Props share the living units' Y-sorted world layer; their root is a foot anchor.
	world.add_child(prop)


func _crop_prop_textures() -> void:
	for index in range(6):
		var texture := AtlasTexture.new()
		texture.atlas = PROPS
		texture.region = Rect2(PROP_REGIONS[index])
		texture.filter_clip = true
		prop_textures.append(texture)


func _build_road() -> void:
	for layer in range(3):
		var road := Polygon2D.new()
		road.name = "RoadEdge%d" % layer if layer < 2 else "DirtRoad"
		road.texture = DIRT
		road.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		road.texture_scale = Vector2(3.0, 3.0)
		road.antialiased = true
		road.modulate.a = [0.16, 0.27, 0.9][layer]
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		var extra_width: float = [14.0, 6.0, 0.0][layer]
		for index in range(49):
			var x := -30.0 + index * (FIELD_SIZE.x + 60.0) / 48.0
			var center := FIELD_SIZE.y / 2.0 + 10.0 + sin(x / 190.0) * 11.0 + sin(x / 375.0) * 8.0
			var half_width := 39.0 + sin(x / 215.0) * 6.0 + extra_width
			top.append(Vector2(x, center - half_width + sin(index * 1.7) * 2.0))
			bottom.append(Vector2(x, center + half_width + sin(index * 0.9) * 2.0))
		bottom.reverse()
		top.append_array(bottom)
		road.polygon = top
		add_child(road)


func _build_ground_patches() -> void:
	for index in range(13):
		var patch := Polygon2D.new()
		patch.name = "EarthPatch%02d" % index
		patch.position = Vector2(120 + fmod(index * 397.0, FIELD_SIZE.x - 240.0), 100 + fmod(index * 173.0, FIELD_SIZE.y - 190.0))
		patch.texture = DIRT
		patch.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		patch.texture_scale = Vector2(3.0, 3.0)
		patch.antialiased = true
		patch.modulate.a = 0.1
		var points := PackedVector2Array()
		for corner in range(14):
			var angle := TAU * corner / 14.0
			var radius := 30.0 + 12.0 * sin(corner * 2.7 + index)
			points.append(Vector2(cos(angle) * radius * 1.5, sin(angle) * radius * 0.7))
		patch.polygon = points
		add_child(patch)


func _draw() -> void:
	# Reusable ground tiles, rather than a painted image of the whole battlefield.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.4, 0.4))
	draw_texture_rect(GRASS, Rect2(Vector2.ZERO, FIELD_SIZE / 0.4), true)
	draw_set_transform(Vector2.ZERO)
