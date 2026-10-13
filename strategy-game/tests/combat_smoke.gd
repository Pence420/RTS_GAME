extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var player_squads: Array = battle.get("player_squads")
	var enemy_squads: Array = battle.get("enemy_squads")
	var enemy_reserve_start: Vector2 = enemy_squads[1].get_center()
	if player_squads.size() != 4 or enemy_squads.size() != 4:
		_fail("Expected four squads on each team.")
		return

	var reserve: BattleSquad = player_squads[1]
	battle.call("_select_at", reserve.units[0].global_position)
	if battle.get("selected_squad") != reserve:
		_fail("Clicking a soldier did not select its whole squad.")
		return
	battle.get_node("CanvasLayer/FormationButtons/Column").emit_signal("pressed")
	if reserve.formation != BattleSquad.Formation.COLUMN or not _has_column_rows(reserve):
		_fail("Column formation did not arrange soldiers into five rows.")
		return
	battle.get_node("CanvasLayer/FormationButtons/ShieldWall").emit_signal("pressed")
	if reserve.units[0].formation_speed_multiplier != 0.8 or reserve.units[0].destination.x != reserve.units[9].destination.x:
		_fail("Shield Wall did not apply its movement penalty and wall slots.")
		return
	var enemy: BattleUnit = enemy_squads[1].units[0]
	if enemy.calculate_damage_against(reserve.units[0]) >= 6:
		_fail("Shield Wall did not reduce incoming damage.")
		return
	battle.get_node("CanvasLayer/FormationButtons/Wedge").emit_signal("pressed")
	var wedge_damage := reserve.units[0].calculate_damage_against(enemy)
	reserve.units[0].formation_attack_multiplier = 1.0
	var normal_damage := reserve.units[0].calculate_damage_against(enemy)
	reserve.units[0].formation_attack_multiplier = 1.1
	if wedge_damage <= normal_damage or not _has_wedge_point(reserve):
		_fail("Wedge did not apply its attack bonus and forward point.")
		return
	battle.get_node("CanvasLayer/FormationButtons/Line").emit_signal("pressed")
	if reserve.units[0].formation_speed_multiplier != 1.0 or reserve.units[0].formation_attack_multiplier != 1.0:
		_fail("Line did not clear formation bonuses.")
		return
	reserve.move_to(Vector2(550, 600))
	for unit in reserve.units:
		if not unit.manual_move:
			_fail("Squad move did not order every surviving soldier.")
			return
	if reserve.units[0].destination == reserve.units[1].destination:
		_fail("Squad move did not preserve distinct soldier slots.")
		return
	reserve.units[0].receive_damage(5)
	var status_label: Label = battle.get_node("CanvasLayer/Status")
	if not status_label.text.contains("HP 99%"):
		_fail("Selected squad HP did not refresh when a soldier took damage.")
		return

	for frame in range(120):
		await physics_frame
	if not enemy_squads[1].get_center().is_equal_approx(enemy_reserve_start):
		_fail("Enemy reserve moved during deployment.")
		return
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	if not battle.get("battle_started") or enemy_squads[0].target_squad == null or enemy_squads[1].target_squad == null:
		_fail("Start Battle did not enable combat and enemy squad orders.")
		return
	for frame in range(480):
		await physics_frame
	var survivors := 0
	for squad in player_squads + enemy_squads:
		survivors += squad.units.size()
	if survivors >= 80:
		_fail("Expected the nearby squads to fight until a soldier dies.")
		return
	print("Squad and combat smoke passed: %d of 80 soldiers survived." % survivors)
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_column_rows(squad: BattleSquad) -> bool:
	var rows := {}
	for unit in squad.units:
		rows[snappedf(unit.destination.y, 0.1)] = true
	return rows.size() == 5


func _has_wedge_point(squad: BattleSquad) -> bool:
	var front := -INF
	for unit in squad.units:
		front = maxf(front, unit.destination.x)
	var front_count := 0
	for unit in squad.units:
		if is_equal_approx(unit.destination.x, front):
			front_count += 1
	return front_count == 1 and front > squad.ordered_center.x
