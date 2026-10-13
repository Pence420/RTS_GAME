extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 8.0
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var player_squads: Array = battle.get("player_squads")
	var enemy_squads: Array = battle.get("enemy_squads")
	for squad in player_squads:
		squad.set_formation(BattleSquad.Formation.WEDGE)
		squad.set_target(enemy_squads[0], BattleSquad.Command.CHARGE)
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	for frame in range(3600):
		if battle.get("battle_result") != "":
			break
		# Keep the rally aura near advancing infantry instead of leaving the
		# General at deployment while fighting across the larger field.
		if frame % 45 == 0 and is_instance_valid(battle.player_general):
			var center := Vector2.ZERO
			var count := 0
			for squad in player_squads:
				if squad.unit_type != BattleUnit.UnitType.ARCHER and not squad.routing:
					center += squad.get_center()
					count += 1
			if count > 0:
				battle._select_at(battle.player_general.global_position)
				battle._issue_move(center / count - Vector2(100, 0))
		await physics_frame
	var result: String = battle.get("battle_result")
	if result != "VICTORY":
		_fail("Coordinated charge with General support did not produce a playable win; result was " + result)
		return
	print("Player strategy smoke passed: coordinated charge with General rally support won naturally.")
	_cleanup()
	quit()


func _fail(message: String) -> void:
	push_error(message)
	_cleanup()
	quit(1)


func _cleanup() -> void:
	paused = false
	Engine.time_scale = 1.0
