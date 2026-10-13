extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var toggle: Button = battle.get_node("CanvasLayer/OrdersToggle")
	if toggle.icon == null or not toggle.text.is_empty():
		_fail("Orders toggle still uses a text label instead of an icon")
		return
	toggle.emit_signal("pressed")
	await process_frame
	var tray: Control = battle.get_node("CanvasLayer/OrdersPanel")
	var icons := {}
	for group in ["FormationButtons", "CommandButtons", "PointerButtons"]:
		for button in battle.get_node("CanvasLayer/" + group).get_children():
			if not button.visible:
				continue
			if button.icon == null or not button.text.is_empty() or button.tooltip_text.is_empty():
				_fail("An icon order is missing its image or explanatory tooltip: " + button.name)
				return
			if button.size.x < 44.0 or button.size.y < 44.0 or not tray.get_global_rect().encloses(button.get_global_rect()):
				_fail("An order icon has a small or clipped touchpad click target: " + button.name)
				return
			if icons.has(button.icon.resource_path):
				_fail("Different actions share an ambiguous icon")
				return
			icons[button.icon.resource_path] = true
	if icons.size() != 9:
		_fail("Orders tray should expose four formations, two stances, and three touchpad alternatives")
		return
	var squad: BattleSquad = battle.player_squads[0]
	battle.get_node("CanvasLayer/CommandButtons/Defend").emit_signal("pressed")
	if squad.stance != BattleSquad.Stance.DEFEND:
		_fail("Defend icon lost its stance binding")
		return
	print("Order icons passed: 9 unique icons, tooltips, laptop click targets, and live command binding.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
