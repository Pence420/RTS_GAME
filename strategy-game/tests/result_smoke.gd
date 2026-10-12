extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var enemy_squads: Array = battle.get("enemy_squads")
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	enemy_squads[0].apply_morale_change(-100.0)
	if battle.get("battle_result") != "":
		_fail("Battle must continue while an enemy squad can still fight.")
		return
	for squad in enemy_squads.slice(1):
		squad.apply_morale_change(-100.0)
	if battle.get("battle_result") != "VICTORY" or not paused:
		_fail("All enemy squads routing must show victory and pause combat.")
		return
	await process_frame
	var overlay: Control = battle.get_node("CanvasLayer/ResultOverlay")
	var title: Label = battle.get_node("CanvasLayer/ResultOverlay/Center/Content/ResultTitle")
	var detail: Label = battle.get_node("CanvasLayer/ResultOverlay/Center/Content/ResultDetail")
	if not overlay.visible or title.text != "VICTORY" or not detail.text.contains("Red: 0"):
		_fail("Victory result screen is not visible or has the wrong title.")
		return
	var viewport_size := battle.get_viewport_rect().size
	var content: Control = battle.get_node("CanvasLayer/ResultOverlay/Center/Content")
	var content_center := content.global_position + content.size / 2.0
	if not overlay.size.is_equal_approx(viewport_size) or content_center.distance_to(viewport_size / 2.0) > 2.0:
		_fail("Result layout mismatch: overlay=%s viewport=%s center=%s content=%s" % [str(overlay.size), str(viewport_size), str(content_center), str(content.size)])
		return
	battle.get_node("CanvasLayer/ResultOverlay/Center/Content/RestartButton").emit_signal("pressed")
	await process_frame
	if paused or current_scene == null or current_scene.get("battle_result") != "":
		_fail("Play Again must unpause and load a fresh battle.")
		return

	var new_battle: Node2D = current_scene
	var player_squads: Array = new_battle.get("player_squads")
	new_battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	for squad in player_squads:
		squad.apply_morale_change(-100.0)
	if new_battle.get("battle_result") != "DEFEAT" or not paused:
		_fail("All player squads routing must show defeat and pause combat.")
		return
	new_battle.get_node("CanvasLayer/ResultOverlay/Center/Content/MainMenuButton").emit_signal("pressed")
	await process_frame
	if paused or current_scene == null or current_scene.name != "MainMenu":
		_fail("Main Menu must work from the result screen.")
		return
	print("Result smoke passed: victory, restart, defeat, and return to main menu.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
