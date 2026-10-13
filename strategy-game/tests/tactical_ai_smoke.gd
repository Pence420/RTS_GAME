extends SceneTree

const UNIT_SCENE = preload("res://scenes/unit.tscn")
const SQUAD_SCENE = preload("res://scenes/squad.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Equal logic for both teams: favor a useful matchup over a tiny distance gain.
	for team in [0, 1]:
		for pair in [[BattleUnit.UnitType.SWORDSMAN, BattleUnit.UnitType.SPEARMAN], [BattleUnit.UnitType.AXEMAN, BattleUnit.UnitType.SWORDSMAN], [BattleUnit.UnitType.ARCHER, BattleUnit.UnitType.AXEMAN]]:
			var actor := _unit(team, pair[0], Vector2(500, 450))
			var ordinary := _unit(1 - team, BattleUnit.UnitType.ARCHER, Vector2(600, 450))
			var preferred := _unit(1 - team, pair[1], Vector2(615, 480))
			if actor._find_nearest_enemy() != preferred:
				_fail("Soldier ignores its tactical matchup on team %d, role %d" % [team, pair[0]])
				return
			actor.set_command(BattleUnit.Command.FOCUS_TARGET)
			actor.set_focus_targets([ordinary])
			if actor._find_nearest_enemy() != ordinary:
				_fail("Role preference overrides the player's explicit focus target")
				return
			actor.queue_free()
			ordinary.queue_free()
			preferred.queue_free()
			await process_frame
			await process_frame
	var archer := _unit(0, BattleUnit.UnitType.ARCHER, Vector2(500, 450))
	var enemy_archer := _unit(1, BattleUnit.UnitType.ARCHER, Vector2(550, 450))
	if archer._nearby_melee_threat() != null:
		_fail("An archer treats another archer as a melee threat")
		return
	enemy_archer.queue_free()
	await process_frame
	await process_frame
	var foe := _unit(1, BattleUnit.UnitType.SWORDSMAN, Vector2(550, 450))
	archer.combat_enabled = true
	for frame in range(70):
		await physics_frame
	if archer.global_position.distance_to(foe.global_position) < 110.0:
		_fail("Archer stops retreating before opening safe firing space")
		return
	archer.set_command(BattleUnit.Command.HOLD)
	var held_position := archer.global_position
	for frame in range(12):
		await physics_frame
	if archer.global_position.distance_to(held_position) > 0.1:
		_fail("Autonomous retreat overrides Hold")
		return
	archer.move_to(held_position + Vector2(0, 65))
	await physics_frame
	await physics_frame
	if archer.global_position.y <= held_position.y:
		_fail("Autonomous tactics override a manual move")
		return
	archer.queue_free()
	foe.queue_free()
	await process_frame
	await process_frame
	# A nearby vulnerable ally makes interception preferable to a slightly
	# closer unrelated melee opponent. Exercise the same rule on both teams.
	for team in [0, 1]:
		var guard := _unit(team, BattleUnit.UnitType.SPEARMAN, Vector2(500, 450))
		var closer := _unit(1 - team, BattleUnit.UnitType.SWORDSMAN, Vector2(600, 380))
		var danger := _unit(1 - team, BattleUnit.UnitType.SWORDSMAN, Vector2(650, 450))
		var vulnerable := _unit(team, BattleUnit.UnitType.ARCHER, Vector2(715, 450))
		if guard._find_nearest_enemy() != danger:
			_fail("Infantry ignores an enemy threatening its own archer")
			return
		vulnerable.unit_type = BattleUnit.UnitType.SWORDSMAN
		vulnerable.is_general = true
		if guard._find_nearest_enemy() != danger:
			_fail("Infantry ignores an enemy threatening its own general")
			return
		for unit in [guard, closer, danger, vulnerable]:
			unit.queue_free()
		await process_frame
		await process_frame
	var straggler := _unit(0, BattleUnit.UnitType.SWORDSMAN, Vector2(700, 450))
	var distant := _unit(1, BattleUnit.UnitType.SWORDSMAN, Vector2(900, 450))
	straggler.squad_attached = true
	straggler.squad_center = Vector2(500, 450)
	straggler.combat_enabled = true
	await physics_frame
	await physics_frame
	if straggler.velocity.x >= 0.0 or not straggler.regrouping:
		_fail("A lone advancing straggler abandons its squad instead of regrouping")
		return
	straggler.set_command(BattleUnit.Command.FOCUS_TARGET)
	straggler.set_focus_targets([distant])
	await physics_frame
	await physics_frame
	if straggler.velocity.x <= 0.0:
		_fail("Cohesion overrides the player's explicit focused attack")
		return
	straggler.queue_free()
	distant.queue_free()
	await process_frame
	await process_frame
	var battle = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	var chosen := {}
	for squad in battle.enemy_squads:
		if squad.target_squad != null:
			chosen[squad.target_squad] = true
	if chosen.size() < 2:
		_fail("Enemy army funnels every squad into the same target")
		return
	print("Tactical AI passed: mirrored role choices, explicit focus, ranged threat recognition, safe retreat, ally protection, cohesion, player order priority, and army target distribution.")
	quit()

func _unit(team: int, role: int, point: Vector2) -> BattleUnit:
	var unit := UNIT_SCENE.instantiate() as BattleUnit
	unit.team = team
	unit.configure_type(role)
	unit.position = point
	root.add_child(unit)
	return unit

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
