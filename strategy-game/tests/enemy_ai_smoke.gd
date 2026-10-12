extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var player_squads: Array = battle.get("player_squads")
	var enemy_squads: Array = battle.get("enemy_squads")
	var reserve: BattleSquad = enemy_squads[1]
	var initial_center := reserve.get_center()
	for frame in range(60):
		await physics_frame
	if reserve.target_squad != null or not reserve.get_center().is_equal_approx(initial_center):
		_fail("Enemy AI must wait during deployment.")
		return

	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	if not battle.get("battle_started") or reserve.target_squad == null:
		_fail("Start Battle did not activate enemy AI.")
		return
	for unit in reserve.units:
		if not unit.combat_enabled:
			_fail("Start Battle did not enable soldier combat.")
			return
	for frame in range(90):
		await physics_frame
	if reserve.get_center().distance_to(initial_center) < 30.0:
		_fail("Enemy reserve did not advance toward the player army.")
		return

	var first_target := reserve.target_squad
	for unit in first_target.units.duplicate():
		unit.receive_damage(999)
	if player_squads.has(first_target):
		_fail("Eliminated player squad remained in the army list.")
		return
	for frame in range(90):
		await physics_frame
	if reserve.target_squad == null or reserve.target_squad == first_target or not player_squads.has(reserve.target_squad):
		_fail("Enemy AI did not select a surviving player squad after losing its target.")
		return
	print("Enemy AI smoke passed: deployment, advance, and target reassignment.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
