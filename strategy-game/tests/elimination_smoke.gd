extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var blue: Array = battle.get("player_squads")
	var red: Array = battle.get("enemy_squads")
	var doomed: BattleSquad = blue[0]
	var hunter: BattleSquad = red[0]
	battle.call("_select_at", doomed.units[0].global_position)
	if battle.get("selected_squad") != doomed:
		_fail("Could not select the squad before elimination.")
		return
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	hunter.set_target(doomed, BattleSquad.Command.FOCUS_TARGET)
	for unit in doomed.units.duplicate():
		unit.receive_damage(1000.0)
	if blue.has(doomed) or battle.get("selected_squad") != null:
		_fail("Eliminated selected squad remains in the army or selection.")
		return
	if hunter.target_squad != null or hunter.command != BattleSquad.Command.ADVANCE:
		_fail("Hunter did not clear its eliminated target.")
		return
	if not battle.get_node("CanvasLayer/CommandButtons/Defend").disabled:
		_fail("Command buttons stayed enabled after the selected squad died.")
		return
	if battle.get("battle_result") != "":
		_fail("Battle ended while the player still had a fighting squad.")
		return
	for squad in blue.duplicate():
		for unit in squad.units.duplicate():
			unit.receive_damage(1000.0)
	if battle.get("battle_result") != "DEFEAT" or not paused:
		_fail("Eliminating every player squad did not end in defeat.")
		return
	print("Elimination smoke passed: selection, target cleanup, and defeat.")
	paused = false
	quit()


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
