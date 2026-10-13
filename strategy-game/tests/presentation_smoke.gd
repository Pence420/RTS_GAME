extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var squad: BattleSquad = battle.player_squads[0]
	var actor: BattleUnit = squad.units[0]
	var scale: Vector2 = actor.visual_sprite.scale
	var spacing: Vector2 = squad.SLOT_SPACING
	var worst := 0.0
	for team in range(2):
		for role in range(4):
			var frames: SpriteFrames = actor.UNIT_VISUALS.frames_for(role, team, false)
			for frame_index in range(frames.get_frame_count(&"idle")):
				var image: Image = frames.get_frame_texture(&"idle", frame_index).get_image()
				image.resize(roundi(image.get_width() * scale.x), roundi(image.get_height() * scale.y), Image.INTERPOLATE_LANCZOS)
				var opaque := 0
				var intersections := [0, 0]
				for y in range(image.get_height()):
					for x in range(image.get_width()):
						if image.get_pixel(x, y).a < 0.25:
							continue
						opaque += 1
						if x >= int(spacing.x) and image.get_pixel(x - int(spacing.x), y).a >= 0.25:
							intersections[0] += 1
						if y >= int(spacing.y) and image.get_pixel(x, y - int(spacing.y)).a >= 0.25:
							intersections[1] += 1
				worst = maxf(worst, float(maxi(intersections[0], intersections[1])) / maxi(opaque, 1))
	if worst > 0.10:
		_fail("Idle silhouettes overlap by %.1f%%; expected at most 10%%" % (worst * 100.0))
		return
	squad.set_formation(BattleSquad.Formation.SHIELD_WALL)
	squad.move_to(Vector2(160, 170))
	for soldier in squad.units:
		if not soldier.FIELD_BOUNDS.has_point(soldier.destination):
			_fail("Wider formation places a soldier outside the field when moved to an edge")
			return
	squad.set_formation(BattleSquad.Formation.LINE)
	squad.move_to(squad.global_position)
	var hud = battle.get_node("CanvasLayer")
	var tray: Control = hud.get_node("OrdersPanel")
	if tray.visible:
		_fail("Orders tray should start closed")
		return
	hud.get_node("OrdersToggle").emit_signal("pressed")
	if not tray.visible or battle.call("_is_gameplay_point", tray.get_global_rect().get_center()):
		_fail("Open Orders tray did not block world input")
		return
	var camera_before: Vector2 = battle.get_node("Camera2D").position
	var order_before := squad.ordered_center
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = tray.get_global_rect().get_center()
	battle._input(press)
	var drag := InputEventMouseMotion.new()
	drag.position = press.position + Vector2(40, 0)
	drag.relative = Vector2(40, 0)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	battle._input(drag)
	press.pressed = false
	press.position = drag.position
	battle._input(press)
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	battle._unhandled_input(press)
	if battle.get_node("Camera2D").position != camera_before or squad.ordered_center != order_before:
		_fail("Dragging or right-clicking the Orders tray issued a world action")
		return
	hud.get_node("GeneralSlot").emit_signal("pressed")
	if battle.selected_general != battle.player_general:
		_fail("General portrait did not select the commander")
		return
	hud.get_node("SquadSlots/C").emit_signal("pressed")
	if battle.selected_squad.squad_id != "Blue C":
		_fail("Squad portrait did not select the matching squad")
		return
	battle.call("_on_menu_unit_type_changed", 2, BattleUnit.UnitType.ARCHER)
	var portrait := hud.get_node("SquadSlots/C").icon as AtlasTexture
	if not portrait.atlas.resource_path.ends_with("archer_blue.png") or not hud.get_node("Status").text.contains("Archer"):
		_fail("Deployment composition change left a stale portrait or selection summary")
		return
	var survivor: BattleSquad = battle.player_squads[2]
	for unit in squad.units.duplicate():
		unit.receive_damage(10000.0)
	await process_frame
	await process_frame
	var effects: Node = battle.get_node("GroundEffects")
	if effects.get_child_count() != 10:
		_fail("Death splatter disappeared with the final soldier's squad")
		return
	if not hud.get_node("SquadSlots/A").disabled or hud.get_node("SquadSlots/C").disabled:
		_fail("Dead portrait disabled the wrong squad")
		return
	hud.get_node("SquadSlots/C").emit_signal("pressed")
	if battle.selected_squad != survivor:
		_fail("Portrait identity shifted after another squad was removed")
		return
	for effect in effects.get_children():
		effect._process(4.0)
	await process_frame
	if effects.get_child_count() != 0:
		_fail("Death effects did not clean themselves up")
		return
	print("Presentation passed: %.1f%% maximum idle overlap, Orders input guard, stable portraits, surviving death splatter and cleanup." % (worst * 100.0))
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
