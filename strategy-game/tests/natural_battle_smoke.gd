extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 8.0
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	for frame in range(3600):
		if battle.get("battle_result") != "":
			break
		await physics_frame
	var result: String = battle.get("battle_result")
	if result == "":
		var blue: Array = battle.get("player_squads")
		var red: Array = battle.get("enemy_squads")
		_fail("Natural battle did not finish within 3600 physics frames (blue squads %d, red squads %d)." % [blue.size(), red.size()])
		return
	if result != "VICTORY" and result != "DEFEAT" and result != "DRAW":
		_fail("Natural battle returned an unknown result: " + result)
		return
	print("Natural battle smoke passed: %s." % result)
	_cleanup()
	quit()


func _fail(message: String) -> void:
	push_error(message)
	_cleanup()
	quit(1)


func _cleanup() -> void:
	paused = false
	Engine.time_scale = 1.0
