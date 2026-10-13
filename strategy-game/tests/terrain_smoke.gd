extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var terrain: Node2D = battle.get_node("Terrain")
	if terrain.z_index >= 0 or terrain.texture_repeat != CanvasItem.TEXTURE_REPEAT_MIRROR:
		_fail("Ground tiles do not draw below the battle or repeat safely at their edges")
		return
	if terrain.get_node("DirtRoad").texture == null or terrain.prop_textures.size() != 6:
		_fail("The road or six reusable prop sprites are missing")
		return
	var source: Image = terrain.PROPS.get_image()
	if source.get_pixel(0, 0).a > 0.2:
		_fail("Environment sprite atlas has an opaque background")
		return
	for texture in terrain.prop_textures:
		var frame := texture as AtlasTexture
		if frame == null or not frame.filter_clip or frame.region.size.x < 32 or frame.region.size.y < 32 or not Rect2(Vector2.ZERO, terrain.PROPS.get_size()).encloses(frame.region):
			_fail("A prop region is empty, clipped, or extends outside the source atlas")
			return
	var props := get_nodes_in_group("scenery_props")
	if props.size() != 34 or not battle.y_sort_enabled:
		_fail("Independent environment props or world depth sorting are missing")
		return
	for prop in props:
		if prop.get_parent() != battle or prop.z_index != 1 or prop.get_node_or_null("WindPivot/Sprite2D") == null:
			_fail("An environment prop is baked into the ground rather than its own depth-sorted sprite")
			return
		if prop.prop_kind <= 1:
			var sprite: Sprite2D = prop.get_node("WindPivot/Sprite2D")
			var width: float = sprite.texture.get_width() * sprite.scale.x
			var crown := Rect2(prop.position + Vector2(-width / 2.0, -prop.display_height), Vector2(width, prop.display_height))
			for squad in battle.player_squads + battle.enemy_squads:
				for unit in squad.units:
					if crown.has_point(unit.global_position):
						_fail("A tree hides a soldier's initial deployment position")
						return
	battle.call("_restart_battle")
	await process_frame
	await process_frame
	if get_nodes_in_group("scenery_props").size() != 34:
		_fail("Restart duplicated or leaked environment props")
		return
	print("Terrain passed: reusable ground, transparent prop atlas, 34 independent sprites, depth sorting, safe deployment, and clean restart.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
