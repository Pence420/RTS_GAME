extends Node2D

const FIELD = preload("res://scripts/battle_field.gd")
const FIELD_SIZE := FIELD.SIZE
const TILE := 64
const GROUND: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/ground.png")
const ELEVATION: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/elevation.png")
const WATER: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/water.png")
const FOAM: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/foam.png")
const TREE: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/tree.png")
const PROP_SCRIPT = preload("res://scripts/terrain_prop.gd")
const PROP_NAMES := ["Pine", "Stone", "Shrub", "LargeShrub"]
const LARGE_STONE: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/stone_large.png")
const SMALL_SHRUB: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/shrub_small.png")
const LARGE_SHRUB: Texture2D = preload("res://assets/terrain/tiny_swords_cc0/shrub_large.png")

# Terrain beyond the command boundary supplies coastline and backdrop only.
# Every point inside UNIT_BOUNDS remains flat ground, including deployment.
var land_cells: Dictionary[Vector2i, bool] = {}
var ground_tiles: Array[Vector2i] = []
var ground_sources: Array[Vector2i] = []
var south_edges: Array[Vector2i] = []
var cliff_sources: Array[Vector2i] = []
var coast_cells: Array[Vector2i] = []
var prop_textures: Array[Texture2D] = []
var foam_frame := 0
var foam_clock := 0.0
var scenery_count := 0
var tree_frames: Array[Texture2D] = []


func _ready() -> void:
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_build_land()
	_crop_prop_textures()
	queue_redraw()


func _process(delta: float) -> void:
	foam_clock += delta
	if foam_clock >= 0.1:
		foam_frame = (foam_frame + int(foam_clock / 0.1)) % 8
		foam_clock = fmod(foam_clock, 0.1)
		queue_redraw()


func _build_land() -> void:
	# Broad central plateau, with stepped headlands entirely outside the field.
	_fill_land(Rect2i(0, 0, 38, 22))
	_fill_land(Rect2i(3, -2, 9, 2))
	_fill_land(Rect2i(25, -3, 9, 3))
	_fill_land(Rect2i(-3, 2, 3, 5))
	_fill_land(Rect2i(-2, 12, 2, 7))
	_fill_land(Rect2i(38, 4, 3, 7))
	_fill_land(Rect2i(38, 16, 2, 4))
	_fill_land(Rect2i(5, 22, 9, 2))
	_fill_land(Rect2i(25, 22, 7, 3))
	# Small coastal islets make the water read as space, not an empty background.
	_fill_land(Rect2i(-5, 9, 2, 2))
	_fill_land(Rect2i(41, 13, 2, 2))
	for cell: Vector2i in land_cells:
		var west := land_cells.has(cell + Vector2i.LEFT)
		var east := land_cells.has(cell + Vector2i.RIGHT)
		var north := land_cells.has(cell + Vector2i.UP)
		var south := land_cells.has(cell + Vector2i.DOWN)
		ground_tiles.append(cell)
		ground_sources.append(Vector2i(0 if not west else (2 if not east else 1), 0 if not north else (2 if not south else 1)))
		if not south:
			south_edges.append(cell)
			cliff_sources.append(Vector2i(0 if not west else (2 if not east else 1), 3))
		if not west or not east or not north or not south:
			coast_cells.append(cell)


func _fill_land(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			land_cells[Vector2i(x, y)] = true


func is_battle_ground(point: Vector2) -> bool:
	return land_cells.has(Vector2i(floori(point.x / TILE), floori(point.y / TILE)))


func _crop_prop_textures() -> void:
	for index in range(6):
		var tree := AtlasTexture.new()
		tree.atlas = TREE
		tree.region = Rect2(40 + (index % 4) * 192, 4 + (index / 4) * 192, 112, 176)
		tree.filter_clip = true
		tree_frames.append(tree)
	prop_textures = [tree_frames[0]]
	for source: Texture2D in [LARGE_STONE, SMALL_SHRUB, LARGE_SHRUB]:
		var texture := AtlasTexture.new()
		texture.atlas = source
		texture.region = Rect2(source.get_image().get_used_rect())
		texture.filter_clip = true
		prop_textures.append(texture)


func build_scenery(world: Node2D) -> void:
	# Forest crowns stay outside the playable rectangle, so soldiers are readable
	# even when commanded to the boundary. Tree roots define their Y-sort anchor.
	for index in range(13):
		var y := 120.0 + index * 96.0
		var left := Vector2(4 if index % 2 == 0 else -62, y)
		var right := Vector2(2428 if index % 2 == 0 else 2490, y + 24)
		if not is_battle_ground(left):
			left.x = 4
		if not is_battle_ground(right):
			right.x = 2428
		_add_prop(world, 0, left, 160 + index % 3 * 8)
		_add_prop(world, 0, right, 168 + index % 3 * 8)
		if index % 2 == 0:
			_add_grounded_prop(world, 1, Vector2(-34, y + 36), 34)
			_add_grounded_prop(world, 2, Vector2(2460, y + 64), 30)
	for index in range(17):
		var x := 96.0 + index * 138.0
		var north := Vector2(x, 40 - (index % 3) * 24)
		if not is_battle_ground(north):
			north.y = 20
		_add_prop(world, 0, north, 164 + index % 3 * 8)
		_add_grounded_prop(world, 0, Vector2(x + 22, 1528 if x < 1000 else 1584), 170 + index % 3 * 8)
		if index % 3 == 0:
			_add_prop(world, 3, Vector2(x + 60, 22), 44)
			_add_grounded_prop(world, 1, Vector2(x + 76, 1460), 38)
	# Low tufts/rocks add scale without obscuring formations or implying a wall.
	for point in [Vector2(180, 210), Vector2(2220, 240), Vector2(280, 1160), Vector2(2140, 1190), Vector2(500, 190), Vector2(1860, 210)]:
		_add_prop(world, 2, point, 24)


func _add_grounded_prop(world: Node2D, kind: int, point: Vector2, height: float) -> void:
	if is_battle_ground(point):
		_add_prop(world, kind, point, height)


func _add_prop(world: Node2D, kind: int, point: Vector2, height: float) -> void:
	var prop := PROP_SCRIPT.new() as Node2D
	prop.name = "%s_%03d" % [PROP_NAMES[kind], scenery_count]
	prop.prop_kind = kind
	prop.prop_texture = prop_textures[kind]
	prop.display_height = height
	prop.pixel_art = true
	if kind == 0:
		prop.animation_frames = tree_frames
	prop.position = point
	world.add_child(prop)
	scenery_count += 1


func _draw() -> void:
	var ocean := Rect2(Vector2(-1024, -1024), FIELD_SIZE + Vector2(2048, 2048))
	draw_texture_rect(WATER, ocean, true)
	# Waves sit underneath grass and cliff sprites. Their opaque centre never
	# covers the land; only the exposed foam fringe remains visible.
	for index in range(coast_cells.size()):
		var cell := coast_cells[index]
		var center := Vector2(cell * TILE) + Vector2(32, 48)
		var frame := (foam_frame + index % 4) % 8
		draw_texture_rect_region(FOAM, Rect2(center - Vector2(96, 96), Vector2(192, 192)), Rect2(frame * 192, 0, 192, 192), Color(1, 1, 1, 0.65))
	for index in range(south_edges.size()):
		var target := Rect2(Vector2(south_edges[index] * TILE) + Vector2(0, 32), Vector2(TILE, 96))
		draw_texture_rect_region(ELEVATION, target, Rect2(Vector2(cliff_sources[index] * TILE), Vector2(TILE, TILE)))
	for index in range(ground_tiles.size()):
		draw_texture_rect_region(GROUND, Rect2(Vector2(ground_tiles[index] * TILE), Vector2(TILE, TILE)), Rect2(Vector2(ground_sources[index] * TILE), Vector2(TILE, TILE)), Color(0.73, 0.84, 0.75))
	# Connected earth tiles form a gentle bend through the central battlefield.
	for x in range(3, 35):
		var y := 10 if x < 10 or x >= 25 else 11
		var col := 0 if x == 3 else (2 if x == 34 else 1)
		draw_texture_rect_region(GROUND, Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), Rect2(Vector2(5 + col, 3) * TILE, Vector2(TILE, TILE)), Color(0.8, 0.71, 0.53, 0.9))
		if x == 9 or x == 25:
			_draw_patch(Rect2i(x, 10, 2, 2), 5, Color(0.8, 0.71, 0.53, 0.9))
	# Raised northern shelves stop at the playable boundary, supplying relief
	# without adding impassable cells or changing combat/navigation.
	_draw_raised_shelf(Rect2i(3, -2, 9, 2))
	_draw_raised_shelf(Rect2i(25, -3, 9, 3))


func _draw_raised_shelf(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		var col := 0 if x == rect.position.x else (2 if x == rect.end.x - 1 else 1)
		draw_texture_rect_region(ELEVATION, Rect2(Vector2(x, rect.end.y) * TILE, Vector2(TILE, TILE)), Rect2(Vector2(col, 3) * TILE, Vector2(TILE, TILE)))
	_draw_patch(rect, 0, Color(0.82, 0.93, 0.78))


func _draw_patch(rect: Rect2i, source_x: int, tint: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var col := 0 if x == rect.position.x else (2 if x == rect.end.x - 1 else 1)
			var row := 0 if y == rect.position.y else (2 if y == rect.end.y - 1 else 1)
			draw_texture_rect_region(GROUND, Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), Rect2(Vector2(source_x + col, row) * TILE, Vector2(TILE, TILE)), tint)
