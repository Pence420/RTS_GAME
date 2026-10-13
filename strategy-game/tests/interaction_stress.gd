extends SceneTree

const SCENARIOS := 12
const MAX_FRAMES := 1800

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	rng.seed = 20261008
	Engine.time_scale = 8.0
	var results: Dictionary = {}
	for scenario in range(SCENARIOS):
		var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
		root.add_child(battle)
		var blue: Array = battle.get("player_squads")
		var red: Array = battle.get("enemy_squads")
		if scenario % 3 == 0:
			for squad in blue:
				squad.set_formation(BattleSquad.Formation.WEDGE)
				squad.set_target(red[0], BattleSquad.Command.CHARGE)
		battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
		for frame in range(MAX_FRAMES):
			if frame % 30 == 0:
				_random_order(battle)
				var problem := _check_invariants(battle)
				if problem != "":
					_fail("Scenario %d frame %d: %s" % [scenario, frame, problem])
					return
			if battle.get("battle_result") != "":
				break
			await physics_frame
		var result: String = battle.get("battle_result")
		results[result] = results.get(result, 0) + 1
		var problem := _check_invariants(battle)
		if problem != "":
			_fail("Scenario %d final: %s" % [scenario, problem])
			return
		paused = false
		battle.queue_free()
		await process_frame
	print("Interaction stress passed: %d scenarios, results %s" % [SCENARIOS, str(results)])
	Engine.time_scale = 1.0
	quit()


func _random_order(battle: Node2D) -> void:
	var blue: Array = battle.get("player_squads")
	var red: Array = battle.get("enemy_squads")
	if blue.is_empty() or battle.get("battle_result") != "":
		return
	if rng.randi_range(0, 7) == 0:
		var general: BattleUnit = battle.get("player_general")
		if is_instance_valid(general):
			battle.call("_select_at", general.global_position)
			battle.call("_issue_right_click", Vector2(rng.randf_range(350.0, 1050.0), rng.randf_range(200.0, 700.0)))
			return
	var squad: BattleSquad = blue[rng.randi_range(0, blue.size() - 1)]
	if squad.routing or squad.units.is_empty():
		return
	battle.call("_select_at", squad.units[0].global_position)
	if battle.get("selected_squad") != squad:
		return
	match rng.randi_range(0, 5):
		0:
			battle.call("_on_formation_pressed", rng.randi_range(0, 3))
		1:
			battle.call("_on_stance_pressed", rng.randi_range(1, 2))
		2:
			battle.call("_issue_right_click", Vector2(rng.randf_range(200.0, 1400.0), rng.randf_range(180.0, 720.0)), rng.randi_range(0, 1) == 1)
		3:
			if not red.is_empty():
				var enemy: BattleSquad = red[rng.randi_range(0, red.size() - 1)]
				if not enemy.routing and not enemy.units.is_empty():
					battle.call("_issue_right_click", enemy.units[0].global_position)
		4:
			battle.call("_on_stance_pressed", BattleSquad.Stance.FULL_ATTACK)
		5:
			battle.call("_on_pointer_mode_pressed", 2)
			if not red.is_empty():
				var enemy: BattleSquad = red[rng.randi_range(0, red.size() - 1)]
				if not enemy.routing and not enemy.units.is_empty():
					battle.call("_issue_right_click", enemy.units[0].global_position)


func _check_invariants(battle: Node2D) -> String:
	for team in range(2):
		var squads: Array = battle.get("player_squads") if team == 0 else battle.get("enemy_squads")
		for squad in squads:
			if not is_instance_valid(squad):
				return "army contains a freed squad"
			if squad.team != team or squad.units.is_empty():
				return "army contains wrong-team or empty squad"
			if squad.target_squad != null and (not is_instance_valid(squad.target_squad) or squad.target_squad.routing):
				return "squad has an invalid target"
			if squad.routing and squad.target_squad != null:
				return "routing squad still has a target"
			for unit in squad.units:
				if not is_instance_valid(unit) or unit.team != team:
					return "squad contains a freed or wrong-team unit"
				if unit.current_hp <= 0.0 or unit.current_hp > unit.max_hp:
					return "unit health is out of bounds"
				if not unit.global_position.is_finite() or not unit.destination.is_finite():
					return "unit position is not finite"
	var result: String = battle.get("battle_result")
	if result != "":
		if not paused or not battle.get_node("CanvasLayer/ResultOverlay").visible:
			return "finished battle is not paused with visible result"
		if battle.get_node("EnemyAI").active:
			return "enemy AI stays active after battle result"
	return ""


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	Engine.time_scale = 1.0
	quit(1)
