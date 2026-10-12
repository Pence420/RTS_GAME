extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var blue: BattleSquad = battle.get("player_squads")[0]
	var red: BattleSquad = battle.get("enemy_squads")[0]
	blue.set_target(red, BattleSquad.Command.FOCUS_TARGET)
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	var casualty: BattleUnit = red.units[0]
	casualty.receive_damage(1000.0)
	if red.units.has(casualty) or blue.target_squad != red:
		_fail("Focused squad lost its target after a single casualty.")
		return
	for frame in range(60):
		await physics_frame
		if battle.get("battle_result") != "":
			break
	if battle.get("battle_result") != "" or red.units.is_empty():
		_fail("Battle ended unexpectedly after a single focused casualty.")
		return
	var next_target: BattleUnit = blue.units[0]._find_nearest_enemy()
	if next_target == null or not red.units.has(next_target):
		_fail("Focused squad did not retarget a surviving enemy.")
		return
	print("Target casualty smoke passed: surviving target retained.")
	paused = false
	quit()


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
