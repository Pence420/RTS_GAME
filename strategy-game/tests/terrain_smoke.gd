extends SceneTree

const FIELD = preload("res://scripts/battle_field.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var terrain: Node2D = battle.get_node("Terrain")
	if terrain.z_index >= 0 or terrain.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Pixel terrain is blurred or draws above the units")
		return
	if terrain.GROUND.get_size() != Vector2(640, 256) or terrain.ELEVATION.get_size() != Vector2(256, 512) or terrain.south_edges.size() < 40:
		_fail("The actual terrain atlas or exposed cliff faces are missing")
		return
	if terrain.FOAM.get_width() != 192 * 8 or terrain.coast_cells.size() < 80:
		_fail("Animated coastline sprites are missing")
		return
	# Check the full playable rectangle, not just the current spawning positions.
	for y in range(64, 1337, 16):
		for x in range(64, 2337, 16):
			if not terrain.is_battle_ground(Vector2(x, y)):
				_fail("A decorative coastline removes playable ground")
				return
	var props := get_nodes_in_group("scenery_props")
	var count := props.size()
	if count < 60 or count != terrain.scenery_count or not battle.y_sort_enabled:
		_fail("Independent depth-sorted environment sprites are missing")
		return
	for prop in props:
		if not terrain.is_battle_ground(prop.position):
			_fail("A tree or decoration is floating on the ocean")
			return
		if prop.get_parent() != battle or prop.z_index != 1 or prop.get_node_or_null("WindPivot/Sprite2D") == null:
			_fail("Scenery is baked into the ground rather than depth-sorted")
			return
		if not prop.pixel_art or prop.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			_fail("A pixel prop is blurred")
			return
		if prop.prop_kind == 0:
			if prop.animation_frames.size() != 6:
				_fail("Authored tree wind frames are missing")
				return
			var sprite: Sprite2D = prop.get_node("WindPivot/Sprite2D")
			var width: float = sprite.texture.get_width() * sprite.scale.x
			var crown := Rect2(prop.position + Vector2(-width / 2.0, -prop.display_height), Vector2(width, prop.display_height))
			if crown.intersects(FIELD.UNIT_BOUNDS):
				_fail("A forest crown hides the playable boundary")
				return
	var before: int = terrain.foam_frame
	terrain._process(0.1)
	if terrain.foam_frame == before:
		_fail("Shoreline animation does not advance")
		return
	battle.call("_restart_battle")
	await process_frame
	await process_frame
	if get_nodes_in_group("scenery_props").size() != count:
		_fail("Restart duplicated or leaked scenery")
		return
	print("Terrain passed: CC0 sprite tiles, cliffs, animated coast, full walkable field, forest clearance, pixel filtering, depth sorting, and clean restart.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
