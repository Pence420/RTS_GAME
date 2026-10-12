extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var player_squads: Array = battle.get("player_squads")
	var enemy_squads: Array = battle.get("enemy_squads")
	var squad: BattleSquad = player_squads[1]
	var enemy_squad: BattleSquad = enemy_squads[1]
	var soldier: BattleUnit = squad.units[0]
	var enemy: BattleUnit = enemy_squad.units[0]
	battle.call("_select_at", soldier.global_position)

	squad.move_to(Vector2(550, 600))
	battle.get_node("CanvasLayer/CommandButtons/Hold").emit_signal("pressed")
	if squad.command != BattleSquad.Command.HOLD or soldier.manual_move or soldier._find_nearest_enemy() != null:
		_fail("Hold must cancel movement and ignore enemies beyond attack range.")
		return
	var old_enemy_position := enemy.global_position
	enemy.global_position = soldier.global_position + Vector2(20, 0)
	if soldier._find_nearest_enemy() != enemy:
		_fail("Hold must still detect an enemy in attack range.")
		return
	enemy.global_position = old_enemy_position

	battle.get_node("CanvasLayer/CommandButtons/Advance").emit_signal("pressed")
	battle.call("_issue_right_click", Vector2(550, 600))
	if squad.command != BattleSquad.Command.ADVANCE or not soldier.manual_move:
		_fail("Advance must allow a squad movement order.")
		return

	var normal_damage := enemy.calculate_damage_against(soldier)
	battle.get_node("CanvasLayer/CommandButtons/Defend").emit_signal("pressed")
	if squad.command != BattleSquad.Command.DEFEND or soldier.manual_move or enemy.calculate_damage_against(soldier) >= normal_damage:
		_fail("Defend must stop movement and reduce incoming damage.")
		return
	battle.call("_issue_right_click", Vector2(520, 600))
	if squad.command != BattleSquad.Command.DEFEND or not soldier.manual_move or soldier.command_speed_multiplier != 0.8:
		_fail("Defend reposition must keep the defense order and reduced speed.")
		return

	battle.get_node("CanvasLayer/CommandButtons/Charge").emit_signal("pressed")
	if squad.command != BattleSquad.Command.CHARGE or squad.target_squad == null or soldier.manual_move or soldier.command_speed_multiplier != 1.35:
		_fail("Charge must target the nearest enemy squad and override an old move order.")
		return
	soldier.charge_bonus_timer = 2.0
	var charged_damage := soldier.calculate_damage_against(enemy)
	soldier.charge_bonus_timer = 0.0
	var normal_charge_damage := soldier.calculate_damage_against(enemy)
	soldier.charge_bonus_timer = 2.0
	if charged_damage <= normal_charge_damage:
		_fail("Charge must provide a temporary damage bonus.")
		return

	battle.get_node("CanvasLayer/CommandButtons/FocusTarget").emit_signal("pressed")
	if not battle.get("pending_focus_target"):
		_fail("Focus Target must prompt for an enemy squad.")
		return
	battle.call("_issue_right_click", enemy.global_position)
	if squad.command != BattleSquad.Command.FOCUS_TARGET or squad.target_squad != enemy_squad or soldier.manual_move:
		_fail("Focus Target failed: command=%d target=%s moving=%s" % [squad.command, str(squad.target_squad), str(soldier.manual_move)])
		return
	var focused_enemy: BattleUnit = soldier._find_nearest_enemy()
	if focused_enemy == null or not enemy_squad.units.has(focused_enemy):
		_fail("Focused soldiers must seek only members of the chosen squad.")
		return

	for target in enemy_squad.units.duplicate():
		target.receive_damage(999)
	if squad.command != BattleSquad.Command.ADVANCE or squad.target_squad != null:
		_fail("A squad must return to Advance when its focused target is eliminated.")
		return
	print("Command smoke passed: Hold, Advance, Defend, Charge, and Focus Target.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
