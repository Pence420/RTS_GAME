extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var terrain := load("res://assets/terrain/battlefield_smooth.png") as Texture2D
	if terrain == null or terrain.get_width() < 1024 or terrain.get_height() < 576 or absf(float(terrain.get_width()) / float(terrain.get_height()) - 16.0 / 9.0) > 0.05:
		_fail("Smooth battlefield texture is missing or has the wrong size")
		return
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var top: Control = battle.get_node_or_null("CanvasLayer/TopBar")
	var dock: Control = battle.get_node_or_null("CanvasLayer/BottomDock")
	var phase: Label = battle.get_node_or_null("CanvasLayer/Phase")
	var blue_count: Label = battle.get_node_or_null("CanvasLayer/BlueCount")
	var red_count: Label = battle.get_node_or_null("CanvasLayer/RedCount")
	if top == null or dock == null or phase == null or blue_count == null or red_count == null:
		_fail("Tactical HUD panels or battle counters are missing.")
		return
	if root.min_size != Vector2i(1152, 648):
		_fail("The HUD can be shrunk below its supported minimum size.")
		return
	if phase.text != "DEPLOYMENT" or not blue_count.text.contains("40") or not red_count.text.contains("40"):
		_fail("Deployment header does not show the battle state and army sizes.")
		return
	var safe_top := top.get_global_rect().end.y + 25.0
	var safe_bottom := dock.get_global_rect().position.y - 12.0
	for squad in battle.get("player_squads") + battle.get("enemy_squads"):
		for unit in squad.units:
			var screen_y: float = unit.get_global_transform_with_canvas().origin.y
			if screen_y < safe_top or screen_y > safe_bottom:
				_fail("Starting soldier is hidden behind HUD: %s at %.1f outside %.1f–%.1f" % [squad.squad_id, screen_y, safe_top, safe_bottom])
				return
	for panel_name in ["FormationButtons", "CommandButtons"]:
		var panel: Control = battle.get_node("CanvasLayer/" + panel_name)
		if not dock.get_global_rect().encloses(panel.get_global_rect()):
			_fail(panel_name + " extends outside the bottom dock.")
			return
	root.size = Vector2i(1440, 900)
	await process_frame
	if not dock.get_global_rect().encloses(battle.get_node("CanvasLayer/CommandButtons").get_global_rect()):
		_fail("Command panel moves outside the dock in a larger window.")
		return
	root.size = Vector2i(1152, 648)
	await process_frame
	var selected: BattleSquad = battle.get("player_squads")[0]
	battle.call("_select_at", selected.units[0].global_position)
	var status: Label = battle.get_node("CanvasLayer/Status")
	if not status.text.contains("Swordsman") or not status.text.contains("HP 100%"):
		_fail("Selected squad details did not appear in the HUD.")
		return
	battle.get_node("CanvasLayer/CommandButtons/FocusTarget").emit_signal("pressed")
	if not status.text.contains("Left-click a red squad") or status.text.count("\n") > 3:
		_fail("Focus prompt overflows the selection card.")
		return
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	if phase.text != "BATTLE" or battle.get_node("CanvasLayer/StartBattle").visible:
		_fail("Battle header did not update after Start Battle.")
		return
	print("HUD smoke passed: safe layout, counters, selection, and phase update.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
