extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var squad: BattleSquad = battle.player_squads[0]
	var enemy: BattleSquad = battle.enemy_squads[0]
	battle._select_at(squad.units[0].global_position)
	if squad.command != BattleSquad.Command.GUARD:
		_fail("Player squads should guard their deployment position by default")
		return
	battle._issue_right_click(Vector2(500, 500))
	if not squad.units[0].manual_move or squad.target_squad != null or squad.units[0].travel_speed_multiplier != 1.0:
		_fail("Single right-click did not issue a normal move")
		return
	var run_click := InputEventMouseButton.new()
	run_click.button_index = MOUSE_BUTTON_RIGHT
	run_click.pressed = true
	run_click.double_click = true
	run_click.position = battle.get_global_transform_with_canvas() * Vector2(550, 500)
	root.push_input(run_click, true)
	if squad.units[0].travel_speed_multiplier <= 1.0 or squad.ordered_center.distance_to(Vector2(550, 500)) > 1.0:
		_fail("Double right-click did not issue a run")
		return
	var destination := squad.units[0].destination
	battle.get_node("CanvasLayer/CommandButtons/Defend").emit_signal("pressed")
	if squad.stance != BattleSquad.Stance.DEFEND or not squad.units[0].manual_move or squad.units[0].destination != destination:
		_fail("Defend stance interrupted the player's active movement order")
		return
	battle._issue_right_click(enemy.units[0].global_position)
	if squad.target_squad != enemy or squad.units[0].manual_move or squad.units[0].command_damage_taken_multiplier != 0.8:
		_fail("Right-click attack did not choose the enemy while retaining Defend protection")
		return
	battle.get_node("CanvasLayer/CommandButtons/FullAttack").emit_signal("pressed")
	if squad.stance != BattleSquad.Stance.FULL_ATTACK or squad.target_squad != enemy or squad.command != BattleSquad.Command.CHARGE:
		_fail("Full Attack did not charge the explicitly chosen target")
		return
	battle._issue_right_click(Vector2(450, 600))
	if squad.units[0]._movement_speed() > squad.units[0].move_speed * 1.01:
		_fail("Full Attack stacks a run bonus onto an ordinary ground move")
		return
	if squad.target_squad != null or not squad.units[0].manual_move or squad.stance != BattleSquad.Stance.FULL_ATTACK:
		_fail("Ground move did not disengage while retaining the chosen stance")
		return
	battle.get_node("CanvasLayer/CommandButtons/FullAttack").emit_signal("pressed")
	if squad.stance != BattleSquad.Stance.AUTO or squad.command != BattleSquad.Command.GUARD:
		_fail("Toggling Full Attack off did not restore automatic guarding")
		return
	var commander: BattleUnit = battle.enemy_general
	battle._issue_right_click(commander.global_position)
	if squad.target_general != commander or not squad.units[0].focus_targets.has(commander):
		_fail("Right-clicking the enemy general does not give an explicit attack target")
		return
	var own_general: BattleUnit = battle.player_general
	battle._select_at(own_general.global_position)
	battle._issue_right_click(enemy.units[0].global_position)
	if own_general.command_mode != BattleUnit.Command.FOCUS_TARGET or not own_general.focus_targets.has(enemy.units[0]):
		_fail("The selected general cannot attack an enemy squad by right-click")
		return
	battle._issue_right_click(commander.global_position)
	commander.receive_damage(999)
	if squad.target_general != null or squad.command != BattleSquad.Command.GUARD or own_general.command_mode != BattleUnit.Command.HOLD:
		_fail("A slain general leaves a stale explicit attack target")
		return
	battle.queue_free()
	await process_frame
	await process_frame
	var unit_scene = load("res://scenes/unit.tscn")
	var defender: BattleUnit = unit_scene.instantiate()
	defender.position = Vector2(500, 450)
	root.add_child(defender)
	defender.set_command(BattleUnit.Command.DEFEND)
	defender.combat_enabled = true
	var foe: BattleUnit = unit_scene.instantiate()
	foe.team = 1
	foe.position = Vector2(800, 450)
	root.add_child(foe)
	for frame in range(20):
		await physics_frame
	if defender.position.distance_to(Vector2(500, 450)) > 0.1:
		_fail("Defender abandons its position to pursue a distant enemy")
		return
	foe.position = Vector2(570, 450)
	for frame in range(60):
		await physics_frame
	if foe.current_hp >= foe.max_hp or defender.position.distance_to(defender.guard_anchor) > 61.0:
		_fail("Defender stands idle against a nearby enemy or breaks its guard leash")
		return
	foe.position = Vector2(1000, 450)
	for frame in range(90):
		await physics_frame
	if defender.position.distance_to(defender.guard_anchor) > 1.0:
		_fail("Defender did not return to formation after the enemy left")
		return
	print("Direct orders passed: right-click move/run/attack, independent Defend/Full Attack stances, nearby counterattack, guard leash, and formation return.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
